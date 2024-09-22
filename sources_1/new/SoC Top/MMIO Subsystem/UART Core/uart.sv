`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/29/2024 05:53:02 PM
// Design Name: 
// Module Name: uart
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


module uart
#(parameter DBIT = 8, SB_TICK = 16,  FIFO_W = 2)     // FIFO_W is the addr bits of FIFO
    (
        input logic clk, reset,
        //Baud Rate Generator
        input logic [10 : 0] dvsr,
        //Rx
        input logic rx,
        input logic rd_uart,
        output logic rx_empty,
        output logic [DBIT - 1: 0] r_data,
        //Tx
        input logic [DBIT - 1: 0] w_data,
        input logic wr_uart,
        output logic tx_full,
        output logic tx
    );

                                                //Signal Declaration

   logic tick, rx_done_s_tick, tx_done_tick;
   logic tx_empty, tx_fifo_not_empty;
   logic [DBIT - 1: 0] tx_fifo_out, rx_data_out;

                                                //Baud Rate Generator

baudrate_generator Baudrate_Generator 
(.*);

                                                //Rx module and FIFO

uart_rx #(.DBIT(DBIT), .SB_TICK(SB_TICK)) Receiver
(.*, .s_tick(tick), .dout(rx_data_out));

fifo #(.DATA_WIDTH(DBIT), .ADDR_WIDTH(FIFO_W)) fifo_rx_unit
(.*, .rd(rd_uart), .wr(rx_done_tick), .w_data(rx_data_out),
 .empty(rx_empty), .full(), .r_data(r_data));

                                                //Tx module and FIFO

uart_tx #(.DBIT(DBIT), .SB_TICK(SB_TICK)) Transmitter
(.*, .s_tick(tick), .tx_start(tx_fifo_not_empty), .din(tx_fifo_out));

fifo #(.DATA_WIDTH(DBIT), .ADDR_WIDTH(FIFO_W)) fifo_tx_unit
(.*, .rd(tx_done_tick), .wr(wr_uart), .w_data(w_data), .empty(tx_empty),
 .full(tx_full), .r_data(tx_fifo_out));

assign tx_fifo_not_empty = ~tx_empty;

endmodule
