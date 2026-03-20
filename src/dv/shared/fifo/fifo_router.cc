#include <atomic>
#include <cassert>
#include <cerrno>
#include <chrono>
#include <climits>
#include <csignal>
#include <cstdio>
#include <cstdlib>
#include <getopt.h>
#include <iostream>
#include <optional>
#include <thread>
#include <unistd.h>

#include "verilated.h"
#include "verilated_fst_c.h"
#include "Vfifo_router.h"

#define TRACE_NAME "waveform.fst"
#define DUT_TYPE Vfifo_router

#define GET_PACKET_WEN(packet) (packet[4UL] & 0x1)
#define GET_PACKET_ID(packet) (packet[3UL])
#define GET_PACKET_ADDR(packet) (packet[2UL])
#define GET_PACKET_PAYLOAD(packet) \
    (((uint64_t)((uint64_t)(packet[1UL])) << 32UL) | ((uint64_t)(packet[0UL])))
#define SET_PACKET_WEN(packet, wen) \
    packet[4UL] = (wen & 0x1);
#define SET_PACKET_ID(packet, id) \
    packet[3UL] = id;
#define SET_PACKET_ADDR(packet, addr) \
    packet[2UL] = addr;
#define SET_PACKET_PAYLOAD(packet, payload) \
    packet[1UL] = (((uint64_t) payload) >> 32) & 0xFFFFFFFF; \
    packet[0UL] = (((uint64_t) payload)) & 0xFFFFFFFF;

struct TBCfg {
    bool trace_en;
    unsigned long cycle_limit;
    DUT_TYPE *dutp;
    VerilatedFstC *tracep;
};

struct netReqPacket {
    bool wen;
    uint32_t id;
    uint32_t addr;
    uint64_t payload;
    uint64_t payload_comp;
};

const TBCfg default_config {
    .trace_en = false,
    .cycle_limit = 100000,
    .dutp = NULL,
    .tracep = NULL
};

static TBCfg config;

std::deque<netReqPacket> requestBufferQueue = {};
std::deque<netReqPacket> commitBufferQueue = {};
std::deque<netReqPacket> even_net_packet_queue = {};
std::deque<netReqPacket> odd_net_packet_queue = {};

vluint64_t sim_time = 0;
vluint64_t cycles = 0;

void print_config(TBCfg& config);
void print_help();
auto parse_cli(int argc, char **argv) -> std::optional<TBCfg>;
void signal_handler (int signum);
void tick (DUT_TYPE& dut, VerilatedFstC& trace);
void reset (DUT_TYPE& dut, VerilatedFstC& trace);
void req_reset (DUT_TYPE& dut);
void net_reset (DUT_TYPE& dut);
void req_create (
    DUT_TYPE& dut,
    bool ren,
    bool wen,
    uint64_t addr,
    uint64_t payload
);
void net_req_accept (DUT_TYPE& dut, VerilatedFstC& trace);
void net_req_comp (DUT_TYPE& dut, std::deque<netReqPacket>& packet_queue);
void req_complete (DUT_TYPE& dut, VerilatedFstC& trace, netReqPacket packet);

void print_config (TBCfg& config) {
    std::cout << "Configuration: " << std::endl;
    std::cout << "\tTrace: " << ((config.trace_en) ? "Enabled" : "Disabled") << std::endl;
    std::cout << "\tCycle Limit: " << config.cycle_limit << std::endl;
}

void print_help () {
    std::cerr << "Usage: ./Vfifo_router [flags...]" << std::endl;
    std::cerr << "\t--trace-en: Enable FST wave tracing" << std::endl;
    std::cerr << "\t--cycle-limit n: Set cycle count limit to n" << std::endl;
    std::cerr << "\t--help: Print this" << std::endl;
}

