`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/29/2024 09:17:36 PM
// Design Name: 
// Module Name: gpi
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

//General Purpose Input Core --> will be connected to switches
module gpi
#(parameter W = 16)//Width of the input port    
    (
        input logic clk, 
        input logic reset,
        //slot interface
        input logic cs, //chip select for slot 
        input logic read,//en
        input logic write,//en
        input logic [4:0] addr,//internal address of registers
        input logic [31: 0] wr_data, //data to be written
        output logic [31: 0] rd_data,//data to be read
        //outside-world --> external signals
        input logic [W - 1: 0] din
    );

                                            //Signal Declaration

    logic [W - 1: 0] rd_data_reg;

                                            //Register Logic    

    always_ff @( posedge clk, posedge reset )
        if (reset)
            rd_data_reg <= 0;
        else
            rd_data_reg <= din;
            
    assign rd_data[W - 1: 0] = rd_data_reg;
    assign rd_data[31: W] = 0;
endmodule
