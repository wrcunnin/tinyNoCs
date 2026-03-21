/*

Author: William Cunningham
Date  : 03/21/2026

Description:
    2-endpoint ring network

*/

import packet_pkg::*;

`define CREATE_ENDPOINT_XBAR(id, start_addr, stop_addr) \
logic        endpoint_``id``_req_full; \
logic        endpoint_``id``_req_empty; \
logic        endpoint_``id``_req_en; \
packet_t     endpoint_``id``_req_packet; \
logic        endpoint_``id``_req_comp_stall; \
logic        endpoint_``id``_req_comp_en; \
packet_t     endpoint_``id``_req_comp_packet; \
logic        endpoint_``id``_resp_stall; \
logic        endpoint_``id``_resp_en; \
packet_t     endpoint_``id``_resp_packet; \
logic        endpoint_``id``_resp_comp_en; \
addr_t       endpoint_``id``_resp_comp_return_addr; \
packet_t     endpoint_``id``_resp_comp_packet; \
logic        endpoint_``id``_net_stall_tx; \
logic        endpoint_``id``_net_en_tx; \
net_packet_t endpoint_``id``_net_packet_tx; \
logic        endpoint_``id``_net_stall_rx; \
logic        endpoint_``id``_net_en_rx; \
net_packet_t endpoint_``id``_net_packet_rx; \
endpoint #( \
    .TX_BUFFER_DEPTH(TX_BUFFER_DEPTH), \
    .RX_BUFFER_DEPTH(RX_BUFFER_DEPTH), \
    .ENDPOINT_ADDR(start_addr) \
) endpoint_``id`` ( \
    .CLK(CLK), \
    .nRST(nRST), \
    .req_full(endpoint_``id``_req_full), \
    .req_empty(endpoint_``id``_req_empty), \
    .req_en(endpoint_``id``_req_en), \
    .req_packet(endpoint_``id``_req_packet), \
    .req_comp_stall(endpoint_``id``_req_comp_stall), \
    .req_comp_en(endpoint_``id``_req_comp_en), \
    .req_comp_packet(endpoint_``id``_req_comp_packet), \
    .resp_stall(endpoint_``id``_resp_stall), \
    .resp_en(endpoint_``id``_resp_en), \
    .resp_packet(endpoint_``id``_resp_packet), \
    .resp_comp_en(endpoint_``id``_resp_comp_en), \
    .resp_comp_return_addr(endpoint_``id``_resp_comp_return_addr), \
    .resp_comp_packet(endpoint_``id``_resp_comp_packet), \
    .net_stall_tx(endpoint_``id``_net_stall_tx), \
    .net_en_tx(endpoint_``id``_net_en_tx), \
    .net_packet_tx(endpoint_``id``_net_packet_tx), \
    .net_stall_rx(endpoint_``id``_net_stall_rx), \
    .net_en_rx(endpoint_``id``_net_en_rx), \
    .net_packet_rx(endpoint_``id``_net_packet_rx) \
); \
\
logic        rxbar_``id``_net_stall_rx; \
logic        rxbar_``id``_net_en_rx; \
net_packet_t rxbar_``id``_net_packet_rx; \
logic        rxbar_``id``_net_stall_tx; \
logic        rxbar_``id``_net_en_tx; \
net_packet_t rxbar_``id``_net_packet_tx; \
logic        rxbar_``id``_endpoint_stall_rx; \
logic        rxbar_``id``_endpoint_en_rx; \
net_packet_t rxbar_``id``_endpoint_packet_rx; \
logic        rxbar_``id``_endpoint_stall_tx; \
logic        rxbar_``id``_endpoint_en_tx; \
net_packet_t rxbar_``id``_endpoint_packet_tx; \
ring_xbar #( \
    .ENDPOINT_ADDR_START(start_addr), \
    .ENDPOINT_ADDR_STOP(stop_addr), \
    .NET_BUFFER_TX_DEPTH(2*TX_BUFFER_DEPTH), \
    .EP_BUFFER_RX_DEPTH(TX_BUFFER_DEPTH), \
    .EP_BUFFER_TX_DEPTH(RX_BUFFER_DEPTH) \
) rxbar_``id`` ( \
    .CLK(CLK), \
    .nRST(nRST), \
    .net_stall_rx(rxbar_``id``_net_stall_rx), \
    .net_en_rx(rxbar_``id``_net_en_rx), \
    .net_packet_rx(rxbar_``id``_net_packet_rx), \
    .net_stall_tx(rxbar_``id``_net_stall_tx), \
    .net_en_tx(rxbar_``id``_net_en_tx), \
    .net_packet_tx(rxbar_``id``_net_packet_tx), \
    .endpoint_stall_rx(rxbar_``id``_endpoint_stall_rx), \
    .endpoint_en_rx(rxbar_``id``_endpoint_en_rx), \
    .endpoint_packet_rx(rxbar_``id``_endpoint_packet_rx), \
    .endpoint_stall_tx(rxbar_``id``_endpoint_stall_tx), \
    .endpoint_en_tx(rxbar_``id``_endpoint_en_tx), \
    .endpoint_packet_tx(rxbar_``id``_endpoint_packet_tx) \
);

`define CONNECT_XBAR(id, rx_id, tx_id) \
assign req_full[id] = endpoint_``id``_req_full; \
assign req_empty[id] = endpoint_``id``_req_empty; \
assign req_comp_en[id] = endpoint_``id``_req_comp_en; \
assign req_comp_packet[id] = endpoint_``id``_req_comp_packet; \
assign resp_packet[id] = endpoint_``id``_resp_packet; \
assign resp_en[id] = endpoint_``id``_resp_en; \
assign endpoint_``id``_req_en = req_en[id]; \
assign endpoint_``id``_req_packet = req_packet[id]; \
assign endpoint_``id``_req_comp_stall = req_comp_stall[id]; \
assign endpoint_``id``_resp_stall = resp_stall[id]; \
assign endpoint_``id``_resp_comp_en = resp_comp_en[id]; \
assign endpoint_``id``_resp_comp_return_addr = resp_comp_return_addr[id]; \
assign endpoint_``id``_resp_comp_packet = resp_comp_packet[id]; \
assign endpoint_``id``_net_stall_tx = rxbar_``id``_endpoint_stall_rx; \
assign endpoint_``id``_net_en_rx = rxbar_``id``_endpoint_en_tx; \
assign endpoint_``id``_net_packet_rx = rxbar_``id``_endpoint_packet_tx; \
assign rxbar_``id``_net_en_rx = rxbar_``rx_id``_net_en_tx; \
assign rxbar_``id``_net_packet_rx = rxbar_``rx_id``_net_packet_tx; \
assign rxbar_``id``_net_stall_tx = rxbar_``tx_id``_net_stall_rx; \
assign rxbar_``id``_endpoint_en_rx = endpoint_``id``_net_en_tx; \
assign rxbar_``id``_endpoint_packet_rx = endpoint_``id``_net_packet_tx; \
assign rxbar_``id``_endpoint_stall_tx = endpoint_``id``_net_stall_rx;

