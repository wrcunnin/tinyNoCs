/*

Author: William Cunningham
Date  : 04/18/2026

Description:
    Arbitrates packets from cardinal directions and 

*/

import packet_pkg::*;

module torus_xbar_arbiter #(
    parameter int unsigned POS_X,
    parameter int unsigned POS_Y,
    parameter int unsigned MAX_X,
    parameter int unsigned MAX_Y,
    parameter PREFER_VERTICAL = 0,
    parameter VERTICAL_TORUS = 0
) (
    input logic CLK, nRST,

    ////////////////////////////////////////////////////////
    // North inputs/outputs
    `CREATE_MESH_XBAR_IO(north),

    ////////////////////////////////////////////////////////
    // South inputs/outputs
    `CREATE_MESH_XBAR_IO(south),

    ////////////////////////////////////////////////////////
    // West inputs/outputs
    `CREATE_MESH_XBAR_IO(west),

    ////////////////////////////////////////////////////////
    // East inputs/outputs
    `CREATE_MESH_XBAR_IO(east),

    ////////////////////////////////////////////////////////
    // Torus inputs/outputs
    `CREATE_MESH_XBAR_IO(torus)
);

`CREATE_TORUS_XBARB_CTRL(north);
`CREATE_TORUS_XBARB_CTRL(south);
`CREATE_TORUS_XBARB_CTRL(east);
`CREATE_TORUS_XBARB_CTRL(west);
`CREATE_TORUS_XBARB_CTRL(torus);

`CONNECT_TORUS_XBARB_CTRL_IO(north);
`CONNECT_TORUS_XBARB_CTRL_IO(south);
`CONNECT_TORUS_XBARB_CTRL_IO(east);
`CONNECT_TORUS_XBARB_CTRL_IO(west);
`CONNECT_TORUS_XBARB_CTRL_IO(torus);

`CONNECT_TORUS_XBARB_CTRL_INTERNAL(north, west, south, east, torus);
`CONNECT_TORUS_XBARB_CTRL_INTERNAL(west, south, east, torus, north);
`CONNECT_TORUS_XBARB_CTRL_INTERNAL(south, east, torus, north, west);
`CONNECT_TORUS_XBARB_CTRL_INTERNAL(east, torus, north, west, south);
`CONNECT_TORUS_XBARB_CTRL_INTERNAL(torus, north, west, south, east);

endmodule