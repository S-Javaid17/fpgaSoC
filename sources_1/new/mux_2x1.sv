`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/16/2024 01:08:36 AM
// Design Name: 
// Module Name: mux_2x1
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


module mux_2x1(
    input logic x0,
    input logic x1,
    input logic s,
    output logic f
    );

    logic p0, p1;

    assign f = p0 | p1;
    assign p0 = x0 & ~s;
    assign p1 = x1 & s;
endmodule
