
.phony: fifo-router clean

fifo-router:
	fusesoc --cores-root . run --build --target tb_fifo_router tinynocs:src:dv-shared
	build/tinynocs_src_dv-shared_0.0.1/tb_fifo_router-verilator/Vfifo_router --trace-en

clean:
	rm -rf build
