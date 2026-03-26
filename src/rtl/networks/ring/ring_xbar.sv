/*

Author: William Cunningham
Date  : 03/21/2026

Description:
    Crossbar router for a ring network

*/

import packet_pkg::*;

module ring_xbar #(
    parameter int unsigned ENDPOINT_ADDR_START,
    parameter int unsigned ENDPOINT_ADDR_STOP,
    parameter int NET_BUFFER_TX_DEPTH,
    parameter int EP_BUFFER_RX_DEPTH,
    parameter int EP_BUFFER_TX_DEPTH
) (
    // Clock, async reset
    input logic CLK, nRST,

    ////////////////////////////////////////////////////////
    // From Ring Crossbar
    // Stall the incoming network packet
    output logic net_stall_rx,

    // Indicates an incoming packet from the network
    input logic net_en_rx,

    // Incoming packet from the network
    input net_packet_t net_packet_rx,

    ////////////////////////////////////////////////////////
    // To Ring Crossbar
    // Outgoing packet is getting stalled
    input logic net_stall_tx,

    // Indicates an outgoing packet from the network
    output logic net_en_tx,

    // Outgoing packet to the network
    output net_packet_t net_packet_tx,

    ////////////////////////////////////////////////////////
    // From Endpoint
    // Stall the incoming endpoint packet
    output logic endpoint_stall_rx,

    // Indicates an incoming packet from the endpoint
    input logic endpoint_en_rx,

    // Incoming packet from the endpoint
    input net_packet_t endpoint_packet_rx,

    ////////////////////////////////////////////////////////
    // To Endpoint
    // Stall the outgoing endpoint packet
    input logic endpoint_stall_tx,

    // Indicates an incoming packet from the endpoint
    output logic endpoint_en_tx,

    // Incoming packet from the endpoint
    output net_packet_t endpoint_packet_tx

);

/************************************************/
/* net_buffer_tx                                */
/************************************************/
logic                       net_buffer_tx_ren;
logic                       net_buffer_tx_wen;
logic [NET_PACKET_BITS-1:0] net_buffer_tx_rdata;
logic [NET_PACKET_BITS-1:0] net_buffer_tx_wdata;
logic                       net_buffer_tx_full;
logic                       net_buffer_tx_empty;

fifo_basic #(
    .DEPTH(NET_BUFFER_TX_DEPTH),
    .DATA_WIDTH(NET_PACKET_BITS)
) net_buffer_tx (
    .CLK(CLK),
    .nRST(nRST),
    .full(net_buffer_tx_full),
    .empty(net_buffer_tx_empty),
    .ren(net_buffer_tx_ren),
    .rdata(net_buffer_tx_rdata),
    .wen(net_buffer_tx_wen),
    .wdata(net_buffer_tx_wdata)
);


/************************************************/
/* endpoint_buffer_rx                           */
/************************************************/
logic                       endpoint_buffer_rx_ren;
logic                       endpoint_buffer_rx_wen;
logic [NET_PACKET_BITS-1:0] endpoint_buffer_rx_rdata;
logic [NET_PACKET_BITS-1:0] endpoint_buffer_rx_wdata;
logic                       endpoint_buffer_rx_full;
logic                       endpoint_buffer_rx_empty;

fifo_basic #(
    .DEPTH(EP_BUFFER_RX_DEPTH),
    .DATA_WIDTH(NET_PACKET_BITS)
) endpoint_buffer_rx (
    .CLK(CLK),
    .nRST(nRST),
    .full(endpoint_buffer_rx_full),
    .empty(endpoint_buffer_rx_empty),
    .ren(endpoint_buffer_rx_ren),
    .rdata(endpoint_buffer_rx_rdata),
    .wen(endpoint_buffer_rx_wen),
    .wdata(endpoint_buffer_rx_wdata)
);


/************************************************/
/* xbarb                                        */
/************************************************/
logic        xbarb_net_stall_rx;
logic        xbarb_net_en_rx;
net_packet_t xbarb_net_packet_rx;
logic        xbarb_net_stall_tx;
logic        xbarb_net_en_tx;
net_packet_t xbarb_net_packet_tx;
logic        xbarb_endpoint_stall_rx;
logic        xbarb_endpoint_en_rx;
net_packet_t xbarb_endpoint_packet_rx;
logic        xbarb_endpoint_stall_tx;
logic        xbarb_endpoint_en_tx;
net_packet_t xbarb_endpoint_packet_tx;
ring_xbar_arbiter #(
    .ENDPOINT_ADDR_START(ENDPOINT_ADDR_START),
    .ENDPOINT_ADDR_STOP(ENDPOINT_ADDR_STOP)
) xbarb (
    .CLK(CLK),
    .nRST(nRST),
    .net_stall_rx(xbarb_net_stall_rx),
    .net_en_rx(xbarb_net_en_rx),
    .net_packet_rx(xbarb_net_packet_rx),
    .net_stall_tx(xbarb_net_stall_tx),
    .net_en_tx(xbarb_net_en_tx),
    .net_packet_tx(xbarb_net_packet_tx),
    .endpoint_stall_rx(xbarb_endpoint_stall_rx),
    .endpoint_en_rx(xbarb_endpoint_en_rx),
    .endpoint_packet_rx(xbarb_endpoint_packet_rx),
    .endpoint_stall_tx(xbarb_endpoint_stall_tx),
    .endpoint_en_tx(xbarb_endpoint_en_tx),
    .endpoint_packet_tx(xbarb_endpoint_packet_tx)
);


/************************************************/
/* assigns                                      */
/************************************************/
assign net_stall_rx = xbarb_net_stall_rx;
assign net_en_tx = !net_buffer_tx_empty;
assign net_packet_tx = net_buffer_tx_rdata;
assign endpoint_stall_rx = endpoint_buffer_rx_full;
assign endpoint_en_tx = xbarb_endpoint_en_tx;
assign endpoint_packet_tx = xbarb_endpoint_packet_tx;

assign net_buffer_tx_ren = !net_stall_tx;
assign net_buffer_tx_wen = xbarb_net_en_tx;
assign net_buffer_tx_wdata = xbarb_net_packet_tx;

assign endpoint_buffer_rx_ren = !xbarb_endpoint_stall_rx;
assign endpoint_buffer_rx_wen = endpoint_en_rx;
assign endpoint_buffer_rx_wdata = endpoint_packet_rx;

assign xbarb_net_en_rx = net_en_rx;
assign xbarb_net_packet_rx = net_packet_rx;
assign xbarb_net_stall_tx = net_buffer_tx_full;
assign xbarb_endpoint_en_rx = !endpoint_buffer_rx_empty;
assign xbarb_endpoint_packet_rx = endpoint_buffer_rx_rdata;
assign xbarb_endpoint_stall_tx = endpoint_stall_tx;

always_comb begin : sanityChecks
    assert (ENDPOINT_ADDR_START <= ENDPOINT_ADDR_STOP);
end

endmodule