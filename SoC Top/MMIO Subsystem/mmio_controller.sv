`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/29/2024 10:12:28 PM
// Design Name: 
// Module Name: mmio_controller
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


module mmio_controller
(  
   // FPro bus 
   input  logic clk,
   input  logic reset,
   input  logic mmio_cs,
   input  logic mmio_wr,
   input  logic mmio_rd,
   input  logic [20:0] mmio_addr, // 11 LSB used; 2^6 slot/2^5 reg each 
   input  logic [31:0] mmio_wr_data,
   output logic [31:0] mmio_rd_data,
   // slot interface
   output logic [63:0] slot_cs_array,
   output logic [63:0] slot_mem_rd_array,
   output logic [63:0] slot_mem_wr_array,
   output logic [4:0]  slot_reg_addr_array [63:0],
   input  logic  [31:0] slot_rd_data_array [63:0], 
   output logic [31:0] slot_wr_data_array [63:0]
);

                                        // signal declaration
   logic [5:0] slot_addr;
   logic [4:0] reg_addr;


   assign slot_addr = mmio_addr[10:5];
   assign reg_addr  = mmio_addr[4:0];

                                       // address decoding
   always_comb
   begin
      slot_cs_array = 0;//default, don't select any slot
      if (mmio_cs)
         slot_cs_array[slot_addr] = 1;//Chip select/enable only the slot that is addressed
   end
   
                                        // broadcast to all slots 
   generate
      genvar i;
      for (i=0; i<64; i=i+1) 
      begin:  slot_signal_gen
         assign slot_mem_rd_array[i] = mmio_rd;//en
         assign slot_mem_wr_array[i] = mmio_wr;//en
         assign slot_wr_data_array[i] = mmio_wr_data;//data
         assign slot_reg_addr_array[i] = reg_addr;//address
      end
   endgenerate
                                       // mux for read data 
   assign mmio_rd_data = slot_rd_data_array[slot_addr];   //Since it's the only input to the MCS from the MMIO
endmodule
