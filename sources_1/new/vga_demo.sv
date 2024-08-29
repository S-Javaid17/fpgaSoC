`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/28/2024 09:13:06 PM
// Design Name: 
// Module Name: vga_demo
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


module vga_demo
#(parameter CD = 12)//colour depth
(
    input logic clk,
    input logic [13:0] sw,
    //to VGA monitor
    output logic hsync, vsync,
    output logic [CD - 1: 0] rgb
);

// logic [CD-1:0] declaration

    logic [10:0] hc, vc;
    logic [CD-1:0] bar_rgb; //test pattern gen. to mux
    logic [CD-1:0] back_rgb; //connected to switches, bypassing test pattern
    logic [CD-1:0] gray_rgb; //grayscale conversion to mux
    logic [CD-1:0] color_rgb; //rgb output from first mux (either from test pattern, or switches)
    logic [CD-1:0] vga_rgb;//output of second mux, to vga display
    logic [CD-1:0] bypass_bar;//mux1 signal, to switch
    logic [CD-1:0] bypass_gray;//mux2 signal, to switch 

//Assign switches

assign back_rgb = sw[11:0];
assign bypass_bar = sw[12];
assign bypass_gray = sw[13];

//Instantiate test patter generator

bar_demo test_pattern_gen 
(
    .x(hc),
    .y(vc),
    .bar_rgb(bar_rgb)
);

//Instantiate RGB to Grayscale converter

rgb2gray colour_to_grayscale_unit
(
    .color_rgb(color_rgb),
    .gray_rgb(gray_rgb)
);

//Instantiate video synchronization circuit
vga_synch_circuit #(.CD(CD)) synchronization_unit
(
    .clk(clk), .reset(0), 
    .vga_si_rgb(vga_rgb),
    .hsync(hsync), .vsync(vsync), .rgb(rgb), 
    .hc(hc), .vc(vc)
);

//Mux 1
assign color_rgb = (bypass_bar) ? back_rgb : bar_rgb;

//Mux 2
assign vga_rgb = (bypass_gray) ? (color_rgb) : (gray_rgb);
endmodule
