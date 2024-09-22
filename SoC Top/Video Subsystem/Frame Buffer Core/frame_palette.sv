`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/31/2024 07:16:14 PM
// Design Name: 
// Module Name: frame_palette
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

//Will convert 9 bit pixel color, from video RAM to 12 bit
module frame_palette
(
    input logic [8:0] color_in,
    output logic [11:0] color_out
);

//Internal Signal
logic [2:0] r_in, g_in, b_in;
logic [3:0] r_out, g_out, b_out;

//Body
//From RAM
assign r_in = color_in[8:6];
assign g_in = color_in[5:3];
assign b_in = color_in[2:0];
//Extended Color Palette
assign r_out = {r_in, r_in[2]};
assign g_out = {g_in, g_in[2]};
assign b_out = {b_in, b_in[2]};

//Output Logic
assign color_out = {r_out, g_out, b_out};
endmodule
