`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/31/2024 06:40:20 PM
// Design Name: 
// Module Name: vga_sprite_mouse_core
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


module vga_sprite_mouse_core
#(parameter CD = 12,//colour depth
            ADDR = 10,//addr bits
            KEY_COLOR = 0//chroma key --> black
)
(
    input logic clk, reset,
    //FC
    input logic [10:0] x, y,//x and y coordinates from FC
    //Video slot interface
    input  logic cs,      
    input  logic write,  
    input  logic [13:0] addr,    
    input  logic [31:0] wr_data,
    //Stream interface
    input  logic [11:0] si_rgb,
    output logic [11:0] so_rgb
);

//Signal Declaration, refer to reg map
logic wr_en;
logic wr_ram;//write to ram (en) 
logic wr_reg;//write to a control register (en) 
logic wr_bypass;// en for 0x2000 
logic wr_x0, wr_y0;//en for x0 and y0 locations in reg map

logic [CD - 1: 0] mouse_rgb;// mouse sprite gen. circuit output (foreground)
logic [CD - 1: 0] chrom_rgb;// blended output of pixel gen. circuit
logic [10:0] x0_reg, y0_reg;// x0 and y0 reg values 
logic bypass_reg;// mux signal

//Instantiate mouse sprite generator
mouse_src #(.CD(12), .KEY_COLOR(0)) mouse_src_unit 
(
    .clk(clk), 
    .x(x), .y(y), 
    .x0(x0_reg), .y0(y0_reg),
    .we(wr_ram), .addr_w(addr[ADDR - 1: 0]),
    .pixel_in(wr_data[CD - 1: 0]), 
    .mouse_rgb(mouse_rgb)
);

//Register Logic
always_ff @( posedge clk, posedge reset) 
begin
    if (reset)
        begin
            x0_reg <= 0;
            y0_reg <= 0;
            bypass_reg <= 0;
        end
    else
        begin
            if (wr_x0)
                x0_reg <= wr_data[10:0];
            if (wr_y0)
                x0_reg <= wr_data[10:0];
            if (wr_bypass)
                bypass_reg <= wr_data[0];
        end
end

//NOTE:
// "&" --> bitwise AND. Performs an AND operation on individual corresponding bits (EX. 010 & 110 --> 010)
// "&&" --> logical AND. The operands are treated as (boolean) expressions, and an output of 1 or 0 is returned if both are true or not. (EX. wr_reg && (addr[1:0] == 2'b00) --> True / False)
//Decoding Logic
assign wr_en = write & cs;
assign wr_ram = ~addr[13] && wr_en;// write to ram registers if msb of addr is 0
assign wr_reg =  addr[13] && wr_en;// write to control registers if msb of addr is 1
assign wr_bypass = wr_reg && (addr[1:0] == 2'b00);
assign wr_x0 = wr_reg && (addr[1:0] == 2'b01);
assign wr_y0 = wr_reg && (addr[1:0] == 2'b10);

//Chromakey blending

//si_rgb is the background b, mouse_rgb is the foreground f, and chrom_rgb is r, and KEY_COLOR is Ck
assign chrom_rgb = (mouse_rgb != KEY_COLOR) ? (mouse_rgb) : (si_rgb);//if the mouse_rgb/pixel gen output aka foreground, is NOT the chromakey colour, route the foreground pixel to the output,
                                                                     //otherwise (if it is the chromakey colour), route the background to the output.
                                                                     //the latter would be true if the FC pixel was out of sprite region boundary
//Bypass Mux
assign so_rgb = (bypass_reg) ? si_rgb : chrom_rgb; //if bypass, route input to output, otherwise route blended sprite data to output
endmodule
