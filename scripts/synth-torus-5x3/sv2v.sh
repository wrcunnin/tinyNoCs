#/usr/bin/bash

# to be run from the ROOT directory of this repository

# create a directory to put the verilog ring files
folder_name="verilog-torus-5x3"

rm -rf $folder_name
mkdir $folder_name

# convert all necessary files into new folder
sv2v --top=torus --define=SYNTHESIS --define=USE_5x3 \
    src/rtl/shared/packages/packet_pkg.sv \
    src/rtl/shared/fifo/fifo_basic.sv \
    src/rtl/shared/fifo/fifo_router.sv \
    src/rtl/shared/endpoint/endpoint_rx_arbiter.sv \
    src/rtl/shared/endpoint/endpoint_tx_arbiter.sv \
    src/rtl/shared/endpoint/endpoint.sv \
    src/rtl/networks/mesh/mesh_xbar_arbiter_in_ctrl.sv \
    src/rtl/networks/mesh/mesh_xbar_arbiter_out_ctrl.sv \
    src/rtl/networks/mesh/mesh_xbar_arbiter.sv \
    src/rtl/networks/mesh/mesh_xbar.sv \
    src/rtl/networks/torus/torus_xbar_arbiter_in_ctrl.sv \
    src/rtl/networks/torus/torus_xbar_arbiter_out_ctrl.sv \
    src/rtl/networks/torus/torus_xbar_arbiter.sv \
    src/rtl/networks/torus/torus_xbar.sv \
    src/rtl/networks/torus/torus.sv > "${folder_name}/torus.v"

