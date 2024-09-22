`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/31/2024 06:47:45 PM
// Design Name: 
// Module Name: osd_src
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

//OSD pixel generation circuit
module osd_src
#(parameter CD = 12,// colour depth
            KEY_COLOR = 0//Chroma key
)
(
    input logic clk,
    input logic [10:0] x, y,//x and y from FC
    //Tile ram wr port
    input logic [6:0] xt,//tile coordinates from cpu
    input logic [4:0] yt,// tile coordinates from cpu
    input logic [7:0] ch_in,//character which the cpu wants to write
    input logic we_ch,//character wr en
    //Forground/background color of char tile
    input  logic [CD-1:0] front_rgb, back_rgb,
    //Pixel output
    output logic [CD-1:0] osd_rgb
);

//localparam declaration
    localparam NULL_CHAR = 7'b000_0000;  

//Internal Signal Declaration, (refer to notes)

//font ROM
    logic [6:0] char_addr;//char_out
    logic [10:0] rom_addr;
    logic [3:0] row_addr;
    logic [2:0] bit_addr;
    logic [7:0] font_word;
//character tile RAM
   logic [11:0] addr_w, addr_r;
   logic [7:0] ch_ram_out;//becomes char_addr
   logic [7:0] ch_d1_reg;// the above signal is delayed 1 cycl
//Delay Registers
logic [2:0] x_delay1_reg, x_delay2_reg;
logic [3:0] y_delay1_reg;
//Colour control signals
logic font_bit, rev_bit;
logic [CD - 1: 0] f_rgb, b_rgb, p_rgb;


//Memory Instantiation

font_rom font_unit
(
    .clk(clk),
    .addr(rom_addr),
    .data(font_word)
);

sync_rw_port_ram #(.ADDR_WIDTH(12), .DATA_WIDTH(8)) text_ram_unit
(
    .clk(clk),
    // write from main system
    .we(we_ch), .addr_w(addr_w), .din(ch_in),
    // read to vga
    .addr_r(addr_r), .dout(ch_ram_out)
);
assign addr_w = {yt, xt};//same as (yt << 7) + xt

//Delay Registers

always_ff @( posedge clk ) 
begin
    y_delay1_reg <= y[3:0];
    x_delay1_reg <= x[2:0];
    x_delay2_reg <= x_delay1_reg;
    ch_d1_reg <= ch_ram_out;
end

//Pixel Data Reading (refer to diagram)

assign addr_r = {y[8:4], x[9:3]};
assign char_addr = ch_ram_out[6:0];//the 7 LSbs (ascii code)
//font ROM
assign row_addr = y_delay1_reg;
assign rom_addr = {char_addr, row_addr};
//Bit selector
assign bit_addr = x_delay2_reg;//select signal for mux
assign font_bit = font_word[~bit_addr];//we negate the mux signal since the font_word data is arranged as MSB-->signal 0, LSB --> signal 7
                                       //whereas the bit_addr expects signal 000 to correspond to the LSB. Thus we need the signal's complement

//Reverse Colour Control
    
//Allows inverting/switching the BG and FG with eachother
assign rev_bit = ch_d1_reg[7];// the MSB of the delayed character address signal is the invert bit 
assign f_rgb = (rev_bit) ? (back_rgb) : (front_rgb);// if the reverse bit is asserted, change the FG colour to the BG colour
assign b_rgb = (rev_bit) ? (front_rgb) : (back_rgb);// likewise, change the BG colour to the FG colour
//Palette Circuit
assign p_rgb = (font_bit) ? f_rgb : b_rgb;
//Transparency
assign osd_rgb = (ch_d1_reg[6:0]==NULL_CHAR) ? KEY_COLOR : p_rgb;// if a null character is being addressed, just output the chromakey,
                                                                // if not, then output the intended colour for that pixel bit.
endmodule
