/*

Author: William Cunningham
Date  : 03/21/2026

Description:
    2-endpoint ring network

*/

import packet_pkg::*;

module ring_16 #(
    parameter int TX_BUFFER_DEPTH = 8,
    parameter int RX_BUFFER_DEPTH = 8
) (
    // Clock, async reset
    input logic CLK, nRST,

    ////////////////////////////////////////////////////////
    // Requester sending data
    // Lets requester know if TX FIFO is full/empty
    output logic [15:0] req_full, req_empty,

    // Requester wants to send a packet
    input logic [15:0] req_en,

    // Packet information requester wants to send
    input packet_t [15:0] req_packet,

    // Indicates if a requester requires the completion to stall
    input logic [15:0] req_comp_stall,

    // Indicates a request is ready to be completed
    output logic [15:0] req_comp_en,

    // Packet information returned back to requester
    output packet_t [15:0] req_comp_packet,

    ////////////////////////////////////////////////////////
    // Responder sending data
    // Lets responder know if RX FIFO is full/empty
    output logic [15:0] resp_full, resp_empty,

    // Stalls the responding FIFO
    input logic [15:0] resp_stall,

    // Initiates the responder to begin servicing this request
    output logic [15:0] resp_en,

    // Packet going out to the responder
    output packet_t [15:0] resp_packet,

    // Responder wants to send a packet
    input logic [15:0] resp_comp_en,

    // Return address of the packet
    input addr_t [15:0] resp_comp_return_addr,

    // Packet information responder wants to send
    input packet_t [15:0] resp_comp_packet
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