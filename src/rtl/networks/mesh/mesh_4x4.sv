module mesh_4x4 #(
    parameter int unsigned TX_BUFFER_DEPTH = 4,
    parameter int unsigned RX_BUFFER_DEPTH = 4,
    parameter int unsigned BUFFER_RX_DEPTH = 32
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

// See MESH_4x4_ENDPOINTS for mappings
`CREATE_ENDPOINT_MESH(0, 0, 1);
`CREATE_ENDPOINT_MESH(1, 0, 2);
`CREATE_ENDPOINT_MESH(2, 0, 3);
`CREATE_ENDPOINT_MESH(3, 0, 4);
`CREATE_ENDPOINT_MESH(4, 1, 5);
`CREATE_ENDPOINT_MESH(5, 2, 5);
`CREATE_ENDPOINT_MESH(6, 3, 5);
`CREATE_ENDPOINT_MESH(7, 4, 5);
`CREATE_ENDPOINT_MESH(8, 5, 1);
`CREATE_ENDPOINT_MESH(9, 5, 2);
`CREATE_ENDPOINT_MESH(10, 5, 3);
`CREATE_ENDPOINT_MESH(11, 5, 4);
`CREATE_ENDPOINT_MESH(12, 1, 0);
`CREATE_ENDPOINT_MESH(13, 2, 0);
`CREATE_ENDPOINT_MESH(14, 3, 0);
`CREATE_ENDPOINT_MESH(15, 4, 0);

// First row
`CREATE_MESH_XBAR(1, 1, 4, 4, 1);
`CREATE_MESH_XBAR(2, 1, 4, 4, 0);
`CREATE_MESH_XBAR(3, 1, 4, 4, 1);
`CREATE_MESH_XBAR(4, 1, 4, 4, 0);

// Second Row
`CREATE_MESH_XBAR(1, 2, 4, 4, 0);
`CREATE_MESH_XBAR(2, 2, 4, 4, 1);
`CREATE_MESH_XBAR(3, 2, 4, 4, 0);
`CREATE_MESH_XBAR(4, 2, 4, 4, 1);

// Third Row
`CREATE_MESH_XBAR(1, 3, 4, 4, 1);
`CREATE_MESH_XBAR(2, 3, 4, 4, 0);
`CREATE_MESH_XBAR(3, 3, 4, 4, 1);
`CREATE_MESH_XBAR(4, 3, 4, 4, 0);

// Fourth Row
`CREATE_MESH_XBAR(1, 4, 4, 4, 0);
`CREATE_MESH_XBAR(2, 4, 4, 4, 1);
`CREATE_MESH_XBAR(3, 4, 4, 4, 0);
`CREATE_MESH_XBAR(4, 4, 4, 4, 1);

// Connecting everything!
// First Row
// (1, 1)
`CONNECT_MESH_XBAR_TO_ENDPOINT(1, 1, endpoint_12_net, north);
`CONNECT_MESH_XBARS(1, 1, mesh_xbar_1_2, south, north);
`CONNECT_MESH_XBARS(1, 1, mesh_xbar_2_1, east, west);
`CONNECT_MESH_XBAR_TO_ENDPOINT(1, 1, endpoint_0_net, west);

// (2, 1)
`CONNECT_MESH_XBAR_TO_ENDPOINT(2, 1, endpoint_13_net, north);
`CONNECT_MESH_XBARS(2, 1, mesh_xbar_2_2, south, north);
`CONNECT_MESH_XBARS(2, 1, mesh_xbar_3_1, east, west);
`CONNECT_MESH_XBARS(2, 1, mesh_xbar_1_1, west, east);

// (3, 1)
`CONNECT_MESH_XBAR_TO_ENDPOINT(3, 1, endpoint_14_net, north);
`CONNECT_MESH_XBARS(3, 1, mesh_xbar_3_2, south, north);
`CONNECT_MESH_XBARS(3, 1, mesh_xbar_4_1, east, west);
`CONNECT_MESH_XBARS(3, 1, mesh_xbar_2_1, west, east);

// (4, 1)
`CONNECT_MESH_XBAR_TO_ENDPOINT(4, 1, endpoint_15_net, north);
`CONNECT_MESH_XBARS(4, 1, mesh_xbar_4_2, south, north);
`CONNECT_MESH_XBAR_TO_ENDPOINT(4, 1, endpoint_8_net, east);
`CONNECT_MESH_XBARS(4, 1, mesh_xbar_3_1, west, east);

// Second Row
// (1, 2)
`CONNECT_MESH_XBARS(1, 2, mesh_xbar_1_1, north, south);
`CONNECT_MESH_XBARS(1, 2, mesh_xbar_1_3, south, north);
`CONNECT_MESH_XBARS(1, 2, mesh_xbar_2_2, east, west);
`CONNECT_MESH_XBAR_TO_ENDPOINT(1, 2, endpoint_1_net, west);

