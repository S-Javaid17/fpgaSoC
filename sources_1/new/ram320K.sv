`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/31/2024 07:21:05 PM
// Design Name: 
// Module Name: ram320K
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

//===
// VGA frame buffer 
//     - 640*480 = 307,200 = 0x4b000 
//     - 19-bit address, where MSb is for En
//     - Uses 2 synch. Dual-Port (B)RAM modules (256K+64K = 320K)       
//     - Total Memory = 320K addresses * color depth
module ram320K
#(parameter DW = 9) // data width from RAM
(
    input  logic clk,
    input  logic we,
    input  logic [18:0] addr_w, 
    input  logic [18:0] addr_r, 
    input  logic [DW-1:0] data_w,
    output logic [DW-1:0] data_r
);


//Internal Signal Declaration
logic [DW-1:0] data_r_256k, data_r_64k;//outputs from RAM
logic we_256k, we_64k;//wr_en

//64KB RAM
sync_rw_port_ram #(.ADDR_WIDTH(16), .DATA_WIDTH(DW)) ram_64KB
(
    .clk(clk), 
    .we(we_64k), 
    .addr_w(addr_w[15:0]), .din(data_w),
    .addr_r(addr_r[15:0]), .dout(data_r_64k)
);

//256KB RAM
sync_rw_port_ram #(.ADDR_WIDTH(18), .DATA_WIDTH(DW)) ram_256KB 
( 
    .clk(clk), 
    .we(we_256k), 
    .addr_w(addr_w[17:0]), .din(data_w),
    .addr_r(addr_r[17:0]), .dout(data_r_256k)
);

//Output Logic
assign data_r = (addr_r[18]) ? (data_r_64k) : (data_r_256k);
//Enable Pins
assign we_256k = we & ~addr_r[18];
assign we_64k  = we & addr_w[18];
endmodule
