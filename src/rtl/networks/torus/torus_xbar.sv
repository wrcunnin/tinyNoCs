import packet_pkg::*;
import mesh_pkg::*;
import torus_pkg::*;

module torus_xbar #(
    parameter int unsigned BufferRxDepth
) (
    input logic clk, nrst,

    ////////////////////////////////////////////////////////
    // Straps
    input endpoint_id_t strap_pos_x,
    input endpoint_id_t strap_pos_y,
    input endpoint_id_t strap_max_x,
    input endpoint_id_t strap_max_y,

    input logic         strap_vertical_torus,
    input logic         strap_prefer_vertical,

    ////////////////////////////////////////////////////////
    // North inputs/outputs
    `CREATE_MESH_XBAR_IO(north),

    ////////////////////////////////////////////////////////
    // South inputs/outputs
    `CREATE_MESH_XBAR_IO(south),

    ////////////////////////////////////////////////////////
    // West inputs/outputs
    `CREATE_MESH_XBAR_IO(west),

    ////////////////////////////////////////////////////////
    // East inputs/outputs
    `CREATE_MESH_XBAR_IO(east),

    ////////////////////////////////////////////////////////
    // Torus inputs/outputs
    `CREATE_MESH_XBAR_IO(torus)
);

/************************************************/
/* north_buffer_rx                              */
/************************************************/
logic                     north_buffer_rx_push_valid;
logic [NetPacketBits-1:0] north_buffer_rx_push_data;
logic                     north_buffer_rx_push_ready;
logic                     north_buffer_rx_pop_valid;
logic [NetPacketBits-1:0] north_buffer_rx_pop_data;
logic                     north_buffer_rx_pop_ready;
fifo_basic #(
    .Depth(BufferRxDepth),
    .Width(NetPacketBits)
) north_buffer_rx (
    .clk(clk),
    .nrst(nrst),
    .push_valid(north_buffer_rx_push_valid),
    .push_data(north_buffer_rx_push_data),
    .push_ready(north_buffer_rx_push_ready),
    .pop_valid(north_buffer_rx_pop_valid),
    .pop_data(north_buffer_rx_pop_data),
    .pop_ready(north_buffer_rx_pop_ready)
);

/************************************************/
/* south_buffer_rx                              */
/************************************************/
logic                     south_buffer_rx_push_valid;
logic [NetPacketBits-1:0] south_buffer_rx_push_data;
logic                     south_buffer_rx_push_ready;
logic                     south_buffer_rx_pop_valid;
logic [NetPacketBits-1:0] south_buffer_rx_pop_data;
logic                     south_buffer_rx_pop_ready;
fifo_basic #(
    .Depth(BufferRxDepth),
    .Width(NetPacketBits)
) south_buffer_rx (
    .clk(clk),
    .nrst(nrst),
    .push_valid(south_buffer_rx_push_valid),
    .push_data(south_buffer_rx_push_data),
    .push_ready(south_buffer_rx_push_ready),
    .pop_valid(south_buffer_rx_pop_valid),
    .pop_data(south_buffer_rx_pop_data),
    .pop_ready(south_buffer_rx_pop_ready)
);

/************************************************/
/* east_buffer_rx                               */
/************************************************/
logic                     east_buffer_rx_push_valid;
logic [NetPacketBits-1:0] east_buffer_rx_push_data;
logic                     east_buffer_rx_push_ready;
logic                     east_buffer_rx_pop_valid;
logic [NetPacketBits-1:0] east_buffer_rx_pop_data;
logic                     east_buffer_rx_pop_ready;
fifo_basic #(
    .Depth(BufferRxDepth),
    .Width(NetPacketBits)
) east_buffer_rx (
    .clk(clk),
    .nrst(nrst),
    .push_valid(east_buffer_rx_push_valid),
    .push_data(east_buffer_rx_push_data),
    .push_ready(east_buffer_rx_push_ready),
    .pop_valid(east_buffer_rx_pop_valid),
    .pop_data(east_buffer_rx_pop_data),
    .pop_ready(east_buffer_rx_pop_ready)
);

/************************************************/
/* west_buffer_rx                               */
/************************************************/
logic                     west_buffer_rx_push_valid;
logic [NetPacketBits-1:0] west_buffer_rx_push_data;
logic                     west_buffer_rx_push_ready;
logic                     west_buffer_rx_pop_valid;
logic [NetPacketBits-1:0] west_buffer_rx_pop_data;
logic                     west_buffer_rx_pop_ready;
fifo_basic #(
    .Depth(BufferRxDepth),
    .Width(NetPacketBits)
) west_buffer_rx (
    .clk(clk),
    .nrst(nrst),
    .push_valid(west_buffer_rx_push_valid),
    .push_data(west_buffer_rx_push_data),
    .push_ready(west_buffer_rx_push_ready),
    .pop_valid(west_buffer_rx_pop_valid),
    .pop_data(west_buffer_rx_pop_data),
    .pop_ready(west_buffer_rx_pop_ready)
);

/************************************************/
/* torus_buffer_rx                               */
/************************************************/
logic                     torus_buffer_rx_push_valid;
logic [NetPacketBits-1:0] torus_buffer_rx_push_data;
logic                     torus_buffer_rx_push_ready;
logic                     torus_buffer_rx_pop_valid;
logic [NetPacketBits-1:0] torus_buffer_rx_pop_data;
logic                     torus_buffer_rx_pop_ready;
fifo_basic #(
    .Depth(BufferRxDepth),
    .Width(NetPacketBits)
) torus_buffer_rx (
    .clk(clk),
    .nrst(nrst),
    .push_valid(torus_buffer_rx_push_valid),
    .push_data(torus_buffer_rx_push_data),
    .push_ready(torus_buffer_rx_push_ready),
    .pop_valid(torus_buffer_rx_pop_valid),
    .pop_data(torus_buffer_rx_pop_data),
    .pop_ready(torus_buffer_rx_pop_ready)
);

/************************************************/
/* torus_xbarb                                   */
/************************************************/
logic        torus_xbarb_north_pop_ready;
logic        torus_xbarb_north_pop_valid;
net_packet_t torus_xbarb_north_pop_data;
logic        torus_xbarb_north_push_ready;
logic        torus_xbarb_north_push_valid;
net_packet_t torus_xbarb_north_push_data;
logic        torus_xbarb_south_pop_ready;
logic        torus_xbarb_south_pop_valid;
net_packet_t torus_xbarb_south_pop_data;
logic        torus_xbarb_south_push_ready;
logic        torus_xbarb_south_push_valid;
net_packet_t torus_xbarb_south_push_data;
logic        torus_xbarb_east_pop_ready;
logic        torus_xbarb_east_pop_valid;
net_packet_t torus_xbarb_east_pop_data;
logic        torus_xbarb_east_push_ready;
logic        torus_xbarb_east_push_valid;
net_packet_t torus_xbarb_east_push_data;
logic        torus_xbarb_west_pop_ready;
logic        torus_xbarb_west_pop_valid;
net_packet_t torus_xbarb_west_pop_data;
logic        torus_xbarb_west_push_ready;
logic        torus_xbarb_west_push_valid;
net_packet_t torus_xbarb_west_push_data;
logic        torus_xbarb_torus_pop_ready;
logic        torus_xbarb_torus_pop_valid;
net_packet_t torus_xbarb_torus_pop_data;
logic        torus_xbarb_torus_push_ready;
logic        torus_xbarb_torus_push_valid;
net_packet_t torus_xbarb_torus_push_data;
torus_xbar_arbiter torus_xbarb (
    .clk(nrst),
    .nrst(nrst),
    .strap_pos_x(strap_pos_x),
    .strap_pos_y(strap_pos_y),
    .strap_max_x(strap_max_x),
    .strap_max_y(strap_max_y),
    .strap_vertical_torus(strap_vertical_torus),
    .strap_prefer_vertical(strap_prefer_vertical),
    .north_pop_ready(torus_xbarb_north_pop_ready),
    .north_pop_valid(torus_xbarb_north_pop_valid),
    .north_pop_data(torus_xbarb_north_pop_data),
    .north_push_ready(torus_xbarb_north_push_ready),
    .north_push_valid(torus_xbarb_north_push_valid),
    .north_push_data(torus_xbarb_north_push_data),
    .south_pop_ready(torus_xbarb_south_pop_ready),
    .south_pop_valid(torus_xbarb_south_pop_valid),
    .south_pop_data(torus_xbarb_south_pop_data),
    .south_push_ready(torus_xbarb_south_push_ready),
    .south_push_valid(torus_xbarb_south_push_valid),
    .south_push_data(torus_xbarb_south_push_data),
    .east_pop_ready(torus_xbarb_east_pop_ready),
    .east_pop_valid(torus_xbarb_east_pop_valid),
    .east_pop_data(torus_xbarb_east_pop_data),
    .east_push_ready(torus_xbarb_east_push_ready),
    .east_push_valid(torus_xbarb_east_push_valid),
    .east_push_data(torus_xbarb_east_push_data),
    .west_pop_ready(torus_xbarb_west_pop_ready),
    .west_pop_valid(torus_xbarb_west_pop_valid),
    .west_pop_data(torus_xbarb_west_pop_data),
    .west_push_ready(torus_xbarb_west_push_ready),
    .west_push_valid(torus_xbarb_west_push_valid),
    .west_push_data(torus_xbarb_west_push_data),
    .torus_pop_ready(torus_xbarb_torus_pop_ready),
    .torus_pop_valid(torus_xbarb_torus_pop_valid),
    .torus_pop_data(torus_xbarb_torus_pop_data),
    .torus_push_ready(torus_xbarb_torus_push_ready),
    .torus_push_valid(torus_xbarb_torus_push_valid),
    .torus_push_data(torus_xbarb_torus_push_data)
);

`CONNECT_TORUS_XBAR_INTERNALS(north);
`CONNECT_TORUS_XBAR_INTERNALS(west);
`CONNECT_TORUS_XBAR_INTERNALS(south);
`CONNECT_TORUS_XBAR_INTERNALS(east);
`CONNECT_TORUS_XBAR_INTERNALS(torus);

endmodule