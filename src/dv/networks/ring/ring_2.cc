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
#include "Vring_2.h"

#define TRACE_NAME "waveform.fst"
#define DUT_TYPE Vring_2
#define NUM_ENDPOINTS 2
#define ENDPOINT_GRAN (~(0xFFFFFFFF >> (NUM_ENDPOINTS - 1)))
#define TOTAL_REQUESTS 100

#define GET_LOGIC(logic, idx) ((logic >> (idx * 8)) & 0xFF) 
#define GET_ADDR(addr, idx) ( (addr >> (idx * 32)) & 0xFFFFFFFF )
#define GET_PACKET_WEN(packet, idx) (packet[4UL + idx * 5] & 0x1)
#define GET_PACKET_ID(packet, idx) (packet[3UL + idx * 5])
#define GET_PACKET_ADDR(packet, idx) (packet[2UL + idx * 5])
#define GET_PACKET_PAYLOAD(packet, idx) \
    (((uint64_t)((uint64_t)(packet[1UL + idx * 5])) << 32UL) | ((uint64_t)(packet[0UL + idx * 5])))

#define SET_LOGIC(logic, value, idx) \
    logic = ((logic) & (~(0x1 << (idx)))) | (((value) & 0x1) << (idx));
#define SET_ADDR(addr, value, idx) \
    addr = (((uint64_t) addr) & (~(0xFFFFFFFF))) | ((((uint64_t) value) & 0xFFFFFFFF) << (idx * 32));
#define SET_PACKET_WEN(packet, wen, idx) \
    packet[4UL + idx * 5] = (wen & 0x1);
#define SET_PACKET_ID(packet, id, idx) \
    packet[3UL + idx * 5] = id;
#define SET_PACKET_ADDR(packet, addr, idx) \
    packet[2UL + idx * 5] = addr;
#define SET_PACKET_PAYLOAD(packet, payload, idx) \
    packet[1UL + idx * 5] = (((uint64_t) payload) >> 32) & 0xFFFFFFFF; \
    packet[0UL + idx * 5] = (((uint64_t) payload)) & 0xFFFFFFFF;

struct TBCfg {
    bool trace_en;
    unsigned long cycle_limit;
    DUT_TYPE *dutp;
    VerilatedFstC *tracep;
};

struct netPacket {
    // net_packet_t fields
    bool request;
    uint32_t start_addr;

    // packet_t fields
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

std::vector<std::deque<netPacket>> requestBufferQueue (5);
std::deque<netPacket> responseBufferQueue = {};
std::deque<netPacket> networkQueue = {};

int ENDPOINT_START_ADDRS[NUM_ENDPOINTS] = {
    0x00000000,
    0x80000000
};
int requestsSent[NUM_ENDPOINTS] = {};
int requestsCompleted[NUM_ENDPOINTS] = {};

vluint64_t sim_time = 0;
vluint64_t cycles = 0;

void print_config(TBCfg& config);
void print_help();
auto parse_cli(int argc, char **argv) -> std::optional<TBCfg>;
void signal_handler (int signum);
void tick (DUT_TYPE& dut, VerilatedFstC& trace);
void reset (DUT_TYPE& dut, VerilatedFstC& trace);
void req_reset (DUT_TYPE& dut);
void resp_reset (DUT_TYPE& dut);
void net_reset_tx (DUT_TYPE& dut);
void net_reset_rx (DUT_TYPE& dut);
void req_send (
    DUT_TYPE& dut,
    int endpoint_idx
);

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
    resp_reset(dut);
}

void reset (DUT_TYPE& dut, VerilatedFstC& trace) {
    // Initialize signals
    dut.CLK = 0;
    dut.nRST = 0;
    req_reset(dut);
    resp_reset(dut);

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
    for (int i = 0; i < NUM_ENDPOINTS; i++) {
        SET_LOGIC(dut.req_en, 0, i);
        SET_PACKET_WEN(dut.req_packet, 0, i);
        SET_PACKET_ID(dut.req_packet, 0, i);
        SET_PACKET_ADDR(dut.req_packet, 0, i);
        SET_PACKET_PAYLOAD(dut.req_packet, 0, i);

        // for committing requests to FIFO
        SET_LOGIC(dut.req_comp_stall, 1, i);
    }
}

