`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/29/2024 05:55:30 PM
// Design Name: 
// Module Name: uart_tx
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


module uart_tx
#(parameter DBIT = 8, SB_TICK = 16)//number of data bits, and number of stop bits (ticks) per packet, respectively    
    (
        input logic clk, reset,
        input logic s_tick,
        input logic tx_start,
        input logic [DBIT - 1: 0] din,
        output logic tx,
        output logic tx_done_tick
    );

                                            //Define registers and States

typedef enum { idle, start, data, stop} state_type;

state_type state_next, state_reg;//Stores the state we're in
logic [3: 0] s_next, s_reg; //stores the number of s_ticks, from the counter, that've passed
logic [$clog2(DBIT) - 1: 0] n_next, n_reg; // The number of bits that've been shifted out
logic [DBIT - 1: 0] b_next, b_reg; // Stores the actual data bits from the fifo
logic tx_reg, tx_next; //stores the value to be shifted out

                                            //Register Logic

always_ff @( posedge clk, posedge reset ) 
begin
    if (reset)
        begin
            state_reg <= idle;
            s_reg <= 0;
            n_reg <= 0;
            b_reg <= 0;
            tx_reg <= 1'b1;//keep the line on high
        end
    else
        begin
            state_reg <= state_next;
            s_reg <= s_next;
            n_reg <= n_next;
            b_reg <= b_next;
            tx_reg <= tx_next;
        end
end

                                            //Next State Logic
//Will implement a FSM, from an ASMD chart

always_comb 
    begin
        //defaults, covers the else statements
        state_next = state_reg;
        tx_done_tick = 1'b0;
        s_next = s_reg;
        n_next = n_reg;
        b_next = b_reg;
        tx_next = tx_reg;
            case (state_reg)
                idle:
                    begin
                        tx_next = 1'b1;
                        if (tx_start) 
                            begin
                                s_next = 0;
                                b_next = din;    
                                state_next = start;
                            end
                    end
                start:
                    begin
                        tx_next = 1'b0;
                        if (s_tick) 
                            if (s_reg == 15) 
                                begin
                                    s_next = 0;
                                    n_next = 0;
                                    state_next = data;
                                end
                            else
                                    s_next = s_reg + 1;
                    end    
                data:
                    begin
                        tx_next = b_reg[0];
                        if (s_tick) 
                                if (s_reg == 15) 
                                    begin
                                        s_next = 0;
                                        b_next = b_reg >> 1;
                                        if (n_reg == (DBIT - 1)) 
                                            state_next = stop;        
                                        else
                                            n_next = n_reg + 1;
                                    end
                                else
                                        s_next = s_reg + 1;
                    end
                stop:
                    begin
                        tx_next = 1'b1;
                        if (s_tick) 
                                if (s_reg == (SB_TICK - 1)) 
                                    begin
                                        tx_done_tick = 1'b1;
                                        state_next = idle;
                                    end
                                else
                                        s_next = s_reg + 1;
                    end
            endcase
    end

                                            //Ouput Logic
assign tx = tx_reg;
endmodule
