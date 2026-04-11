/*

Author: William Cunningham
Date  : 04/10/2026

Description:
    Arbitrates packets from cardinal directions and 

*/

import packet_pkg::*;

module mesh_xbar_arbiter #(
    parameter int unsigned POS_X,
    parameter int unsigned POS_Y,
    parameter int unsigned MAX_X,
    parameter int unsigned MAX_Y,
    parameter PREFER_VERTICAL = 0
) (
    input logic CLK, nRST,

    ////////////////////////////////////////////////////////
    // North inputs/outputs
    `CREATE_MESH_XBAR_IO(north),

    ////////////////////////////////////////////////////////
    // South inputs/outputs
    `CREATE_MESH_XBAR_IO(south),

    ////////////////////////////////////////////////////////
    // East inputs/outputs
    `CREATE_MESH_XBAR_IO(west),

    ////////////////////////////////////////////////////////
    // West inputs/outputs
    `CREATE_MESH_XBAR_IO(east)
);

`CREATE_MESH_XBARB_CTRL(north);
`CREATE_MESH_XBARB_CTRL(south);
`CREATE_MESH_XBARB_CTRL(east);
`CREATE_MESH_XBARB_CTRL(west);

`CONNECT_MESH_XBARB_CTRL_IO(north);
`CONNECT_MESH_XBARB_CTRL_IO(south);
`CONNECT_MESH_XBARB_CTRL_IO(east);
`CONNECT_MESH_XBARB_CTRL_IO(west);

`CONNECT_MESH_XBARB_CTRL_INTERNAL(north, west, south, east);
`CONNECT_MESH_XBARB_CTRL_INTERNAL(west, south, east, north);
`CONNECT_MESH_XBARB_CTRL_INTERNAL(south, east, north, west);
`CONNECT_MESH_XBARB_CTRL_INTERNAL(east, north, west, south);

endmodule