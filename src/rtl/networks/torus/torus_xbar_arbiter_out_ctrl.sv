/*

Author: William Cunningham
Date  : 04/18/2026

Description:
    Output control for any direction, implementing LRU scheduling

*/

import packet_pkg::*;

module torus_xbar_arbiter_out_ctrl (
    input logic CLK, nRST,

    // Output is being stalled
    input logic net_stall_tx,

    // Enable the writing of the packet
    output logic net_en_tx,

    // Packet to transmit
    output net_packet_t net_packet_tx,

    // Stall the inputs
    output logic [3:0] net_stall_rx,

    // Indicates an input is wanting to send through this output
    input logic [3:0] net_en_rx,

    // To stall the outputs
    input net_packet_t [3:0] net_packet_rx
);

typedef logic [1:0] lru_state_t;
lru_state_t [3:0] lru;

logic [3:0] input_to_send;
logic [2:0] input_to_send_idx;
logic is0gt1, is0gt2, is0gt3, is1gt2, is1gt3, is2gt3;

assign is0gt1 = lru[0] > lru[1];
assign is0gt2 = lru[0] > lru[2];
assign is0gt3 = lru[0] > lru[3];
assign is1gt2 = lru[1] > lru[2];
assign is1gt3 = lru[1] > lru[3];
assign is2gt3 = lru[2] > lru[3];

always_ff @( posedge CLK, negedge nRST ) begin : LRU_STATE
    if (!nRST) begin
        lru[0] <= 2'd0;
        lru[1] <= 2'd1;
        lru[2] <= 2'd2;
        lru[3] <= 2'd3;
    end else if (!net_stall_tx) begin
        if (input_to_send[0]) begin
            lru[0] <= 2'd0;
            lru[1] <= updateTorusLRU(is1gt2, is1gt3);
            lru[2] <= updateTorusLRU(!is1gt2, is2gt3);
            lru[2] <= updateTorusLRU(!is1gt3, is2gt3);
        end
        else if (input_to_send[1]) begin
            lru[0] <= updateTorusLRU(is0gt2, is0gt3);
            lru[1] <= 2'd0;
            lru[2] <= updateTorusLRU(!is0gt2, is2gt3);
            lru[3] <= updateTorusLRU(!is0gt3, !is2gt3);
        end
        else if (input_to_send[2]) begin
            lru[0] <= updateTorusLRU(is0gt1, is0gt3);
            lru[1] <= updateTorusLRU(!is0gt1, is1gt3);
            lru[2] <= 2'd0;
            lru[3] <= updateTorusLRU(!is0gt3, !is1gt3);
        end
        else if (input_to_send[3]) begin
            lru[0] <= updateTorusLRU(is0gt1, is0gt2);
            lru[1] <= updateTorusLRU(!is0gt1, is1gt2);
            lru[2] <= updateTorusLRU(!is0gt2, !is1gt2);
            lru[3] <= 2'd0;
        end
    end
end

always_comb begin : INPUT_TO_SEND_CTRL
    input_to_send = '0;
    input_to_send_idx = 4;  // probably doesn't need to 4, but this is unused so it's fine

    casez({net_en_rx[0], net_en_rx[1], net_en_rx[2], net_en_rx[3], is0gt1, is0gt2, is0gt3, is1gt2, is1gt3, is2gt3})
        // We should send input 0
        10'b1000??????, // 0 en, nothing else
        10'b1???111???, // 0 en, and LRU
        10'b1001??1???, // 0 & 3 en, and 0 > 3
        10'b1010?1????, // 0 & 2 en, and 0 > 2
        10'b11001?????, // 0 & 1 en, and 0 > 1
        10'b1011?11???, // 0, 2, & 3 en, and 0 > 2 & 0 > 3
        10'b11011?1???, // 0, 1, & 3 en, and 0 > 1 & 0 > 3
        10'b111011????: begin // 0, 1, & 2 en, and 0 > 1 & 0 > 2
            input_to_send[0] = 1;
            input_to_send_idx = 0;
        end

        // We should send input 1
        10'b0100??????, // 1 en, nothing else
        10'b?1??0??11?, // 1 en, and LRU
        10'b0101????1?, // 1 & 3 en, and 1 > 3
        10'b0110???1??, // 1 & 2 en, and 1 > 2
        10'b11000?????, // 0 & 1 en, and 0 < 1
        10'b0111???11?, // 1, 2, & 3 en, and 1 > 2 & 1 > 3
        10'b11010???1?, // 0, 1, & 3 en, and 0 < 1 & 1 > 3
        10'b11100??1??: begin // 0, 1, & 2 en, and 0 < 1 & 1 > 2
            input_to_send[1] = 1;
            input_to_send_idx = 1;
        end

        // We should send input 2
        10'b0010??????, // 2 en, nothing else
        10'b??1??0?0?1, // 2 en, and LRU
        10'b0011?????1, // 2 & 3 en, and 2 > 3
        10'b0110???0??, // 1 & 2 en, and 1 < 2
        10'b1010?0????, // 0 & 2 en, and 0 < 2
        10'b0111???0?1, // 1, 2, & 3 en, and 1 < 2 & 2 > 3
        10'b1011?0???1, // 0, 2, & 3 en, and 0 < 2 & 2 > 3
        10'b1110?0?0??: begin // 0, 1, & 2 en, and 0 < 2 & 1 < 2
            input_to_send[2] = 1;
            input_to_send_idx = 2;
        end

        // We should send input 3
        10'b0001??????, // 3 en, nothing else
        10'b???1??0?00, // 3 en, and LRU
        10'b0011?????0, // 2 & 3 en, and 2 < 3
        10'b0101????0?, // 1 & 3 en, and 1 < 3
        10'b1001??0???, // 0 & 3 en, and 0 < 3
        10'b0111????00, // 1, 2, & 3 en, and 1 < 3 & 2 < 3
        10'b1011??0??0, // 0, 2, & 3 en, and 0 < 3 & 2 < 3
        10'b1101??0?0?: begin  // 0, 1, & 3 en, and 0 < 3 & 1 < 3
            input_to_send[3] = 1;
            input_to_send_idx = 3;
        end

        // Nothing matching
        // TODO(wrcunnin): this could have major bugs...
        default: begin
            input_to_send = '0;
            input_to_send_idx = 4;
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

function lru_state_t updateTorusLRU;
    input logic cond1;
    input logic cond2;

    updateTorusLRU = cond1 && cond2 ? 2'd3 :
                        cond1 ^ cond2 ? 2'd2 : 2'd1;
endfunction

endmodule