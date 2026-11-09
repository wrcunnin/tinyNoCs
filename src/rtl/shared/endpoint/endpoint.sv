/*

Author: William Cunningham
Date  : 03/16/2026

Description:
    General purpose, customizable endpoint for networks.
    - endpoint_tx_buffer
        ~ stores requests to network
    - endpoint_rx_buffer
        ~ stores requests from network
    - return_id_buffer
        ~ stores return addresses for active requests from the network
    - rx_arbiter
        ~ manages which buffer a packet from the network goes to
    - tx_arbiter
        ~ manages which buffer to select a packet from to send to the network

*/

import packet_pkg::*;
import ring_pkg::*;
import mesh_pkg::*;

module endpoint #(
    parameter int TxBufferDepth = 8,
    parameter int RxBufferDepth = 8,
    parameter network_type_t NetworkType = kRing
) (
    // Clock, async reset
    input logic clk,
    input logic nrst,

    // Straps
    input endpoint_id_t strap_endpoint_id_x,
    input endpoint_id_t strap_endpoint_id_y,

    ////////////////////////////////////////////////////////
    // Requester sending data
    input logic    req_push_valid,
    input packet_t req_push_data,
    output logic   req_push_ready,

    // Requester receiving data
    output logic    req_pop_valid,
    output packet_t req_pop_data,
    input  logic    req_pop_ready,

    output logic req_full,
    output logic req_empty,

    ////////////////////////////////////////////////////////
    // Responder sending data
    input logic    resp_push_valid,
    input packet_t resp_push_data,
    output logic   resp_push_ready,

    // Responder receiving data
    output logic    resp_pop_valid,
    output packet_t resp_pop_data,
    input  logic    resp_pop_ready,

    output logic resp_full,
    output logic resp_empty,

    ////////////////////////////////////////////////////////
    // Network sending data
    output logic        net_pop_valid,
    output net_packet_t net_pop_data,
    input  logic        net_pop_ready,

    // Network receiving data
    input  logic        net_push_valid,
    input  net_packet_t net_push_data,
    output logic        net_push_ready
);


  /************************************************/
  /* endpoint_tx_buffer                           */
  /************************************************/
  logic    endpoint_tx_buffer_fifo_rob_full;
  logic    endpoint_tx_buffer_fifo_rob_empty;
  logic    endpoint_tx_buffer_req_push_valid;
  packet_t endpoint_tx_buffer_req_push_data;
  logic    endpoint_tx_buffer_req_push_ready;
  logic    endpoint_tx_buffer_req_pop_valid;
  logic    endpoint_tx_buffer_req_pop_ready;
  packet_t endpoint_tx_buffer_req_pop_data;
  logic    endpoint_tx_buffer_net_pop_valid;
  logic    endpoint_tx_buffer_net_pop_ready;
  packet_t endpoint_tx_buffer_net_pop_data;
  logic    endpoint_tx_buffer_net_push_valid;
  packet_t endpoint_tx_buffer_net_push_data;
  logic    endpoint_tx_buffer_net_push_ready;

  fifo_rob #(
      .Depth(TxBufferDepth)
  ) endpoint_tx_buffer (
      .clk           (clk),
      .nrst          (nrst),
      .fifo_rob_full (endpoint_tx_buffer_fifo_rob_full),
      .fifo_rob_empty(endpoint_tx_buffer_fifo_rob_empty),
      .req_push_valid(endpoint_tx_buffer_req_push_valid),
      .req_push_data (endpoint_tx_buffer_req_push_data),
      .req_push_ready(endpoint_tx_buffer_req_push_ready),
      .req_pop_valid (endpoint_tx_buffer_req_pop_valid),
      .req_pop_ready (endpoint_tx_buffer_req_pop_ready),
      .req_pop_data  (endpoint_tx_buffer_req_pop_data),
      .net_pop_valid (endpoint_tx_buffer_net_pop_valid),
      .net_pop_ready (endpoint_tx_buffer_net_pop_ready),
      .net_pop_data  (endpoint_tx_buffer_net_pop_data),
      .net_push_valid(endpoint_tx_buffer_net_push_valid),
      .net_push_data (endpoint_tx_buffer_net_push_data),
      .net_push_ready(endpoint_tx_buffer_net_push_ready)
  );


  /************************************************/
  /* endpoint_rx_buffer                           */
  /************************************************/
  logic    endpoint_rx_buffer_fifo_rob_full;
  logic    endpoint_rx_buffer_fifo_rob_empty;
  logic    endpoint_rx_buffer_req_push_valid;
  packet_t endpoint_rx_buffer_req_push_data;
  logic    endpoint_rx_buffer_req_push_ready;
  logic    endpoint_rx_buffer_req_pop_valid;
  logic    endpoint_rx_buffer_req_pop_ready;
  packet_t endpoint_rx_buffer_req_pop_data;
  logic    endpoint_rx_buffer_net_pop_valid;
  logic    endpoint_rx_buffer_net_pop_ready;
  packet_t endpoint_rx_buffer_net_pop_data;
  logic    endpoint_rx_buffer_net_push_valid;
  packet_t endpoint_rx_buffer_net_push_data;
  logic    endpoint_rx_buffer_net_push_ready;

  fifo_rob #(
      .Depth(RxBufferDepth)
  ) endpoint_rx_buffer (
      .clk           (clk),
      .nrst          (nrst),
      .fifo_rob_full (endpoint_rx_buffer_fifo_rob_full),
      .fifo_rob_empty(endpoint_rx_buffer_fifo_rob_empty),
      .req_push_valid(endpoint_rx_buffer_req_push_valid),
      .req_push_data (endpoint_rx_buffer_req_push_data),
      .req_push_ready(endpoint_rx_buffer_req_push_ready),
      .req_pop_valid (endpoint_rx_buffer_req_pop_valid),
      .req_pop_ready (endpoint_rx_buffer_req_pop_ready),
      .req_pop_data  (endpoint_rx_buffer_req_pop_data),
      .net_pop_valid (endpoint_rx_buffer_net_pop_valid),
      .net_pop_ready (endpoint_rx_buffer_net_pop_ready),
      .net_pop_data  (endpoint_rx_buffer_net_pop_data),
      .net_push_valid(endpoint_rx_buffer_net_push_valid),
      .net_push_data (endpoint_rx_buffer_net_push_data),
      .net_push_ready(endpoint_rx_buffer_net_push_ready)
  );


  /************************************************/
  /* net_rx_buffer                                */
  /************************************************/
  logic                     net_rx_buffer_push_valid;
  logic [NetPacketBits-1:0] net_rx_buffer_push_data;
  logic                     net_rx_buffer_push_ready;
  logic                     net_rx_buffer_pop_valid;
  logic [NetPacketBits-1:0] net_rx_buffer_pop_data;
  logic                     net_rx_buffer_pop_ready;

  fifo_basic #(
      .Depth(2 * RxBufferDepth),
      .Width(NetPacketBits)
  ) net_rx_buffer (
      .clk       (clk),
      .nrst      (nrst),
      .push_valid(net_rx_buffer_push_valid),
      .push_data (net_rx_buffer_push_data),
      .push_ready(net_rx_buffer_push_ready),
      .pop_valid (net_rx_buffer_pop_valid),
      .pop_data  (net_rx_buffer_pop_data),
      .pop_ready (net_rx_buffer_pop_ready)
  );

  /************************************************/
  /* return_id_buffer                             */
  /************************************************/
  logic               return_id_buffer_push_valid;
  endpoint_id_t [1:0] return_id_buffer_push_data;
  logic               return_id_buffer_push_ready;
  logic               return_id_buffer_pop_valid;
  endpoint_id_t [1:0] return_id_buffer_pop_data;
  logic               return_id_buffer_pop_ready;

  fifo_basic #(
      .Depth(RxBufferDepth),
      .Width(2 * EndpointIdBits)
  ) return_id_buffer (
      .clk       (clk),
      .nrst      (nrst),
      .push_valid(return_id_buffer_push_valid),
      .push_data (return_id_buffer_push_data),
      .push_ready(return_id_buffer_push_ready),
      .pop_valid (return_id_buffer_pop_valid),
      .pop_data  (return_id_buffer_pop_data),
      .pop_ready (return_id_buffer_pop_ready)
  );


  /************************************************/
  /* rx_arbiter                                   */
  /************************************************/
  logic               rx_arbiter_req_pop_ready;
  logic               rx_arbiter_req_pop_valid;
  endpoint_id_t [1:0] rx_arbiter_req_return_id;
  packet_t            rx_arbiter_req_pop_data;
  logic               rx_arbiter_resp_pop_ready;
  logic               rx_arbiter_resp_pop_valid;
  endpoint_id_t [1:0] rx_arbiter_resp_return_id;
  packet_t            rx_arbiter_resp_pop_data;
  logic               rx_arbiter_push_valid;
  logic               rx_arbiter_push_ready;
  net_packet_t        rx_arbiter_push_data;

  endpoint_rx_arbiter rx_arbiter (
      .req_pop_ready (rx_arbiter_req_pop_ready),
      .req_pop_valid (rx_arbiter_req_pop_valid),
      .req_return_id (rx_arbiter_req_return_id),
      .req_pop_data  (rx_arbiter_req_pop_data),
      .resp_pop_ready(rx_arbiter_resp_pop_ready),
      .resp_pop_valid(rx_arbiter_resp_pop_valid),
      .resp_return_id(rx_arbiter_resp_return_id),
      .resp_pop_data (rx_arbiter_resp_pop_data),
      .push_valid    (rx_arbiter_push_valid),
      .push_ready    (rx_arbiter_push_ready),
      .push_data     (rx_arbiter_push_data)
  );


  /************************************************/
  /* tx_arbiter                                   */
  /************************************************/
  logic               tx_arbiter_req_push_ready;
  logic               tx_arbiter_req_push_valid;
  packet_t            tx_arbiter_req_push_data;
  logic               tx_arbiter_resp_push_ready;
  logic               tx_arbiter_resp_push_valid;
  endpoint_id_t [1:0] tx_arbiter_resp_return_id;
  packet_t            tx_arbiter_resp_push_data;
  logic               tx_arbiter_pop_valid;
  logic               tx_arbiter_pop_ready;
  net_packet_t        tx_arbiter_pop_data;

  endpoint_tx_arbiter #(
      .NetworkType(NetworkType)
  ) tx_arbiter (
      .clk,
      .nrst,
      .strap_endpoint_id_x,
      .strap_endpoint_id_y,
      .req_push_ready (tx_arbiter_req_push_ready),
      .req_push_valid (tx_arbiter_req_push_valid),
      .req_push_data  (tx_arbiter_req_push_data),
      .resp_push_ready(tx_arbiter_resp_push_ready),
      .resp_push_valid(tx_arbiter_resp_push_valid),
      .resp_return_id (tx_arbiter_resp_return_id),
      .resp_push_data (tx_arbiter_resp_push_data),
      .pop_valid      (tx_arbiter_pop_valid),
      .pop_ready      (tx_arbiter_pop_ready),
      .pop_data       (tx_arbiter_pop_data)
  );


  /************************************************/
  /* assigns                                      */
  /************************************************/
  assign req_full = endpoint_tx_buffer_fifo_rob_full;
  assign req_empty = endpoint_tx_buffer_fifo_rob_empty;
  assign endpoint_tx_buffer_req_push_valid = req_push_valid;
  assign endpoint_tx_buffer_req_push_data = req_push_data;
  assign req_push_ready = endpoint_tx_buffer_req_push_ready;
  assign endpoint_tx_buffer_req_pop_ready = req_pop_ready;
  assign endpoint_tx_buffer_net_pop_ready = tx_arbiter_req_push_ready;
  assign endpoint_tx_buffer_net_push_valid = rx_arbiter_req_pop_valid;
  assign endpoint_tx_buffer_net_push_data = rx_arbiter_req_pop_data;
  assign req_pop_valid = endpoint_tx_buffer_req_pop_valid;
  assign req_pop_data = endpoint_tx_buffer_req_pop_data;

  assign resp_full = endpoint_rx_buffer_fifo_rob_full;
  assign resp_empty = endpoint_rx_buffer_fifo_rob_empty;
  assign endpoint_rx_buffer_req_push_valid = rx_arbiter_resp_pop_valid;
  assign endpoint_rx_buffer_req_push_data = rx_arbiter_resp_pop_data;
  assign endpoint_rx_buffer_req_pop_ready = tx_arbiter_resp_push_ready;
  assign endpoint_rx_buffer_net_pop_ready = resp_pop_ready;
  assign endpoint_rx_buffer_net_push_valid = resp_push_valid;
  assign endpoint_rx_buffer_net_push_data = resp_push_data;
  assign resp_push_ready = endpoint_rx_buffer_net_push_ready;
  assign resp_pop_valid = endpoint_rx_buffer_net_pop_valid;
  assign resp_pop_data = endpoint_rx_buffer_net_pop_data;

  assign return_id_buffer_pop_ready = tx_arbiter_resp_push_ready;
  assign return_id_buffer_push_valid = rx_arbiter_resp_pop_valid;
  assign return_id_buffer_push_data = rx_arbiter_resp_return_id;

  assign rx_arbiter_req_pop_ready = endpoint_tx_buffer_net_push_ready;
  assign rx_arbiter_resp_pop_ready = endpoint_rx_buffer_req_push_ready;
  assign rx_arbiter_push_valid = net_rx_buffer_pop_valid;
  assign rx_arbiter_push_data = net_rx_buffer_pop_data;
  assign net_push_ready = net_rx_buffer_push_ready;

  assign net_rx_buffer_pop_ready = rx_arbiter_push_ready;
  assign net_rx_buffer_push_valid = net_push_valid;
  assign net_rx_buffer_push_data = net_push_data;

  assign tx_arbiter_req_push_valid = endpoint_tx_buffer_net_pop_valid;
  assign tx_arbiter_req_push_data = endpoint_tx_buffer_net_pop_data;
  assign tx_arbiter_resp_push_valid = endpoint_rx_buffer_req_pop_valid;
  assign tx_arbiter_resp_return_id = return_id_buffer_pop_data;
  assign tx_arbiter_resp_push_data = endpoint_rx_buffer_req_pop_data;
  assign tx_arbiter_pop_ready = net_pop_ready;
  assign net_pop_valid = tx_arbiter_pop_valid;
  assign net_pop_data = tx_arbiter_pop_data;

  // Sanity checks
  always_comb begin
    // TODO(wrcunnin): make push_ready deassert when in reset
    if (nrst) begin
      assert (!return_id_buffer_push_ready == endpoint_rx_buffer_fifo_rob_full);
      assert (!return_id_buffer_pop_valid == endpoint_rx_buffer_fifo_rob_empty);
    end
  end

endmodule
