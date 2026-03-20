/*

Author: William Cunningham
Date  : 03/19/2026

Description:
    Arbitrates between sending a response or request to the network.
*/

import packet_pkg::*;

module endpoint_tx_arbiter #(
    parameter int ENDPOINT_ADDR
) (
    // Clock, async reset
    input logic CLK, nRST,

    ////////////////////////////////////////////////////////
    // Requester sending data
    // Stalls the requesting FIFO
    output logic req_stall

    // Requester wants to send a packet
    input logic req_en,

    // Packet information requester wants to send
    input packet_t req_packet,

    ////////////////////////////////////////////////////////
    // Responder sending data
    // Stalls the responding FIFO
    output logic resp_stall,

    // Responder wants to send a packet
    input logic resp_en,

    // Return address of the packet
    input addr_t resp_return_addr,

    // Packet information responder wants to send
    input packet_t resp_packet,

    ////////////////////////////////////////////////////////
    // To Network signals
    // Stalls requests/responses to network
    input net_stall,

    // Indicates we are sending a packet into the network
    output net_en,

    // Packaged packet to send out to network
    output net_packet_t net_packet
);

typedef enum logic [1:0] { EPTXARB_NONE, EPTXARB_REQ, EPTXARB_RESP } endpoint_tx_arbiter_lru_state_t;

endpoint_tx_arbiter_lru_state_t lru, next_lru, selected;

always_ff @( posedge CLK, negedge nRST ) begin : EPTXARB_LRU
    if (!nRST)
        lru <= EPTXARB_REQ;

    // if the network is enabled & there's no stall, update the LRU state
    else if (net_en && !net_stall)
        lru <= next_lru;
end

always_comb begin : packetSelection
    selected = EPTXARB_NONE;
    next_lru = lru;

    // If both want to send
    if (req_en && resp_en) begin
        selected = lru;
        next_lru = lru == EPTXARB_REQ ? EPTXARB_RESP : EPTXARB_REQ;
    end

    // If the requester is wanting to send & responder has nothing to send
    else if (req_en && !resp_en) begin
        selected = EPTXARB_REQ;
        next_lru = EPTXARB_RESP;
    end

    // If the responder is wanting to send & requester has nothing to send
    else if (!rep_en && resp_en) begin
        selected = EPTXARB_RESP;
        next_lru = EPTXARB_REQ;
    end
end

always_comb begin : packetCreation
    req_stall = 1;
    resp_stall = 1;
    net_en = 0;
    net_packet = '0;

    // The requester has been selected
    // - We enable the network send signal
    // - Set the requester stall to the network stall
    // - Set the request signal to 1 since this is a request
    // - Set the start address to that of this endpoint
    // - Set the packet to that in the requester's FIFO (TX)
    if (selected == EPTXARB_REQ) begin
        net_en = 1;
        req_stall = net_stall;
        net_packet.request = 1;
        net_packet.start_addr = addr_t'(ENDPOINT_ADDR);
        net_packet.packet = req_packet;
    end

    // The responder has been selected
    // - We enable the network send signal
    // - Set the responder stall to the network stall
    // - Set the request signal to 0 since this is a response
    // - Set the start address to that the address originally in the packet
    // - Set the packet to that in the responder's FIFO (RX)
    // - Set the address in the packet from the FIFO to the return address
    else if (selected == EPTXARB_RESP) begin
        net_en = 1;
        resp_stall = net_stall;
        net_packet.request = 0;
        net_packet.start_addr = resp_packet.addr;
        net_packet.packet = resp_packet;
        net_packet.packet.addr = resp_return_addr;
    end
end

endmodule