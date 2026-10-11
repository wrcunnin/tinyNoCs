/*

Author: William Cunningham
Date  : 11/08/2026

Description:
    Package for mesh network endpoints and defines
*/

import packet_pkg::*;

package mesh_pkg;

  // This is so fucking disgusting
  logic [0:NumEndpoints-1][0:1][EndpointIdBits-1:0] Mesh4x4Endpoints = {
    // {x_idx, y_idx}
    // West side, ID's 0 thru 3
    {
      4'd0, 4'd1
    },
    {4'd0, 4'd2},
    {4'd0, 4'd3},
    {4'd0, 4'd4},

    // South side, ID's 4 thru 7
    {
      4'd1, 4'd5
    },
    {4'd2, 4'd5},
    {4'd3, 4'd5},
    {4'd4, 4'd5},

    // East side,  ID's 8 through 11
    {
      4'd5, 4'd1
    },
    {4'd5, 4'd2},
    {4'd5, 4'd3},
    {4'd5, 4'd4},

    // North side, ID's 12 thru 15
    {
      4'd1, 4'd0
    },
    {4'd2, 4'd0},
    {4'd3, 4'd0},
    {4'd4, 4'd0}
  };

  logic [0:NumEndpoints-1][0:1][EndpointIdBits-1:0] Mesh5x3Endpoints = {
    // {x_idx, y_idx}
    // West side, ID's 0 thru 4
    {
      4'd0, 4'd1
    },
    {4'd0, 4'd2},
    {4'd0, 4'd3},
    {4'd0, 4'd4},
    {4'd0, 4'd5},

    // South side, ID's 5 thru 7
    {
      4'd1, 4'd6
    },
    {4'd2, 4'd6},
    {4'd3, 4'd6},

    // East side,  ID's 8 through 12
    {
      4'd4, 4'd1
    },
    {4'd4, 4'd2},
    {4'd4, 4'd3},
    {4'd4, 4'd4},
    {4'd4, 4'd5},

    // North side, ID's 13 thru 15
    {
      4'd1, 4'd0
    },
    {4'd2, 4'd0},
    {4'd3, 4'd0}
  };

  ////////////////////////////////////////////////////////
  // Mesh defines
  ////////////////////////////////////////////////////////
  `define CREATE_MESH_XBARB_CTRL(direction) \
logic        ``direction``_mesh_xbarb_in_ctrl_push_ready; \
logic        ``direction``_mesh_xbarb_in_ctrl_push_valid; \
net_packet_t ``direction``_mesh_xbarb_in_ctrl_push_data; \
logic        ``direction``_mesh_xbarb_in_ctrl_north_pop_valid; \
logic        ``direction``_mesh_xbarb_in_ctrl_south_pop_valid; \
logic        ``direction``_mesh_xbarb_in_ctrl_east_pop_valid; \
logic        ``direction``_mesh_xbarb_in_ctrl_west_pop_valid; \
logic        ``direction``_mesh_xbarb_in_ctrl_north_pop_ready; \
logic        ``direction``_mesh_xbarb_in_ctrl_south_pop_ready; \
logic        ``direction``_mesh_xbarb_in_ctrl_east_pop_ready; \
logic        ``direction``_mesh_xbarb_in_ctrl_west_pop_ready; \
mesh_xbar_arbiter_in_ctrl ``direction``_mesh_xbarb_in_ctrl ( \
    .strap_pos_x(strap_pos_x), \
    .strap_pos_y(strap_pos_y), \
    .strap_min_x(endpoint_id_t'(1'b1)), \
    .strap_min_y(endpoint_id_t'(1'b1)), \
    .strap_max_x(strap_max_x), \
    .strap_max_y(strap_max_y), \
    .strap_prefer_vertical(strap_prefer_vertical), \
    .push_ready(``direction``_mesh_xbarb_in_ctrl_push_ready), \
    .push_valid(``direction``_mesh_xbarb_in_ctrl_push_valid), \
    .push_data(``direction``_mesh_xbarb_in_ctrl_push_data), \
    .north_pop_valid(``direction``_mesh_xbarb_in_ctrl_north_pop_valid), \
    .south_pop_valid(``direction``_mesh_xbarb_in_ctrl_south_pop_valid), \
    .east_pop_valid(``direction``_mesh_xbarb_in_ctrl_east_pop_valid), \
    .west_pop_valid(``direction``_mesh_xbarb_in_ctrl_west_pop_valid), \
    .north_pop_ready(``direction``_mesh_xbarb_in_ctrl_north_pop_ready), \
    .south_pop_ready(``direction``_mesh_xbarb_in_ctrl_south_pop_ready), \
    .east_pop_ready(``direction``_mesh_xbarb_in_ctrl_east_pop_ready), \
    .west_pop_ready(``direction``_mesh_xbarb_in_ctrl_west_pop_ready) \
); \
logic              ``direction``_mesh_xbarb_out_ctrl_pop_ready; \
logic              ``direction``_mesh_xbarb_out_ctrl_pop_valid; \
net_packet_t       ``direction``_mesh_xbarb_out_ctrl_pop_data; \
logic        [2:0] ``direction``_mesh_xbarb_out_ctrl_push_ready; \
logic        [2:0] ``direction``_mesh_xbarb_out_ctrl_push_valid; \
net_packet_t [2:0] ``direction``_mesh_xbarb_out_ctrl_push_data; \
mesh_xbar_arbiter_out_ctrl ``direction``_mesh_xbarb_out_ctrl ( \
    .CLK(CLK), \
    .nRST(nRST), \
    .pop_ready(``direction``_mesh_xbarb_out_ctrl_pop_ready), \
    .pop_valid(``direction``_mesh_xbarb_out_ctrl_pop_valid), \
    .pop_data(``direction``_mesh_xbarb_out_ctrl_pop_data), \
    .push_ready(``direction``_mesh_xbarb_out_ctrl_push_ready), \
    .push_valid(``direction``_mesh_xbarb_out_ctrl_push_valid), \
    .push_data(``direction``_mesh_xbarb_out_ctrl_push_data) \
);

  `define CONNECT_MESH_XBARB_CTRL_IO(direction) \
