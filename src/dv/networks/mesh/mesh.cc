#include <atomic>
#include <cassert>
#include <cerrno>
#include <chrono>
#include <climits>
#include <csignal>
#include <cstdio>
#include <cstdlib>
#include <cmath>
#include <getopt.h>
#include <iostream>
#include <optional>
#include <thread>
#include <unistd.h>

#include "verilated.h"
#include "verilated_fst_c.h"
#include "Vmesh.h"

#define TRACE_NAME "waveform.fst"
#define DUT_TYPE Vmesh
#define NETWORK_STYLE "Mesh"
#define NUM_ENDPOINTS 16
#define ENDPOINT_GRAN ( 0x80000000 >> (( (int) ceil(log2f( (float) NUM_ENDPOINTS )) ) - 1) )
#define ENDPOINT_MASK (~(0xFFFFFFFF >> (( (int) ceil(log2f( (float) NUM_ENDPOINTS )) ))))
#define TOTAL_REQUESTS 10000

#define GET_LOGIC(logic, idx) ((logic >> (idx)) & 0x1) 
#define GET_ADDR(addr, idx) ( ((addr[idx / 2]) >> ((idx % 2) * 32)) & 0xFFFFFFFF )
#define GET_PACKET_WEN(packet, idx) (packet[4UL + idx * 5] & 0x1)
#define GET_PACKET_ID(packet, idx) (packet[3UL + idx * 5])
#define GET_PACKET_ADDR(packet, idx) (packet[2UL + idx * 5])
#define GET_PACKET_PAYLOAD(packet, idx) \
    (((uint64_t)((uint64_t)(packet[1UL + idx * 5])) << 32UL) | ((uint64_t)(packet[0UL + idx * 5])))

#define SET_LOGIC(logic, value, idx) \
    logic = ((logic) & (~(0x1 << (idx)))) | (((value) & 0x1) << (idx));
#define SET_ADDR(addr, value, idx) \
    addr[idx / 2] = (((uint64_t) addr[idx / 2]) & (~(0xFFFFFFFF << ((idx % 2) * 32)))) | ((((uint64_t) value) & 0xFFFFFFFF) << ((idx % 2) * 32));
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
    bool perfect_mapping;
    bool split_endpoints;
    unsigned long cycle_limit;
    bool debug;
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

    // TB only
    bool uninitialized = true;
};

const TBCfg default_config {
    .trace_en = false,
    .perfect_mapping = false,
    .split_endpoints = false,
    .cycle_limit = 1000000,
    .debug = false,
    .dutp = NULL,
    .tracep = NULL
};

static TBCfg config;

// Modified by requesters
// A queue of outgoing requests in a network
std::vector<std::deque<netPacket>> requestBufferQueue (NUM_ENDPOINTS);

// Modified by responders
// This is a queue of what SHOULD reach a responder
std::vector<std::deque<netPacket>> expectedRequestQueue (NUM_ENDPOINTS);

// TODO: Is this needed?
std::deque<netPacket> networkQueue = {};

