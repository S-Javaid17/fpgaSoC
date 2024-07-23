`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/19/2024 11:18:51 PM
// Design Name: 
// Module Name: delayed_debouncer
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


module delayed_debouncer(
        input logic clk, reset,
        input logic sw,
        output logic debounced
    );

    //Counter Instantiation

    logic m_tick; //internal output signal from counter
    mod_m_counter #(.M(1_000_000)) ticker //10 ms counter
    (
        .clk(clk),
        .reset(reset),
        .q(),
        .max_tick(m_tick)
    );

    //FSM State Types

    typedef enum {zero, wait1_1, wait1_2, wait1_3, one, wait0_1, wait0_2, wait0_3} state_type;

    //Signal Declaration

    state_type state_reg, state_next;

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

    //[2] Next State Logic

    always_comb
        begin
            case(state_reg)
                zero:
                        if(sw)
                            state_next = wait1_1;
                        else
                            state_next = zero;
                wait1_1:
                        if(sw)
                            if(m_tick)
                                state_next = wait1_2;
                            else
                                state_next = wait1_1;
                        else
                            state_next = zero;
                wait1_2:
                        if(sw)
                            if(m_tick)
                                state_next = wait1_3;
                            else
                                state_next = wait1_2;
                        else
                            state_next = zero;                   
                wait1_3:
                        if(sw)
                            if(m_tick)
                                state_next = one;
                            else 
                                state_next = wait1_3;
                        else
                            state_next = zero;    
                one:
                        if(~sw)
                            state_next = wait0_1;
                        else
                            state_next = one;
                wait0_1:
                        if(~sw)
                            if(~m_tick)
                                state_next = wait0_1;
                            else
                                state_next = wait0_2;
                        else
                            state_next = one;
                wait0_2:
                        if(~sw)
                            if(~m_tick)
                                state_next = wait0_2;
                            else 
                                state_next = wait0_3;
                        else
                            state_next = one;                   
                wait0_3:
                        if(~sw)
                            if(~m_tick)
                                state_next = wait0_3;
                            else
                                state_next = zero;
                        else
                            state_next = one; 
                default: state_next = zero;
            endcase
        end
        
        // Moore output logic
        assign debounced = (    (state_reg == one) || 
                            (state_reg == wait0_1) || 
                            (state_reg == wait0_2) || 
                            (state_reg == wait0_3));
endmodule

