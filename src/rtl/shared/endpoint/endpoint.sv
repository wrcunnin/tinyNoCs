/*

Author: William Cunningham
Date  : 03/16/2026

Description:
    General purpose, customizable endpoint for networks.
    - endpoint_tx_buffer
        ~ stores requests to network
    - endpoint_rx_buffer
        ~ stores requests from network
    - return_addr_buffer
        ~ stores return addresses for active requests from the network
    - rx_arbiter
        ~ manages which buffer a packet from the network goes to
    - tx_arbiter
        ~ manages which buffer to select a packet from to send to the network

*/

import packet_pkg::*;

module endpoint #(
    parameter int TX_BUFFER_DEPTH,
    parameter int RX_BUFFER_DEPTH
) (
    // Clock, async reset
    input logic CLK, nRST,

    ////////////////////////////////////////////////////////
    // Requester sending data
    // Stalls the requesting FIFO
    output logic req_stall,

    // Requester wants to send a packet
    input logic req_en,

    // Packet information requester wants to send
    input packet_t req_packet,

    // Indicates if a requester requires the completion to stall
    input logic req_comp_stall,

    ////////////////////////////////////////////////////////
    // Responder sending data
    // Stalls the responding FIFO
    input logic resp_stall,

    // Responder wants to send a packet
    input logic resp_comp_en,

    // Return address of the packet
    input addr_t resp_comp_return_addr,

    // Packet information responder wants to send
    input packet_t resp_comp_packet,

    ////////////////////////////////////////////////////////
    // To Network signals
    // Stalls requests/responses to network
    input net_stall_tx,

    // Indicates we are sending a packet into the network
    output net_en_tx,

    // Packaged packet to send out to network
    output net_packet_t net_packet_tx,

    ////////////////////////////////////////////////////////
    // From Network signals
    // Stalls packets from network
    output net_stall_rx,

    // Indicates we are sending a packet into the network
    input net_en_rx,

    // Packaged packet to send out to network
    input net_packet_t net_packet_rx
);


/************************************************/
/* endpoint_tx_buffer                           */
/************************************************/
logic    endpoint_tx_buffer_fifo_router_full;
logic    endpoint_tx_buffer_fifo_router_empty;
logic    endpoint_tx_buffer_req_en;
packet_t endpoint_tx_buffer_req_packet;
logic    endpoint_tx_buffer_req_comp;
logic    endpoint_tx_buffer_req_comp_stall;
packet_t endpoint_tx_buffer_req_comp_packet;
logic    endpoint_tx_buffer_net_en;
logic    endpoint_tx_buffer_net_stall;
packet_t endpoint_tx_buffer_net_packet;
logic    endpoint_tx_buffer_net_comp;
packet_t endpoint_tx_buffer_net_comp_packet;

fifo_router #(
    .DEPTH(TX_BUFFER_DEPTH)
) endpoint_tx_buffer (
    .CLK(CLK),
    .nRST(nRST),
    .fifo_router_full(endpoint_tx_buffer_fifo_router_full),
    .fifo_router_empty(endpoint_tx_buffer_fifo_router_empty),
    .req_en(endpoint_tx_buffer_req_en),
    .req_packet(endpoint_tx_buffer_req_packet),
    .req_comp(endpoint_tx_buffer_req_comp),
    .req_comp_stall(endpoint_tx_buffer_req_comp_stall),
    .req_comp_packet(endpoint_tx_buffer_req_comp_packet),
    .net_en(endpoint_tx_buffer_net_en),
    .net_stall(endpoint_tx_buffer_net_stall),
    .net_packet(endpoint_tx_buffer_net_packet),
    .net_comp(endpoint_tx_buffer_net_comp),
    .net_comp_packet(endpoint_tx_buffer_net_comp_packet)
);


/************************************************/
/* endpoint_rx_buffer                           */
/************************************************/
logic    endpoint_rx_buffer_fifo_router_full;
logic    endpoint_rx_buffer_fifo_router_empty;
logic    endpoint_rx_buffer_req_en;
packet_t endpoint_rx_buffer_req_packet;
logic    endpoint_rx_buffer_req_comp;
logic    endpoint_rx_buffer_req_comp_stall;
packet_t endpoint_rx_buffer_req_comp_packet;
logic    endpoint_rx_buffer_net_en;
logic    endpoint_rx_buffer_net_stall;
packet_t endpoint_rx_buffer_net_packet;
logic    endpoint_rx_buffer_net_comp;
packet_t endpoint_rx_buffer_net_comp_packet;

fifo_router #(
    .DEPTH(RX_BUFFER_DEPTH)
) endpoint_rx_buffer (
    .CLK(CLK),
    .nRST(nRST),
    .fifo_router_full(endpoint_rx_buffer_fifo_router_full),
    .fifo_router_empty(endpoint_rx_buffer_fifo_router_empty),
    .req_en(endpoint_rx_buffer_req_en),
    .req_packet(endpoint_rx_buffer_req_packet),
    .req_comp(endpoint_rx_buffer_req_comp),
    .req_comp_stall(endpoint_rx_buffer_req_comp_stall),
    .req_comp_packet(endpoint_rx_buffer_req_comp_packet),
    .net_en(endpoint_rx_buffer_net_en),
    .net_stall(endpoint_rx_buffer_net_stall),
    .net_packet(endpoint_rx_buffer_net_packet),
    .net_comp(endpoint_rx_buffer_net_comp),
    .net_comp_packet(endpoint_rx_buffer_net_comp_packet)
);


