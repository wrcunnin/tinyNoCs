/*

Author: William Cunningham
Date  : 04/18/2026

Description:
    Input control for any direction, implementing LRU scheduling

*/

import packet_pkg::*;
import mesh_pkg::*;
import torus_pkg::*;

module torus_xbar_arbiter_in_ctrl (
    // Straps
    input endpoint_id_t strap_pos_x,
    input endpoint_id_t strap_pos_y,
    input endpoint_id_t strap_min_x,
    input endpoint_id_t strap_min_y,
    input endpoint_id_t strap_max_x,
    input endpoint_id_t strap_max_y,

    input logic strap_vertical_torus,
    input logic strap_prefer_vertical,

    // Ready to receive data
    output logic push_ready,

    // Data is in the receive buffer
    input logic push_valid,

    // Packet containing the destinations
    input net_packet_t push_data,

    // Directions the packet should go within the XBar
    output logic north_pop_valid,
    output logic south_pop_valid,
    output logic east_pop_valid,
    output logic west_pop_valid,
    output logic torus_pop_valid,

    // Ready signals coming in from each direction
    input logic north_pop_ready,
    input logic south_pop_ready,
    input logic east_pop_ready,
    input logic west_pop_ready,
    input logic torus_pop_ready
);

  logic north, south, east, west, torus;

  assign north = push_data.dst_id[1] < strap_pos_y;
  assign south = push_data.dst_id[1] > strap_pos_y;
  assign east  = push_data.dst_id[0] > strap_pos_x;
  assign west  = push_data.dst_id[0] < strap_pos_x;

  always_comb begin : TORUS_CTRL
    torus = 0;

    // this means we have vertical torus
    if (strap_vertical_torus) begin
      if (strap_pos_y == strap_max_y) torus = push_data.dst_id[1] < (strap_pos_y / 2);
      else if (strap_pos_y == strap_min_y)
        torus = push_data.dst_id[1] > ((strap_max_y / 2) + strap_pos_y);
    end else begin
      if (strap_pos_x == strap_max_x) torus = push_data.dst_id[0] < (strap_pos_x / 2);
      else if (strap_pos_x == strap_min_x)
        torus = push_data.dst_id[0] > ((strap_max_x / 2) + strap_pos_x);
    end
  end

  always_comb begin : DIR_CTRL
    north_pop_valid = 0;
    south_pop_valid = 0;
    east_pop_valid  = 0;
    west_pop_valid  = 0;
    torus_pop_valid = 0;

    if (push_valid) begin
      casez ({
        torus, north, south, east, west
      })
        // Special case: we take advantage of the torus before anything else
        5'b1????: torus_pop_valid = 1;

        // Normal one-hot cases
        5'b01000: north_pop_valid = 1;
        5'b00100: south_pop_valid = 1;
        5'b00010: east_pop_valid = 1;
        5'b00001: west_pop_valid = 1;

        // Edge cases where we can go two directions
        // We need to go north and east
        5'b01010: begin
          // We are at the eastern edge of the network,
          // We cannot issue east until we get aligned North
          if (strap_pos_x == strap_max_x) begin
            north_pop_valid = 1;
          end  // We are at the northern edge of the network
               // We cannot issue east until we get aligned East
          else if (strap_pos_y == strap_min_y) begin
            east_pop_valid = 1;
          end  // We are in a central mesh node and we should traverse depending
               // on the direction preference assigned to this xbar
          else begin
            north_pop_valid = strap_prefer_vertical ? 1 : 0;
            east_pop_valid  = strap_prefer_vertical ? 0 : 1;
          end
        end

        // We need to go north and west
        5'b01001: begin
          // We are at the Western edge of the network,
          // We cannot issue West until we get aligned North
          if (strap_pos_x == strap_min_x) begin
            north_pop_valid = 1;
          end  // We are at the northern edge of the network
               // We cannot issue east until we get aligned Wast
          else if (strap_pos_y == strap_min_y) begin
            west_pop_valid = 1;
          end  // We are in a central mesh node and we should traverse depending
               // on the direction preference assigned to this xbar
          else begin
            north_pop_valid = strap_prefer_vertical ? 1 : 0;
            west_pop_valid  = strap_prefer_vertical ? 0 : 1;
          end
        end

        // We need to go south and east
        5'b00110: begin
          // We are at the eastern edge of the network,
          // We cannot issue east until we get aligned South
          if (strap_pos_x == strap_max_x) begin
            south_pop_valid = 1;
          end  // We are at the southern edge of the network
               // We cannot issue east until we get aligned East
          else if (strap_pos_y == strap_max_y) begin
            east_pop_valid = 1;
          end  // We are in a central mesh node and we should traverse depending
               // on the direction preference assigned to this xbar
          else begin
            south_pop_valid = strap_prefer_vertical ? 1 : 0;
            east_pop_valid  = strap_prefer_vertical ? 0 : 1;
          end
        end

        // We need to go south and west
        5'b00101: begin
          // We are at the Western edge of the network,
          // We cannot issue West until we get aligned South
          if (strap_pos_x == strap_min_x) begin
            south_pop_valid = 1;
          end  // We are at the southern edge of the network
               // We cannot issue east until we get aligned Wast
          else if (strap_pos_y == strap_max_y) begin
            west_pop_valid = 1;
          end  // We are in a central mesh node and we should traverse depending
               // on the direction preference assigned to this xbar
          else begin
            south_pop_valid = strap_prefer_vertical ? 1 : 0;
            west_pop_valid  = strap_prefer_vertical ? 0 : 1;
          end
        end

        default:
        assert (({torus, north, south, east, west} == 4'b0) || (north ^ south) && (east ^ west));
      endcase
    end
  end

  always_comb begin : STALL_CTRL
    push_ready = 0;
    casez ({
      torus_pop_valid, north_pop_valid, south_pop_valid, east_pop_valid, west_pop_valid
    })
      5'b10000: push_ready = torus_pop_ready;
      5'b01000: push_ready = north_pop_ready;
      5'b00100: push_ready = south_pop_ready;
      5'b00010: push_ready = east_pop_ready;
      5'b00001: push_ready = west_pop_ready;

      // TODO(wrcunnin): this is a BAD default without the assertion
      default: begin
        // make sure this signal is one hot or zero, otw, we have a problem
        if ({torus_pop_valid, north_pop_valid, south_pop_valid, east_pop_valid, west_pop_valid})
          assert ($onehot(
              {torus_pop_valid, north_pop_valid, south_pop_valid, east_pop_valid, west_pop_valid}
          ));
        push_ready = 0;
      end
    endcase
  end

endmodule
