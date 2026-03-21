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
#include "Vfifo_basic.h"

#define TRACE_NAME "waveform.fst"
#define DUT_TYPE Vfifo_basic

struct TBCfg {
    bool trace_en;
    DUT_TYPE *dutp;
    VerilatedFstC *tracep;
};

const TBCfg default_config {
    .trace_en = false,
    .dutp = NULL,
    .tracep = NULL
};

static TBCfg config;

std::deque<uint32_t> producerQueue = {};

vluint64_t sim_time = 0;
vluint64_t cycles = 0;

void print_config(TBCfg& config);
void print_help();
auto parse_cli(int argc, char **argv) -> std::optional<TBCfg>;
void signal_handler (int signum);
void tick (DUT_TYPE& dut, VerilatedFstC& trace);
void reset (DUT_TYPE& dut, VerilatedFstC& trace);

void reset_producer (DUT_TYPE& dut);
void reset_consumer (DUT_TYPE& dut);
void produce (DUT_TYPE& dut, uint32_t wdata);
void consume (DUT_TYPE& dut, VerilatedFstC& trace);

void print_config (TBCfg& config) {
    std::cout << "Configuration: " << std::endl;
    std::cout << "\tTrace: " << ((config.trace_en) ? "Enabled" : "Disabled") << std::endl;
}

void print_help () {
    std::cerr << "Usage: ./Vfifo_basic [flags...]" << std::endl;
    std::cerr << "\t--trace-en: Enable FST wave tracing" << std::endl;
    std::cerr << "\t--help: Print this" << std::endl;
}

auto parse_cli (int argc, char **argv) -> std::optional<TBCfg> {
    static struct option long_options[] = {
        {"trace-en",        no_argument,        0, 't'},
        {"help",            no_argument,        0, 'h'},
        {0, 0, 0, 0}
    };

    TBCfg config = default_config;
    int option_index = 0;
    char *endp = NULL;

    for(;;) {
        int c = getopt_long(argc, argv, "t:h", long_options, &option_index);
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

    reset_producer(dut);
    reset_consumer(dut);
}

void reset (DUT_TYPE& dut, VerilatedFstC& trace) {
    // Initialize signals
    dut.CLK = 0;
    dut.nRST = 0;
    reset_producer(dut);
    reset_consumer(dut);

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

void reset_producer (DUT_TYPE& dut) {
    dut.wen = 0;
    dut.wdata = 0;
}

void reset_consumer (DUT_TYPE& dut) {
    dut.ren = 0;
}

void produce (DUT_TYPE& dut, uint32_t wdata){
    std::cout << "[INFO] Producer writing data to FIFO" << std::endl;
    std::cout << "       wdata : 0x" << std::hex << wdata << std::dec << "\n" << std::endl;
    dut.wen = 1;
    dut.wdata = wdata;

    producerQueue.push_back(wdata);
}

void consume (DUT_TYPE& dut, VerilatedFstC& trace) {

    // begin to read
    dut.ren = 1;

    // consume has to tick for the TB unfortunately
    dut.CLK = 0;
    dut.eval();
    if (config.trace_en)
        trace.dump(sim_time);
    sim_time++;

    uint32_t rdata = dut.rdata;
    uint32_t expected_rdata = producerQueue.front();

    std::cout << "[INFO] Consumer reading data from FIFO" << std::endl;
    std::cout << "       rdata : 0x" << std::hex << rdata << std::dec << std::endl;
    std::cout << "    expected : 0x" << std::hex << expected_rdata << std::dec << "\n" << std::endl;

    assert(rdata == expected_rdata);

    producerQueue.pop_front();

    // consume has to tick for the TB unfortunately
    dut.CLK = 1;
    dut.eval();
    if (config.trace_en)
        trace.dump(sim_time);
    sim_time++;

    cycles++;

    reset_producer(dut);
    reset_consumer(dut);
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
    assert(dut.empty);

    // Fill the buffer
    for (int i = 0; !dut.full; i++) {
        assert(!dut.full);

        uint32_t r1 = std::rand();
        produce(dut, r1);
        tick(dut, trace);

        assert(!dut.empty);
    }

    assert(dut.full);

    for (int i = 0; !dut.empty; i++) {
        assert(!dut.empty);

        consume(dut, trace);

        assert(!dut.full);
    }

    assert(dut.empty);

    reset(dut, trace);
    tick(dut, trace);

    // End test bench
    auto tend = std::chrono::high_resolution_clock::now();
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(tend - tstart);
    std::cout   << "Simulated " << cycles 
                << " cycles in " << ms.count() << "ms" 
                << ", rate of " << (float)cycles / ((float)ms.count() / 1000.0) 
                << " cycles per second." << std::endl;

    if(config.trace_en)
        trace.close();

    dut.final();

    return EXIT_SUCCESS;
}