// (2, 2)
`CONNECT_MESH_XBARS(2, 2, mesh_xbar_2_1, north, south);
`CONNECT_MESH_XBARS(2, 2, mesh_xbar_2_3, south, north);
`CONNECT_MESH_XBARS(2, 2, mesh_xbar_3_2, east, west);
`CONNECT_MESH_XBARS(2, 2, mesh_xbar_1_2, west, east);

// (3, 2)
`CONNECT_MESH_XBARS(3, 2, mesh_xbar_3_1, north, south);
`CONNECT_MESH_XBARS(3, 2, mesh_xbar_3_3, south, north);
`CONNECT_MESH_XBARS(3, 2, mesh_xbar_4_2, east, west);
`CONNECT_MESH_XBARS(3, 2, mesh_xbar_2_2, west, east);

// (4, 2)
`CONNECT_MESH_XBARS(4, 2, mesh_xbar_4_1, north, south);
`CONNECT_MESH_XBARS(4, 2, mesh_xbar_4_3, south, north);
`CONNECT_MESH_XBAR_TO_ENDPOINT(4, 2, endpoint_9_net, east);
`CONNECT_MESH_XBARS(4, 2, mesh_xbar_3_2, west, east);

// Third Row
// (1, 3)
`CONNECT_MESH_XBARS(1, 3, mesh_xbar_1_2, north, south);
`CONNECT_MESH_XBARS(1, 3, mesh_xbar_1_4, south, north);
`CONNECT_MESH_XBARS(1, 3, mesh_xbar_2_3, east, west);
`CONNECT_MESH_XBAR_TO_ENDPOINT(1, 3, endpoint_2_net, west);

// (2, 3)
`CONNECT_MESH_XBARS(2, 3, mesh_xbar_2_2, north, south);
`CONNECT_MESH_XBARS(2, 3, mesh_xbar_2_4, south, north);
`CONNECT_MESH_XBARS(2, 3, mesh_xbar_3_3, east, west);
`CONNECT_MESH_XBARS(2, 3, mesh_xbar_1_3, west, east);

// (3, 3)
`CONNECT_MESH_XBARS(3, 3, mesh_xbar_3_2, north, south);
`CONNECT_MESH_XBARS(3, 3, mesh_xbar_3_4, south, north);
`CONNECT_MESH_XBARS(3, 3, mesh_xbar_4_3, east, west);
`CONNECT_MESH_XBARS(3, 3, mesh_xbar_2_3, west, east);

// (4, 3)
`CONNECT_MESH_XBARS(4, 3, mesh_xbar_4_2, north, south);
`CONNECT_MESH_XBARS(4, 3, mesh_xbar_4_4, south, north);
`CONNECT_MESH_XBAR_TO_ENDPOINT(4, 3, endpoint_10_net, east);
`CONNECT_MESH_XBARS(4, 3, mesh_xbar_3_3, west, east);

// Fourth Row
// (1, 4)
`CONNECT_MESH_XBARS(1, 4, mesh_xbar_1_3, north, south);
`CONNECT_MESH_XBAR_TO_ENDPOINT(1, 4, endpoint_4_net, south);
`CONNECT_MESH_XBARS(1, 4, mesh_xbar_2_4, east, west);
`CONNECT_MESH_XBAR_TO_ENDPOINT(1, 4, endpoint_3_net, west);

// (2, 4)
`CONNECT_MESH_XBARS(2, 4, mesh_xbar_2_3, north, south);
`CONNECT_MESH_XBAR_TO_ENDPOINT(2, 4, endpoint_5_net, south);
`CONNECT_MESH_XBARS(2, 4, mesh_xbar_3_4, east, west);
`CONNECT_MESH_XBARS(2, 4, mesh_xbar_1_4, west, east);

// (3, 4)
`CONNECT_MESH_XBARS(3, 4, mesh_xbar_3_3, north, south);
`CONNECT_MESH_XBAR_TO_ENDPOINT(3, 4, endpoint_6_net, south);
`CONNECT_MESH_XBARS(3, 4, mesh_xbar_4_4, east, west);
`CONNECT_MESH_XBARS(3, 4, mesh_xbar_2_4, west, east);

// (4, 4)
`CONNECT_MESH_XBARS(4, 4, mesh_xbar_4_3, north, south);
`CONNECT_MESH_XBAR_TO_ENDPOINT(4, 4, endpoint_7_net, south);
`CONNECT_MESH_XBAR_TO_ENDPOINT(4, 4, endpoint_11_net, east);
`CONNECT_MESH_XBARS(4, 4, mesh_xbar_3_4, west, east);

endmodule