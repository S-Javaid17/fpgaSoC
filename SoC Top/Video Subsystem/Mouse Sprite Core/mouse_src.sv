`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/31/2024 06:49:25 PM
// Design Name: 
// Module Name: mouse_src
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

//Whole pixel generation circuit for mouse sprite core
//not the wrapping circuit
module mouse_src
#(parameter CD = 12,//colour depth
            ADDR = 10,//addr bits
            KEY_COLOR = 0//chroma key --> black
)
(
    input logic clk,
    input logic [10:0] x, y,//x and y coordinates from FC
    input logic [10:0] x0, y0,//origin of sprite
    //sprite RAM write
    input logic we,//en
    input logic [ADDR - 1: 0] addr_w,
    input logic [CD - 1: 0]pixel_in,
    //pixel Output
    output logic [CD - 1: 0] mouse_rgb
);

//Localparams
localparam H_SIZE = 32;//sprite width
localparam V_SIZE = 32;//sprite depth

//Signal Declaration
logic [11: 0] xr, yr;//relative coordinates to sprite origin
logic in_region; //"pixel within sprite image" signal
logic [ADDR - 1: 0] addr_r;//read addr for RAM
logic [CD - 1: 0] full_rgb;// output of pixel RAM
logic [CD - 1: 0] out_rgb; // blender output
logic [CD - 1: 0] out_rgb_d1_reg;//1 clk delayed blender output

//Instantiate mouse RAM
mouse_ram #(.ADDR_WIDTH(ADDR), .DATA_WIDTH(CD)) ram_unit
(
    .clk(clk),
    .we(we),
    .addr_r(addr),
    .addr_w(addr_w),
    .din(pixel_in),
    .dout(full_rgb)
);

//Relative Coordinates

// xr and yr are 12 bits long because the operands are 5 bits + 1 signed bit each --> (6+6). Though we only need the 5 lsbs
//use the system function $signed so that synthesizer knows this is a signed subtraction. Avoids overflow --> also why we added a 0 sign extension.
//Incase the subtraction leads to a -ve number. 
//Both x/y and x0/y0 are positives, hence, the sign extension is a bit 0
assign xr = $signed({1'b0, x}) - $signed({1'b0, x0});
assign yr = $signed({1'b0, y}) - $signed({1'b0, y0});

assign addr_r = {yr[4:0], xr[4:0]};//RAM addressing, refer to notes
//In-Region Circuit

assign in_region = (0 <= xr) && (xr < H_SIZE) && (0 <= yr) && (yr < V_SIZE);
assign out_rgb = (in_region) ? (full_rgb) : (KEY_COLOR);// If in region, display RAM pixel, otherwise chroma-key.

//1 clock cycle delay
always_ff @(posedge clk) 
    out_rgb_d1_reg <= out_rgb;

//Output Logic

assign mouse_rgb = out_rgb_d1_reg;
endmodule
