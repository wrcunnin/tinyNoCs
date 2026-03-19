/*

Author: William Cunningham
Date  : 03/16/2026

Description:
    FIFO with basic capabilities. Producing and consuming are in order.

*/

module fifo_basic #(
    parameter int DEPTH = 8,
    parameter int DATA_WIDTH = 32,
    localparam int DEPTH_BITS = $clog2(DEPTH)
) (
    // Clock, async reset
    input logic CLK, nRST,

    // Read enable coming from the consumer
    input logic ren,

    // Write enable coming from the producer
    input logic wen,

    // Read data to the consumer
    output logic [DATA_WIDTH-1:0] rdata,

    // Write data from the producer
    input logic [DATA_WIDTH-1:0] wdata,

    // Full/enable signals to go to producer/consumer
    output logic full, empty
);

// R/W pointers
logic [DEPTH_BITS-1:0] rptr, next_rptr;
logic [DEPTH_BITS-1:0] wptr, next_wptr;

// FIFO buffer
logic [DEPTH-1:0] [DATA_WIDTH-1:0] buffer, next_buffer;

// Full/empty next signals
logic next_full, next_empty;

always_ff @( posedge CLK, negedge nRST ) begin : fifoBasicFF
    if (!nRST) begin
        buffer <= '0;
        rptr   <= '0;
        wptr   <= '0;
        full   <= '0;
        empty  <= '1;
    end
    else begin
        buffer <= next_buffer;
        rptr   <= next_rptr;
        wptr   <= next_wptr;
        full   <= next_full;
        empty  <= next_empty;
    end
end

always_comb begin : entryUpdate
    next_buffer = buffer;
    next_rptr = rptr;
    next_wptr = wptr;
    rdata = 0;

    // read the data from the buffer & update rptr
    if (ren && !empty) begin
        rdata = buffer[rptr];
        next_rptr = updatePointer(rptr);
    end

    // write the data to the buffer & update wptr
    if (wen && !full) begin
        next_buffer[wptr] = wdata;
        next_wptr = updatePointer(wptr);
    end
end

always_comb begin : controlFullEmpty
    next_full = full;
    next_empty = empty;

    // if we're writing to the buffer & its not full, we need 
    // to assert empty is 0 and full is 1 if ptr's are equal
    if (wen && !full) begin
        next_full = next_rptr == next_wptr;
        next_empty = 0;
    end

    // if we're read from the buffer & its not empty, we need 
    // to assert full is 0 and empty is 1 if ptr's are equal
    else if (ren && !empty) begin
        next_full = 0;
        next_empty = next_rptr == next_wptr;
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