`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/09/2024 08:32:38 AM
// Design Name: 
// Module Name: ps2_tx
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


module ps2_tx
(
    input logic clk, reset,
    input logic wr_ps2, //wr en from processor
    input logic rx_idle,// if the Rx is idle or not
    input logic [7:0] din,//data to be transmitted
    inout tri ps2d, ps2c, 
    output logic tx_idle, tx_done_tick
);

//Internal Signals and Registers

typedef enum { idle, waitr, rts, start, data, stop} state_type;

state_type state_next, state_reg;
logic [10:0] bit_reg, bit_next;//stores actual bits
logic [3:0] n_reg, n_next;//number of bits shifted out
logic [7:0] filter_reg, filter_next;// will filter the noisy values
logic f_ps2c_next, f_ps2c_reg; //filtered ps2 clock, for negedge detection
logic fall_edge; //falling edge or not
logic [12:0] counter_reg, counter_next;
logic par; //parity bit
logic ps2d_out, ps2c_out;//prior to TSB. Routed to output
logic tri_c, tri_d;//enable signals for TSBs

//Falling-Edge Detector + Filter

always_ff @(posedge clk, posedge reset)
if (reset)
    begin
        filter_reg <= 0;
        f_ps2c_reg <= 0;
    end
else
    begin
        filter_reg <= filter_next;
        f_ps2c_reg <= f_ps2c_next;
    end

assign filter_next = {ps2c, filter_reg[7:1]};
assign f_ps2c_next = (filter_reg==8'b11111111) ? 1'b1 :
                    (filter_reg==8'b00000000) ? 1'b0 :
                        f_ps2c_reg;
assign fall_edge = f_ps2c_reg & ~f_ps2c_next;

//Implementation of FSM

always_ff @( posedge clk, posedge reset ) 
begin
    if (reset)
        begin
            state_reg <= idle;
            counter_reg <= 0;
            n_reg <= 0;
            bit_reg <= 0;
        end
    else
        begin
            state_reg <= state_next;
            counter_reg <= counter_next;
            n_reg <= n_next;
            bit_reg <= bit_next;
        end
end

// Odd Parity Bit
assign par = ~(^din);//IMO it should be xor not xnor

//Next State Logic

always_comb 
begin  
    //Defaults
    ps2c_out = 1'b1; 
    ps2d_out = 1'b1;
    tri_c = 1'b0;
    tri_d = 1'b0;
    tx_done_tick = 1'b0;
    tx_idle = 1'b0;
    counter_next = counter_reg;
    state_next = state_reg;
    bit_next = bit_reg;
    n_next = n_reg;
    
    case (state_reg)
        idle:
            begin
                tx_idle = 1'b1;
                if (wr_ps2)
                    begin
                        bit_next = {par, din};
                        counter_next = 13'h1fff;//2^13 - 1
                        state_next = waitr; 
                    end
            end
        waitr://check to make sure that Rx is in idle
            begin
                if (rx_idle)
                    state_next = rts;
            end
        rts:
            begin
                ps2c_out = 1'b0;
                tri_c = 1'b1;
                counter_next = counter_reg - 1;
                if (counter_reg == 0)
                    state_next = start;
            end
        start:
            begin
                ps2d_out = 1'b0;
                tri_d = 1'b1;
                if (fall_edge)
                    begin
                        n_next = 4'b1000;//8
                        state_next = data;
                    end
            end
        data:
            begin
                ps2d_out = bit_reg[8];
                tri_d = 1'b1;
                if (fall_edge)
                    begin
                        bit_next = {1'b0, bit_reg[8:1]}; // Shift out right
                        if(n_reg == 0)
                            state_next = stop;
                        else
                            n_next = n_reg - 1;
                    end
            end
        default: //Covers stop case
            begin
                if (fall_edge)
                begin
                    state_next = idle;
                    tx_done_tick = 1'b1;
                end
            end
    endcase
end

//InOut Tristate Logic

assign ps2c = (tri_c) ? ps2c_out : 1'bz ;
assign ps2d = (tri_d) ? ps2d_out : 1'bz ;
endmodule
