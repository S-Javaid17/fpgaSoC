`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/18/2024 11:30:42 PM
// Design Name: 
// Module Name: fsm_multi_segment
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fsm_multi_segment(
        input logic clk, reset,
        input logic a, b,
        output logic y0, y1
    );
    

    typedef enum {s0, s1, s2} state_type;

    state_type state_reg, state_next; // signal declaration

                                            //State Register

    always_ff @( posedge clk, posedge reset ) 
    begin : StateRegister

        if (reset) begin
            state_reg <= s0;
        end
        else
            state_reg <= state_next;
    end

                                            //Next-State Logic

    always_comb 
    begin : NextState

        case (state_reg)
            s0: if (a) begin
                    if (b) begin
                        state_next = s2;
                    end
                    else
                        state_next = s1;
                end
                else
                    state_next = s0;
            s1: if (a) begin
                    state_next = s0;
                end
                else
                    state_next = s1;
            s2:     
                    state_next = s0;
            default: state_next = s0;
        endcase
    end
                                            //Mealy Output Logic

    assign y0 = (state_reg == s0) & (a & b);

                                            //Moore Output Logic

    assign y1 = (state_reg == s0) | (state_reg == s1);
endmodule
