`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/19/2024 12:00:03 AM
// Design Name: 
// Module Name: fsm_two_segment
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

//basically just incorporate the mealy and moore outputs into the next-state logic block
module fsm_two_segment(
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
        y1 = 1'b0;//def
        y0 = 1'b0;
        state_next = s0;
        case (state_reg)
            s0: if (a) 
                begin
                    y1 = 1'b1;    
                        if (b) begin
                            state_next = s2;
                            y0 = 1'b1;
                        end
                        else
                            state_next = s1;
                end
                else
                    state_next = s0;
            s1: if (a) 
                begin
                    y1 = 1'b1; 
                    state_next = s0;
                end
                else
                    state_next = s1;
            s2:     
                    state_next = s0;
            default: state_next = s0;
        endcase
    end
endmodule
