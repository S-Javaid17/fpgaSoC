`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/27/2024 09:23:27 PM
// Design Name: 
// Module Name: vga_synch_circuit
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

//Implements the entire synchronization circuit
//Simplified demo
//refer to notes
module vga_synch_circuit
#(parameter CD =12)//colour depth
(
    input logic clk, reset,
//Stream Input
    input logic [CD - 1: 0] vga_si_rgb, //vga stream input data
//To VGA monitor
    output logic hsync, vsync,
    output logic [CD - 1: 0] rgb,
//Frame Counter Output
    output logic [10:0] hc, vc
);

//Local parameter declaration for a 640x480 vga
        //Useful for adjusting according to need/monitor specs

localparam HD = 640;  // horizontal display area
localparam HF = 16;   // h. front porch
localparam HB = 48;   // h. back porch
localparam HR = 96;   // h. retrace
localparam HT = HD+HF+HB+HR; // horizontal total (800)

localparam VD = 480;  // vertical display area
localparam VF = 10;   // v. front porch
localparam VB = 33;   // v. back porch
localparam VR = 2;    // v. retrace
localparam VT = VD+VF+VB+VR; // vertical total (525)

//Internal Signal Declaration

logic [1:0] q_reg;//modulo 4 counter register
logic tick_25M;//will be the enable signal for the counter increment
logic [10:0] x, y;//hc and vc
logic hsync_i, vsync_i, video_on_i;
logic hsync_reg, vsync_reg;
logic [CD - 1: 0] rgb_reg;

//Mod 4 counter --> 25 Mhz clk

always_ff @( posedge clk) 
begin
    q_reg <= q_reg + 1;
end

assign tick_25M = (q_reg == 2'b11) ? 1 : 0;//assert every 4 system clock cycles

//Frame Counter Instantiation

frame_counter #(.HMAX(HT), .VMAX(VT)) frame_unit 
(
    .clk(clk), .reset(reset), .sync_clr(0), 
    .hcount(x), .vcount(y), 
    .inc(tick_25M), .frame_start(), .frame_end()
);

//Horizontal Sync Decoding
assign hsync_i = ((x >= (HD + HF)) && (x <= (HD + HF + HR - 1))) ? 0 : 1;// hsync is only low between 656 --> 751

//Vertical Sync Decoding
assign vsync_i = ((y >= (VD + VF)) && (y <= (VD + VF + VR - 1))) ? 0 : 1; // vsync is only low between 490 --> 591

//On/Off Display
assign video_on_i = ((x < HD) && (y < VD)) ? 1: 0;// pixel display area


//Stream Control Unit / Buffered output to VGA
always_ff @( posedge clk ) 
begin
    vsync_reg <= vsync_i;
    hsync_reg <= hsync_i;

    if (video_on_i)//multiplexer circuit
        rgb_reg <= vga_si_rgb;
    else
        rgb_reg <= 0; //Black when display is off
end

//Output Logic

assign hsync = hsync_reg;
assign vsync = vsync_reg;
assign rgb = rgb_reg;
assign hc = x;
assign vc = y;
endmodule