module ring_2 #(
    parameter int TX_BUFFER_DEPTH,
    parameter int RX_BUFFER_DEPTH
) (
    // Clock, async reset
    input logic CLK, nRST,

    ////////////////////////////////////////////////////////
    // Requester sending data
    // Lets requester know if TX FIFO is full/empty
    output logic [1:0] req_full, req_empty,

    // Requester wants to send a packet
    input logic [1:0] req_en,

    // Packet information requester wants to send
    input packet_t [1:0] req_packet,

    // Indicates if a requester requires the completion to stall
    input logic [1:0] req_comp_stall,

    // Indicates a request is ready to be completed
    output logic [1:0] req_comp_en,

    // Packet information returned back to requester
    output packet_t [1:0] req_comp_packet,

    ////////////////////////////////////////////////////////
    // Responder sending data
    // Stalls the responding FIFO
    input logic [1:0] resp_stall,

    // Initiates the responder to begin servicing this request
    output logic [1:0] resp_en,

    // Packet going out to the responder
    output packet_t [1:0] resp_packet,

    // Responder wants to send a packet
    input logic [1:0] resp_comp_en,

    // Return address of the packet
    input addr_t [1:0] resp_comp_return_addr,

    // Packet information responder wants to send
    input packet_t [1:0] resp_comp_packet
);

`CREATE_ENDPOINT_XBAR(0, 32'h00000000, 32'h7FFFFFFF);
`CREATE_ENDPOINT_XBAR(1, 32'h80000000, 32'hFFFFFFFF);
`CONNECT_XBAR(0, 1, 1);
`CONNECT_XBAR(1, 0, 0);

