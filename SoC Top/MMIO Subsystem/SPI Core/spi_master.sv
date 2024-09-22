`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/06/2024 01:50:05 AM
// Design Name: 
// Module Name: spi_master
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


module spi_master
(
    input logic clk, reset,
    input logic [15:0] dvsr,//value corresponding to half the period of the SCLK clock aka twice the freq 
    input logic [7:0] din,
    input logic miso,
    input logic start, cpol, cpha,//start signal, clock polarity, clock phase
    output logic [7:0] dout,
    output logic mosi,
    output logic sclk,//spi clock
    output logic spi_done_tick, 
    output logic ready//lets processor know data can be transmitted (idle state)
);

//State Registers

typedef enum { idle, cpha_delay, p0, p1 } state_type;

//Register Declaration

state_type state_next, state_reg;
logic [15: 0] c_next, c_reg;//stores  the counter which will be compared to the dvsr
logic [2: 0] n_next, n_reg;//the number of bits that've been shifted so far
logic [7: 0] so_next, so_reg;//serial out, from master
logic [7: 0] si_next, si_reg;//serial in
logic p_clk; //clock mode
logic spi_clk_reg, spi_clk_next;//spi clock
logic ready_i, spi_done_tick_i;//internal signals

//Register Logic

always_ff @( posedge clk, posedge reset ) 
begin
    if (reset)
        begin
            state_reg <= idle;
            si_reg <= 0;
            so_reg <= 0;
            c_reg <= 0;
            n_reg <= 0;
            spi_clk_reg <= 0;
        end
    else
        begin
            state_reg <= state_next;
            si_reg <= si_next;
            so_reg <= so_next;
            c_reg <= c_next;
            n_reg <= n_next;
            spi_clk_reg <= spi_clk_next;
        end
end

//Next State Logic

always_comb 
begin
    //Defaults
    state_next = state_reg;
    si_next = si_reg;
    so_next = so_reg;
    c_next = c_reg;
    n_next = n_reg;
    spi_done_tick_i = 0;
    ready_i = 0;

    case (state_reg)
        idle:
            begin
                ready_i = 1'b1;
                if (start)
                    begin
                        c_next = 0;
                        n_next = 0;
                        so_next = din;
                            if (cpha) 
                                state_next = cpha_delay;//phase delay by half a sclk cycle
                            else
                                state_next = p0;
                    end
            end
        cpha_delay: 
            begin
                if(c_reg == dvsr)
                    begin
                        state_next = p0;
                        c_next = 0;
                    end
            end
        p0: //high to low
            begin
                if (c_reg == dvsr) 
                    begin
                        c_next = 0;
                        si_next = {si_reg[6:0], miso}; //shift out MSb, and put in the miso bit into the LSb
                        state_next = p1;
                    end
                else
                    c_next = c_reg + 1;
            end
        p1: //low to high        
            begin
                if (c_reg == dvsr) 
                        if (n_reg == 7) 
                            begin
                                spi_done_tick_i = 1'b1;
                                state_next = idle;
                            end
                        else
                            begin
                                c_next = 0;
                                so_next = {so_reg[6:0], 1'b0}; //shift out MSb, and put in the a 0 bit into the LSb of the serial out reg
                                state_next = p0;
                                n_next = n_reg + 1;
                            end
                else
                    c_next = c_reg + 1;
            end
    endcase
end
assign ready = ready_i;
assign spi_done_tick = spi_done_tick_i;

//Lookahead (output) Decoding

assign p_clk = ((state_next == p1) && ~cpha)  ||  (((state_next == p0) && cpha));//Covers mode 0 and mode 1, respectively
//since in p1, the Sclock is low(-->high) and phase shift is de-asserted, and in p0, the sclk is high(-->low) and phase shift is asserted
assign spi_clk_next = (cpol) ? ~p_clk : p_clk;// the negating branch covers mode 2 and 3, since they are the opposite of whatever modes 0 and 1 may be

//Output Logic

assign dout = si_reg;//data to be read from spi master, by the processor
assign mosi = so_reg[7];//data to be sent to slave, bit by bit
assign sclk = spi_clk_reg;//spi clock (registered to avoid glitches)
endmodule
