module mesh_xbar #(
    parameter int unsigned POS_X,
    parameter int unsigned POS_Y,
    parameter int unsigned MAX_X,
    parameter int unsigned MAX_Y,
    parameter int unsigned BUFFER_RX_DEPTH,
    parameter PREFER_VERTICAL = 0
) (
    input logic CLK, nRST,

    ////////////////////////////////////////////////////////
    // North inputs/outputs
    `CREATE_MESH_XBAR_IO(north),

    ////////////////////////////////////////////////////////
    // South inputs/outputs
    `CREATE_MESH_XBAR_IO(south),

    ////////////////////////////////////////////////////////
    // East inputs/outputs
    `CREATE_MESH_XBAR_IO(west),

    ////////////////////////////////////////////////////////
    // West inputs/outputs
    `CREATE_MESH_XBAR_IO(east)
);

/************************************************/
/* north_buffer_rx                              */
/************************************************/
logic                       north_buffer_rx_ren;
logic                       north_buffer_rx_wen;
logic [NET_PACKET_BITS-1:0] north_buffer_rx_rdata;
logic [NET_PACKET_BITS-1:0] north_buffer_rx_wdata;
logic                       north_buffer_rx_full;
logic                       north_buffer_rx_empty;
fifo_basic #(
    .DEPTH(BUFFER_RX_DEPTH),
    .DATA_WIDTH(NET_PACKET_BITS)
) north_buffer_rx (
    .CLK(CLK),
    .nRST(nRST),
    .full(north_buffer_rx_full),
    .empty(north_buffer_rx_empty),
    .ren(north_buffer_rx_ren),
    .rdata(north_buffer_rx_rdata),
    .wen(north_buffer_rx_wen),
    .wdata(north_buffer_rx_wdata)
);

/************************************************/
/* south_buffer_rx                              */
/************************************************/
logic                       south_buffer_rx_ren;
logic                       south_buffer_rx_wen;
logic [NET_PACKET_BITS-1:0] south_buffer_rx_rdata;
logic [NET_PACKET_BITS-1:0] south_buffer_rx_wdata;
logic                       south_buffer_rx_full;
logic                       south_buffer_rx_empty;
fifo_basic #(
    .DEPTH(BUFFER_RX_DEPTH),
    .DATA_WIDTH(NET_PACKET_BITS)
) south_buffer_rx (
    .CLK(CLK),
    .nRST(nRST),
    .full(south_buffer_rx_full),
    .empty(south_buffer_rx_empty),
    .ren(south_buffer_rx_ren),
    .rdata(south_buffer_rx_rdata),
    .wen(south_buffer_rx_wen),
    .wdata(south_buffer_rx_wdata)
);

/************************************************/
/* east_buffer_rx                               */
/************************************************/
logic                       east_buffer_rx_ren;
logic                       east_buffer_rx_wen;
logic [NET_PACKET_BITS-1:0] east_buffer_rx_rdata;
logic [NET_PACKET_BITS-1:0] east_buffer_rx_wdata;
logic                       east_buffer_rx_full;
logic                       east_buffer_rx_empty;
fifo_basic #(
    .DEPTH(BUFFER_RX_DEPTH),
    .DATA_WIDTH(NET_PACKET_BITS)
) east_buffer_rx (
    .CLK(CLK),
    .nRST(nRST),
    .full(east_buffer_rx_full),
    .empty(east_buffer_rx_empty),
    .ren(east_buffer_rx_ren),
    .rdata(east_buffer_rx_rdata),
    .wen(east_buffer_rx_wen),
    .wdata(east_buffer_rx_wdata)
);

/************************************************/
/* west_buffer_rx                               */
/************************************************/
logic                       west_buffer_rx_ren;
logic                       west_buffer_rx_wen;
logic [NET_PACKET_BITS-1:0] west_buffer_rx_rdata;
logic [NET_PACKET_BITS-1:0] west_buffer_rx_wdata;
logic                       west_buffer_rx_full;
logic                       west_buffer_rx_empty;
fifo_basic #(
    .DEPTH(BUFFER_RX_DEPTH),
    .DATA_WIDTH(NET_PACKET_BITS)
) west_buffer_rx (
    .CLK(CLK),
    .nRST(nRST),
    .full(west_buffer_rx_full),
    .empty(west_buffer_rx_empty),
    .ren(west_buffer_rx_ren),
    .rdata(west_buffer_rx_rdata),
    .wen(west_buffer_rx_wen),
    .wdata(west_buffer_rx_wdata)
);

