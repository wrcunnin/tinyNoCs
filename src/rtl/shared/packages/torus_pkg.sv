/*

Author: William Cunningham
Date  : 11/08/2026

Description:
    Package for torus network defines
*/

package torus_pkg;

  import packet_pkg::*;

  ////////////////////////////////////////////////////////
  // Begin Torus Defines
  ////////////////////////////////////////////////////////
  `define CREATE_TORUS_XBARB_CTRL(direction) \
logic        ``direction``_torus_xbarb_in_ctrl_push_ready; \
logic        ``direction``_torus_xbarb_in_ctrl_push_valid; \
net_packet_t ``direction``_torus_xbarb_in_ctrl_push_data; \
logic        ``direction``_torus_xbarb_in_ctrl_north_pop_valid; \
logic        ``direction``_torus_xbarb_in_ctrl_south_pop_valid; \
logic        ``direction``_torus_xbarb_in_ctrl_east_pop_valid; \
logic        ``direction``_torus_xbarb_in_ctrl_west_pop_valid; \
logic        ``direction``_torus_xbarb_in_ctrl_torus_pop_valid; \
logic        ``direction``_torus_xbarb_in_ctrl_north_pop_ready; \
logic        ``direction``_torus_xbarb_in_ctrl_south_pop_ready; \
logic        ``direction``_torus_xbarb_in_ctrl_east_pop_ready; \
logic        ``direction``_torus_xbarb_in_ctrl_west_pop_ready; \
logic        ``direction``_torus_xbarb_in_ctrl_torus_pop_ready; \
torus_xbar_arbiter_in_ctrl ``direction``_torus_xbarb_in_ctrl ( \
    .strap_pos_x(strap_pos_x), \
    .strap_pos_y(strap_pos_y), \
    .strap_min_x(endpoint_id_t'(1'b1)), \
    .strap_min_y(endpoint_id_t'(1'b1)), \
    .strap_max_x(strap_max_x), \
    .strap_max_y(strap_max_y), \
    .strap_vertical_torus(strap_vertical_torus), \
    .strap_prefer_vertical(strap_prefer_vertical), \
    .push_ready(``direction``_torus_xbarb_in_ctrl_push_ready), \
    .push_valid(``direction``_torus_xbarb_in_ctrl_push_valid), \
    .push_data(``direction``_torus_xbarb_in_ctrl_push_data), \
    .north_pop_valid(``direction``_torus_xbarb_in_ctrl_north_pop_valid), \
    .south_pop_valid(``direction``_torus_xbarb_in_ctrl_south_pop_valid), \
    .east_pop_valid(``direction``_torus_xbarb_in_ctrl_east_pop_valid), \
    .west_pop_valid(``direction``_torus_xbarb_in_ctrl_west_pop_valid), \
    .torus_pop_valid(``direction``_torus_xbarb_in_ctrl_torus_pop_valid), \
    .north_pop_ready(``direction``_torus_xbarb_in_ctrl_north_pop_ready), \
    .south_pop_ready(``direction``_torus_xbarb_in_ctrl_south_pop_ready), \
    .east_pop_ready(``direction``_torus_xbarb_in_ctrl_east_pop_ready), \
    .west_pop_ready(``direction``_torus_xbarb_in_ctrl_west_pop_ready), \
    .torus_pop_ready(``direction``_torus_xbarb_in_ctrl_torus_pop_ready) \
); \
logic              ``direction``_torus_xbarb_out_ctrl_pop_ready; \
logic              ``direction``_torus_xbarb_out_ctrl_pop_valid; \
net_packet_t       ``direction``_torus_xbarb_out_ctrl_pop_data; \
logic        [3:0] ``direction``_torus_xbarb_out_ctrl_push_ready; \
logic        [3:0] ``direction``_torus_xbarb_out_ctrl_push_valid; \
net_packet_t [3:0] ``direction``_torus_xbarb_out_ctrl_push_data; \
torus_xbar_arbiter_out_ctrl ``direction``_torus_xbarb_out_ctrl ( \
    .clk(clk), \
    .nrst(nrst), \
    .pop_ready(``direction``_torus_xbarb_out_ctrl_pop_ready), \
    .pop_valid(``direction``_torus_xbarb_out_ctrl_pop_valid), \
    .pop_data(``direction``_torus_xbarb_out_ctrl_pop_data), \
    .push_ready(``direction``_torus_xbarb_out_ctrl_push_ready), \
    .push_valid(``direction``_torus_xbarb_out_ctrl_push_valid), \
    .push_data(``direction``_torus_xbarb_out_ctrl_push_data) \
);

  `define CONNECT_TORUS_XBARB_CTRL_IO(direction) \
