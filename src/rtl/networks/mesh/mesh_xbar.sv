module mesh_xbar #(
    parameter int unsigned BufferRxDepth
) (
    input logic CLK,
    nRST,

    ////////////////////////////////////////////////////////
    // Straps
    input endpoint_id_t strap_pos_x,
    input endpoint_id_t strap_pos_y,
    input endpoint_id_t strap_max_x,
    input endpoint_id_t strap_max_y,
    input logic         strap_prefer_vertical,

    ////////////////////////////////////////////////////////
    // North inputs/outputs
    `CREATE_MESH_XBAR_IO(north),

    ////////////////////////////////////////////////////////
    // South inputs/outputs
    `CREATE_MESH_XBAR_IO(south),

    ////////////////////////////////////////////////////////
    // East inputs/outputs
    `CREATE_MESH_XBAR_IO(west),

    ////////////////////////////////////////////////////////
    // West inputs/outputs
    `CREATE_MESH_XBAR_IO(east)
);

  /************************************************/
  /* north_buffer_rx                              */
  /************************************************/
  logic                     north_buffer_rx_push_valid;
  logic [NetPacketBits-1:0] north_buffer_rx_push_data;
  logic                     north_buffer_rx_push_ready;
  logic                     north_buffer_rx_pop_valid;
  logic [NetPacketBits-1:0] north_buffer_rx_pop_data;
  logic                     north_buffer_rx_pop_ready;
  fifo_basic #(
      .Depth(BufferRxDepth),
      .Width(NetPacketBits)
  ) north_buffer_rx (
      .CLK       (CLK),
      .nRST      (nRST),
      .push_valid(north_buffer_rx_push_valid),
      .push_data (north_buffer_rx_push_data),
      .push_ready(north_buffer_rx_push_ready),
      .pop_valid (north_buffer_rx_pop_valid),
      .pop_data  (north_buffer_rx_pop_data),
      .pop_ready (north_buffer_rx_pop_ready)
  );

  /************************************************/
  /* south_buffer_rx                              */
  /************************************************/
  logic                     south_buffer_rx_push_valid;
  logic [NetPacketBits-1:0] south_buffer_rx_push_data;
  logic                     south_buffer_rx_push_ready;
  logic                     south_buffer_rx_pop_valid;
  logic [NetPacketBits-1:0] south_buffer_rx_pop_data;
  logic                     south_buffer_rx_pop_ready;
  fifo_basic #(
      .Depth(BufferRxDepth),
      .Width(NetPacketBits)
  ) south_buffer_rx (
      .CLK       (CLK),
      .nRST      (nRST),
      .push_valid(south_buffer_rx_push_valid),
      .push_data (south_buffer_rx_push_data),
      .push_ready(south_buffer_rx_push_ready),
      .pop_valid (south_buffer_rx_pop_valid),
      .pop_data  (south_buffer_rx_pop_data),
      .pop_ready (south_buffer_rx_pop_ready)
  );

  /************************************************/
  /* east_buffer_rx                               */
  /************************************************/
  logic                     east_buffer_rx_push_valid;
  logic [NetPacketBits-1:0] east_buffer_rx_push_data;
  logic                     east_buffer_rx_push_ready;
  logic                     east_buffer_rx_pop_valid;
  logic [NetPacketBits-1:0] east_buffer_rx_pop_data;
  logic                     east_buffer_rx_pop_ready;
  fifo_basic #(
      .Depth(BufferRxDepth),
      .Width(NetPacketBits)
  ) east_buffer_rx (
      .CLK       (CLK),
      .nRST      (nRST),
      .push_valid(east_buffer_rx_push_valid),
      .push_data (east_buffer_rx_push_data),
      .push_ready(east_buffer_rx_push_ready),
      .pop_valid (east_buffer_rx_pop_valid),
      .pop_data  (east_buffer_rx_pop_data),
      .pop_ready (east_buffer_rx_pop_ready)
  );

  /************************************************/
  /* west_buffer_rx                               */
  /************************************************/
  logic                     west_buffer_rx_push_valid;
  logic [NetPacketBits-1:0] west_buffer_rx_push_data;
  logic                     west_buffer_rx_push_ready;
  logic                     west_buffer_rx_pop_valid;
  logic [NetPacketBits-1:0] west_buffer_rx_pop_data;
  logic                     west_buffer_rx_pop_ready;
  fifo_basic #(
      .Depth(BufferRxDepth),
      .Width(NetPacketBits)
  ) west_buffer_rx (
      .CLK       (CLK),
      .nRST      (nRST),
      .push_valid(west_buffer_rx_push_valid),
      .push_data (west_buffer_rx_push_data),
      .push_ready(west_buffer_rx_push_ready),
      .pop_valid (west_buffer_rx_pop_valid),
      .pop_data  (west_buffer_rx_pop_data),
      .pop_ready (west_buffer_rx_pop_ready)
  );

  /************************************************/
  /* mesh_xbarb                                   */
  /************************************************/
  logic        mesh_xbarb_north_pop_ready;
  logic        mesh_xbarb_north_pop_valid;
  net_packet_t mesh_xbarb_north_pop_data;
  logic        mesh_xbarb_north_push_ready;
  logic        mesh_xbarb_north_push_valid;
  net_packet_t mesh_xbarb_north_push_data;
  logic        mesh_xbarb_south_pop_ready;
  logic        mesh_xbarb_south_pop_valid;
  net_packet_t mesh_xbarb_south_pop_data;
  logic        mesh_xbarb_south_push_ready;
  logic        mesh_xbarb_south_push_valid;
  net_packet_t mesh_xbarb_south_push_data;
  logic        mesh_xbarb_east_pop_ready;
  logic        mesh_xbarb_east_pop_valid;
  net_packet_t mesh_xbarb_east_pop_data;
  logic        mesh_xbarb_east_push_ready;
  logic        mesh_xbarb_east_push_valid;
  net_packet_t mesh_xbarb_east_push_data;
  logic        mesh_xbarb_west_pop_ready;
  logic        mesh_xbarb_west_pop_valid;
  net_packet_t mesh_xbarb_west_pop_data;
  logic        mesh_xbarb_west_push_ready;
  logic        mesh_xbarb_west_push_valid;
  net_packet_t mesh_xbarb_west_push_data;
  mesh_xbar_arbiter mesh_xbarb (
      .CLK,
      .nRST,
      .strap_pos_x,
      .strap_pos_y,
      .strap_max_x,
      .strap_max_y,
      .strap_prefer_vertical,
      .north_pop_ready (mesh_xbarb_north_pop_ready),
      .north_pop_valid (mesh_xbarb_north_pop_valid),
      .north_pop_data  (mesh_xbarb_north_pop_data),
      .north_push_ready(mesh_xbarb_north_push_ready),
      .north_push_valid(mesh_xbarb_north_push_valid),
      .north_push_data (mesh_xbarb_north_push_data),
      .south_pop_ready (mesh_xbarb_south_pop_ready),
      .south_pop_valid (mesh_xbarb_south_pop_valid),
      .south_pop_data  (mesh_xbarb_south_pop_data),
      .south_push_ready(mesh_xbarb_south_push_ready),
      .south_push_valid(mesh_xbarb_south_push_valid),
      .south_push_data (mesh_xbarb_south_push_data),
      .east_pop_ready  (mesh_xbarb_east_pop_ready),
      .east_pop_valid  (mesh_xbarb_east_pop_valid),
      .east_pop_data   (mesh_xbarb_east_pop_data),
      .east_push_ready (mesh_xbarb_east_push_ready),
      .east_push_valid (mesh_xbarb_east_push_valid),
      .east_push_data  (mesh_xbarb_east_push_data),
      .west_pop_ready  (mesh_xbarb_west_pop_ready),
      .west_pop_valid  (mesh_xbarb_west_pop_valid),
      .west_pop_data   (mesh_xbarb_west_pop_data),
      .west_push_ready (mesh_xbarb_west_push_ready),
      .west_push_valid (mesh_xbarb_west_push_valid),
      .west_push_data  (mesh_xbarb_west_push_data)
  );

  `CONNECT_MESH_XBAR_INTERNALS(north);
  `CONNECT_MESH_XBAR_INTERNALS(west);
  `CONNECT_MESH_XBAR_INTERNALS(south);
  `CONNECT_MESH_XBAR_INTERNALS(east);

endmodule
