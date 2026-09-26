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

fifo_basic  #(
    .Depth(Depth),
    .Width(Width)
) fifo_basic_inst (
    .*
);

endmodule
