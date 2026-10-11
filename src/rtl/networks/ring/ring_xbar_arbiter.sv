/*

Author: William Cunningham
Date  : 03/21/2026

Description:
    Arbiter for a ring crossbar

*/

import packet_pkg::*;
import ring_pkg::*;

module ring_xbar_arbiter (
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

  typedef enum logic [1:0] {
    RXBAR_NONE,
    RXBAR_EP,
    RXBAR_NET
  } ring_xbar_arbiter_lru_state_t;

  ring_xbar_arbiter_lru_state_t lru, next_lru, selected;

  always_ff @(posedge CLK, negedge nRST) begin : RXBAR_LRU
    if (!nRST) lru <= RXBAR_EP;

    // if the network is enabled & ready, update the LRU state
    else if (net_pop_valid && net_pop_ready) lru <= next_lru;
  end

  // Determines if the incoming network packet is intended for the endpoint
  logic net_dest_match;
  assign net_dest_match = net_push_valid && (strap_endpoint_id == net_push_data.dst_id[0]);

  always_comb begin : packetSelection
    selected = RXBAR_NONE;
    next_lru = lru;

    // Network has data for endpoint
    if (net_dest_match) begin
      selected = RXBAR_EP;
      next_lru = RXBAR_NET;
    end  // Both endpoint and network could pass data to network
    else begin
      // If both want to send
      if (endpoint_push_valid && net_push_valid) begin
        selected = lru;
        next_lru = lru == RXBAR_EP ? RXBAR_NET : RXBAR_EP;
      end  // If the requester is wanting to send & responder has nothing to send
      else if (endpoint_push_valid && !net_push_valid) begin
        selected = RXBAR_EP;
        next_lru = RXBAR_NET;
      end  // If the responder is wanting to send & requester has nothing to send
      else if (!endpoint_push_valid && net_push_valid) begin
        selected = RXBAR_NET;
        next_lru = RXBAR_EP;
      end
    end
  end

  always_comb begin : packetRouting
    net_push_ready = 0;
    net_pop_valid = 0;
    net_pop_data = '0;
    endpoint_push_ready = 0;
    endpoint_pop_valid = 0;
    endpoint_pop_data = '0;

    // If xbar is receiving a packet from the network for the attached endpoint
    if (net_dest_match) begin
      net_pop_valid = endpoint_push_valid;
      net_pop_data = endpoint_push_data;
      endpoint_push_ready = net_pop_ready;
      endpoint_pop_valid = net_push_valid;
      endpoint_pop_data = net_push_data;
      net_push_ready = endpoint_pop_ready;
    end  // Both endpoint and network may want to put packets in the FIFO,
         // so we must respect what got selected
    else if (selected == RXBAR_EP) begin
      net_pop_valid = 1;
      net_pop_data = endpoint_push_data;
      endpoint_push_ready = net_pop_ready;
    end else if (selected == RXBAR_NET) begin
      net_pop_valid  = 1;
      net_pop_data   = net_push_data;
      net_push_ready = net_pop_ready;
    end
  end

endmodule
