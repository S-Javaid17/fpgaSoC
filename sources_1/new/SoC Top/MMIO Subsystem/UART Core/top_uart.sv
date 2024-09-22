`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/29/2024 08:25:39 PM
// Design Name: 
// Module Name: top_uart
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

//  Reg map (each port uses 4 address space)
//    * 0: read data and status
//    * 1: write baud rate 
//    * 2: write data 
//    * 3: dummy write to remove data from head of rx FIFO 

//This is the wrapping circuit for the UART core

module top_uart
#(parameter  FIFO_DEPTH_BIT = 8)  // # addr bits of FIFO
    (
        input logic clk, reset,
        //slot interface
        input logic cs, //chip select for slot 
        input logic read,//en
        input logic write,//en
        input logic [4:0] addr,//internal address of registers
        input logic [31: 0] wr_data, //data to be written
        output logic [31: 0] rd_data,//data to be read
        //outside-world interface
        input logic rx,
        output logic tx
    );

                                            //Internal Signals

    logic wr_dvsr;//will create our own circuit to determine baudrate
    logic [10:0] dvsr_reg; //stores final value for counter

    logic rd_uart;
    logic rx_empty;
    logic [7:0] r_data;

    logic wr_uart;
    logic tx_full;
    //w_data will be taken from the first 8 bits of the input wr_data

    logic ctrl_reg;//not sure why this is included

                                            //Instantiate UART

    uart #(.DBIT(8), .SB_TICK(16), .FIFO_W(FIFO_DEPTH_BIT)) UART_unit
    (
        .*, .dvsr(dvsr_reg), .w_data(wr_data[7:0]) 
    );

                                            //dvsr Register
    
    always_ff @( posedge clk, posedge reset ) 
        if (reset) 
            dvsr_reg <= 0;   
        else
            if (wr_dvsr)//When is this asserted? check below
                dvsr_reg <= wr_data[10:0];//we can write into the dvsr_reg and config. a baud rate
              
                                            // Decoding logic  (refer to register map above)

   assign wr_dvsr = (write && cs && (addr[1:0]==2'b01)); // Assert wr_dvsr if chip select is enabled, and the command to write, and the address points to the second word
   assign wr_uart = (write && cs && (addr[1:0]==2'b10)); // Assert wr_uart if chip select is enabled, and the command to write, and the address points to the third word
   assign rd_uart = (write && cs && (addr[1:0]==2'b11)); // Assert rd_uart if chip select is enabled, and the command to write, and the address points to the fourth word

                                            // Slot read interface

   assign rd_data = {22'h000000, tx_full,  rx_empty, r_data};//22 bits 0, 1 bit, 1 bit, 8 bits  --> reads all possible data (that's meant to be read)
endmodule