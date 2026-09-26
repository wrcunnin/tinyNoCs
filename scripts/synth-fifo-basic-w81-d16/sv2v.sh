#/usr/bin/bash

# to be run from the ROOT directory of this repository

# create a directory to put the verilog ring files
folder_name="verilog-fifo-basic-w81-d16"
top_name="fifo_basic_w81_d16"

rm -rf $folder_name
mkdir $folder_name

# convert all necessary files into new folder
sv2v --top=${top_name} --define=SYNTHESIS \
    src/rtl/shared/packages/packet_pkg.sv \
    src/rtl/shared/fifo/fifo_basic.sv \
    src/rtl/shared/fifo/fifo_basic_w81_d16.sv > "${folder_name}/${top_name}.v"

