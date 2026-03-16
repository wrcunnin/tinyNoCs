/*

Author: William Cunningham
Date  : 02/11/2026

Description:
    FIFO for routers. Endpoints produce/commit requests in-order, but the
    network can complete requests out of order.

*/

module fifo_router #(
    parameter int DEPTH = 8,
    parameter int ADDRESS_BITS = 32,
    parameter int PAYLOAD_BITS = 64,
    localparam int DEPTH_BITS = $clog2(DEPTH)
) (
    // Clock, async reset
    input logic CLK, nRST,

    // Indicates a request from the requester.
    // Requester either reads or writes to this address
    input logic req_ren, req_wen,

    // Requesting address
    input logic [ADDRESS_BITS-1:0] req_addr,

    // Payload for a request when writing
    input logic [PAYLOAD_BITS-1:0] req_payload,

    // Indicate an entry is ready to commit (assume requester takes 1 cycle)
    output logic req_comp,

    // Address of the completed request
    output logic [ADDRESS_BITS-1:0] req_addr_comp,

    // Payload for a request after reading
    output logic [PAYLOAD_BITS-1:0] req_payload_comp,

    // Indicating if the buffer is full and empty
    output logic fifo_router_full, fifo_router_empty,

    // Indicates a request is getting sent out to the network
    output logic net_en,

    // Indicating if a packet is writing to a location
    output logic net_req_wen,

    // Address of issued request
    output logic [ADDRESS_BITS-1:0] net_req_addr,

    // Payload of issued request
    output logic [PAYLOAD_BITS-1:0] net_req_payload,

    // ID in the buffer for the issued request
    output logic [DEPTH_BITS-1:0] net_req_id,

    // Indicates a request is complete and can commit in the buffer
    input logic net_en_comp,

    // Returning payload for the network request
    input logic [PAYLOAD_BITS-1:0] net_req_payload_comp,

    // ID in the buffer for the completing request
    input logic [DEPTH_BITS-1:0] net_req_id_comp,

    // Indicates the network cannot accept another request
    input logic net_stall
);

typedef struct packed {
    logic valid;
    logic wen;  // 1 for write, 0 for read
    logic [ADDRESS_BITS-1:0] addr;
    logic [PAYLOAD_BITS-1:0] wdata;
    logic [PAYLOAD_BITS-1:0] rdata;
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

// Signal for enabling a write to the FIFO
logic req_en;

// Only enable when there is a requesting read or write
assign req_en = req_ren || req_wen;

always_ff @( posedge CLK, negedge nRST ) begin : blockName
    if (!nRST) begin
        fifo_router_buffer <= '0;
        fifo_router_full   <= 0;
        fifo_router_empty  <= 1;

        req_pointer <= '0;
        net_pointer <= '0;
        req_comp_pointer <= '0;
    end
    else begin
        fifo_router_buffer <= next_fifo_router_buffer;
        fifo_router_full   <= next_fifo_router_full;
        fifo_router_empty  <= next_fifo_router_empty;

        req_pointer <= next_req_pointer;
        net_pointer <= next_net_pointer;
        req_comp_pointer <= next_req_comp_pointer;
    end
end

always_comb begin : entryUpdate
    next_req_pointer = req_pointer;
    next_req_comp_pointer = req_comp_pointer;
    next_net_pointer = net_pointer;
    next_fifo_router_buffer = fifo_router_buffer;

    net_en = '0;
    net_req_id = '0;
    net_req_wen = '0;
    net_req_addr = '0;
    net_req_payload = '0;

    req_comp = '0;
    req_addr_comp = '0;
    req_payload_comp = '0;

    // The requester is requesting and it can write to the FIFO
    if (!fifo_router_full && req_en) begin
        next_fifo_router_buffer[req_pointer].valid = 0;
        next_fifo_router_buffer[req_pointer].wen   = req_wen;
        next_fifo_router_buffer[req_pointer].addr  = req_addr;
        next_fifo_router_buffer[req_pointer].wdata = req_payload;
        next_fifo_router_buffer[req_pointer].rdata = 0;

        next_req_pointer = updatePointer(req_pointer);
    end

    // Issuing to the network
    if (!fifo_router_empty) begin
        net_en = 1;
        net_req_id = net_pointer;
        net_req_wen     = fifo_router_buffer[net_pointer].wen;
        net_req_addr    = fifo_router_buffer[net_pointer].addr;
        net_req_payload = fifo_router_buffer[net_pointer].wdata;

        // Only update the pointer when the network is not stalled
        if (!net_stall) next_net_pointer = updatePointer(net_pointer);
    end

    // Updating the buffer from the network
    if (net_en_comp) begin
        next_fifo_router_buffer[net_req_id_comp].rdata = net_req_payload_comp;
        next_fifo_router_buffer[net_req_id_comp].valid = 1;
    end

    // Commiting the request back to the requester
    // Requester MUST detect the completed data within a clock cycle
    if (fifo_router_buffer[req_comp_pointer].valid) begin
        req_comp = !fifo_router_empty;
        req_addr_comp = fifo_router_buffer[req_comp_pointer].addr;
        req_payload_comp = fifo_router_buffer[req_comp_pointer].rdata;
        next_req_comp_pointer = updatePointer(req_comp_pointer);
    end
end

always_comb begin : controlFullEmpty
    next_fifo_router_full = fifo_router_full;
    next_fifo_router_empty = fifo_router_empty;

    if (next_req_pointer == next_req_comp_pointer) begin
        // FIFO will be full if:
        // - requester makes a request
        // - request is not completed
        if (req_en && !req_comp) begin
            next_fifo_router_full = 1;
            next_fifo_router_empty = 0;
        end

        // FIFO will be empty if:
        // - requester does not make a request
        // - request is completed
        else if (!req_en && req_comp) begin
            next_fifo_router_full = 0;
            next_fifo_router_empty = 1;
        end

        // Otherwise, FIFO remains unchanged and there
        // was not a request created nor completed.
        else begin
            assert(!req_en);
            assert(!req_comp);
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