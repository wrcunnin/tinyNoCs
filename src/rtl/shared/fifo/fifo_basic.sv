/*

Author: William Cunningham
Date  : 03/16/2026

Description:
    FIFO with basic capabilities. Producing and consuming are in order.

*/

module fifo_basic #(
    parameter int Depth = 8,
    parameter int Width = 32,
    localparam int DepthBits = $clog2(Depth)
) (
    // Clock, async reset
    input logic CLK,
    input logic nRST,

    // Read enable coming from the consumer
    input logic ren,

    // Write enable coming from the producer
    input logic wen,

    // Read data to the consumer
    output logic [Width-1:0] rdata,

    // Write data from the producer
    input logic [Width-1:0] wdata,

    // Full/enable signals to go to producer/consumer
    output logic full,
    output logic empty
);

  // R/W pointers
  logic [DepthBits-1:0] rptr, next_rptr;
  logic [DepthBits-1:0] wptr, next_wptr;

  // FIFO buffer
  logic [Depth-1:0][Width-1:0] buffer, next_buffer;

  // Full/empty next signals
  logic next_full, next_empty;

  always_ff @(posedge CLK, negedge nRST) begin : fifoBasicFF
    if (!nRST) begin
      buffer <= '0;
      rptr   <= '0;
      wptr   <= '0;
      full   <= '0;
      empty  <= '1;
    end else begin
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
    rdata = buffer[rptr];

    // read the data from the buffer & update rptr
    if (ren && !empty) begin
      next_rptr = updatePointer(rptr);
    end

    // write the data to the buffer & update wptr
    if (wen && !full) begin
      next_buffer[wptr] = wdata;
      next_wptr = updatePointer(wptr);
    end
  end

  always_comb begin : controlFullEmpty
    next_full  = full;
    next_empty = empty;

    // if we're writing to the buffer & its not full, we need 
    // to assert empty is 0 and full is 1 if ptr's are equal
    if (wen && !full) begin
      next_full  = next_rptr == next_wptr;
      next_empty = 0;
    end  // if we're read from the buffer & its not empty, we need 
         // to assert full is 0 and empty is 1 if ptr's are equal
    else if (ren && !empty) begin
      next_full  = 0;
      next_empty = next_rptr == next_wptr;
    end
  end

`ifndef SYNTHESIS
  logic [DepthBits:0] occupancy, next_occupancy;
  always_ff @(posedge CLK, negedge nRST) begin
    if (!nRST) occupancy <= '0;
    else occupancy <= next_occupancy;
  end
  always_comb begin
    next_occupancy = occupancy;
    if (wen && !full) next_occupancy = next_occupancy + 1;

    if (ren && !empty) next_occupancy = next_occupancy - 1;
  end
`endif

  function logic [DepthBits-1:0] updatePointer;
    input logic [DepthBits-1:0] pointer;

    // Depth is a power of 2
    if ($clog2(Depth) != $clog2(Depth - 1)) updatePointer = pointer + 1;

    // Depth is not a power of two, so we must do extra control
    else begin
      if (pointer == (Depth - 1)) updatePointer = 0;
      else updatePointer = pointer + 1;
    end
  endfunction

endmodule
