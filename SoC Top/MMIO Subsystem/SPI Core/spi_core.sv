`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/06/2024 04:33:02 AM
// Design Name: 
// Module Name: spi_core
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

//Refer to notes for register map

module spi_core
#(parameter S = 2)//width of ouput port (# of bits). --> number of slaves
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
    input logic  spi_miso,
    output logic spi_mosi,
    output logic spi_sclk,
    output logic [S - 1: 0] spi_ss_n//slave select
);

//Signal Declaration
logic wr_en, wr_ss, wr_spi, wr_ctrl;//write enable for core, wr enable for offset 1, 2, and 3, respectively
logic spi_ready;
logic [17: 0] ctrl_reg;
logic [S - 1: 0] ss_n_reg;
logic [7: 0] spi_out;//data from slave peripheral
logic [15: 0] dvsr;
logic cpha, cpol;  

//Instantiating spi master controller

spi_master spi_unit 
(
    .clk(clk), 
    .reset(reset), 
    .din(wr_data[7:0]),//data to slave peripheral
    .dvsr(dvsr),
    .start(wr_spi),
    .cpol(cpol),
    .cpha(cpha),
    .dout(spi_out),
    .sclk(spi_sclk),
    .miso(spi_miso),
    .mosi(spi_mosi),
    .spi_done_tick(),
    .ready(spi_ready)
);

//Registers

always_ff @(posedge clk, posedge reset)
    if (reset) begin
        ctrl_reg <= 17'h0_0200;    // dvsr=512, which gives a frequency of about 2*50Khz. 
                                   //Since the dvsr counts to only half the total period (p0 and p1), its value must correspond to twice the desired freq for the sclk, (thus, we have about a 50 KHz sclk for 100MHz system clk)  
        ss_n_reg <= {S{1'b1}};     // de-assert all ss_n
    end 
    else begin
        if (wr_ctrl)
            ctrl_reg <= wr_data[17:0];
        if (wr_ss)
            ss_n_reg <= wr_data[S-1:0];
    end

//Decoding

assign wr_en = cs & write;
assign wr_ss = wr_en && addr[1:0]==2'b01;//offset 1
assign wr_spi = wr_en && addr[1:0]==2'b10;//offset 2
assign wr_ctrl = wr_en && addr[1:0]==2'b11;//offset 3

//Control Signals (refer to reg map)

assign dvsr = ctrl_reg[15:0];
assign cpol = ctrl_reg[16];
assign cpha = ctrl_reg[17];
assign spi_ss_n = ss_n_reg;

// Read Multiplexing 

assign  rd_data = {23'b0, spi_ready, spi_out};
endmodule  
