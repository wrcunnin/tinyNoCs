/*

Author: William Cunningham
Date  : 04/10/2026

Description:
    Output control for any direction, implementing LRU scheduling

*/

import packet_pkg::*;

module mesh_xbar_arbiter_out_ctrl (
    input logic CLK, nRST,

    // Output is being stalled
    input logic net_stall_tx,

    // Enable the writing of the packet
    output logic net_en_tx,

    // Packet to transmit
    output net_packet_t net_packet_tx,

    // Stall the inputs
    output logic [2:0] net_stall_rx,

    // Indicates an input is wanting to send through this output
    input logic [2:0] net_en_rx,

    // To stall the outputs
    input net_packet_t [2:0] net_packet_rx
);

typedef logic [1:0] lru_state_t;
lru_state_t [2:0] lru;

logic [2:0] input_to_send;
logic [1:0] input_to_send_idx;
logic is0gt1, is0gt2, is1gt2;

assign is0gt1 = lru[0] > lru[1];
assign is0gt2 = lru[0] > lru[2];
assign is1gt2 = lru[1] > lru[2];

always_ff @( posedge CLK, negedge nRST ) begin : LRU_STATE
    if (!nRST) begin
        lru[0] <= 2'd0;
        lru[1] <= 2'd1;
        lru[2] <= 2'd2;
    end else if (!net_stall_tx) begin
        if (input_to_send[0]) begin
            lru[0] <= 2'd0;
            lru[1] <= is1gt2 ? 2'd2 : 2'd1;
            lru[2] <= is1gt2 ? 2'd1 : 2'd2;
        end
        else if (input_to_send[1]) begin
            lru[0] <= is0gt2 ? 2'd2 : 2'd1;
            lru[1] <= 2'd0;
            lru[2] <= is0gt2 ? 2'd1 : 2'd2;
        end

        else if (input_to_send[2]) begin
            lru[0] <= is0gt1 ? 2'd2 : 2'd1;
            lru[1] <= is0gt1 ? 2'd1 : 2'd2;
            lru[2] <= 2'd0;
        end
    end
end

always_comb begin : INPUT_TO_SEND_CTRL
    input_to_send = '0;
    input_to_send_idx = 3;  // probably doesn't need to 3, but this is unused so it's fine

    casez({net_en_rx[0], net_en_rx[1], net_en_rx[2], is0gt1, is0gt2, is1gt2})
        // We should send input 0
        6'b100???,
        6'b1??11?,
        6'b101?1?,
        6'b1101??: begin
            input_to_send[0] = 1;
            input_to_send_idx = 0;
        end

        // We should send input 1
        6'b010???,
        6'b?1?0?1,
        6'b1100??,
        6'b011??1: begin
            input_to_send[1] = 1;
            input_to_send_idx = 1;
        end

        // We should sent input 2
        6'b001???,
        6'b??1?00,
        6'b101?0?,
        6'b011??0: begin
            input_to_send[2] = 1;
            input_to_send_idx = 2;
        end

        // Nothing matching
        // TODO(wrcunnin): this could have major bugs...
        default: begin
            input_to_send = '0;
            input_to_send_idx = 3;
        end
    endcase 
end

always_comb begin : OUTPUT_CTRL
    net_packet_tx = '0;
    net_en_tx = 0;
    net_stall_rx = '1;

    if (!net_stall_tx && input_to_send) begin
        net_packet_tx = net_packet_rx[input_to_send_idx];
        net_en_tx = 1;
        net_stall_rx[input_to_send_idx] = 0;
    end
end

endmodule