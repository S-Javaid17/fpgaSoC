`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/29/2024 11:41:42 PM
// Design Name: 
// Module Name: vga_bar_core
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

//Wrapping circuit for bar test pattern generator
module vga_bar_core
(
    input logic clk, reset,
    //Frame counter (global)
    input logic [10:0] x, y,
    //Video slot interface
    input logic cs,
    input logic write,//en
    input logic [13:0] addr,
    input logic [31:0] wr_data,
    //Stream interface
    input logic [11:0] si_rgb,//input pixel data
    output logic [11:0] so_rgb//output pixel data
);

//Signal declaration
logic wr_en;
logic bypass_reg;//mux signal
logic [11:0] bar_rgb; //output of pixel gen circuit

//Bar Gen. Instantiation
bar_gen bar_pattern_generator
(
    .clk(clk),
    .x(x), .y(y),
    .bar_rgb(bar_rgb)
);

//Register logic
always_ff @( posedge clk, posedge reset ) 
begin
    if (reset)
        bypass_reg <= 1;
    else if (wr_en)
        bypass_reg <= wr_data[0]; //lsb of data is the mux signal
end

//Decoding logic
assign wr_en = write & cs;

//Blending/Bypass mux

assign so_rgb = bypass_reg ? (si_rgb) : (bar_rgb);//if asserted, assign output to input, without pixel gen. circuit
endmodule
