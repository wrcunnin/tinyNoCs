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
    input logic              clk,
    input logic              nrst,

    // Push Interface
    input logic              push_valid,
    input logic [Width-1:0]  push_data,
    output logic             push_ready,

    // Pop Interface
    output logic             pop_valid,
    output logic [Width-1:0] pop_data,
    input logic              pop_ready
);

  // R/W pointers
  logic [DepthBits-1:0] pop_ptr, next_pop_ptr;
  logic [DepthBits-1:0] push_ptr, next_push_ptr;

  // FIFO buffer
  logic [Depth-1:0][Width-1:0] buffer, next_buffer;

  // push_ready/pop_valid next signals
  logic next_push_ready, next_pop_valid;

  function automatic logic [DepthBits-1:0] updatePointer;
    input logic [DepthBits-1:0] pointer;

    // Depth is a power of 2
    if ($clog2(Depth) != $clog2(Depth - 1)) updatePointer = pointer + 1;

    // Depth is not a power of two, so we must do extra control
    else begin
      if (pointer == (Depth - 1)) updatePointer = 0;
      else updatePointer = pointer + 1;
    end
  endfunction

  always_ff @(posedge clk, negedge nrst) begin : fifoBasicFF
    if (!nrst) begin
      buffer     <= '0;
      pop_ptr    <= '0;
      push_ptr   <= '0;
    // TODO(wrcunnin): make push_ready deassert when in reset, but assert when out. maybe when sync reset is added?
      push_ready <= '1;
      pop_valid  <= '0;
    end else begin
      buffer     <= next_buffer;
      pop_ptr    <= next_pop_ptr;
      push_ptr   <= next_push_ptr;
      push_ready <= next_push_ready;
      pop_valid  <= next_pop_valid;
    end
  end

  always_comb begin : entryUpdate
    next_buffer = buffer;
    next_pop_ptr = pop_ptr;
    next_push_ptr = push_ptr;
    pop_data = buffer[pop_ptr];

    // read the data from the buffer & update pop_ptr
    if (pop_ready && pop_valid) begin
      next_pop_ptr = updatePointer(pop_ptr);
    end

    // write the data to the buffer & update push_ptr
    if (push_valid && push_ready) begin
      next_buffer[push_ptr] = push_data;
      next_push_ptr = updatePointer(push_ptr);
    end
  end

  always_comb begin : controlpush_readypop_valid
    next_push_ready = push_ready;
    next_pop_valid = pop_valid;

    // if we're pushing valid data  we need assert pop_valid next cycle
    // and push_ready is 0 if ptr's are equal
    if (push_valid && push_ready) begin
      next_push_ready = next_pop_ptr != next_push_ptr;
      next_pop_valid = 1'b1;
    end
    // if pop interface consumes the data, we assert push_ready next cycle
    // and pop_valid to 0 if ptr's are equal
    else if (pop_ready && pop_valid) begin
      next_push_ready = 1'b1;
      next_pop_valid = next_pop_ptr != next_push_ptr;
    end
  end

`ifndef SYNTHESIS
  logic [DepthBits:0] occupancy, next_occupancy;
  always_ff @(posedge clk, negedge nrst) begin
    if (!nrst) occupancy <= '0;
    else occupancy <= next_occupancy;
  end
  always_comb begin
    next_occupancy = occupancy;
    if (push_valid && push_ready) next_occupancy = next_occupancy + 1;

    if (pop_ready && pop_valid) next_occupancy = next_occupancy - 1;
  end
`endif

endmodule
