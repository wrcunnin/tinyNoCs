/*

Author: William Cunningham
Date  : 03/21/2026

Description:
    16-endpoint ring network

*/

import packet_pkg::*;
import ring_pkg::*;

module ring_16 #(
    parameter int TxBufferDepth = 8,
    parameter int RxBufferDepth = 8,
    parameter int BufferRxDepth = 16
) (
    // Clock, async reset
    input logic CLK,
    input logic nRST,

    ////////////////////////////////////////////////////////
    // Requester sending data
    input logic [15:0]    req_push_valid,
    input packet_t [15:0] req_push_data,
    output logic [15:0]   req_push_ready,

    // Requester receiving data
    output logic    [15:0] req_pop_valid,
    output packet_t [15:0] req_pop_data,
    input  logic    [15:0] req_pop_ready,

    output logic [15:0] req_full,
    output logic [15:0] req_empty,

    ////////////////////////////////////////////////////////
    // Responder sending data
    input logic [15:0]    resp_push_valid,
    input packet_t [15:0] resp_push_data,
    output logic [15:0]   resp_push_ready,

    // Responder receiving data
    output logic    [15:0] resp_pop_valid,
    output packet_t [15:0] resp_pop_data,
    input  logic    [15:0] resp_pop_ready,

    output logic [15:0] resp_full,
    output logic [15:0] resp_empty
);

  `CREATE_ENDPOINT_RING_XBAR(0);
  `CREATE_ENDPOINT_RING_XBAR(1);
  `CREATE_ENDPOINT_RING_XBAR(2);
  `CREATE_ENDPOINT_RING_XBAR(3);
  `CREATE_ENDPOINT_RING_XBAR(4);
  `CREATE_ENDPOINT_RING_XBAR(5);
  `CREATE_ENDPOINT_RING_XBAR(6);
  `CREATE_ENDPOINT_RING_XBAR(7);
  `CREATE_ENDPOINT_RING_XBAR(8);
  `CREATE_ENDPOINT_RING_XBAR(9);
  `CREATE_ENDPOINT_RING_XBAR(10);
  `CREATE_ENDPOINT_RING_XBAR(11);
  `CREATE_ENDPOINT_RING_XBAR(12);
  `CREATE_ENDPOINT_RING_XBAR(13);
  `CREATE_ENDPOINT_RING_XBAR(14);
  `CREATE_ENDPOINT_RING_XBAR(15);
  `CONNECT_RING_XBAR(0, 15, 1);
  `CONNECT_RING_XBAR(1, 0, 2);
  `CONNECT_RING_XBAR(2, 1, 3);
  `CONNECT_RING_XBAR(3, 2, 4);
  `CONNECT_RING_XBAR(4, 3, 5);
  `CONNECT_RING_XBAR(5, 4, 6);
  `CONNECT_RING_XBAR(6, 5, 7);
  `CONNECT_RING_XBAR(7, 6, 8);
  `CONNECT_RING_XBAR(8, 7, 9);
  `CONNECT_RING_XBAR(9, 8, 10);
  `CONNECT_RING_XBAR(10, 9, 11);
  `CONNECT_RING_XBAR(11, 10, 12);
  `CONNECT_RING_XBAR(12, 11, 13);
  `CONNECT_RING_XBAR(13, 12, 14);
  `CONNECT_RING_XBAR(14, 13, 15);
  `CONNECT_RING_XBAR(15, 14, 0);

endmodule
