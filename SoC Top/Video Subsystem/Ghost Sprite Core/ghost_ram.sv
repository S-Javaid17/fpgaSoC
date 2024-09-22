`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/01/2024 09:49:15 PM
// Design Name: 
// Module Name: ghost_ram
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

//Dual port BRAM for ghost image
// Singular read/write
module ghost_ram
#(parameter DATA_WIDTH = 2,//encoded colour depth
            ADDR_WIDTH = 10//2^10 addresses
)
(
    input logic clk,
    input logic we,
    input logic [ADDR_WIDTH - 1: 0] addr_r,
    input logic [ADDR_WIDTH - 1: 0] addr_w,
    input logic [DATA_WIDTH - 1: 0] din,
    output logic [DATA_WIDTH - 1: 0] dout
);

//Ram Declaration

logic [DATA_WIDTH - 1: 0] ram [0: 2**ADDR_WIDTH - 1];//first element describes the width
logic [DATA_WIDTH - 1: 0] data_reg;

initial
    $readmemb("ghost_bitmap.txt", ram);// read the binary data in the file and store/initialize the ram with it

always_ff @(posedge clk ) 
begin
    if (we)
        ram[addr_w] <= din;//write
    data_reg <= ram[addr_r];//read
end

assign dout = data_reg;
endmodule
