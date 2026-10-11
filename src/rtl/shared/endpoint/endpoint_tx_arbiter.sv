/*

Author: William Cunningham
Date  : 03/19/2026

Description:
    Arbitrates between sending a response or request to the network.
*/

import packet_pkg::*;
import ring_pkg::*;
import mesh_pkg::*;

module endpoint_tx_arbiter #(
    parameter network_type_t NetworkType = 0
) (
    // Clock, async reset
    input logic CLK,
    nRST,

    // Straps
    input endpoint_id_t strap_endpoint_id_x,
    input endpoint_id_t strap_endpoint_id_y,

    ////////////////////////////////////////////////////////
    // Requester sending data
    output logic   req_push_ready,
    input logic    req_push_valid,
    input packet_t req_push_data,

    ////////////////////////////////////////////////////////
    // Responder sending data
    output logic               resp_push_ready,
    input  logic               resp_push_valid,
    input  endpoint_id_t [1:0] resp_return_id,
    input  packet_t            resp_push_data,

    ////////////////////////////////////////////////////////
    // To Network signals
    input  logic        pop_ready,
    output logic        pop_valid,
    output net_packet_t pop_data
);

  typedef enum logic [1:0] {
    EPTXARB_NONE,
    EPTXARB_REQ,
    EPTXARB_RESP
  } endpoint_tx_arbiter_lru_state_t;

  endpoint_tx_arbiter_lru_state_t lru, next_lru, selected;

  endpoint_id_t [1:0] dst_id;

  always_ff @(posedge CLK, negedge nRST) begin : EPTXARB_LRU
    if (!nRST) lru <= EPTXARB_REQ;

    // if the network is enabled & ready, update the LRU state
    else if (pop_valid && pop_ready) lru <= next_lru;
  end

  always_comb begin : packetSelection
    selected = EPTXARB_NONE;
    next_lru = lru;

    // If both want to send
    if (req_push_valid && resp_push_valid) begin
      selected = lru;
      next_lru = lru == EPTXARB_REQ ? EPTXARB_RESP : EPTXARB_REQ;
    end  // If the requester is wanting to send & responder has nothing to send
    else if (req_push_valid && !resp_push_valid) begin
      selected = EPTXARB_REQ;
      next_lru = EPTXARB_RESP;
    end  // If the responder is wanting to send & requester has nothing to send
    else if (!req_push_valid && resp_push_valid) begin
      selected = EPTXARB_RESP;
      next_lru = EPTXARB_REQ;
    end
  end

  always_comb begin : packetCreation
    req_push_ready = 0;
    resp_push_ready = 0;
    pop_valid = 0;
    pop_data = '0;
    pop_data.src_id[0] = strap_endpoint_id_x;
    pop_data.src_id[1] = strap_endpoint_id_y;

    // The requester has been selected
    // - We enable the network send signal
    // - Set the requester ready to the network ready
    // - Set the request signal to 1 since this is a request
    // - Set the start address to that of this endpoint
    // - Set the packet to that in the requester's FIFO (TX)
    if (selected == EPTXARB_REQ) begin
      pop_valid = 1;
      req_push_ready = pop_ready;
      pop_data.request = 1;
      pop_data.dst_id = dst_id;
      pop_data.packet = req_push_data;
    end  // The responder has been selected
         // - We enable the network send signal
         // - Set the responder ready to the network ready
         // - Set the request signal to 0 since this is a response
         // - Set the start address to that the address originally in the packet
         // - Set the packet to that in the responder's FIFO (RX)
         // - Set the address in the packet from the FIFO to the return address
    else if (selected == EPTXARB_RESP) begin
      pop_valid = 1;
      resp_push_ready = pop_ready;
      pop_data.request = 0;
      pop_data.dst_id = resp_return_id;
      pop_data.packet = resp_push_data;
    end
  end

  endpoint_id_t endpoint_idx;
  assign endpoint_idx = req_push_data.addr[(AddressWidth-1)-:EndpointIdBits];

  generate
    if (NetworkType == kRing) begin
      // HACK: Is this always going to be right? Need to have 2**power aligned number of endpoints...
      //       I am the designer and I say this is okay! If you get upset about it,
      //       please do not send your regards.
      assign dst_id[0] = endpoint_idx;
      assign dst_id[1] = 0;
    end else if (NetworkType == kMesh) begin
`ifdef USE_5x3
      assign dst_id[0] = Mesh5x3Endpoints[endpoint_idx][0];
      assign dst_id[1] = Mesh5x3Endpoints[endpoint_idx][1];
`else
      assign dst_id[0] = Mesh4x4Endpoints[endpoint_idx][0];
      assign dst_id[1] = Mesh4x4Endpoints[endpoint_idx][1];
`endif
    end else begin
      always_comb begin
        assert (0);
      end
    end
  endgenerate

endmodule
