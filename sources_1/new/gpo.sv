`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/29/2024 09:18:08 PM
// Design Name: 
// Module Name: gpo
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

//Will connect this to the LEDs
module gpo
#(parameter W = 16)//Width of the output port    
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
        input logic [W - 1: 0] dout
    );

                                            //Signal Declaration

    logic [W - 1: 0] wr_data_reg;
    logic wr_en;

                                            //Register Logic    

    always_ff @( posedge clk, posedge reset )
        if (reset)
            wr_data_reg <= 0;
        else
            if (wr_en)
                wr_data_reg <= wr_data[W - 1: 0];

                                            // Decoding logic
    assign wr_en = (cs && write);
                                            // Slot read interface
    assign rd_data =  0;
                                            // External Output

    assign dout = wr_data_reg;
endmodule
