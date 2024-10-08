`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/19/2024 10:44:42 PM
// Design Name: 
// Module Name: rising_edge_detect_moore
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


module rising_edge_detect_moore(
        input logic clk, reset,
        input logic level,
        output logic tick
    );

    //fsm state types
    typedef enum  { zero, edg, one } state_type;

    // signal declaration
    state_type state_next, state_reg;


    //[1] State Register Logic
    always_ff @( posedge clk, posedge reset ) 
    begin : RegisterLogic
        if (reset) 
        begin
            state_reg <= zero;
        end
        else
            state_reg <= state_next;
    end

    //[2] Next-State Logic
    always_comb 
    begin : NextStateLogic
    state_next = zero;    
        case (state_reg)
            zero: 
                if (level) 
                begin
                    state_next = edg;
                end
                else
                    state_next = zero;
            edg: 
                if (level) 
                begin
                    state_next = one;
                end
                else
                    state_next = zero;
            one: 
                if (level) 
                begin
                    state_next = one;
                end
                else
                    state_next = zero;

            default: state_next = zero;
        endcase
    end

    //Output Logic
    assign tick = (state_reg == edg);

endmodule
