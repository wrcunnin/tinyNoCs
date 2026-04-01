/*

Author: William Cunningham
Date  : 03/20/2026

Description:
    Arbitrates between sending a network packet to the reponse or requester FIFO.
*/

import packet_pkg::*;

module endpoint_rx_arbiter (
    ////////////////////////////////////////////////////////
    // Requester receiving data
    // Indicates the requester FIFO is stalling to prevent writes
    input logic req_stall,

    // Marking a request as ready to write back in request FIFO
    output logic req_en,

    // Address to compare against when returning a response
    output addr_t req_return_addr,

    // Information to return to the request FIFO
    output packet_t req_packet,

    ////////////////////////////////////////////////////////
    // Responder receiving data
    // Indicates the responder FIFO is stalling to prevent writes
    input logic resp_stall,

    // Marking a response as ready to input in response FIFO
    output logic resp_en,

    // Address to insert when returning a response
    output addr_t resp_return_addr,

    // Information to insert in the response FIFO
    output packet_t resp_packet,

    ////////////////////////////////////////////////////////
    // Network incoming data
    // Indicates network is ready to put data in a buffer
    input logic net_en,

    // Stalls the network so it doesn't change its packet until FIFO is ready
    output logic net_stall,

    // Information to put in a buffer
    input net_packet_t net_packet
);

always_comb begin : packetSelection
    req_en = 0;
    req_packet = '0;
    req_return_addr = '0;
    resp_en = 0;
    resp_packet = '0;
    resp_return_addr = '0;
    net_stall = 1;

    if (net_en) begin
        // If a packet is a request, it goes to the response FIFO
        // - We are receiving data we requested/acknowledged
        if (net_packet.request) begin
            resp_en = 1;
            resp_packet = net_packet.packet;
            resp_return_addr = net_packet.start_addr;
            net_stall = resp_stall;
        end
        // If a packet is not a request, it goes to the request FIFO
        // - We are receiving data we requested/acknowledged
        else if (!net_packet.request) begin
            req_en = 1;
            req_packet = net_packet.packet;
            req_return_addr = net_packet.start_addr;
            net_stall = req_stall;
        end
        else
            assert(0);
    end
end

endmodule