/************************************************/
/* return_addr_buffer                           */
/************************************************/
logic                    return_addr_buffer_ren;
logic                    return_addr_buffer_wen;
logic [ADDRESS_BITS-1:0] return_addr_buffer_rdata;
logic [ADDRESS_BITS-1:0] return_addr_buffer_wdata;
logic                    return_addr_buffer_full;
logic                    return_addr_buffer_empty;

fifo_basic #(
    .DEPTH(RX_BUFFER_DEPTH),
    .DATA_WIDTH(ADDRESS_BITS)
) return_addr_buffer (
    .CLK(CLK),
    .nRST(nRST),
    .full(return_addr_buffer_full),
    .empty(return_addr_buffer_empty),
    .ren(return_addr_buffer_ren),
    .rdata(return_addr_buffer_rdata),
    .wen(return_addr_buffer_wen),
    .wdata(return_addr_buffer_wdata)
);


/************************************************/
/* rx_arbiter                                   */
/************************************************/
logic        rx_arbiter_req_stall;
logic        rx_arbiter_req_en;
addr_t       rx_arbiter_req_return_addr;
packet_t     rx_arbiter_req_packet;
logic        rx_arbiter_resp_stall;
logic        rx_arbiter_resp_en;
addr_t       rx_arbiter_resp_return_addr;
packet_t     rx_arbiter_resp_packet;
logic        rx_arbiter_net_en;
logic        rx_arbiter_net_stall;
net_packet_t rx_arbiter_net_packet;

endpoint_rx_arbiter rx_arbiter (
    .req_stall(rx_arbiter_req_stall),
    .req_en(rx_arbiter_req_en),
    .req_return_addr(rx_arbiter_req_return_addr),
    .req_packet(rx_arbiter_req_packet),
    .resp_stall(rx_arbiter_resp_stall),
    .resp_en(rx_arbiter_resp_en),
    .resp_return_addr(rx_arbiter_resp_return_addr),
    .resp_packet(rx_arbiter_resp_packet),
    .net_en(rx_arbiter_net_en),
    .net_stall(rx_arbiter_net_stall),
    .net_packet(rx_arbiter_net_packet)
);


/************************************************/
/* tx_arbiter                                   */
/************************************************/
logic        tx_arbiter_req_stall;
logic        tx_arbiter_req_en;
packet_t     tx_arbiter_req_packet;
logic        tx_arbiter_resp_stall;
logic        tx_arbiter_resp_en;
addr_t       tx_arbiter_resp_return_addr;
packet_t     tx_arbiter_resp_packet;
logic        tx_arbiter_net_en;
logic        tx_arbiter_net_stall;
net_packet_t tx_arbiter_net_packet;

endpoint_tx_arbiter tx_arbiter (
    .CLK(CLK),
    .nRST(nRST),
    .req_stall(tx_arbiter_req_stall),
    .req_en(tx_arbiter_req_en),
    .req_packet(tx_arbiter_req_packet),
    .resp_stall(tx_arbiter_resp_stall),
    .resp_en(tx_arbiter_resp_en),
    .resp_return_addr(tx_arbiter_resp_return_addr),
    .resp_packet(tx_arbiter_resp_packet),
    .net_en(tx_arbiter_net_en),
    .net_stall(tx_arbiter_net_stall),
    .net_packet(tx_arbiter_net_packet)
);


/************************************************/
/* assigns                                      */
/************************************************/
assign req_stall = endpoint_tx_buffer_fifo_router_full;
assign endpoint_tx_buffer_req_en = req_en;
assign endpoint_tx_buffer_req_packet = req_packet;
assign endpoint_tx_buffer_req_comp_stall = req_comp_stall;
assign endpoint_tx_buffer_net_stall = tx_arbiter_req_stall;
assign endpoint_tx_buffer_net_comp = rx_arbiter_req_en;
assign endpoint_tx_buffer_net_comp_packet = rx_arbiter_req_packet;

assign endpoint_rx_buffer_req_en = rx_arbiter_resp_en;
assign endpoint_rx_buffer_req_packet = rx_arbiter_resp_packet;
assign endpoint_rx_buffer_req_comp_stall = tx_arbiter_resp_stall;
assign endpoint_rx_buffer_net_stall = resp_stall;
assign endpoint_rx_buffer_net_comp = resp_comp_en;
assign endpoint_rx_buffer_net_comp_packet = resp_comp_packet;

assign return_addr_buffer_ren = tx_arbiter_resp_en && !tx_arbiter_resp_stall;
assign return_addr_buffer_wen = rx_arbiter_resp_en && !rx_arbiter_resp_stall;
assign return_addr_buffer_wdata = rx_arbiter_resp_return_addr;

assign rx_arbiter_req_stall = 0;
assign rx_arbiter_resp_stall = endpoint_rx_buffer_fifo_router_full;
assign rx_arbiter_net_en = net_en_rx;
assign rx_arbiter_net_packet = net_packet_rx;
assign net_stall_rx = rx_arbiter_net_stall;

assign tx_arbiter_req_en = endpoint_tx_buffer_net_en;
assign tx_arbiter_req_packet = endpoint_tx_buffer_net_packet;
assign tx_arbiter_resp_en = endpoint_rx_buffer_req_comp;
assign tx_arbiter_resp_return_addr = return_addr_buffer_rdata;
assign tx_arbiter_resp_packet = endpoint_rx_buffer_req_comp_packet;
assign tx_arbiter_net_stall = net_stall_tx;
assign net_en_tx = tx_arbiter_net_en;
assign net_packet_tx = tx_arbiter_net_packet;

// Sanity checks
assert (return_addr_buffer_full == endpoint_rx_buffer_fifo_router_full);
assert (return_addr_buffer_empty == endpoint_rx_buffer_fifo_router_empty);

endmodule