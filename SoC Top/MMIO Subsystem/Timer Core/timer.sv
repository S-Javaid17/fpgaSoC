`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/29/2024 10:49:00 PM
// Design Name: 
// Module Name: timer
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

//  * Reg map;
//    * 00: read (32 LSB of counter)
//    * 01: read (16 MSB of counter)
//    * 10: control register: 
//        bit 0: go/pause
//        bit 1: clear (no memory, just used to generate a 1-clock pulse)

//This will be the timer core, using a 48-bit counter (up to 65 days)
module timer
    (
            input logic clk,
            input logic reset,
            //slot interface
            input logic cs, //chip select for slot 
            input logic read,//en
            input logic write,//en
            input logic [4:0] addr,//internal address of registers
            input logic [31: 0] wr_data, //data to be written
            output logic [31: 0] rd_data//data to be read
    );

                                            //Signal Declaration
    logic [47:0] count_reg;
    logic ctrl_reg;
    logic wr_en, clear, go;

                                            //Counter

    always_ff @( posedge clk, posedge reset ) 
        if(reset)
            count_reg <= 0;
        else
            if (clear)
                count_reg <= 0;
            else if (go)
                count_reg <= count_reg + 1;

                                            //Wrapping Circuit
                                            
                                            //Ctrl Register

    always_ff @( posedge clk, posedge reset )
        if (reset)
            ctrl_reg <= 0;
        else   
            if (wr_en)
                ctrl_reg <= wr_data[0];  

                                            //Decoding Logic 

    assign wr_en = (write && cs && (addr[1:0] == 2'b10));   
    assign clear = wr_en && wr_data[1];//if wr_en is asserted, and if wr_data[1] is asserted (asynch clear), doesn't need to be remembered
    assign go = ctrl_reg; // if wr_data[0] is asserted --> go, otherwise it pauses

                                            //Slot Read Interface   
    //(refer to reg map above)
    assign rd_data = (addr[0] == 0) ?
                     count_reg[31:0]:
                    {16'h0000, count_reg[47:32]};                                                                                     
endmodule
