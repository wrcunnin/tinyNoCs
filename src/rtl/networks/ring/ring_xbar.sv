/*

Author: William Cunningham
Date  : 03/21/2026

Description:
    Crossbar router for a ring network

*/

import packet_pkg::*;
import ring_pkg::*;

module ring_xbar #(
    parameter int unsigned NetBufferRxDepth = 8,
    parameter int unsigned EpBufferRxDepth  = 8
) (
    // Clock, async reset
    input logic CLK,
    input logic nRST,

    ////////////////////////////////////////////////////////
    // Straps
    input endpoint_id_t strap_endpoint_id,

    ////////////////////////////////////////////////////////
    // From Ring Crossbar
    output logic        net_push_ready,
    input  logic        net_push_valid,
    input  net_packet_t net_push_data,

    ////////////////////////////////////////////////////////
    // To Ring Crossbar
    input  logic        net_pop_ready,
    output logic        net_pop_valid,
    output net_packet_t net_pop_data,

    ////////////////////////////////////////////////////////
    // From Endpoint
    output logic        endpoint_push_ready,
    input  logic        endpoint_push_valid,
    input  net_packet_t endpoint_push_data,

    ////////////////////////////////////////////////////////
    // To Endpoint
    input  logic        endpoint_pop_ready,
    output logic        endpoint_pop_valid,
    output net_packet_t endpoint_pop_data

);

  /************************************************/
  /* net_buffer_rx                                */
  /************************************************/
  logic                     net_buffer_rx_push_valid;
  logic [NetPacketBits-1:0] net_buffer_rx_push_data;
  logic                     net_buffer_rx_push_ready;
  logic                     net_buffer_rx_pop_valid;
  logic [NetPacketBits-1:0] net_buffer_rx_pop_data;
  logic                     net_buffer_rx_pop_ready;

  fifo_basic #(
      .Depth(NetBufferRxDepth),
      .Width(NetPacketBits)
  ) net_buffer_rx (
      .CLK       (CLK),
      .nRST      (nRST),
      .push_valid(net_buffer_rx_push_valid),
      .push_data (net_buffer_rx_push_data),
      .push_ready(net_buffer_rx_push_ready),
      .pop_valid (net_buffer_rx_pop_valid),
      .pop_data  (net_buffer_rx_pop_data),
      .pop_ready (net_buffer_rx_pop_ready)
  );


  /************************************************/
  /* endpoint_buffer_rx                           */
  /************************************************/
  logic                     endpoint_buffer_rx_push_valid;
  logic [NetPacketBits-1:0] endpoint_buffer_rx_push_data;
  logic                     endpoint_buffer_rx_push_ready;
  logic                     endpoint_buffer_rx_pop_valid;
  logic [NetPacketBits-1:0] endpoint_buffer_rx_pop_data;
  logic                     endpoint_buffer_rx_pop_ready;

  fifo_basic #(
      .Depth(EpBufferRxDepth),
      .Width(NetPacketBits)
  ) endpoint_buffer_rx (
      .CLK       (CLK),
      .nRST      (nRST),
      .push_valid(endpoint_buffer_rx_push_valid),
      .push_data (endpoint_buffer_rx_push_data),
      .push_ready(endpoint_buffer_rx_push_ready),
      .pop_valid (endpoint_buffer_rx_pop_valid),
      .pop_data  (endpoint_buffer_rx_pop_data),
      .pop_ready (endpoint_buffer_rx_pop_ready)
  );


  /************************************************/
  /* xbarb                                        */
  /************************************************/
  logic        xbarb_net_push_ready;
  logic        xbarb_net_push_valid;
  net_packet_t xbarb_net_push_data;
  logic        xbarb_net_pop_ready;
  logic        xbarb_net_pop_valid;
  net_packet_t xbarb_net_pop_data;
  logic        xbarb_endpoint_push_ready;
  logic        xbarb_endpoint_push_valid;
  net_packet_t xbarb_endpoint_push_data;
  logic        xbarb_endpoint_pop_ready;
  logic        xbarb_endpoint_pop_valid;
  net_packet_t xbarb_endpoint_pop_data;
  ring_xbar_arbiter xbarb (
      .CLK,
      .nRST,
      .strap_endpoint_id,
      .net_push_ready     (xbarb_net_push_ready),
      .net_push_valid     (xbarb_net_push_valid),
      .net_push_data      (xbarb_net_push_data),
      .net_pop_ready      (xbarb_net_pop_ready),
      .net_pop_valid      (xbarb_net_pop_valid),
      .net_pop_data       (xbarb_net_pop_data),
      .endpoint_push_ready(xbarb_endpoint_push_ready),
      .endpoint_push_valid(xbarb_endpoint_push_valid),
      .endpoint_push_data (xbarb_endpoint_push_data),
      .endpoint_pop_ready (xbarb_endpoint_pop_ready),
      .endpoint_pop_valid (xbarb_endpoint_pop_valid),
      .endpoint_pop_data  (xbarb_endpoint_pop_data)
  );


  /************************************************/
  /* assigns                                      */
  /************************************************/
  assign net_push_ready = net_buffer_rx_push_ready;
  assign net_pop_valid = xbarb_net_pop_valid;
  assign net_pop_data = xbarb_net_pop_data;
  assign endpoint_push_ready = endpoint_buffer_rx_push_ready;
  assign endpoint_pop_valid = xbarb_endpoint_pop_valid;
  assign endpoint_pop_data = xbarb_endpoint_pop_data;

  assign net_buffer_rx_pop_ready = xbarb_net_push_ready;
  assign net_buffer_rx_push_valid = net_push_valid;
  assign net_buffer_rx_push_data = net_push_data;

  assign endpoint_buffer_rx_pop_ready = xbarb_endpoint_push_ready;
  assign endpoint_buffer_rx_push_valid = endpoint_push_valid;
  assign endpoint_buffer_rx_push_data = endpoint_push_data;

  assign xbarb_net_push_valid = net_buffer_rx_pop_valid;
  assign xbarb_net_push_data = net_buffer_rx_pop_data;
  assign xbarb_net_pop_ready = net_pop_ready;
  assign xbarb_endpoint_push_valid = endpoint_buffer_rx_pop_valid;
  assign xbarb_endpoint_push_data = endpoint_buffer_rx_pop_data;
  assign xbarb_endpoint_pop_ready = endpoint_pop_ready;

endmodule
