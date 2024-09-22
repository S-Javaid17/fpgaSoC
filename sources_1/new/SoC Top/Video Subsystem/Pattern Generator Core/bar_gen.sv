`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/29/2024 11:42:37 PM
// Design Name: 
// Module Name: bar_gen
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



/*-======================================================================
-- Description: generate a 3-level test bar pattern, depending on the inputs x and y:
--   * gray scale 
--   * 8 prime colors
--   * a continuous color spectrum
--   * it is customized for 12-bit VGA
--   * two registers form 2-clock delay line  
--======================================================================*/
//http://en.wikipedia.org/wiki/HSL_and_HSV for further info
module bar_gen
(
    input logic clk,
    input logic [10:0] x, y, //dealt with as x and y cooridnates on the screen
    output logic [11:0] bar_rgb//represents the rgb colour for the pixel at position (x, y) on the screen
);

//Signal Declaration

logic [3:0] up, down;//changing pixel values (corresponding to x-axis movement)
logic [3:0] r, g, b; //rgb pixel values
logic [11:0] reg_d1_reg, reg_d2_reg;//dummy registers for delay

assign up = x[6:3];//has a width of 4, which allows 16 different intensities. 
//                  lower/middle bits are chosen because they allow for moderately fine details, as the bits change at a moderately fast pace
assign down = ~x[6:3];

always_comb 
begin
// Grayscale Pattern. 16 shades. Uses middle bits for mid sized blocks
    if (y < 128)//upper quarter, approx.
        begin
            r = x[8:5];//all three colors have the same value --> gray
            g = x[8:5];//As the x value moves to the right (increases) the bits get closer to max value
            b = x[8:5];// Thus, it's a gradient of black (0000) to white (1111), with 16 blocks
        end
    else if (y < 256)//second quarter. 8 colours, 80% intensity (12/15 --> 1100/1111)
        begin
            r = {x[8], x[8], 2'b00};//red will change last out of the three colours
            g = {x[7], x[7], 2'b00};//will change second
            b = {x[6], x[6], 2'b00};//will change first
            //thus the patter will be blue --> green --> blue-green=cyan --> red --> red-blue=magenta --> red-green=yellow --> red-blue-green=white --> none=black
        end
    else
        begin
            // a continuous color spectrum 
            // width of up/down can be increased to accommodate finer spectrum

            unique case (x[9:7])//broad blocks, which change very slowly, which allows for a smooth color transition over a large portion
                                // of the screen, rather than small chunky blocks.
                                //Implement the RGB color band FSM from notes
            3'b000: begin
                r = 4'b1111;
                g = up;
                b = 4'b0000;
            end   
            3'b001: begin
                r = down;
                g = 4'b1111;
                b = 4'b0000;
            end   
            3'b010: begin
                r = 4'b0000;
                g = 4'b1111;
                b = up;
            end   
            3'b011: begin
                r = 4'b0000;
                g = down;
                b = 4'b1111;
            end   
            3'b100: begin
                r = up;
                g = 4'b0000;
                b = 4'b1111;
            end   
            3'b101: begin
                r = 4'b1111;
                g = 4'b0000;
                b = down;
            end   
            default: begin
                r = 4'b1111;
                g = 4'b1111;
                b = 4'b1111;
            end  
            endcase
        end
end 

//Output Logic

always_ff @(posedge clk) //adds a 2 stage delay, since another core requires that
    begin
        reg_d1_reg <= {r, g, b};
        reg_d2_reg <= reg_d1_reg;
    end
assign bar_rgb = reg_d2_reg;
endmodule
