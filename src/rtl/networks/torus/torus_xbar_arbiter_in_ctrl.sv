/*

Author: William Cunningham
Date  : 04/18/2026

Description:
    Input control for any direction, implementing LRU scheduling

*/

import packet_pkg::*;

module torus_xbar_arbiter_in_ctrl #(
    parameter int unsigned POS_X,
    parameter int unsigned POS_Y,
    parameter int unsigned MIN_X = 1,
    parameter int unsigned MIN_Y = 1,
    parameter int unsigned MAX_X,
    parameter int unsigned MAX_Y,
    parameter PREFER_VERTICAL = 0,
    parameter VERTICAL_TORUS = 0
) (
    // Stalls the receiver data
    output logic net_stall_rx,

    // Data is in the receive buffer
    input logic net_en_rx,

    // Packet containing the destinations
    input net_packet_t net_packet_rx,

    // Directions the packet should go within the XBar
    output logic north_en_rx, south_en_rx, east_en_rx, west_en_rx, torus_en_rx,

    // Stalls coming in from each direction
    input logic north_stall_tx, south_stall_tx, east_stall_tx, west_stall_tx, torus_stall_tx
);

logic north, south, east, west, torus;

assign north = net_packet_rx.dst_id[1] < POS_Y;
assign south = net_packet_rx.dst_id[1] > POS_Y;
assign east = net_packet_rx.dst_id[0] > POS_X;
assign west = net_packet_rx.dst_id[0] < POS_X;

always_comb begin : TORUS_CTRL
    torus = 0;

    // this means we have vertical torus
    if (VERTICAL_TORUS) begin
        if (POS_Y == MAX_Y)
            torus = net_packet_rx.dst_id[1] < (POS_Y / 2);
        else if (POS_Y == MIN_Y)
            torus = net_packet_rx.dst_id[1] > ( (MAX_Y / 2) + POS_Y );
    end else begin
        if (POS_X == MAX_X)
            torus = net_packet_rx.dst_id[0] < (POS_X / 2);
        else if (POS_X == MIN_X)
            torus = net_packet_rx.dst_id[0] > ( (MAX_X / 2) + POS_X );
    end
end

always_comb begin : DIR_CTRL
    north_en_rx = 0;
    south_en_rx = 0;
    east_en_rx = 0;
    west_en_rx = 0;
    torus_en_rx = 0;

    if (net_en_rx) begin
        casez({torus, north, south, east, west})
            // Special case: we take advantage of the torus before anything else
            5'b1????: torus_en_rx = 1;

            // Normal one-hot cases
            5'b01000: north_en_rx = 1;
            5'b00100: south_en_rx = 1;
            5'b00010: east_en_rx = 1;
            5'b00001: west_en_rx = 1;

            // Edge cases where we can go two directions
            // We need to go north and east
            5'b01010: begin
                // We are at the eastern edge of the network,
                // We cannot issue east until we get aligned North
                if (POS_X == MAX_X) begin
                    north_en_rx = 1;
                end
                // We are at the northern edge of the network
                // We cannot issue east until we get aligned East
                else if (POS_Y == MIN_Y) begin
                    east_en_rx = 1;
                end
                // We are in a central mesh node and we should traverse depending
                // on the direction preference assigned to this xbar
                else begin
                    north_en_rx = PREFER_VERTICAL ? 1 : 0;
                    east_en_rx = PREFER_VERTICAL ? 0 : 1;
                end
            end

            // We need to go north and west
            5'b01001: begin
                // We are at the Western edge of the network,
                // We cannot issue West until we get aligned North
                if (POS_X == MIN_X) begin
                    north_en_rx = 1;
                end
                // We are at the northern edge of the network
                // We cannot issue east until we get aligned Wast
                else if (POS_Y == MIN_Y) begin
                    west_en_rx = 1;
                end
                // We are in a central mesh node and we should traverse depending
                // on the direction preference assigned to this xbar
                else begin
                    north_en_rx = PREFER_VERTICAL ? 1 : 0;
                    west_en_rx = PREFER_VERTICAL ? 0 : 1;
                end
            end

            // We need to go south and east
            5'b00110: begin
                // We are at the eastern edge of the network,
                // We cannot issue east until we get aligned South
                if (POS_X == MAX_X) begin
                    south_en_rx = 1;
                end
                // We are at the southern edge of the network
                // We cannot issue east until we get aligned East
                else if (POS_Y == MAX_Y) begin
                    east_en_rx = 1;
                end
                // We are in a central mesh node and we should traverse depending
                // on the direction preference assigned to this xbar
                else begin
                    south_en_rx = PREFER_VERTICAL ? 1 : 0;
                    east_en_rx = PREFER_VERTICAL ? 0 : 1;
                end
            end

            // We need to go south and west
            5'b00101: begin
                // We are at the Western edge of the network,
                // We cannot issue West until we get aligned South
                if (POS_X == MIN_X) begin
                    south_en_rx = 1;
                end
                // We are at the southern edge of the network
                // We cannot issue east until we get aligned Wast
                else if (POS_Y == MAX_Y) begin
                    west_en_rx = 1;
                end
                // We are in a central mesh node and we should traverse depending
                // on the direction preference assigned to this xbar
                else begin
                    south_en_rx = PREFER_VERTICAL ? 1 : 0;
                    west_en_rx = PREFER_VERTICAL ? 0 : 1;
                end
            end

            default: assert(({torus, north, south, east, west} == 4'b0) || (north ^ south) && (east ^ west));
        endcase
    end
end

always_comb begin : STALL_CTRL
    net_stall_rx = 1;
    casez({torus_en_rx, north_en_rx, south_en_rx, east_en_rx, west_en_rx})
        5'b10000: net_stall_rx = torus_stall_tx;
        5'b01000: net_stall_rx = north_stall_tx;
        5'b00100: net_stall_rx = south_stall_tx;
        5'b00010: net_stall_rx = east_stall_tx;
        5'b00001: net_stall_rx = west_stall_tx;

        // TODO(wrcunnin): this is a BAD default without the assertion
        default: begin
            // make sure this signal is one hot or zero, otw, we have a problem
            if ({torus_en_rx, north_en_rx, south_en_rx, east_en_rx, west_en_rx})
                assert($onehot({torus_en_rx, north_en_rx, south_en_rx, east_en_rx, west_en_rx}));
            net_stall_rx = 1;
        end
    endcase
end

endmodule