void resp_reset (DUT_TYPE& dut) {
    // into FIFO buffer
    for (int i = 0; i < NUM_ENDPOINTS; i++) {
        SET_LOGIC(dut.resp_stall, 1, i);
        SET_LOGIC(dut.resp_comp_en, 0, i);
        SET_ADDR(dut.resp_comp_return_addr, 0, i);
        SET_PACKET_WEN(dut.resp_comp_packet, 0, i);
        SET_PACKET_ID(dut.resp_comp_packet, 0, i);
        SET_PACKET_ADDR(dut.resp_comp_packet, 0, i);
        SET_PACKET_PAYLOAD(dut.resp_comp_packet, 0, i);
    }
}

void req_send (
    DUT_TYPE& dut,
    int endpoint_idx
) {
    // if the endpoint is not full
    if (!GET_LOGIC(dut.req_full, endpoint_idx)) {
        uint32_t r1 = std::rand();
        uint32_t r2 = std::rand();

        // Get a random enpoint that is not this current one.
        int dest_endpoint = std::rand() % NUM_ENDPOINTS;
        if (dest_endpoint == endpoint_idx) {
            dest_endpoint = dest_endpoint == NUM_ENDPOINTS - 1 ? 0 : dest_endpoint + 1;
        }

        bool ren = r1 % 2;
        bool wen = (r1 + 1) % 2;
        uint64_t addr = ENDPOINT_START_ADDRS[dest_endpoint] + ((r1 + r2) % ENDPOINT_GRAN);
        uint64_t payload = (( (uint64_t)(r1) ) << 32) + ((uint64_t)(r2));

        std::cout << "[INFO] Creating Request to FIFO Router" << std::endl;
        std::cout << "       req_en             : " << (ren || wen) << std::endl;
        std::cout << "       req_packet.wen     : " << wen << std::endl;
        std::cout << "       req_packet.addr    : 0x" << std::hex << addr << std::dec << std::endl;
        std::cout << "       req_packet.payload : 0x" << std::hex << payload << std::dec << "\n" << std::endl;

        SET_LOGIC(dut.req_en, (ren || wen), endpoint_idx);
        SET_PACKET_WEN(dut.req_packet, wen, endpoint_idx);
        SET_PACKET_ID(dut.req_packet, 0, endpoint_idx);
        SET_PACKET_ADDR(dut.req_packet, addr, endpoint_idx);
        SET_PACKET_PAYLOAD(dut.req_packet, payload, endpoint_idx);

        netPacket packet {
            .request = true,
            .start_addr = ENDPOINT_START_ADDRS[endpoint_idx],
            .wen = wen,
            .addr = addr,
            .payload = payload,
            .payload_comp = 0
        };

        requestBufferQueue[endpoint_idx].push_back(packet);
        requestsSent[endpoint_idx]++;
    }
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

    for(int i = 0; i < NUM_ENDPOINTS; i++) {
        req_send(dut, i);
    }
    tick(dut, trace);
    tick(dut, trace);
    tick(dut, trace);
    tick(dut, trace);
    tick(dut, trace);
    tick(dut, trace);
    tick(dut, trace);
    tick(dut, trace);
    tick(dut, trace);
    tick(dut, trace);
    tick(dut, trace);
    tick(dut, trace);
    tick(dut, trace);

    // End test bench
    auto tend = std::chrono::high_resolution_clock::now();
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(tend - tstart);
    std::cout   << "Simulated " << cycles 
                << " cycles in " << ms.count() << "ms" 
                << ", rate of " << (float)cycles / ((float)ms.count() / 1000.0) 
                << " cycles per second." << std::endl;

    if (cycles >= config.cycle_limit)
        std::cout << "WARNING: Hit max cycle limit! Consider increasing cycle limit." << std::endl;
    
    if(config.trace_en)
        trace.close();

    dut.final();

    return EXIT_SUCCESS;
}
