/*

Author: William Cunningham
Date  : 03/20/2026

Description:
    Arbitrates between sending a network packet to the reponse or requester FIFO.
*/

import packet_pkg::*;

module endpoint_rx_arbiter (
    ////////////////////////////////////////////////////////
    // Requester receiving data
    input  logic               req_pop_ready,
    output logic               req_pop_valid,
    output endpoint_id_t [1:0] req_return_id,
    output packet_t            req_pop_data,

    ////////////////////////////////////////////////////////
    // Responder receiving data
    input  logic               resp_pop_ready,
    output logic               resp_pop_valid,
    output endpoint_id_t [1:0] resp_return_id,
    output packet_t            resp_pop_data,

    ////////////////////////////////////////////////////////
    // Network incoming data
    input  logic        push_valid,
    output logic        push_ready,
    input  net_packet_t push_data
);

  always_comb begin : packetSelection
    req_pop_valid  = 0;
    req_pop_data   = '0;
    req_return_id  = '0;
    resp_pop_valid = 0;
    resp_pop_data  = '0;
    resp_return_id = '0;
    push_ready     = 0;

    if (push_valid) begin
      // If an incoming packet is a request, it goes to the response FIFO
      // - We are receiving data from an external endpoint
      if (push_data.request) begin
        resp_pop_valid = 1;
        resp_pop_data  = push_data.packet;
        resp_return_id = push_data.src_id;
        push_ready     = resp_pop_ready;
      end  // If an incoming packet is not a request, it goes to the request FIFO
           // - We are receiving data we requested/acknowledged
      else if (!push_data.request) begin
        req_pop_valid = 1;
        req_pop_data  = push_data.packet;
        req_return_id = push_data.src_id;
        push_ready    = req_pop_ready;
      end else assert (0);
    end
  end

endmodule