assign ``direction``_mesh_xbarb_out_ctrl_pop_ready = ``direction``_pop_ready; \
assign ``direction``_pop_valid = ``direction``_mesh_xbarb_out_ctrl_pop_valid; \
assign ``direction``_pop_data = ``direction``_mesh_xbarb_out_ctrl_pop_data; \
assign ``direction``_push_ready = ``direction``_mesh_xbarb_in_ctrl_push_ready; \
assign ``direction``_mesh_xbarb_in_ctrl_push_valid = ``direction``_push_valid; \
assign ``direction``_mesh_xbarb_in_ctrl_push_data = ``direction``_push_data;

  `define CONNECT_MESH_XBARB_CTRL_INTERNAL(direction, dir0, dir1, dir2) \
assign ``direction``_mesh_xbarb_in_ctrl_``direction``_pop_ready = 0; \
assign ``direction``_mesh_xbarb_in_ctrl_``dir0``_pop_ready  = ``dir0``_mesh_xbarb_out_ctrl_push_ready[2]; \
assign ``direction``_mesh_xbarb_in_ctrl_``dir1``_pop_ready = ``dir1``_mesh_xbarb_out_ctrl_push_ready[1]; \
assign ``direction``_mesh_xbarb_in_ctrl_``dir2``_pop_ready  = ``dir2``_mesh_xbarb_out_ctrl_push_ready[0]; \
assign ``direction``_mesh_xbarb_out_ctrl_push_valid[0] = ``dir0``_mesh_xbarb_in_ctrl_``direction``_pop_valid; \
assign ``direction``_mesh_xbarb_out_ctrl_push_valid[1] = ``dir1``_mesh_xbarb_in_ctrl_``direction``_pop_valid; \
assign ``direction``_mesh_xbarb_out_ctrl_push_valid[2] = ``dir2``_mesh_xbarb_in_ctrl_``direction``_pop_valid; \
assign ``direction``_mesh_xbarb_out_ctrl_push_data[0] = ``dir0``_push_data; \
assign ``direction``_mesh_xbarb_out_ctrl_push_data[1] = ``dir1``_push_data; \
assign ``direction``_mesh_xbarb_out_ctrl_push_data[2] = ``dir2``_push_data;

  `define CREATE_MESH_XBAR_IO(direction) \
    input logic ``direction``_pop_ready, \
    output logic ``direction``_pop_valid, \
    output net_packet_t ``direction``_pop_data, \
    output logic ``direction``_push_ready, \
    input logic ``direction``_push_valid, \
    input net_packet_t ``direction``_push_data

  `define CONNECT_MESH_XBAR_INTERNALS(direction) \
assign ``direction``_buffer_rx_pop_ready = mesh_xbarb_``direction``_push_ready; \
assign mesh_xbarb_``direction``_push_valid = ``direction``_buffer_rx_pop_valid; \
assign mesh_xbarb_``direction``_push_data = ``direction``_buffer_rx_pop_data; \
assign ``direction``_push_ready = ``direction``_buffer_rx_push_ready; \
assign ``direction``_buffer_rx_push_data = ``direction``_push_data; \
assign ``direction``_buffer_rx_push_valid = ``direction``_push_valid; \
assign mesh_xbarb_``direction``_pop_ready = ``direction``_pop_ready; \
assign ``direction``_pop_valid = mesh_xbarb_``direction``_pop_valid; \
assign ``direction``_pop_data = mesh_xbarb_``direction``_pop_data;

  `define CREATE_MESH_XBAR(xid, yid, max_x, max_y, prefer_vertical) \