auto parse_cli (int argc, char **argv) -> std::optional<TBCfg> {
    static struct option long_options[] = {
        {"trace-en",        no_argument,        0, 't'},
        {"cycle-limit",     required_argument,  0, 'c'},
        {"help",            no_argument,        0, 'h'},
        {0, 0, 0, 0}
    };

    TBCfg config = default_config;
    int option_index = 0;
    char *endp = NULL;

    for(;;) {
        int c = getopt_long(argc, argv, "t:c:h", long_options, &option_index);
        if(c == -1) {
            break;
        }

        switch(c) {
            case '?':
            case 'h':
                print_help();
                return {};
                break;
            case 't':
                config.trace_en = true;
                break;
            case 'c':
                endp = nullptr;
                errno = 0;
                config.cycle_limit = std::strtoul(optarg, &endp, 0);
                if(errno == ERANGE) {
                    std::cerr << "Error: Input value " << optarg << " for cycle-limit "
                        << " does not fit within an unsigned long" << std::endl;
                    return {};
                } else if(errno == EINVAL) {
                    std::cerr << "Error: Input value " << optarg << " for cycle-limit "
                        << " did not have a valid base" << std::endl;
                    return {};
                }
                break;
        }
    }

    return std::make_optional(std::move(config));
}

void signal_handler (int signum) {
    std::cout << "Got signal " << signum << std::endl;

    config.dutp->final();

    if (config.trace_en)
        config.tracep->close();

    exit(1);
}

void tick (DUT_TYPE& dut, VerilatedFstC& trace) {
    dut.CLK = 0;
    dut.eval();
    if (config.trace_en)
        trace.dump(sim_time);
    sim_time++;

    dut.CLK = 1;
    dut.eval();
    if (config.trace_en)
        trace.dump(sim_time);
    sim_time++;

    cycles++;

    req_reset(dut);
    net_reset(dut);
}

void reset (DUT_TYPE& dut, VerilatedFstC& trace) {
    // Initialize signals
    dut.CLK = 0;
    dut.nRST = 0;
    req_reset(dut);
    net_reset(dut);

    tick(dut, trace);
    dut.nRST = 0;
    tick(dut, trace);
    dut.nRST = 1;
    tick(dut, trace);

    tick(dut, trace);
    dut.nRST = 0;
    tick(dut, trace);
    dut.nRST = 1;
    tick(dut, trace);
}

void req_reset (DUT_TYPE& dut) {
    // into FIFO buffer
    dut.req_en = 0;
    SET_PACKET_WEN(dut.req_packet, 0);
    SET_PACKET_ID(dut.req_packet, 0);
    SET_PACKET_ADDR(dut.req_packet, 0);
    SET_PACKET_PAYLOAD(dut.req_packet, 0);

    // for committing requests to FIFO
    dut.req_comp_stall = 1;
}

void net_reset (DUT_TYPE& dut){
    // to network
    dut.net_stall = 1;

    // from network
    dut.net_en_comp = 0;
    SET_PACKET_WEN(dut.net_comp_packet, 0);
    SET_PACKET_ID(dut.net_comp_packet, 0);
    SET_PACKET_ADDR(dut.net_comp_packet, 0);
    SET_PACKET_PAYLOAD(dut.net_comp_packet, 0);
}

void req_create (
    DUT_TYPE& dut,
    bool ren,
    bool wen,
    uint64_t addr,
    uint64_t payload
) {
    std::cout << "[INFO] Creating Request to FIFO Router" << std::endl;
    std::cout << "       req_en             : " << (ren || wen) << std::endl;
    std::cout << "       req_packet.wen     : " << wen << std::endl;
    std::cout << "       req_packet.addr    : 0x" << std::hex << addr << std::dec << std::endl;
    std::cout << "       req_packet.payload : 0x" << std::hex << payload << std::dec << "\n" << std::endl;

    // PACKET_T new_packet;
    dut.req_en = ren || wen;
    SET_PACKET_WEN(dut.req_packet, wen);
    SET_PACKET_ID(dut.req_packet, 0);
    SET_PACKET_ADDR(dut.req_packet, addr);
    SET_PACKET_PAYLOAD(dut.req_packet, payload);

    netReqPacket packet {
        .wen = wen,
        .id = 0,
        .addr = addr,
        .payload = payload,
        .payload_comp = 0,
    };

    requestBufferQueue.push_back(packet);
}

