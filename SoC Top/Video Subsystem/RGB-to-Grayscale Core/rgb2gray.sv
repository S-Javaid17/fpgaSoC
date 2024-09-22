`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/28/2024 08:51:11 PM
// Design Name: 
// Module Name: rgb2gray
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



/*=======================================================
- gray = 0.21R + 0.72G + 0.07B
- Q4.0 * Q0.8 => Q4.8
- green: g*.72 => g*.72*256 => g*0xb8 
=======================================================*/
//Will use the Luminosity, Colour-to-Grayscale method to convert rgb-->gray
module rgb2gray
(
    input logic [11:0] color_rgb,
    output logic [11:0] gray_rgb
);

//Local parameters

    localparam RW = 8'h35;//weight for the colour red, refer to notes
    localparam GW = 8'hb8;
    localparam BW = 8'h12;

//Internal Signal Declaration
    logic [3:0] r, g, b, gray;
    logic [11:0]gray12;

    assign r = color_rgb[11:8];//MS 4 bits
    assign g = color_rgb[7:4];//Middle 4 bits
    assign b = color_rgb[3:0];//LSbits

    assign gray12 = r*RW + g*GW + b*BW;//multiply bit values with the weights 
    assign gray = gray12[11:8];// the result of the multiplication is in Q4.8 format, where the Most sig. 4 bits are the the integer, and the least sig 8 are the fraction
    assign gray_rgb = {gray, gray, gray};// red green and blue must have the same values
endmodule