// /************************************************/
// /* endpoint_0                                   */
// /************************************************/
// logic        endpoint_0_req_full;
// logic        endpoint_0_req_empty;
// logic        endpoint_0_req_en;
// packet_t     endpoint_0_req_packet;
// logic        endpoint_0_req_comp_stall;
// logic        endpoint_0_req_comp_en;
// packet_t     endpoint_0_req_comp_packet;
// logic        endpoint_0_resp_stall;
// logic        endpoint_0_resp_en;
// packet_t     endpoint_0_resp_packet;
// logic        endpoint_0_resp_comp_en;
// addr_t       endpoint_0_resp_comp_return_addr;
// packet_t     endpoint_0_resp_comp_packet;
// logic        endpoint_0_net_stall_tx;
// logic        endpoint_0_net_en_tx;
// net_packet_t endpoint_0_net_packet_tx;
// logic        endpoint_0_net_stall_rx;
// logic        endpoint_0_net_en_rx;
// net_packet_t endpoint_0_net_packet_rx;
// endpoint #(
//     .TX_BUFFER_DEPTH(TX_BUFFER_DEPTH),
//     .RX_BUFFER_DEPTH(RX_BUFFER_DEPTH),
//     .ENDPOINT_ADDR(32'h00000000)
// ) endpoint_0 (
//     .CLK(CLK),
//     .nRST(nRST),
//     .req_full(endpoint_0_req_full),
//     .req_empty(endpoint_0_req_empty),
//     .req_en(endpoint_0_req_en),
//     .req_packet(endpoint_0_req_packet),
//     .req_comp_stall(endpoint_0_req_comp_stall),
//     .req_comp_en(endpoint_0_req_comp_en),
//     .req_comp_packet(endpoint_0_req_comp_packet),
//     .resp_stall(endpoint_0_resp_stall),
//     .resp_en(endpoint_0_resp_en),
//     .resp_packet(endpoint_0_resp_packet),
//     .resp_comp_en(endpoint_0_resp_comp_en),
//     .resp_comp_return_addr(endpoint_0_resp_comp_return_addr),
//     .resp_comp_packet(endpoint_0_resp_comp_packet),
//     .net_stall_tx(endpoint_0_net_stall_tx),
//     .net_en_tx(endpoint_0_net_en_tx),
//     .net_packet_tx(endpoint_0_net_packet_tx),
//     .net_stall_rx(endpoint_0_net_stall_rx),
//     .net_en_rx(endpoint_0_net_en_rx),
//     .net_packet_rx(endpoint_0_net_packet_rx)
// );


// /************************************************/
// /* endpoint_1                                   */
// /************************************************/
// logic        endpoint_1_req_full;
// logic        endpoint_1_req_empty;
// logic        endpoint_1_req_en;
// packet_t     endpoint_1_req_packet;
// logic        endpoint_1_req_comp_stall;
// logic        endpoint_1_req_comp_en;
// packet_t     endpoint_1_req_comp_packet;
// logic        endpoint_1_resp_stall;
// logic        endpoint_1_resp_en;
// packet_t     endpoint_1_resp_packet;
// logic        endpoint_1_resp_comp_en;
// addr_t       endpoint_1_resp_comp_return_addr;
// packet_t     endpoint_1_resp_comp_packet;
// logic        endpoint_1_net_stall_tx;
// logic        endpoint_1_net_en_tx;
// net_packet_t endpoint_1_net_packet_tx;
// logic        endpoint_1_net_stall_rx;
// logic        endpoint_1_net_en_rx;
// net_packet_t endpoint_1_net_packet_rx;
// endpoint #(
//     .TX_BUFFER_DEPTH(TX_BUFFER_DEPTH),
//     .RX_BUFFER_DEPTH(RX_BUFFER_DEPTH),
//     .ENDPOINT_ADDR(32'h80000000)
// ) endpoint_1 (
//     .CLK(CLK),
//     .nRST(nRST),
//     .req_full(endpoint_1_req_full),
//     .req_empty(endpoint_1_req_empty),
//     .req_en(endpoint_1_req_en),
//     .req_packet(endpoint_1_req_packet),
//     .req_comp_stall(endpoint_1_req_comp_stall),
//     .req_comp_en(endpoint_1_req_comp_en),
//     .req_comp_packet(endpoint_1_req_comp_packet),
//     .resp_stall(endpoint_1_resp_stall),
//     .resp_en(endpoint_1_resp_en),
//     .resp_packet(endpoint_1_resp_packet),
//     .resp_comp_en(endpoint_1_resp_comp_en),
//     .resp_comp_return_addr(endpoint_1_resp_comp_return_addr),
//     .resp_comp_packet(endpoint_1_resp_comp_packet),
//     .net_stall_tx(endpoint_1_net_stall_tx),
//     .net_en_tx(endpoint_1_net_en_tx),
//     .net_packet_tx(endpoint_1_net_packet_tx),
//     .net_stall_rx(endpoint_1_net_stall_rx),
//     .net_en_rx(endpoint_1_net_en_rx),
//     .net_packet_rx(endpoint_1_net_packet_rx)
// );


