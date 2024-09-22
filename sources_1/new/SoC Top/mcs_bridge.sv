`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/29/2024 09:52:57 PM
// Design Name: 
// Module Name: mcs_bridge
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

//We'll use the Fpro bus to translate between the MCS bus and our custom bus

module mcs_bridge
#(parameter BRG_BASE = 32'hc000_0000)   // default base address for bridge
    (
        // MicroBlaze MCS I/O bus
        input  logic io_addr_strobe, // won't use this
        input  logic io_read_strobe, 
        input  logic io_write_strobe, 
        input  logic [3:0] io_byte_enable, // won't use this
        input  logic [31:0] io_address, 
        input  logic [31:0] io_write_data, 
        output logic [31:0] io_read_data, 
        output logic io_ready, //always asserted

        // FPro bus from book (what we'll interact with)
        output logic fp_video_cs,
        output logic fp_mmio_cs, 
        output logic fp_wr,
        output logic fp_rd,
        output logic [20:0]fp_addr,
        output logic [31:0] fp_wr_data ,
        input logic [31:0] fp_rd_data
    );

                                        // Signal Declaration
   logic mcs_bridge_en;
   logic [29:0] word_addr;//won't use the typical 32 bit byte address

                                        // Address Translation and Decoding
   
   assign word_addr = io_address[31:2]; //  2 LSbs are "00" due to word alignment
   assign mcs_bridge_en = (io_address[31:24] == BRG_BASE[31:24]);//8 MSbs are enable bits --> (0xc0)
   assign fp_video_cs = (mcs_bridge_en && io_address[23] == 1);//1 bit for MMIO or Video subsystem
   assign fp_mmio_cs = (mcs_bridge_en && io_address[23] == 0);
   assign fp_addr = word_addr[20:0];//21 bits are the I/O register address

                                        //  Control Line Conversion 

   assign fp_wr = io_write_strobe;
   assign fp_rd = io_read_strobe;
   assign io_ready = 1; // won't use this; transaction done in 1 clock. Thus, always asserted.

                                        // Data Line Conversion

   assign fp_wr_data = io_write_data;
   assign io_read_data = fp_rd_data;  
 endmodule
