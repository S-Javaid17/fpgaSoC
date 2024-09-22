`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/09/2024 05:24:59 AM
// Design Name: 
// Module Name: ps2_rx
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


module ps2_rx
(
    input logic clk, reset,
    input logic ps2d, ps2c,
    input logic rx_en,
    output logic [7:0] dout,
    output logic rx_done_tick,
    output logic rx_idle
);

//Signal and Register Declaration

typedef enum { idle, dps, load } state_type;

state_type state_next, state_reg;
logic [10:0] bit_reg, bit_next;//stores actual bits
logic [3:0] n_reg, n_next;//number of bits shifted in
logic [7:0] filter_reg, filter_next;// will filter the noisy values
logic f_ps2c_next, f_ps2c_reg; //filtered ps2 clock, for negedge detection
logic fall_edge; //falling edge or not

//Falling Edge-Detection

always_ff @( posedge clk, posedge reset ) 
begin
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
end

assign filter_next = {ps2c, filter_reg[7:1]};//right shift in the ps2 clock values

assign f_ps2c_next = (filter_reg == 8'b1111_1111) ? 1'b1 ://has the signal been stable at 1 for 8 (system) clk cycles, if yes, the pclk should be 1
                     (filter_reg == 8'b0000_0000) ? 1'b0 ://same question for 0
                     f_ps2c_reg;//if neither of the above, let the filtered pclk retain its value

assign fall_edge = f_ps2c_reg & ~f_ps2c_next;//currently at 1 and next state is 0

//Implementation of FSMD

always_ff @( posedge clk, posedge reset ) 
begin
    if (reset)
    begin
        state_reg <= idle;
        bit_reg <= 0;
        n_reg <= 0;
    end
    else
    begin
        state_reg <= idle;
        bit_reg <= bit_next;
        n_reg <= n_next;
    end
end

//Next State Logic

always_comb 
begin
    state_next = state_reg;
    bit_next = bit_reg;
    n_next = n_reg;
    rx_idle = 1'b0;
    rx_done_tick = 1'b0;

    case (state_reg)
        idle:
            begin
                rx_idle = 1'b1;
                if (rx_en && fall_edge)
                    begin
                        bit_next = {ps2d, bit_reg[10:1]};//shift in (right) the data value
                        n_next = 4'b1001;//9
                        state_next = dps;
                    end
            end
        dps:
            begin
                if (fall_edge)
                    begin
                        bit_next = {ps2d, bit_reg[10:1]};
                        if (n_reg == 0)
                            state_next = load;
                        else
                            n_next = n_reg - 1;
                    end
            end
        default://Covers load case
            begin
                rx_done_tick = 1'b1;
                state_next = idle;
            end 
    endcase
end

//Output Logic

assign dout = bit_reg[8:1];//ignore the LSb (start) and the two MSbs (parity and stop)
endmodule