// /************************************************/
// /* rxbar_0                                      */
// /************************************************/
// logic        rxbar_0_net_stall_rx;
// logic        rxbar_0_net_en_rx;
// net_packet_t rxbar_0_net_packet_rx;
// logic        rxbar_0_net_stall_tx;
// logic        rxbar_0_net_en_tx;
// net_packet_t rxbar_0_net_packet_tx;
// logic        rxbar_0_endpoint_stall_rx;
// logic        rxbar_0_endpoint_en_rx;
// net_packet_t rxbar_0_endpoint_packet_rx;
// logic        rxbar_0_endpoint_stall_tx;
// logic        rxbar_0_endpoint_en_tx;
// net_packet_t rxbar_0_endpoint_packet_tx;

// ring_xbar #(
//     .ENDPOINT_ADDR_START(32'h00000000),
//     .ENDPOINT_ADDR_STOP(32'h7FFFFFFF),
//     .NET_BUFFER_TX_DEPTH(2*TX_BUFFER_DEPTH),
//     .EP_BUFFER_RX_DEPTH(TX_BUFFER_DEPTH),
//     .EP_BUFFER_TX_DEPTH(RX_BUFFER_DEPTH)
// ) rxbar_0 (
//     .CLK(CLK),
//     .nRST(nRST),
//     .net_stall_rx(rxbar_0_net_stall_rx),
//     .net_en_rx(rxbar_0_net_en_rx),
//     .net_packet_rx(rxbar_0_net_packet_rx),
//     .net_stall_tx(rxbar_0_net_stall_tx),
//     .net_en_tx(rxbar_0_net_en_tx),
//     .net_packet_tx(rxbar_0_net_packet_tx),
//     .endpoint_stall_rx(rxbar_0_endpoint_stall_rx),
//     .endpoint_en_rx(rxbar_0_endpoint_en_rx),
//     .endpoint_packet_rx(rxbar_0_endpoint_packet_rx),
//     .endpoint_stall_tx(rxbar_0_endpoint_stall_tx),
//     .endpoint_en_tx(rxbar_0_endpoint_en_tx),
//     .endpoint_packet_tx(rxbar_0_endpoint_packet_tx)
// );


// /************************************************/
// /* rxbar_1                                      */
// /************************************************/
// logic        rxbar_1_net_stall_rx;
// logic        rxbar_1_net_en_rx;
// net_packet_t rxbar_1_net_packet_rx;
// logic        rxbar_1_net_stall_tx;
// logic        rxbar_1_net_en_tx;
// net_packet_t rxbar_1_net_packet_tx;
// logic        rxbar_1_endpoint_stall_rx;
// logic        rxbar_1_endpoint_en_rx;
// net_packet_t rxbar_1_endpoint_packet_rx;
// logic        rxbar_1_endpoint_stall_tx;
// logic        rxbar_1_endpoint_en_tx;
// net_packet_t rxbar_1_endpoint_packet_tx;