endpoint_id_t mesh_xbar_``xid``_``yid``_strap_pos_x; \
endpoint_id_t mesh_xbar_``xid``_``yid``_strap_pos_y; \
endpoint_id_t mesh_xbar_``xid``_``yid``_strap_max_x; \
endpoint_id_t mesh_xbar_``xid``_``yid``_strap_max_y; \
logic         mesh_xbar_``xid``_``yid``_strap_prefer_vertical; \
logic         mesh_xbar_``xid``_``yid``_north_pop_ready; \
logic         mesh_xbar_``xid``_``yid``_north_pop_valid; \
net_packet_t  mesh_xbar_``xid``_``yid``_north_pop_data; \
logic         mesh_xbar_``xid``_``yid``_north_push_ready; \
logic         mesh_xbar_``xid``_``yid``_north_push_valid; \
net_packet_t  mesh_xbar_``xid``_``yid``_north_push_data; \
logic         mesh_xbar_``xid``_``yid``_south_pop_ready; \
logic         mesh_xbar_``xid``_``yid``_south_pop_valid; \
net_packet_t  mesh_xbar_``xid``_``yid``_south_pop_data; \
logic         mesh_xbar_``xid``_``yid``_south_push_ready; \
logic         mesh_xbar_``xid``_``yid``_south_push_valid; \
net_packet_t  mesh_xbar_``xid``_``yid``_south_push_data; \
logic         mesh_xbar_``xid``_``yid``_east_pop_ready; \
logic         mesh_xbar_``xid``_``yid``_east_pop_valid; \
net_packet_t  mesh_xbar_``xid``_``yid``_east_pop_data; \
logic         mesh_xbar_``xid``_``yid``_east_push_ready; \
logic         mesh_xbar_``xid``_``yid``_east_push_valid; \
net_packet_t  mesh_xbar_``xid``_``yid``_east_push_data; \
logic         mesh_xbar_``xid``_``yid``_west_pop_ready; \
logic         mesh_xbar_``xid``_``yid``_west_pop_valid; \
net_packet_t  mesh_xbar_``xid``_``yid``_west_pop_data; \
logic         mesh_xbar_``xid``_``yid``_west_push_ready; \
logic         mesh_xbar_``xid``_``yid``_west_push_valid; \
net_packet_t  mesh_xbar_``xid``_``yid``_west_push_data; \
assign mesh_xbar_``xid``_``yid``_strap_pos_x = endpoint_id_t'(xid); \
assign mesh_xbar_``xid``_``yid``_strap_pos_y = endpoint_id_t'(yid); \
assign mesh_xbar_``xid``_``yid``_strap_max_x = endpoint_id_t'(max_x); \
assign mesh_xbar_``xid``_``yid``_strap_max_y = endpoint_id_t'(max_y); \
assign mesh_xbar_``xid``_``yid``_strap_prefer_vertical = 1'b1; \
mesh_xbar #( \
    .BufferRxDepth(BufferRxDepth) \
) mesh_xbar_``xid``_``yid`` ( \
    .CLK(CLK), \
    .nRST(nRST), \
    .strap_pos_x(mesh_xbar_``xid``_``yid``_strap_pos_x), \
    .strap_pos_y(mesh_xbar_``xid``_``yid``_strap_pos_y), \
    .strap_max_x(mesh_xbar_``xid``_``yid``_strap_max_x), \
    .strap_max_y(mesh_xbar_``xid``_``yid``_strap_max_y), \
    .strap_prefer_vertical(mesh_xbar_``xid``_``yid``_strap_prefer_vertical), \
    .north_pop_ready(mesh_xbar_``xid``_``yid``_north_pop_ready), \
    .north_pop_valid(mesh_xbar_``xid``_``yid``_north_pop_valid), \
    .north_pop_data(mesh_xbar_``xid``_``yid``_north_pop_data), \
    .north_push_ready(mesh_xbar_``xid``_``yid``_north_push_ready), \
    .north_push_valid(mesh_xbar_``xid``_``yid``_north_push_valid), \
    .north_push_data(mesh_xbar_``xid``_``yid``_north_push_data), \
    .south_pop_ready(mesh_xbar_``xid``_``yid``_south_pop_ready), \
    .south_pop_valid(mesh_xbar_``xid``_``yid``_south_pop_valid), \
    .south_pop_data(mesh_xbar_``xid``_``yid``_south_pop_data), \
    .south_push_ready(mesh_xbar_``xid``_``yid``_south_push_ready), \
    .south_push_valid(mesh_xbar_``xid``_``yid``_south_push_valid), \
    .south_push_data(mesh_xbar_``xid``_``yid``_south_push_data), \
    .east_pop_ready(mesh_xbar_``xid``_``yid``_east_pop_ready), \
    .east_pop_valid(mesh_xbar_``xid``_``yid``_east_pop_valid), \
    .east_pop_data(mesh_xbar_``xid``_``yid``_east_pop_data), \
    .east_push_ready(mesh_xbar_``xid``_``yid``_east_push_ready), \
    .east_push_valid(mesh_xbar_``xid``_``yid``_east_push_valid), \
    .east_push_data(mesh_xbar_``xid``_``yid``_east_push_data), \
    .west_pop_ready(mesh_xbar_``xid``_``yid``_west_pop_ready), \
    .west_pop_valid(mesh_xbar_``xid``_``yid``_west_pop_valid), \
    .west_pop_data(mesh_xbar_``xid``_``yid``_west_pop_data), \
    .west_push_ready(mesh_xbar_``xid``_``yid``_west_push_ready), \
    .west_push_valid(mesh_xbar_``xid``_``yid``_west_push_valid), \
    .west_push_data(mesh_xbar_``xid``_``yid``_west_push_data) \
);

  `define CREATE_ENDPOINT_MESH(id, xid, yid) \
endpoint_id_t endpoint_``id``_strap_endpoint_id_x; \
endpoint_id_t endpoint_``id``_strap_endpoint_id_y; \
logic         endpoint_``id``_req_full; \
logic         endpoint_``id``_req_empty; \
logic         endpoint_``id``_req_push_valid; \
packet_t      endpoint_``id``_req_push_data; \
logic         endpoint_``id``_req_push_ready; \
logic         endpoint_``id``_req_pop_ready; \
logic         endpoint_``id``_req_pop_valid; \
packet_t      endpoint_``id``_req_pop_data; \
logic         endpoint_``id``_resp_full; \
logic         endpoint_``id``_resp_empty; \
logic         endpoint_``id``_resp_pop_ready; \
logic         endpoint_``id``_resp_pop_valid; \
packet_t      endpoint_``id``_resp_pop_data; \
logic         endpoint_``id``_resp_push_valid; \
packet_t      endpoint_``id``_resp_push_data; \
logic         endpoint_``id``_resp_push_ready; \
logic         endpoint_``id``_net_pop_ready; \
logic         endpoint_``id``_net_pop_valid; \
net_packet_t  endpoint_``id``_net_pop_data; \
logic         endpoint_``id``_net_push_ready; \
logic         endpoint_``id``_net_push_valid; \
net_packet_t  endpoint_``id``_net_push_data; \
assign endpoint_``id``_strap_endpoint_id_x = endpoint_id_t'(xid); \
assign endpoint_``id``_strap_endpoint_id_y = endpoint_id_t'(yid); \
generate \
endpoint #( \
    .TxBufferDepth(TxBufferDepth), \
    .RxBufferDepth(RxBufferDepth), \
    .NetworkType(kMesh) \
) endpoint_``id`` ( \
    .CLK(CLK), \
    .nRST(nRST), \
    .strap_endpoint_id_x(endpoint_``id``_strap_endpoint_id_x), \
    .strap_endpoint_id_y(endpoint_``id``_strap_endpoint_id_y), \
    .req_full(endpoint_``id``_req_full), \
    .req_empty(endpoint_``id``_req_empty), \
    .req_push_valid(endpoint_``id``_req_push_valid), \
    .req_push_data(endpoint_``id``_req_push_data), \
    .req_push_ready(endpoint_``id``_req_push_ready), \
    .req_pop_ready(endpoint_``id``_req_pop_ready), \
    .req_pop_valid(endpoint_``id``_req_pop_valid), \
    .req_pop_data(endpoint_``id``_req_pop_data), \
    .resp_full(endpoint_``id``_resp_full), \
    .resp_empty(endpoint_``id``_resp_empty), \
    .resp_pop_ready(endpoint_``id``_resp_pop_ready), \
    .resp_pop_valid(endpoint_``id``_resp_pop_valid), \
    .resp_pop_data(endpoint_``id``_resp_pop_data), \
    .resp_push_valid(endpoint_``id``_resp_push_valid), \
    .resp_push_data(endpoint_``id``_resp_push_data), \
    .resp_push_ready(endpoint_``id``_resp_push_ready), \
    .net_pop_ready(endpoint_``id``_net_pop_ready), \
    .net_pop_valid(endpoint_``id``_net_pop_valid), \
    .net_pop_data(endpoint_``id``_net_pop_data), \
    .net_push_ready(endpoint_``id``_net_push_ready), \
    .net_push_valid(endpoint_``id``_net_push_valid), \
    .net_push_data(endpoint_``id``_net_push_data) \
); \
endgenerate \
assign req_full[id] = endpoint_``id``_req_full; \
assign req_empty[id] = endpoint_``id``_req_empty; \
assign req_push_ready[id] = endpoint_``id``_req_push_ready; \
assign req_pop_valid[id] = endpoint_``id``_req_pop_valid; \
assign req_pop_data[id] = endpoint_``id``_req_pop_data; \
assign resp_full[id] = endpoint_``id``_resp_full; \
assign resp_empty[id] = endpoint_``id``_resp_empty; \
assign resp_push_ready[id] = endpoint_``id``_resp_push_ready; \
assign resp_pop_data[id] = endpoint_``id``_resp_pop_data; \
assign resp_pop_valid[id] = endpoint_``id``_resp_pop_valid; \
assign endpoint_``id``_req_push_valid = req_push_valid[id]; \
assign endpoint_``id``_req_push_data = req_push_data[id]; \
assign endpoint_``id``_req_pop_ready = req_pop_ready[id]; \
assign endpoint_``id``_resp_pop_ready = resp_pop_ready[id]; \
assign endpoint_``id``_resp_push_valid = resp_push_valid[id]; \
assign endpoint_``id``_resp_push_data = resp_push_data[id];

  `define CONNECT_MESH_XBARS(xid, yid, net_name, in_direction,
                             out_direction) \
