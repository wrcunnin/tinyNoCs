/*

Author: William Cunningham
Date  : 11/08/2026

Description:
    Package for ring network defines
*/

import packet_pkg::*;

package ring_pkg;

  ////////////////////////////////////////////////////////
  // Ring defines
  ////////////////////////////////////////////////////////
  `define CREATE_ENDPOINT_RING_XBAR(id) \
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
assign endpoint_``id``_strap_endpoint_id_x = endpoint_id_t'(id); \
assign endpoint_``id``_strap_endpoint_id_y = endpoint_id_t'(0); \
endpoint #( \
    .TxBufferDepth(TxBufferDepth), \
    .RxBufferDepth(RxBufferDepth), \
    .NetworkType(kRing) \
) endpoint_``id`` ( \
    .clk(clk), \
    .nrst(nrst), \
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
\
logic        rxbar_``id``_net_push_ready; \
logic        rxbar_``id``_net_push_valid; \
net_packet_t rxbar_``id``_net_push_data; \
logic        rxbar_``id``_net_pop_ready; \
logic        rxbar_``id``_net_pop_valid; \
net_packet_t rxbar_``id``_net_pop_data; \
logic        rxbar_``id``_endpoint_push_ready; \
logic        rxbar_``id``_endpoint_push_valid; \
net_packet_t rxbar_``id``_endpoint_push_data; \
logic        rxbar_``id``_endpoint_pop_ready; \
logic        rxbar_``id``_endpoint_pop_valid; \
net_packet_t rxbar_``id``_endpoint_pop_data; \
ring_xbar #( \
    .NetBufferRxDepth(2*BufferRxDepth), \
    .EpBufferRxDepth(BufferRxDepth) \
) rxbar_``id`` ( \
    .clk(clk), \
    .nrst(nrst), \
    .strap_endpoint_id(endpoint_id_t'(id)), \
    .net_push_ready(rxbar_``id``_net_push_ready), \
    .net_push_valid(rxbar_``id``_net_push_valid), \
    .net_push_data(rxbar_``id``_net_push_data), \
    .net_pop_ready(rxbar_``id``_net_pop_ready), \
    .net_pop_valid(rxbar_``id``_net_pop_valid), \
    .net_pop_data(rxbar_``id``_net_pop_data), \
    .endpoint_push_ready(rxbar_``id``_endpoint_push_ready), \
    .endpoint_push_valid(rxbar_``id``_endpoint_push_valid), \
    .endpoint_push_data(rxbar_``id``_endpoint_push_data), \
    .endpoint_pop_ready(rxbar_``id``_endpoint_pop_ready), \
    .endpoint_pop_valid(rxbar_``id``_endpoint_pop_valid), \
    .endpoint_pop_data(rxbar_``id``_endpoint_pop_data) \
);

  `define CONNECT_RING_XBAR(id, rx_id, tx_id) \
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
assign endpoint_``id``_resp_push_data = resp_push_data[id]; \
assign endpoint_``id``_net_pop_ready = rxbar_``id``_endpoint_push_ready; \
assign endpoint_``id``_net_push_valid = rxbar_``id``_endpoint_pop_valid; \
assign endpoint_``id``_net_push_data = rxbar_``id``_endpoint_pop_data; \
assign rxbar_``id``_net_push_valid = rxbar_``rx_id``_net_pop_valid; \
assign rxbar_``id``_net_push_data = rxbar_``rx_id``_net_pop_data; \
assign rxbar_``id``_net_pop_ready = rxbar_``tx_id``_net_push_ready; \
assign rxbar_``id``_endpoint_push_valid = endpoint_``id``_net_pop_valid; \
assign rxbar_``id``_endpoint_push_data = endpoint_``id``_net_pop_data; \
assign rxbar_``id``_endpoint_pop_ready = endpoint_``id``_net_push_ready;
  ////////////////////////////////////////////////////////
  // End Ring Defines
  ////////////////////////////////////////////////////////

endpackage