uint32_t ENDPOINT_START_ADDRS[NUM_ENDPOINTS] = {
    0x00000000,
    0x10000000,
    0x20000000,
    0x30000000,
    0x40000000,
    0x50000000,
    0x60000000,
    0x70000000,
    0x80000000,
    0x90000000,
    0xA0000000,
    0xB0000000,
    0xC0000000,
    0xD0000000,
    0xE0000000,
    0xF0000000
};
uint32_t PERFECT_MAPPING_ADDR[NUM_ENDPOINTS] = {
    8, 9, 10, 11, 12, 13, 14, 15,
    0, 1,  2,  3,  4,  5,  6,  7
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
void req_send (
    DUT_TYPE& dut,
    int endpoint_idx
);
void req_comp (
    DUT_TYPE& dut,
    int endpoint_idx
);
void resp_send (
    DUT_TYPE& dut,
    int endpoint_idx
);

void print_config (TBCfg& config) {
    std::cout << "Configuration: " << std::endl;
    std::cout << "\tTrace: " << ((config.trace_en) ? "Enabled" : "Disabled") << std::endl;
    std::cout << "\tCycle Limit: " << config.cycle_limit << std::endl;
}

void print_help () {
    std::cerr << "Usage: ./Vmesh [flags...]" << std::endl;
    std::cerr << "\t--trace-en: Enable FST wave tracing" << std::endl;
    std::cerr << "\t--split-endpoints: Split the endpoints into requester/responder" << std::endl;
    std::cerr << "\t--perfect-mapping: Split the endpoints into requester/responder & assign a perfect mapping" << std::endl;
    std::cerr << "\t--cycle-limit n: Set cycle count limit to n" << std::endl;
    std::cerr << "\t--debug: Enable debug prints" << std::endl;
    std::cerr << "\t--help: Print this" << std::endl;
}

auto parse_cli (int argc, char **argv) -> std::optional<TBCfg> {
    static struct option long_options[] = {
        {"trace-en",        no_argument,        0, 't'},
        {"split-endpoints", no_argument,        0, 's'},
        {"perfect-mapping", no_argument,        0, 'p'},
        {"cycle-limit",     required_argument,  0, 'c'},
        {"debug",           no_argument,        0, 'd'},
        {"help",            no_argument,        0, 'h'},
        {0, 0, 0, 0}
    };

    TBCfg config = default_config;
    int option_index = 0;
    char *endp = NULL;

    for(;;) {
        int c = getopt_long(argc, argv, "t:s:p:c:d:h", long_options, &option_index);
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
            case 's':
                config.split_endpoints = true;
                break;
            case 'p':
                config.perfect_mapping = true;
                config.split_endpoints = true;
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
            case 'd':
                config.debug = true;
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
    if (!GET_LOGIC(dut.req_full, endpoint_idx) && requestsSent[endpoint_idx] < TOTAL_REQUESTS) {
        uint32_t r1 = std::rand();
        uint32_t r2 = std::rand();
        uint32_t r3 = std::rand();
        uint32_t r4 = std::rand();


        // Get a random enpoint that is not this current one.
        int possible_endpoints = config.split_endpoints ? NUM_ENDPOINTS / 2 : NUM_ENDPOINTS;
        int dest_endpoint = std::rand() % possible_endpoints;
        if (config.perfect_mapping)
            dest_endpoint = PERFECT_MAPPING_ADDR[endpoint_idx];
        else if (config.split_endpoints)
            dest_endpoint += NUM_ENDPOINTS / 2;
        else if (dest_endpoint == endpoint_idx)
            dest_endpoint = dest_endpoint == NUM_ENDPOINTS - 1 ? 0 : dest_endpoint + 1;

        bool ren = r1 % 2;
        bool wen = (r1 + 1) % 2;
        uint32_t addr = ENDPOINT_START_ADDRS[dest_endpoint] + ((r1 + r2) % ENDPOINT_GRAN);
        uint64_t payload = (( (uint64_t)(r1) ) << 32) + ((uint64_t)(r2));

        if (config.debug) {
            std::cout << "[INFO] At Cycle " << cycles << ", Creating Request to FIFO Router in Endpoint " << endpoint_idx << std::endl;
            std::cout << "       req_en             : " << (ren || wen) << std::endl;
            std::cout << "       req_packet.wen     : " << wen << std::endl;
            std::cout << "       req_packet.addr    : 0x" << std::hex << addr << std::dec << std::endl;
            std::cout << "       req_packet.payload : 0x" << std::hex << payload << std::dec << "\n" << std::endl;
        }

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
            .payload_comp = wen ? payload : (( (uint64_t)(r3) ) << 32) + ((uint64_t)(r4)),
            .uninitialized = false
        };

        requestBufferQueue[endpoint_idx].push_back(packet);
        expectedRequestQueue[dest_endpoint].push_back(packet);
        requestsSent[endpoint_idx]++;
    }
}

void req_comp (
    DUT_TYPE& dut,
    int endpoint_idx
) {
    if (GET_LOGIC(dut.req_comp_en, endpoint_idx)) {
        bool comp_wen = GET_PACKET_WEN(dut.req_comp_packet, endpoint_idx);
        uint32_t comp_addr = GET_PACKET_ADDR(dut.req_comp_packet, endpoint_idx);
        uint64_t comp_payload = GET_PACKET_PAYLOAD(dut.req_comp_packet, endpoint_idx);

        netPacket packet = requestBufferQueue[endpoint_idx].front();
        requestBufferQueue[endpoint_idx].pop_front();

        if (config.debug) {
            std::cout << "[INFO] At Cycle " << cycles << ", Committing Request from FIFO Router in Endpoint " << endpoint_idx << std::endl;
            std::cout << "       req_addr_comp    : " << comp_wen << std::endl;
            std::cout << "       expected addr    : " << packet.wen << std::endl;
            std::cout << "       req_addr_comp    : 0x" << std::hex << comp_addr << std::dec << std::endl;
            std::cout << "       expected addr    : 0x" << std::hex << packet.addr << std::dec << std::endl;
            std::cout << "       req_payload_comp : 0x" << std::hex << comp_payload << std::dec << std::endl;
            std::cout << "       expected payload : 0x" << std::hex << packet.payload_comp << std::dec << "\n" << std::endl;
        }

        assert(packet.wen == comp_wen);
        assert(packet.addr == comp_addr);
        // assert(packet.payload_comp == comp_payload);

        SET_LOGIC(dut.req_comp_stall, 0, endpoint_idx);
        requestsCompleted[endpoint_idx]++;
    }
}

void resp_send (
    DUT_TYPE& dut,
    int endpoint_idx
) {
    // if there is a request in the response queue
    if (GET_LOGIC(dut.resp_en, endpoint_idx)) {
        bool req_wen = (bool) GET_PACKET_WEN(dut.resp_packet, endpoint_idx);
        uint32_t req_id = GET_PACKET_ID(dut.resp_packet, endpoint_idx);
        uint32_t req_addr = GET_PACKET_ADDR(dut.resp_packet, endpoint_idx);
        uint64_t req_payload = GET_PACKET_PAYLOAD(dut.resp_packet, endpoint_idx);

        if (config.debug) {
            std::cout << "[INFO] At Cycle " << cycles << ", Responding to Request in Endpoint " << endpoint_idx << std::endl;
            std::cout << "       wen          : " << req_wen << std::endl;
            std::cout << "       addr         : 0x" << std::hex << req_addr << std::dec << std::endl;
            std::cout << "       payload      : 0x" << std::hex << req_payload << std::dec << std::endl;
        }
        assert((req_addr & ENDPOINT_MASK) == (ENDPOINT_START_ADDRS[endpoint_idx]));

        // iterate through the expected response queue, make sure that the packet we are receiving
        netPacket packet;
        for (std::deque<netPacket>::iterator it = expectedRequestQueue[endpoint_idx].begin(); it != expectedRequestQueue[endpoint_idx].end(); ++it) {
            if (it->wen == req_wen && it->addr == req_addr && it->payload == req_payload) {
                packet = *it;
                expectedRequestQueue[endpoint_idx].erase(it);
                break;
            }
        }
        assert(!packet.uninitialized);

        // let the response buffer know not to stall
        SET_LOGIC(dut.resp_stall, 0, endpoint_idx);

        // return the payload back to the proper ID in the response queue
        SET_ADDR(dut.resp_comp_return_addr, packet.start_addr, endpoint_idx);
        SET_LOGIC(dut.resp_comp_en, 1, endpoint_idx);
        SET_PACKET_ID(dut.resp_comp_packet, req_id, endpoint_idx);
        SET_PACKET_PAYLOAD(dut.resp_comp_packet, packet.payload_comp, endpoint_idx);

        if (config.debug) {
            std::cout << "       start_addr   : 0x" << std::hex << packet.start_addr << std::dec << std::endl;
            std::cout << "       payload_comp : 0x" << std::hex << packet.payload_comp << std::dec << "\n" << std::endl;
        }
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

    int start_cycle = cycles;

    bool done = false;
    int endpoints_to_check = config.split_endpoints ? NUM_ENDPOINTS / 2 : NUM_ENDPOINTS;
    while (!done && (cycles < config.cycle_limit)) {
        // send/complete requests & responses
        for(int i = 0; i < NUM_ENDPOINTS; i++) {
            if (!config.split_endpoints || i < (NUM_ENDPOINTS / 2))
                req_send(dut, i);
            if (!config.split_endpoints || i >= (NUM_ENDPOINTS / 2))
                resp_send(dut, i);
            req_comp(dut, i);
        }
        // tick the clock
        tick(dut, trace);

        // check to see if all requests have been completed
        done = true;
        for (int i = 0; i < endpoints_to_check; i++) {
            if (requestsCompleted[i] < TOTAL_REQUESTS) {
                done = false;
                break;
            }
        }
    }

    // End test bench
    auto tend = std::chrono::high_resolution_clock::now();
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(tend - tstart);
    std::cout   << "Simulated " << cycles 
                << " cycles in " << ms.count() << "ms" 
                << ", rate of " << (float)cycles / ((float)ms.count() / 1000.0) 
                << " cycles per second.\n" << std::endl;

    if (cycles >= config.cycle_limit)
        std::cout << "WARNING: Hit max cycle limit! Consider increasing cycle limit.\n" << std::endl;
    
    if (done) {
        int total_cycles = cycles - start_cycle;
        int total_requests = TOTAL_REQUESTS * endpoints_to_check;
        float rcr = ((float) total_requests) / ((float) total_cycles);
        std::cout << "[INFO] tinyNoC TB Statistics" << std::endl;
        std::cout << "       Network Style: " << NETWORK_STYLE << std::endl;
        std::cout << "       Number of Endpoints: " << NUM_ENDPOINTS << std::endl;
        std::cout << "       Requester/Responder Endpoints: " << endpoints_to_check << std::endl;
        std::cout << "       Total requests (for all endpoints): " << total_requests << std::endl;
        std::cout << "       Cycles to complete requests: " << total_cycles << std::endl;
        std::cout << "       Request Completion Rate: " << rcr << " requests per cycle" << std::endl;
        std::cout << "       Request Completion Rate Per Endpoint: " << rcr / endpoints_to_check << " requests per cycle" << std::endl;
        std::cout << "       Cycles per Request: " << 1.0f / rcr << "\n" << std::endl;
    }

    if(config.trace_en)
        trace.close();

    dut.final();

    return EXIT_SUCCESS;
}
