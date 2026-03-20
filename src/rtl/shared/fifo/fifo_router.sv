/*

Author: William Cunningham
Date  : 02/11/2026

Description:
    FIFO for routers. Endpoints produce/commit requests in-order, but the
    network can complete requests out of order.

*/

import packet_pkg::*;

module fifo_router #(
    parameter int DEPTH = 8,
    localparam int DEPTH_BITS = $clog2(DEPTH)
) (
    // Clock, async reset
    input logic CLK, nRST,

    // Indicating if the buffer is full and empty
    output logic fifo_router_full, fifo_router_empty,

    ////////////////////////////////////////////////////////
    // Requester sending data
    // Indicates a request from the requester.
    input logic req_en,

    // Requester's information to put in the FIFO
    input packet_t req_packet,

    ////////////////////////////////////////////////////////
    // Requester receiving data
    // Indicate an entry is ready to commit
    output logic req_comp,

    // Indicates if a requester requires the completion to stall
    input logic req_comp_stall,

    // Completed request information to hand off to requester
    output packet_t req_comp_packet,

    ////////////////////////////////////////////////////////
    // Network sending data
    // Indicates a request is getting sent out to the network
    output logic net_en,

    // Indicates the network cannot accept another request
    input logic net_stall,

    // Information to send out to the network from the FIFO
    output packet_t net_req_packet,

    ////////////////////////////////////////////////////////
    // Network receiving data
    // Indicates a request is complete and can commit in the buffer
    input logic net_en_comp,

    // Information received from the network to put back in the FIFO
    input packet_t net_comp_packet

);

typedef struct packed {
    logic valid;
    packet_t packet;
} fifo_router_entry_t;

// FIFO buffer
fifo_router_entry_t [DEPTH-1:0] fifo_router_buffer, next_fifo_router_buffer;

// Requester and Network pointers within buffer
// TODO: Is there any way for this to work without a 3rd pointer?
//       I'm not sure there is. If I end up muxing the return packets, then no.
//       We need to stall the issuing, but we can still commit entries.
logic [DEPTH_BITS-1:0] req_pointer, next_req_pointer;
logic [DEPTH_BITS-1:0] req_comp_pointer, next_req_comp_pointer;
logic [DEPTH_BITS-1:0] net_pointer, next_net_pointer;

logic next_fifo_router_full, next_fifo_router_empty;

always_ff @( posedge CLK, negedge nRST ) begin : fifoRouterFF
    if (!nRST) begin
        fifo_router_buffer <= '0;
        fifo_router_full   <= 0;
        fifo_router_empty  <= 1;
        req_pointer      <= '0;
        net_pointer      <= '0;
        req_comp_pointer <= '0;
    end
    else begin
        fifo_router_buffer <= next_fifo_router_buffer;
        fifo_router_full   <= next_fifo_router_full;
        fifo_router_empty  <= next_fifo_router_empty;
        req_pointer      <= next_req_pointer;
        net_pointer      <= next_net_pointer;
        req_comp_pointer <= next_req_comp_pointer;
    end
end

always_comb begin : entryUpdate
    next_req_pointer = req_pointer;
    next_req_comp_pointer = req_comp_pointer;
    next_net_pointer = net_pointer;
    next_fifo_router_buffer = fifo_router_buffer;

    net_en = '0;
    net_req_packet = '0;

    req_comp = 0;
    req_comp_packet = '0;

    // The requester is requesting and it can write to the FIFO
    if (!fifo_router_full && req_en) begin
        next_fifo_router_buffer[req_pointer].valid = 0;
        next_fifo_router_buffer[req_pointer].packet = req_packet;

        next_req_pointer = updatePointer(req_pointer);
    end

    // Issuing to the network
    if (!fifo_router_empty) begin
        net_en = 1;
        net_req_packet = fifo_router_buffer[net_pointer].packet;
        net_req_packet.id = net_pointer;

        // Only update the pointer when the network is not stalled
        if (!net_stall) next_net_pointer = updatePointer(net_pointer);
    end

    // Updating the buffer from the network
    if (net_en_comp) begin
        // TODO: is it okay not to check for !wen here? putting assertion here for sanity
        assert(!net_comp_packet.wen || fifo_router_buffer[net_comp_packet.id].packet.payload == net_comp_packet.payload)
        next_fifo_router_buffer[net_comp_packet.id].packet.payload = net_comp_packet.payload;
        next_fifo_router_buffer[net_comp_packet.id].valid = 1;
    end

    // Commiting the request back to the requester
    // Requester MUST detect the completed data within a clock cycle
    if (fifo_router_buffer[req_comp_pointer].valid) begin
        req_comp = !fifo_router_empty;
        req_comp_packet = fifo_router_buffer[req_comp_pointer].packet;

        if (!req_comp_stall) next_req_comp_pointer = updatePointer(req_comp_pointer);
    end
end

always_comb begin : controlFullEmpty
    next_fifo_router_full = fifo_router_full;
    next_fifo_router_empty = fifo_router_empty;

    if (next_req_pointer == next_req_comp_pointer) begin
        // FIFO will be full if:
        // - requester makes a request
        // - request is not completed
        if (req_en && !(req_comp && !req_comp_stall)) begin
            next_fifo_router_full = 1;
            next_fifo_router_empty = 0;
        end

        // FIFO will be empty if:
        // - requester does not make a request
        // - request is completed
        else if (!req_en && (req_comp && !req_comp_stall)) begin
            next_fifo_router_full = 0;
            next_fifo_router_empty = 1;
        end

        // Otherwise, FIFO remains unchanged and there
        // was not a request created nor completed.
        else begin
            assert(!req_en);
            assert(!(req_comp && !req_comp_stall));
        end
    end else begin
        if (req_en)
            next_fifo_router_empty = 0;
        if (req_comp)
            next_fifo_router_full = 0;
    end
end

function logic [DEPTH_BITS-1:0] updatePointer;
    input logic [DEPTH_BITS-1:0] pointer;

    // DEPTH is a power of 2
    if ($clog2(DEPTH) != $clog2(DEPTH-1))
        updatePointer = pointer + 1;

    // DEPTH is not a power of two, so we must do extra control
    else begin
        if (pointer == (DEPTH - 1))
            updatePointer = 0;
        else
            updatePointer = pointer + 1;
    end
endfunction

endmodule