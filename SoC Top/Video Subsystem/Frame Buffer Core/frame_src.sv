`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/31/2024 06:45:01 PM
// Design Name: 
// Module Name: frame_src
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

//Pixel Gen. Circuit for Frame Buffer
module frame_src
#(parameter CD = 12, // Colour Depth
            DW = 9   //Data Width from Video RAM
)    
(
    input  logic clk,
    input  logic [10:0] x, y,// x-and  y-coordinate from FC
    // write port 
    input  logic [18:0] addr_pix,//video RAM addr
    input  logic [DW - 1:0] wr_data_pix,//wr data to vid ram
    input  logic write_pix,//wr en for vid ram      
    // pixel output
    output logic [CD-1:0] frame_rgb// output of circuit
);

//Signal Declaration
logic [18:0] r_addr;
logic [DW - 1: 0] r_data;//Output data from Video RAM
logic [CD-1:0] converted_color;
logic [CD-1:0] frame_reg;//Delay regester for above signal, (to output)

//Instantiate Video RAM
ram320K #(.DW(DW))  video_ram_unit
(
    .clk(clk),
    //Write Port, iinterfaced from uP
    .we(write_pix),
    .addr_w(addr_pix[18:0]),
    .data_w(wr_data_pix[DW - 1: 0]),
    //Read Port to Pipe
    .addr_r(r_addr),
    .data_r(r_data)
);

//Instantiate Palete Circuit
frame_palette palette_circuit 
(
    .color_in(r_data), .color_out(converted_color)
);

//Address Translation --> 640*y + x -->  512*y + 128*y + x --> (2^9 * y) + (2^7 * y) + x --> (y<<9) + (y<<7) + x

assign r_addr = {1'b0, y[8:0], 9'b0_0000_0000} +// y<<9 +
                {3'b000, y[8:0], 7'b000_0000} + x;// y<<7 + x
//Output Logic
//1 Cycle Delay
always_ff @(posedge clk)
    frame_reg <= converted_color;
assign frame_rgb = frame_reg;
endmodule
