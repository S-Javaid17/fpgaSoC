`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/31/2024 06:46:01 PM
// Design Name: 
// Module Name: sync_rw_port_ram
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

//Dual port BRAM for Tile
module sync_rw_port_ram
#(parameter DATA_WIDTH = 8,
            ADDR_WIDTH = 12)
(
    input logic clk,
    //port a - write
    input logic we,
    input logic [ADDR_WIDTH - 1: 0] addr_w,
    input logic [DATA_WIDTH - 1: 0] din,
    //port b - read
    input logic [ADDR_WIDTH - 1: 0] addr_r,
    output logic [DATA_WIDTH - 1: 0] dout
);

//RAM
logic [DATA_WIDTH - 1: 0] ram [0: 2**ADDR_WIDTH - 1];
logic [DATA_WIDTH - 1: 0] read_data;

//Reg. Logic
always_ff @( posedge clk ) 
begin
    if (we)
        ram[addr_w] <= din; 
    read_data <= ram[addr_r];
end

//Output logic
assign dout = read_data;
endmodule
