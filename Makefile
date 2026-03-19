
###################################
# FIFO Basic Test Benches
###################################
fifo-basic:
	fusesoc --cores-root . run --build --target tb_fifo_basic tinynocs:src:dv-shared
	build/tinynocs_src_dv-shared_0.0.1/tb_fifo_basic-verilator/Vfifo_basic --trace-en


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
	rm -rf build
