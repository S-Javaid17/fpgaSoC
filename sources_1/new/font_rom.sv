`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/31/2024 06:48:03 PM
// Design Name: 
// Module Name: font_rom
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

//Single Port (B) ROM
module font_rom
#(parameter DATA_WIDTH = 8,
            ADDR_WIDTH = 11
)
(
    input logic clk,
    input  logic [ADDR_WIDTH - 1: 0] addr,
    output logic [DATA_WIDTH - 1: 0] data
);

logic [DATA_WIDTH - 1: 0] rom [0: 2**ADDR_WIDTH - 1];
logic [DATA_WIDTH - 1: 0] data_reg;//output data

// font.txt specifies the initial values of ram , which is the character shapes
initial 
    $readmemb("font.txt", rom);

//Reg. Logic
always_ff @(posedge clk)
data_reg <= rom[addr];

//Output logic
assign data = data_reg;
endmodule