void net_req_accept (DUT_TYPE& dut, VerilatedFstC& trace) {
    // randomly wait at most 10 cycles before accepting
    for (int i = 0; i < std::rand() % 10; i++) {
        tick(dut, trace);
        net_reset(dut);
    }

    dut.net_stall = 0;

    uint32_t r1 = std::rand();
    uint32_t r2 = std::rand();
    netReqPacket packet {
        .wen = (bool) GET_PACKET_WEN(dut.net_packet),
        .id = GET_PACKET_ID(dut.net_packet),
        .addr = GET_PACKET_ADDR(dut.net_packet),
        .payload = GET_PACKET_PAYLOAD(dut.net_packet),
        .payload_comp = (( (uint64_t)(r1) ) << 32) + ((uint64_t)(r2))
    };

    std::cout << "[INFO] Network Accepting Request from FIFO Router" << std::endl;
    std::cout << "       Generating a payload comp for TB..." << std::endl;
    std::cout << "       packet.wen     : " << packet.wen << std::endl;
    std::cout << "       packet.id      : " << packet.id << std::endl;
    std::cout << "       packet.addr    : 0x" << std::hex << packet.addr << std::dec << std::endl;
    std::cout << "       packet.payload : 0x" << std::hex << packet.payload << std::dec << std::endl;
    std::cout << "       return payload : 0x" << std::hex << packet.payload_comp << std::dec << "\n" << std::endl;

    if (packet.id % 2)
        odd_net_packet_queue.push_back(packet);
    else
        even_net_packet_queue.push_back(packet);

    // sanity checks
    if (packet.wen != requestBufferQueue.front().wen) {
        std::cout << "requestBufferQueue.front().addr: 0x" << std::hex << requestBufferQueue.front().addr << std::dec << "\n" << std::endl;
        exit(1);
    };

    netReqPacket request = requestBufferQueue.front();
    assert(packet.wen == request.wen);
    assert(packet.addr == request.addr);
    assert(packet.payload == request.payload);

    request.payload_comp = packet.payload_comp;
    commitBufferQueue.push_back(request);
    requestBufferQueue.pop_front();
}

void net_req_comp (
    DUT_TYPE& dut,
    std::deque<netReqPacket>& packet_queue
) {
    // randomly select an index to pop between [1, size)
    // (or [0] if size == 1)
    int idx = std::rand() % (packet_queue.size() - 1);

    // ensure we're not popping the first index
    if (packet_queue.size() > 1) idx++;
    else idx = 0;

    netReqPacket packet = packet_queue[idx];

    std::cout << "[INFO] Network Completing Request from FIFO Router" << std::endl;
    std::cout << "       net_comp_packet.id      : " << packet.id << std::endl;
    std::cout << "       net_comp_packet.payload : 0x" << std::hex << packet.payload_comp << std::dec << "\n" << std::endl;

    dut.net_en_comp = true;
    SET_PACKET_ID(dut.net_comp_packet, packet.id);
    SET_PACKET_PAYLOAD(dut.net_comp_packet, packet.payload_comp);

    int i = 0;
    for (std::deque<netReqPacket>::iterator it = packet_queue.begin(); it != packet_queue.end();) {
        if (i == idx) {
            packet_queue.erase(it);
            break;
        } else {
            ++it;
        }
        i++;
    }
}


