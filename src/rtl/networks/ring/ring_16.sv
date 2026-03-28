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
logic        endpoint_``id``_resp_full; \
logic        endpoint_``id``_resp_empty; \
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
    .resp_full(endpoint_``id``_resp_full), \
    .resp_empty(endpoint_``id``_resp_empty), \
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
assign resp_full[id] = endpoint_``id``_resp_full; \
assign resp_empty[id] = endpoint_``id``_resp_empty; \
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

module ring_16 #(
    parameter int TX_BUFFER_DEPTH = 8,
    parameter int RX_BUFFER_DEPTH = 8
) (
    // Clock, async reset
    input logic CLK, nRST,

    ////////////////////////////////////////////////////////
    // Requester sending data
    // Lets requester know if TX FIFO is full/empty
    output logic [15:0] req_full, req_empty,

    // Requester wants to send a packet
    input logic [15:0] req_en,

    // Packet information requester wants to send
    input packet_t [15:0] req_packet,

    // Indicates if a requester requires the completion to stall
    input logic [15:0] req_comp_stall,

    // Indicates a request is ready to be completed
    output logic [15:0] req_comp_en,

    // Packet information returned back to requester
    output packet_t [15:0] req_comp_packet,

    ////////////////////////////////////////////////////////
    // Responder sending data
    // Lets responder know if RX FIFO is full/empty
    output logic [15:0] resp_full, resp_empty,

    // Stalls the responding FIFO
    input logic [15:0] resp_stall,

    // Initiates the responder to begin servicing this request
    output logic [15:0] resp_en,

    // Packet going out to the responder
    output packet_t [15:0] resp_packet,

    // Responder wants to send a packet
    input logic [15:0] resp_comp_en,

    // Return address of the packet
    input addr_t [15:0] resp_comp_return_addr,

    // Packet information responder wants to send
    input packet_t [15:0] resp_comp_packet
);

`CREATE_ENDPOINT_XBAR(0, 32'h00000000, 32'h0FFFFFFF);
`CREATE_ENDPOINT_XBAR(1, 32'h10000000, 32'h1FFFFFFF);
`CREATE_ENDPOINT_XBAR(2, 32'h20000000, 32'h2FFFFFFF);
`CREATE_ENDPOINT_XBAR(3, 32'h30000000, 32'h3FFFFFFF);
`CREATE_ENDPOINT_XBAR(4, 32'h40000000, 32'h4FFFFFFF);
`CREATE_ENDPOINT_XBAR(5, 32'h50000000, 32'h5FFFFFFF);
`CREATE_ENDPOINT_XBAR(6, 32'h60000000, 32'h6FFFFFFF);
`CREATE_ENDPOINT_XBAR(7, 32'h70000000, 32'h7FFFFFFF);
`CREATE_ENDPOINT_XBAR(8, 32'h80000000, 32'h8FFFFFFF);
`CREATE_ENDPOINT_XBAR(9, 32'h90000000, 32'h9FFFFFFF);
`CREATE_ENDPOINT_XBAR(10, 32'hA0000000, 32'hAFFFFFFF);
`CREATE_ENDPOINT_XBAR(11, 32'hB0000000, 32'hBFFFFFFF);
`CREATE_ENDPOINT_XBAR(12, 32'hC0000000, 32'hCFFFFFFF);
`CREATE_ENDPOINT_XBAR(13, 32'hD0000000, 32'hDFFFFFFF);
`CREATE_ENDPOINT_XBAR(14, 32'hE0000000, 32'hEFFFFFFF);
`CREATE_ENDPOINT_XBAR(15, 32'hF0000000, 32'hFFFFFFFF);
`CONNECT_XBAR(0, 15, 1);
`CONNECT_XBAR(1, 0, 2);
`CONNECT_XBAR(2, 1, 3);
`CONNECT_XBAR(3, 2, 4);
`CONNECT_XBAR(4, 3, 5);
`CONNECT_XBAR(5, 4, 6);
`CONNECT_XBAR(6, 5, 7);
`CONNECT_XBAR(7, 6, 8);
`CONNECT_XBAR(8, 7, 9);
`CONNECT_XBAR(9, 8, 10);
`CONNECT_XBAR(10, 9, 11);
`CONNECT_XBAR(11, 10, 12);
`CONNECT_XBAR(12, 11, 13);
`CONNECT_XBAR(13, 12, 14);
`CONNECT_XBAR(14, 13, 15);
`CONNECT_XBAR(15, 14, 0);

endmodule