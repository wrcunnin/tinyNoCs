/*

Author: William Cunningham
Date  : 03/21/2026

Description:
    Arbiter for a ring crossbar

*/

module ring_xbar_arbiter #(
    parameter int unsigned ENDPOINT_ADDR_START,
    parameter int unsigned ENDPOINT_ADDR_STOP
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

typedef enum logic [1:0] { RXBAR_NONE, RXBAR_EP, RXBAR_NET } ring_xbar_arbiter_lru_state_t;

ring_xbar_arbiter_lru_state_t lru, next_lru, selected;

always_ff @( posedge CLK, negedge nRST ) begin : RXBAR_LRU
    if (!nRST)
        lru <= RXBAR_EP;

    // if the network is enabled & there's no stall, update the LRU state
    else if (net_en_tx && !net_stall_tx)
        lru <= next_lru;
end

// Determines if the incoming network packet is intended for the endpoint
logic net_dest_match;
assign net_dest_match = net_en_rx && (ENDPOINT_ADDR_START <= net_packet_rx.packet.addr) && (net_packet_rx.packet.addr <= ENDPOINT_ADDR_STOP);

always_comb begin : packetSelection
    selected = RXBAR_NONE;
    next_lru = lru;

    // Network has data for endpoint
    if (net_dest_match) begin
        selected = RXBAR_EP;
        next_lru = RXBAR_NET;
    end
    // Both endpoint and network could pass data to network
    else begin
        // If both want to send
        if (endpoint_en_rx && net_en_rx) begin
            selected = lru;
            next_lru = lru == RXBAR_EP ? RXBAR_NET : RXBAR_EP;
        end

        // If the requester is wanting to send & responder has nothing to send
        else if (endpoint_en_rx && !net_en_rx) begin
            selected = RXBAR_EP;
            next_lru = RXBAR_NET;
        end

        // If the responder is wanting to send & requester has nothing to send
        else if (!endpoint_en_rx && net_en_rx) begin
            selected = RXBAR_NET;
            next_lru = RXBAR_EP;
        end
    end
end

always_comb begin : packetRouting
    net_stall_rx = 1;
    net_en_tx = 0;
    net_packet_tx = '0;
    endpoint_stall_rx = 1;
    endpoint_en_tx = 0;
    endpoint_packet_tx = '0;

    // If xbar is receiving a packet from the network for the attached endpoint
    if (net_dest_match) begin
        net_en_tx = endpoint_en_rx;
        net_packet_tx = endpoint_packet_rx;
        endpoint_stall_rx = net_stall_tx;
        endpoint_en_tx = net_en_rx;
        endpoint_packet_tx = net_packet_rx;
        net_stall_rx = endpoint_stall_tx;
    end
    // Both endpoint and network may want to put packets in the FIFO,
    // so we must respect what got selected
    else if (selected == RXBAR_EP) begin
        net_en_tx = 1;
        net_packet_tx = endpoint_packet_rx;
        endpoint_stall_rx = net_stall_tx;
    end
    else if (selected == RXBAR_NET) begin
        net_en_tx = 1;
        net_packet_tx = net_packet_rx;
        net_stall_rx = net_stall_tx;
    end
end

endmodule