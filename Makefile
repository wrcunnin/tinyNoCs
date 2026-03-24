

###################################
# Ring Test Benches
###################################
ring-2:
	fusesoc --cores-root . run --build --target tb_ring_2 tinynocs:src:dv-ring
	build/tinynocs_src_dv-ring_0.0.1/tb_ring_2-verilator/Vring_2
	build/tinynocs_src_dv-ring_0.0.1/tb_ring_2-verilator/Vring_2 --split-endpoints
	@echo "Built and ran a 2-endpoint ring network with basic params\n"

ring-16:
	fusesoc --cores-root . run --build --target tb_ring_16 tinynocs:src:dv-ring
	build/tinynocs_src_dv-ring_0.0.1/tb_ring_16-verilator/Vring_16
	build/tinynocs_src_dv-ring_0.0.1/tb_ring_16-verilator/Vring_16 --split-endpoints
	@echo "Built and ran a 16-endpoint ring network with basic params\n"

ring-all: ring-2 ring-16
	@echo "Built and ran all Ring Network test benches\n"


###################################
# Endpoint Test Benches
###################################
endpoint:
	fusesoc --cores-root . run --build --target tb_endpoint tinynocs:src:dv-shared
	build/tinynocs_src_dv-shared_0.0.1/tb_endpoint-verilator/Vendpoint --trace-en
	@echo "Built and ran an endpoint with basic params\n"

###################################
# FIFO Basic Test Benches
###################################
fifo-basic:
	fusesoc --cores-root . run --build --target tb_fifo_basic tinynocs:src:dv-shared
	build/tinynocs_src_dv-shared_0.0.1/tb_fifo_basic-verilator/Vfifo_basic --trace-en
	@echo "Built and ran Basic FIFO with its default depth\n"

fifo-basic-10:
	fusesoc --cores-root . run --build --target tb_fifo_basic_10 tinynocs:src:dv-shared
	build/tinynocs_src_dv-shared_0.0.1/tb_fifo_basic_10-verilator/Vfifo_basic --trace-en
	@echo "Built and ran Basic FIFO with a depth of 10 entries\n"

fifo-basic-64:
	fusesoc --cores-root . run --build --target tb_fifo_basic_64 tinynocs:src:dv-shared
	build/tinynocs_src_dv-shared_0.0.1/tb_fifo_basic_64-verilator/Vfifo_basic --trace-en
	@echo "Built and ran Basic FIFO with a depth of 64 entries\n"

fifo-basic-all: fifo-basic fifo-basic-10 fifo-basic-64
	@echo "Built and ran all Basic FIFO test benches\n"


###################################
# FIFO Router Test Benches
###################################
fifo-router:
	fusesoc --cores-root . run --build --target tb_fifo_router tinynocs:src:dv-shared
	build/tinynocs_src_dv-shared_0.0.1/tb_fifo_router-verilator/Vfifo_router --trace-en
	@echo "Built and ran FIFO Router with its default depth\n"

fifo-router-10:
	fusesoc --cores-root . run --build --target tb_fifo_router_10 tinynocs:src:dv-shared
	build/tinynocs_src_dv-shared_0.0.1/tb_fifo_router_10-verilator/Vfifo_router --trace-en
	@echo "Built and ran FIFO Router with a depth of 10 entries\n"

fifo-router-64:
	fusesoc --cores-root . run --build --target tb_fifo_router_64 tinynocs:src:dv-shared
	build/tinynocs_src_dv-shared_0.0.1/tb_fifo_router_64-verilator/Vfifo_router --trace-en
	@echo "Built and ran FIFO Router with a depth of 64 entries\n"

fifo-router-all: fifo-router fifo-router-10 fifo-router-64
	@echo "Built and ran all FIFO Router test benches\n"

###################################
# Utility
###################################
clean:
	rm -rf build waveform.fst.hier
