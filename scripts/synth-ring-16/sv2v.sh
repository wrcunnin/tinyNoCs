#/usr/bin/bash

# to be run from the ROOT directory of this repository

# create a directory to put the verilog ring files
folder_name="verilog-ring-16"

rm -rf $folder_name
mkdir $folder_name

# convert all necessary files into new folder
sv2v --top=ring_16 --define=SYNTHESIS \
    src/rtl/shared/packages/packet_pkg.sv \
    src/rtl/shared/fifo/fifo_basic.sv \
    src/rtl/shared/fifo/fifo_router.sv \
    src/rtl/shared/endpoint/endpoint_rx_arbiter.sv \
    src/rtl/shared/endpoint/endpoint_tx_arbiter.sv \
    src/rtl/shared/endpoint/endpoint.sv \
    src/rtl/networks/ring/ring_xbar_arbiter.sv \
    src/rtl/networks/ring/ring_xbar.sv \
    src/rtl/networks/ring/ring_16.sv > "${folder_name}/ring_16.v"