void req_complete (DUT_TYPE& dut, VerilatedFstC& trace, netReqPacket packet) {
    // randomly wait at most 2 cycles before accepting
    for (int i = 0; i < std::rand() % 2; i++) {
        tick(dut, trace);
    }

    dut.req_comp_stall = 0;
    uint32_t comp_addr = GET_PACKET_ADDR(dut.req_comp_packet);
    uint64_t comp_payload = GET_PACKET_PAYLOAD(dut.req_comp_packet);

    std::cout << "[INFO] Committing Request from FIFO Router" << std::endl;
    std::cout << "       req_comp         : " << (bool) dut.req_comp << std::endl;
    std::cout << "       req_addr_comp    : 0x" << std::hex << comp_addr << std::dec << std::endl;
    std::cout << "       expected addr    : 0x" << std::hex << packet.addr << std::dec << std::endl;
    std::cout << "       req_payload_comp : 0x" << std::hex << comp_payload << std::dec << std::endl;
    std::cout << "       expected payload : 0x" << std::hex << packet.payload_comp << std::dec << "\n" << std::endl;

    assert((bool) dut.req_comp);
    assert(packet.addr == comp_addr);
    assert(packet.payload_comp == comp_payload);
    tick(dut, trace);
}

int main (int argc, char **argv) {
    if (auto result = parse_cli(argc, argv)) {
        config = *result;
    } else {
        return EXIT_FAILURE;
    }

    print_config(config);

    DUT_TYPE dut;
    VerilatedFstC trace;

    config.dutp = &dut;
    config.tracep = &trace;

    if (config.trace_en) {
        Verilated::traceEverOn(true);
        dut.trace(&trace, 5);
        trace.open(TRACE_NAME);
    }

    signal(SIGINT, signal_handler);

    std::cout << "------------------" << std::endl;
    std::cout << " Simulation Begin" << std::endl;
    std::cout << "------------------" << std::endl;

    std::srand(std::time(0));
    auto tstart = std::chrono::high_resolution_clock::now();

    reset(dut, trace);

    tick(dut, trace);

    // Empty Signal should be raised
    assert(dut.fifo_router_empty);

    // Fill the buffer
    for (int i = 0; !dut.fifo_router_full; i++) {
        uint32_t r1 = std::rand();
        uint32_t r2 = std::rand();
        req_create(dut,
            r1 % 2,
            (r1 + 1) % 2,
            r1 + r2,
            (( (uint64_t)(r1) ) << 32) + ((uint64_t)(r2))
        );
        tick(dut, trace);
    }

    // sanity checks on FIFO being full
    assert(dut.fifo_router_full);
    for (int i = 0; i < 5; i++) {
        tick(dut, trace);
        assert(dut.fifo_router_full);
    }

    // take in two requests
    net_req_accept(dut, trace);
    tick(dut, trace);
    net_reset(dut);

    net_req_accept(dut, trace);
    tick(dut, trace);
    net_reset(dut);

    assert(even_net_packet_queue.size() == 1);
    assert(odd_net_packet_queue.size() == 1);

    for (int i = 0; !even_net_packet_queue.empty() || !odd_net_packet_queue.empty(); i++) {
        assert(!dut.req_comp);

        // once there are 2 packets left to send to the network,
        // lets start completing some packets out of order
        if (requestBufferQueue.size() <= 2) {
            if (i % 2)
                net_req_comp(dut, even_net_packet_queue);
            else
                net_req_comp(dut, odd_net_packet_queue);
        }

        // begin accepting packets into the network
        if (requestBufferQueue.size() > 0)
            net_req_accept(dut, trace);

        tick(dut, trace);
        net_reset(dut);
    }

    for (std::deque<netReqPacket>::iterator it = commitBufferQueue.begin(); it != commitBufferQueue.end();) {
        req_complete(dut, trace, *it);
        ++it;
    }

    reset(dut, trace);
    tick(dut, trace);

    // End test bench
    auto tend = std::chrono::high_resolution_clock::now();
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(tend - tstart);
    std::cout   << "Simulated " << sim_time 
                << " cycles in " << ms.count() << "ms" 
                << ", rate of " << (float)sim_time / ((float)ms.count() / 1000.0) 
                << " cycles per second." << std::endl;

    if(config.trace_en)
        trace.close();

    dut.final();

    return EXIT_SUCCESS;
}