assign ``direction``_torus_xbarb_out_ctrl_pop_ready = ``direction``_pop_ready; \
assign ``direction``_pop_valid = ``direction``_torus_xbarb_out_ctrl_pop_valid; \
assign ``direction``_pop_data = ``direction``_torus_xbarb_out_ctrl_pop_data; \
assign ``direction``_push_ready = ``direction``_torus_xbarb_in_ctrl_push_ready; \
assign ``direction``_torus_xbarb_in_ctrl_push_valid = ``direction``_push_valid; \
assign ``direction``_torus_xbarb_in_ctrl_push_data = ``direction``_push_data;

  `define CONNECT_TORUS_XBARB_CTRL_INTERNAL(direction, dir0, dir1, dir2, dir3) \
assign ``direction``_torus_xbarb_in_ctrl_``direction``_pop_ready = 0; \
assign ``direction``_torus_xbarb_in_ctrl_``dir0``_pop_ready = ``dir0``_torus_xbarb_out_ctrl_push_ready[3]; \
assign ``direction``_torus_xbarb_in_ctrl_``dir1``_pop_ready = ``dir1``_torus_xbarb_out_ctrl_push_ready[2]; \
assign ``direction``_torus_xbarb_in_ctrl_``dir2``_pop_ready = ``dir2``_torus_xbarb_out_ctrl_push_ready[1]; \
assign ``direction``_torus_xbarb_in_ctrl_``dir3``_pop_ready = ``dir3``_torus_xbarb_out_ctrl_push_ready[0]; \
assign ``direction``_torus_xbarb_out_ctrl_push_valid[0] = ``dir0``_torus_xbarb_in_ctrl_``direction``_pop_valid; \
assign ``direction``_torus_xbarb_out_ctrl_push_valid[1] = ``dir1``_torus_xbarb_in_ctrl_``direction``_pop_valid; \
assign ``direction``_torus_xbarb_out_ctrl_push_valid[2] = ``dir2``_torus_xbarb_in_ctrl_``direction``_pop_valid; \
assign ``direction``_torus_xbarb_out_ctrl_push_valid[3] = ``dir3``_torus_xbarb_in_ctrl_``direction``_pop_valid; \
assign ``direction``_torus_xbarb_out_ctrl_push_data[0] = ``dir0``_push_data; \
assign ``direction``_torus_xbarb_out_ctrl_push_data[1] = ``dir1``_push_data; \
assign ``direction``_torus_xbarb_out_ctrl_push_data[2] = ``dir2``_push_data; \
assign ``direction``_torus_xbarb_out_ctrl_push_data[3] = ``dir3``_push_data;

  `define CONNECT_TORUS_XBAR_INTERNALS(direction) \