/************************************************/
/* mesh_xbarb                                   */
/************************************************/
logic        mesh_xbarb_north_stall_tx;
logic        mesh_xbarb_north_en_tx;
net_packet_t mesh_xbarb_north_packet_tx;
logic        mesh_xbarb_north_stall_rx;
logic        mesh_xbarb_north_en_rx;
net_packet_t mesh_xbarb_north_packet_rx;
logic        mesh_xbarb_south_stall_tx;
logic        mesh_xbarb_south_en_tx;
net_packet_t mesh_xbarb_south_packet_tx;
logic        mesh_xbarb_south_stall_rx;
logic        mesh_xbarb_south_en_rx;
net_packet_t mesh_xbarb_south_packet_rx;
logic        mesh_xbarb_east_stall_tx;
logic        mesh_xbarb_east_en_tx;
net_packet_t mesh_xbarb_east_packet_tx;
logic        mesh_xbarb_east_stall_rx;
logic        mesh_xbarb_east_en_rx;
net_packet_t mesh_xbarb_east_packet_rx;
logic        mesh_xbarb_west_stall_tx;
logic        mesh_xbarb_west_en_tx;
net_packet_t mesh_xbarb_west_packet_tx;
logic        mesh_xbarb_west_stall_rx;
logic        mesh_xbarb_west_en_rx;
net_packet_t mesh_xbarb_west_packet_rx;
mesh_xbar_arbiter #(
    .POS_X(POS_X),
    .POS_Y(POS_Y),
    .MAX_X(MAX_X),
    .MAX_Y(MAX_Y),
    .PREFER_VERTICAL(PREFER_VERTICAL)
) mesh_xbarb (
    .CLK(CLK),
    .nRST(nRST),
    .north_stall_tx(mesh_xbarb_north_stall_tx),
    .north_en_tx(mesh_xbarb_north_en_tx),
    .north_packet_tx(mesh_xbarb_north_packet_tx),
    .north_stall_rx(mesh_xbarb_north_stall_rx),
    .north_en_rx(mesh_xbarb_north_en_rx),
    .north_packet_rx(mesh_xbarb_north_packet_rx),
    .south_stall_tx(mesh_xbarb_south_stall_tx),
    .south_en_tx(mesh_xbarb_south_en_tx),
    .south_packet_tx(mesh_xbarb_south_packet_tx),
    .south_stall_rx(mesh_xbarb_south_stall_rx),
    .south_en_rx(mesh_xbarb_south_en_rx),
    .south_packet_rx(mesh_xbarb_south_packet_rx),
    .east_stall_tx(mesh_xbarb_east_stall_tx),
    .east_en_tx(mesh_xbarb_east_en_tx),
    .east_packet_tx(mesh_xbarb_east_packet_tx),
    .east_stall_rx(mesh_xbarb_east_stall_rx),
    .east_en_rx(mesh_xbarb_east_en_rx),
    .east_packet_rx(mesh_xbarb_east_packet_rx),
    .west_stall_tx(mesh_xbarb_west_stall_tx),
    .west_en_tx(mesh_xbarb_west_en_tx),
    .west_packet_tx(mesh_xbarb_west_packet_tx),
    .west_stall_rx(mesh_xbarb_west_stall_rx),
    .west_en_rx(mesh_xbarb_west_en_rx),
    .west_packet_rx(mesh_xbarb_west_packet_rx)
);

`CONNECT_MESH_XBAR_INTERNALS(north);
`CONNECT_MESH_XBAR_INTERNALS(west);
`CONNECT_MESH_XBAR_INTERNALS(south);
`CONNECT_MESH_XBAR_INTERNALS(east);

endmodule