assign mesh_xbar_``xid``_``yid``_``in_direction``_pop_ready = ``net_name``_``out_direction``_push_ready; \
assign mesh_xbar_``xid``_``yid``_``in_direction``_push_valid = ``net_name``_``out_direction``_pop_valid; \
assign mesh_xbar_``xid``_``yid``_``in_direction``_push_data = ``net_name``_``out_direction``_pop_data;

  `define CONNECT_MESH_XBAR_TO_ENDPOINT(xid, yid, net_name, direction) \
assign mesh_xbar_``xid``_``yid``_``direction``_pop_ready = ``net_name``_push_ready; \
assign mesh_xbar_``xid``_``yid``_``direction``_push_valid = ``net_name``_pop_valid; \
assign mesh_xbar_``xid``_``yid``_``direction``_push_data = ``net_name``_pop_data; \
assign ``net_name``_pop_ready = mesh_xbar_``xid``_``yid``_``direction``_push_ready; \
assign ``net_name``_push_valid = mesh_xbar_``xid``_``yid``_``direction``_pop_valid; \
assign ``net_name``_push_data = mesh_xbar_``xid``_``yid``_``direction``_pop_data;
  ////////////////////////////////////////////////////////
  // End Mesh Defines
  ////////////////////////////////////////////////////////

endpackage
