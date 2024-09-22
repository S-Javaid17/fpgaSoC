`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/29/2024 05:55:08 PM
// Design Name: 
// Module Name: uart_rx
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


module uart_rx
#(parameter DBIT = 8, SB_TICK = 16)//number of data bits, and number of stop bits (ticks) per packet, respectively    
    (
        input logic clk, reset,
        input logic s_tick,
        input logic rx,
        output logic rx_done_tick,
        output logic [DBIT - 1: 0] dout
    );

                                            //Define registers and States

typedef enum { idle, start, data, stop} state_type;

state_type state_next, state_reg;//Stores the state we're in
logic [3: 0] s_next, s_reg; //stores the number of s_ticks, from the counter, that've passed
logic [$clog2(DBIT) - 1: 0] n_next, n_reg; // The number of bits that've been shifted in
logic [DBIT - 1: 0] b_next, b_reg; // Stores the actual data bits

                                            //Register Logic

always_ff @( posedge clk, posedge reset ) 
begin
    if (reset)
        begin
            state_reg <= idle;
            s_reg <= 0;
            n_reg <= 0;
            b_reg <= 0;
        end
    else
        begin
            state_reg <= state_next;
            s_reg <= s_next;
            n_reg <= n_next;
            b_reg <= b_next;
        end
end

                                            //Next State Logic
//Will implement a FSM, from an ASMD chart

always_comb 
    begin
        //defaults, covers the else statements
        state_next = state_reg;
        rx_done_tick = 1'b0;
        s_next = s_reg;
        n_next = n_reg;
        b_next = b_reg;
            case (state_reg)
                idle:
                    if (~rx) 
                        begin
                            s_next = 0;   
                            state_next = start;
                        end  
                start:
                    if (s_tick) 
                            if (s_reg == 7) 
                                begin
                                    s_next = 0;
                                    n_next = 0;
                                    state_next = data;
                                end
                            else
                                begin
                                    s_next = s_reg + 1;
                                end    
                data:
                    if (s_tick) 
                            if (s_reg == 15) 
                                begin
                                    s_next = 0;
                                    b_next = {rx, b_reg[DBIT - 1: 1]};
                                    if (n_reg == (DBIT - 1)) 
                                        state_next = stop;        
                                    else
                                        n_next = n_reg + 1;
                                end
                            else
                                    s_next = s_reg + 1;
                stop:
                    if (s_tick) 
                            if (s_reg == (SB_TICK - 1)) 
                                begin
                                    rx_done_tick = 1'b1;
                                    state_next = idle;
                                end
                            else
                                    s_next = s_reg + 1;
        endcase
end

                                            //Ouput Logic
assign dout = b_reg;
endmodule