assign ``direction``_buffer_rx_pop_ready = torus_xbarb_``direction``_push_ready; \
assign torus_xbarb_``direction``_push_valid = ``direction``_buffer_rx_pop_valid; \
assign torus_xbarb_``direction``_push_data = ``direction``_buffer_rx_pop_data; \
assign ``direction``_push_ready = ``direction``_buffer_rx_push_ready; \
assign ``direction``_buffer_rx_push_data = ``direction``_push_data; \
assign ``direction``_buffer_rx_push_valid = ``direction``_push_valid; \
assign torus_xbarb_``direction``_pop_ready = ``direction``_pop_ready; \
assign ``direction``_pop_valid = torus_xbarb_``direction``_pop_valid; \
assign ``direction``_pop_data = torus_xbarb_``direction``_pop_data;


  `define CREATE_TORUS_XBAR(xid, yid, max_x, max_y, prefer_vertical, vertical_torus) \
endpoint_id_t torus_xbar_``xid``_``yid``_strap_pos_x; \
endpoint_id_t torus_xbar_``xid``_``yid``_strap_pos_y; \
endpoint_id_t torus_xbar_``xid``_``yid``_strap_max_x; \
endpoint_id_t torus_xbar_``xid``_``yid``_strap_max_y; \
logic         torus_xbar_``xid``_``yid``_strap_vertical_torus; \
logic         torus_xbar_``xid``_``yid``_strap_prefer_vertical; \
logic         torus_xbar_``xid``_``yid``_north_pop_ready; \
logic         torus_xbar_``xid``_``yid``_north_pop_valid; \
net_packet_t  torus_xbar_``xid``_``yid``_north_pop_data; \
logic         torus_xbar_``xid``_``yid``_north_push_ready; \
logic         torus_xbar_``xid``_``yid``_north_push_valid; \
net_packet_t  torus_xbar_``xid``_``yid``_north_push_data; \
logic         torus_xbar_``xid``_``yid``_south_pop_ready; \
logic         torus_xbar_``xid``_``yid``_south_pop_valid; \
net_packet_t  torus_xbar_``xid``_``yid``_south_pop_data; \
logic         torus_xbar_``xid``_``yid``_south_push_ready; \
logic         torus_xbar_``xid``_``yid``_south_push_valid; \
net_packet_t  torus_xbar_``xid``_``yid``_south_push_data; \
logic         torus_xbar_``xid``_``yid``_east_pop_ready; \
logic         torus_xbar_``xid``_``yid``_east_pop_valid; \
net_packet_t  torus_xbar_``xid``_``yid``_east_pop_data; \
logic         torus_xbar_``xid``_``yid``_east_push_ready; \
logic         torus_xbar_``xid``_``yid``_east_push_valid; \
net_packet_t  torus_xbar_``xid``_``yid``_east_push_data; \
logic         torus_xbar_``xid``_``yid``_west_pop_ready; \
logic         torus_xbar_``xid``_``yid``_west_pop_valid; \
net_packet_t  torus_xbar_``xid``_``yid``_west_pop_data; \
logic         torus_xbar_``xid``_``yid``_west_push_ready; \
logic         torus_xbar_``xid``_``yid``_west_push_valid; \
net_packet_t  torus_xbar_``xid``_``yid``_west_push_data; \
logic         torus_xbar_``xid``_``yid``_torus_pop_ready; \
logic         torus_xbar_``xid``_``yid``_torus_pop_valid; \
net_packet_t  torus_xbar_``xid``_``yid``_torus_pop_data; \
logic         torus_xbar_``xid``_``yid``_torus_push_ready; \
logic         torus_xbar_``xid``_``yid``_torus_push_valid; \
net_packet_t  torus_xbar_``xid``_``yid``_torus_push_data; \
assign torus_xbar_``xid``_``yid``_strap_pos_x = endpoint_id_t'(xid); \
assign torus_xbar_``xid``_``yid``_strap_pos_y = endpoint_id_t'(yid); \
assign torus_xbar_``xid``_``yid``_strap_max_x = endpoint_id_t'(max_x); \
assign torus_xbar_``xid``_``yid``_strap_max_y = endpoint_id_t'(max_y); \
assign torus_xbar_``xid``_``yid``_strap_vertical_torus = vertical_torus; \
assign torus_xbar_``xid``_``yid``_strap_prefer_vertical = prefer_vertical; \
torus_xbar #( \
    .BufferRxDepth(BufferRxDepth) \
) torus_xbar_``xid``_``yid`` ( \
    .clk(clk), \
    .nrst(nrst), \
    .strap_pos_x(torus_xbar_``xid``_``yid``_strap_pos_x), \
    .strap_pos_y(torus_xbar_``xid``_``yid``_strap_pos_y), \
    .strap_max_x(torus_xbar_``xid``_``yid``_strap_max_x), \
    .strap_max_y(torus_xbar_``xid``_``yid``_strap_max_y), \
    .strap_vertical_torus(torus_xbar_``xid``_``yid``_strap_vertical_torus), \
    .strap_prefer_vertical(torus_xbar_``xid``_``yid``_strap_prefer_vertical), \
    .north_pop_ready(torus_xbar_``xid``_``yid``_north_pop_ready), \
    .north_pop_valid(torus_xbar_``xid``_``yid``_north_pop_valid), \
    .north_pop_data(torus_xbar_``xid``_``yid``_north_pop_data), \
    .north_push_ready(torus_xbar_``xid``_``yid``_north_push_ready), \
    .north_push_valid(torus_xbar_``xid``_``yid``_north_push_valid), \
    .north_push_data(torus_xbar_``xid``_``yid``_north_push_data), \
    .south_pop_ready(torus_xbar_``xid``_``yid``_south_pop_ready), \
    .south_pop_valid(torus_xbar_``xid``_``yid``_south_pop_valid), \
    .south_pop_data(torus_xbar_``xid``_``yid``_south_pop_data), \
    .south_push_ready(torus_xbar_``xid``_``yid``_south_push_ready), \
    .south_push_valid(torus_xbar_``xid``_``yid``_south_push_valid), \
    .south_push_data(torus_xbar_``xid``_``yid``_south_push_data), \
    .east_pop_ready(torus_xbar_``xid``_``yid``_east_pop_ready), \
    .east_pop_valid(torus_xbar_``xid``_``yid``_east_pop_valid), \
    .east_pop_data(torus_xbar_``xid``_``yid``_east_pop_data), \
    .east_push_ready(torus_xbar_``xid``_``yid``_east_push_ready), \
    .east_push_valid(torus_xbar_``xid``_``yid``_east_push_valid), \
    .east_push_data(torus_xbar_``xid``_``yid``_east_push_data), \
    .west_pop_ready(torus_xbar_``xid``_``yid``_west_pop_ready), \
    .west_pop_valid(torus_xbar_``xid``_``yid``_west_pop_valid), \
    .west_pop_data(torus_xbar_``xid``_``yid``_west_pop_data), \
    .west_push_ready(torus_xbar_``xid``_``yid``_west_push_ready), \
    .west_push_valid(torus_xbar_``xid``_``yid``_west_push_valid), \
    .west_push_data(torus_xbar_``xid``_``yid``_west_push_data), \
    .torus_pop_ready(torus_xbar_``xid``_``yid``_torus_pop_ready), \
    .torus_pop_valid(torus_xbar_``xid``_``yid``_torus_pop_valid), \
    .torus_pop_data(torus_xbar_``xid``_``yid``_torus_pop_data), \
    .torus_push_ready(torus_xbar_``xid``_``yid``_torus_push_ready), \
    .torus_push_valid(torus_xbar_``xid``_``yid``_torus_push_valid), \
    .torus_push_data(torus_xbar_``xid``_``yid``_torus_push_data) \
);

  `define CONNECT_TORUS_XBARS(xid, yid, net_name, in_direction,
                              out_direction) \
assign torus_xbar_``xid``_``yid``_``in_direction``_pop_ready = ``net_name``_``out_direction``_push_ready; \
assign torus_xbar_``xid``_``yid``_``in_direction``_push_valid = ``net_name``_``out_direction``_pop_valid; \
assign torus_xbar_``xid``_``yid``_``in_direction``_push_data = ``net_name``_``out_direction``_pop_data;

  `define CONNECT_TORUS_XBAR_TO_ENDPOINT(xid, yid, net_name, direction) \
assign torus_xbar_``xid``_``yid``_``direction``_pop_ready = ``net_name``_push_ready; \
assign torus_xbar_``xid``_``yid``_``direction``_push_valid = ``net_name``_pop_valid; \
assign torus_xbar_``xid``_``yid``_``direction``_push_data = ``net_name``_pop_data; \
assign ``net_name``_pop_ready = torus_xbar_``xid``_``yid``_``direction``_push_ready; \
assign ``net_name``_push_valid = torus_xbar_``xid``_``yid``_``direction``_pop_valid; \
assign ``net_name``_push_data = torus_xbar_``xid``_``yid``_``direction``_pop_data;

  ////////////////////////////////////////////////////////
  // End Torus Defines
  ////////////////////////////////////////////////////////

endpackage
