/*

Author: William Cunningham
Date  : 02/11/2026

Description:
    Reorder Buffer FIFO for endpoints. Endpoints produce/commit requests in-order, but the
    network can complete requests out of order.

*/

import packet_pkg::*;

module fifo_rob #(
    parameter int Depth = 8,
    localparam int DepthBits = $clog2(Depth)
) (
    // Clock, async reset
    input logic clk,
    input logic nrst,

    // Indicating if the buffer is full and empty
    output logic fifo_rob_full,
    output logic fifo_rob_empty,

    ////////////////////////////////////////////////////////
    // Requester sending data
    input logic     req_push_valid,
    input packet_t  req_push_data,
    output logic    req_push_ready,

    // Requester receiving data
    output logic    req_pop_valid,
    output packet_t req_pop_data,
    input logic     req_pop_ready,


    ////////////////////////////////////////////////////////
    // Network sending data
    output logic    net_pop_valid,
    output packet_t net_pop_data,
    input logic     net_pop_ready,

    // Network receiving data
    input logic     net_push_valid,
    input packet_t  net_push_data,
    output logic    net_push_ready
);

typedef struct packed {
    logic comp;
    logic sent;
    packet_t packet;
} fifo_rob_entry_t;

// FIFO buffer
fifo_rob_entry_t [Depth-1:0] fifo_rob_buffer, next_fifo_rob_buffer;

// Requester and Network pointers within buffer
// TODO: Is there any way for this to work without a 3rd pointer?
//       I'm not sure there is. If I end up muxing the return packets, then no.
//       We need to stall the issuing, but we can still commit entries.
logic [DepthBits-1:0] req_push_ptr, next_req_push_ptr;
logic [DepthBits-1:0] req_pop_ptr, next_req_pop_ptr;
logic [DepthBits-1:0] net_pop_ptr, next_net_pop_ptr;

logic next_fifo_rob_full, next_fifo_rob_empty;
logic req_push, req_pop, net_push, net_pop;

function automatic logic [DepthBits-1:0] updatePointer;
    input logic [DepthBits-1:0] pointer;

    // Depth is a power of 2
    if ($clog2(Depth) != $clog2(Depth-1))
        updatePointer = pointer + 1;

    // Depth is not a power of two, so we must do extra control
    else begin
        if (pointer == (Depth - 1))
            updatePointer = 0;
        else
            updatePointer = pointer + 1;
    end
endfunction

assign req_push = req_push_valid && req_push_ready;
assign req_pop  = req_pop_valid && req_pop_ready;
assign net_push = net_push_valid && net_push_ready;
assign net_pop  = net_pop_valid && net_pop_ready;

always_ff @( posedge clk, negedge nrst ) begin : fifoRouterFF
    if (!nrst) begin
        for (int i = 0; i < Depth; i++) begin
            fifo_rob_buffer[i].comp   <= 1'b0;
            fifo_rob_buffer[i].sent   <= 1'b1;
            fifo_rob_buffer[i].packet <= '0;
        end
        fifo_rob_full   <= 0;
        fifo_rob_empty  <= 1;
        req_push_ptr    <= '0;
        net_pop_ptr     <= '0;
        req_pop_ptr     <= '0;
    end
    else begin
        fifo_rob_buffer <= next_fifo_rob_buffer;
        fifo_rob_full   <= next_fifo_rob_full;
        fifo_rob_empty  <= next_fifo_rob_empty;
        req_push_ptr    <= next_req_push_ptr;
        net_pop_ptr     <= next_net_pop_ptr;
        req_pop_ptr     <= next_req_pop_ptr;
    end
end

always_comb begin : entryUpdate
    next_fifo_rob_buffer = fifo_rob_buffer;
    req_push_ready = ~fifo_rob_full;
    req_pop_valid = 0;
    req_pop_data = '0;
    net_pop_valid = '0;
    net_pop_data = '0;
    net_push_ready = '1;

    // The requester is requesting and it can write to the FIFO
    if (req_push) begin
        next_fifo_rob_buffer[req_push_ptr].comp = 0;
        next_fifo_rob_buffer[req_push_ptr].sent = 0;
        next_fifo_rob_buffer[req_push_ptr].packet = req_push_data;
    end

    // Updating the buffer from the network
    if (net_push) begin
        // TODO: is it okay not to check for !wen here? putting assertion here for sanity
        assert(
            !net_push_data.wen
            || fifo_rob_buffer[net_push_data.id].packet.payload == net_push_data.payload
        );
        next_fifo_rob_buffer[net_push_data.id].packet.payload = net_push_data.payload;
        next_fifo_rob_buffer[net_push_data.id].comp = 1;
    end

    // Issuing to the network
    if (!fifo_rob_empty && !fifo_rob_buffer[net_pop_ptr].sent) begin
        net_pop_valid = 1;
        net_pop_data = fifo_rob_buffer[net_pop_ptr].packet;
        net_pop_data.id = net_pop_ptr;
        next_fifo_rob_buffer[net_pop_ptr].sent = net_pop_ready;
    end

    // Commiting the request back to the requester
    // Requester MUST detect the completed data within a clock cycle
    if (!fifo_rob_empty && fifo_rob_buffer[req_pop_ptr].comp) begin
        // make sure that if comp is set, so should sent
        assert(fifo_rob_buffer[req_pop_ptr].sent);
        req_pop_valid = 1;
        req_pop_data = fifo_rob_buffer[req_pop_ptr].packet;
    end
end

always_comb begin : ptrUpdate
    next_req_push_ptr = req_push_ptr;
    next_req_pop_ptr = req_pop_ptr;
    next_net_pop_ptr = net_pop_ptr;

    if (req_push)
        next_req_push_ptr = updatePointer(req_push_ptr);

    if (net_pop)
        next_net_pop_ptr = updatePointer(net_pop_ptr);

    if (req_pop)
        next_req_pop_ptr = updatePointer(req_pop_ptr);
end

always_comb begin : controlFullEmpty
    next_fifo_rob_full = fifo_rob_full;
    next_fifo_rob_empty = fifo_rob_empty;

    if (next_req_push_ptr == next_req_pop_ptr) begin
        // FIFO will be full if:
        // - requester makes a request
        // - request is not completed
        if (req_push && !req_pop) begin
            next_fifo_rob_full = 1;
            next_fifo_rob_empty = 0;
        end

        // FIFO will be empty if:
        // - requester does not make a request
        // - request is completed
        else if (!req_push && req_pop) begin
            next_fifo_rob_full = 0;
            next_fifo_rob_empty = 1;
        end

        // Otherwise, FIFO remains unchanged and there
        // was not a request created nor completed.
        else begin
            assert(!req_push);
            assert(!req_pop);
        end
    end else begin
        if (req_push)
            next_fifo_rob_empty = 0;
        if (req_pop)
            next_fifo_rob_full = 0;
    end
end

`ifndef SYNTHESIS
logic [DepthBits:0] occupancy, next_occupancy;
always_ff @( posedge clk, negedge nrst ) begin
    if (!nrst)
        occupancy <= '0;
    else
        occupancy <= next_occupancy;
end
always_comb begin
    next_occupancy = occupancy;
    if (req_push_ready && req_push_valid)
        next_occupancy = next_occupancy + 1;

    if (req_pop_valid && req_pop_ready)
        next_occupancy = next_occupancy - 1;
end
`endif

endmodule
