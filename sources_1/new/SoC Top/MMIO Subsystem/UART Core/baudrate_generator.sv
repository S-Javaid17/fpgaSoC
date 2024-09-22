`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/29/2024 05:54:43 PM
// Design Name: 
// Module Name: baudrate_generator
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


module baudrate_generator
    (
        input logic clk, reset,
        input logic [10 : 0] dvsr,// the final value (divisor), hardcoded at 11 bits wide, the value will be an input
        output logic tick
    );

logic [10 : 0] Q_next, Q_reg;
    //Register Logic
always_ff @(posedge clk, posedge reset) 
begin
    if (reset) 
    begin
        Q_reg <= 0;
    end
    else
        Q_reg <= Q_next;
end
    //Next State Logic 
assign Q_next = (Q_reg == dvsr) ? 0 : Q_reg + 1;//Did the register reach the final value? if yes, don't increment, if not, then increment
    //Output Logic
assign tick = (Q_reg == 1); //tick as long as register is counting

endmodule
