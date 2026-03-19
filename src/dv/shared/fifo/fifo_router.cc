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

struct TBCfg {
    bool trace_en;
    unsigned long cycle_limit;
    DUT_TYPE *dutp;
    VerilatedFstC *tracep;
};

struct netReqPacket {
    bool wen;
    uint64_t id;
    uint64_t addr;
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
void req_create (
    DUT_TYPE& dut,
    bool ren,
    bool wen,
    uint64_t req_addr,
    uint64_t req_payload
);
void req_reset (DUT_TYPE& dut);
void net_req_accept (DUT_TYPE& dut, VerilatedFstC& trace);
void net_req_comp (DUT_TYPE& dut, std::deque<netReqPacket>& packet_queue);
void net_reset (DUT_TYPE& dut);

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

void req_create (
    DUT_TYPE& dut,
    bool req_ren,
    bool req_wen,
    uint64_t req_addr,
    uint64_t req_payload
) {
    std::cout << "[INFO] Creating Request to FIFO Router" << std::endl;
    std::cout << "       req_ren     : " << req_ren << std::endl;
    std::cout << "       req_wen     : " << req_wen << std::endl;
    std::cout << "       req_addr    : 0x" << std::hex << req_addr << std::dec << std::endl;
    std::cout << "       req_payload : 0x" << std::hex << req_payload << std::dec << "\n" << std::endl;
    dut.req_ren = req_ren;
    dut.req_wen = req_wen;
    dut.req_addr = req_addr;
    dut.req_payload = req_payload;

    netReqPacket packet {
        .wen = req_wen,
        .id = 0,
        .addr = req_addr,
        .payload = req_payload,
        .payload_comp = 0,
    };

    requestBufferQueue.push_back(packet);
}

void req_reset (DUT_TYPE& dut) {
    // into FIFO buffer
    dut.req_ren = 0;
    dut.req_wen = 0;
    dut.req_addr = 0;
    dut.req_payload = 0;
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
        .wen = (bool) dut.net_req_wen,
        .id = dut.net_req_id,
        .addr = dut.net_req_addr,
        .payload = dut.net_req_payload,
        .payload_comp = (( (uint64_t)(r1) ) << 32) + ((uint64_t)(r2))
    };

    std::cout << "[INFO] Network Accepting Request from FIFO Router" << std::endl;
    std::cout << "       Generating a payload comp for TB..." << std::endl;
    std::cout << "       net_req_wen     : " << packet.wen << std::endl;
    std::cout << "       net_req_id      : " << packet.id << std::endl;
    std::cout << "       net_req_addr    : 0x" << std::hex << packet.addr << std::dec << std::endl;
    std::cout << "       net_req_payload : 0x" << std::hex << packet.payload << std::dec << std::endl;
    std::cout << "       payload_comp    : 0x" << std::hex << packet.payload_comp << std::dec << "\n" << std::endl;

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
    std::cout << "       net_req_id_comp : " << packet.id << std::endl;
    std::cout << "       net_req_payload_comp : 0x" << std::hex << packet.payload_comp << std::dec << "\n" << std::endl;

    dut.net_en_comp = true;
    dut.net_req_id_comp = packet.id;
    dut.net_req_payload_comp = packet.payload_comp;

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

void net_reset (DUT_TYPE& dut){
    // to network
    dut.net_en_comp = 0;
    dut.net_req_payload_comp = 0;
    dut.net_req_id_comp = 0;

    // from network
    dut.net_stall = 1;
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
        std::cout << "[INFO] Committing Request from FIFO Router" << std::endl;
        std::cout << "       req_comp         : " << (bool) dut.req_comp << std::endl;
        std::cout << "       req_addr_comp    : 0x" << std::hex << dut.req_addr_comp << std::dec << std::endl;
        std::cout << "       expected addr    : 0x" << std::hex << it->addr << std::dec << std::endl;
        std::cout << "       req_payload_comp : 0x" << std::hex << dut.req_payload_comp << std::dec << std::endl;
        std::cout << "       expected payload : 0x" << std::hex << it->payload_comp << std::dec << "\n" << std::endl;

        assert((bool) dut.req_comp);
        assert(it->addr == dut.req_addr_comp);
        assert(it->payload_comp == dut.req_payload_comp);
        tick(dut, trace);
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
