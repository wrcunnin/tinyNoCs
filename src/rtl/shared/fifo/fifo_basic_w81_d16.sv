// 81b total
// - 1b valid
// - 8b src_id
// - 8b dst_id
// - 64b payload
module fifo_basic_w81_d16 #(
    localparam int Depth = 16,
    localparam int Width = 81,
    localparam int DepthBits = $clog2(Depth)
) (
    // Clock, async reset
    input logic clk,
    input logic nrst,

    // Push Interface
    input  logic             push_valid,
    input  logic [Width-1:0] push_data,
    output logic             push_ready,

    // Pop Interface
    output logic             pop_valid,
    output logic [Width-1:0] pop_data,
    input  logic             pop_ready
);

  fifo_basic #(
      .Depth(Depth),
      .Width(Width)
  ) fifo_basic_inst (
      .*
  );

endmodule