// ring_xbar #(
//     .ENDPOINT_ADDR_START(32'h80000000),
//     .ENDPOINT_ADDR_STOP(32'hFFFFFFFF),
//     .NET_BUFFER_TX_DEPTH(2*TX_BUFFER_DEPTH),
//     .EP_BUFFER_RX_DEPTH(TX_BUFFER_DEPTH),
//     .EP_BUFFER_TX_DEPTH(RX_BUFFER_DEPTH)
// ) rxbar_1 (
//     .CLK(CLK),
//     .nRST(nRST),
//     .net_stall_rx(rxbar_1_net_stall_rx),
//     .net_en_rx(rxbar_1_net_en_rx),
//     .net_packet_rx(rxbar_1_net_packet_rx),
//     .net_stall_tx(rxbar_1_net_stall_tx),
//     .net_en_tx(rxbar_1_net_en_tx),
//     .net_packet_tx(rxbar_1_net_packet_tx),
//     .endpoint_stall_rx(rxbar_1_endpoint_stall_rx),
//     .endpoint_en_rx(rxbar_1_endpoint_en_rx),
//     .endpoint_packet_rx(rxbar_1_endpoint_packet_rx),
//     .endpoint_stall_tx(rxbar_1_endpoint_stall_tx),
//     .endpoint_en_tx(rxbar_1_endpoint_en_tx),
//     .endpoint_packet_tx(rxbar_1_endpoint_packet_tx)
// );

/************************************************/
/* assigns                                     */
/************************************************/
// assign req_full[0] = endpoint_0_req_full;
// assign req_empty[0] = endpoint_0_req_empty;
// assign req_comp_en[0] = endpoint_0_req_comp_en;
// assign req_comp_packet[0] = endpoint_0_req_comp_packet;
// assign resp_packet[0] = endpoint_0_resp_packet;
// assign resp_en[0] = endpoint_0_resp_en;
// assign endpoint_0_req_en = req_en[0];
// assign endpoint_0_req_packet = req_packet[0];
// assign endpoint_0_req_comp_stall = req_comp_stall[0];
// assign endpoint_0_resp_stall = resp_stall[0];
// assign endpoint_0_resp_comp_en = resp_comp_en[0];
// assign endpoint_0_resp_comp_return_addr = resp_comp_return_addr[0];
// assign endpoint_0_resp_comp_packet = resp_comp_packet[0];
// assign endpoint_0_net_stall_tx = rxbar_0_endpoint_stall_rx;
// assign endpoint_0_net_en_rx = rxbar_0_endpoint_en_tx;
// assign endpoint_0_net_packet_rx = rxbar_0_endpoint_packet_tx;

// assign rxbar_0_net_en_rx = rxbar_1_net_en_tx;
// assign rxbar_0_net_packet_rx = rxbar_1_net_packet_tx;
// assign rxbar_0_net_stall_tx = rxbar_1_net_stall_rx;
// assign rxbar_0_endpoint_en_rx = endpoint_0_net_en_tx;
// assign rxbar_0_endpoint_packet_rx = endpoint_0_net_packet_tx;
// assign rxbar_0_endpoint_stall_tx = endpoint_0_net_stall_rx;


// assign req_full[1] = endpoint_1_req_full;
// assign req_empty[1] = endpoint_1_req_empty;
// assign req_comp_en[1] = endpoint_1_req_comp_en;
// assign req_comp_packet[1] = endpoint_1_req_comp_packet;
// assign resp_en[1] = endpoint_1_resp_en;
// assign resp_packet[1] = endpoint_1_resp_packet;
// assign endpoint_1_req_en = req_en[1];
// assign endpoint_1_req_packet = req_packet[1];
// assign endpoint_1_req_comp_stall = req_comp_stall[1];
// assign endpoint_1_resp_stall = resp_stall[1];
// assign endpoint_1_resp_comp_en = resp_comp_en[1];
// assign endpoint_1_resp_comp_return_addr = resp_comp_return_addr[1];
// assign endpoint_1_resp_comp_packet = resp_comp_packet[1];
// assign endpoint_1_net_stall_tx = ;
// logic        endpoint_1_net_en_tx;
// net_packet_t endpoint_1_net_packet_tx;
// logic        endpoint_1_net_stall_rx;
// assign endpoint_1_net_en_rx = ;
// assign endpoint_1_net_packet_rx = ;

// logic        rxbar_1_net_stall_rx;
// assign rxbar_1_net_en_rx = ;
// assign rxbar_1_net_packet_rx = ;
// assign rxbar_1_net_stall_tx = ;
// logic        rxbar_1_net_en_tx;
// net_packet_t rxbar_1_net_packet_tx;
// logic        rxbar_1_endpoint_stall_rx;
// assign rxbar_1_endpoint_en_rx = ;
// assign rxbar_1_endpoint_packet_rx = ;
// assign rxbar_1_endpoint_stall_tx = ;
// logic        rxbar_1_endpoint_en_tx;
// net_packet_t rxbar_1_endpoint_packet_tx;

endmodule