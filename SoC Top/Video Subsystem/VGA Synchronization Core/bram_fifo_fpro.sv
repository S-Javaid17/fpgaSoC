`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/30/2024 04:58:49 AM
// Design Name: 
// Module Name: bram_fifo_fpro
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

// FIFO_DUALCLOCK_MACRO : In order to incorporate this function into the design,
//     Verilog          : the following instance declaration needs to be placed
//    instance          : in the body of the design code.  The instance name
//   declaration        : (FIFO_DUALCLOCK_MACRO_inst) and/or the port declarations within the
//      code            : parenthesis may be changed to properly reference and
//                      : connect this function to the design.  All inputs
//                      : and outputs must be connected.

//  <-----Cut code below this line---->

   // FIFO_DUALCLOCK_MACRO: Dual Clock First-In, First-Out (FIFO) RAM Buffer
   //                       Artix-7
   // Xilinx HDL Language Template, version 2024.1

   /////////////////////////////////////////////////////////////////
   // DATA_WIDTH | FIFO_SIZE | FIFO Depth | RDCOUNT/WRCOUNT Width //
   // ===========|===========|============|=======================//
   //   37-72    |  "36Kb"   |     512    |         9-bit         //
   //   19-36    |  "36Kb"   |    1024    |        10-bit         //
   //   19-36    |  "18Kb"   |     512    |         9-bit         //
   //   10-18    |  "36Kb"   |    2048    |        11-bit         //
   //   10-18    |  "18Kb"   |    1024    |        10-bit         //
   //    5-9     |  "36Kb"   |    4096    |        12-bit         //
   //    5-9     |  "18Kb"   |    2048    |        11-bit         //
   //    1-4     |  "36Kb"   |    8192    |        13-bit         //
   //    1-4     |  "18Kb"   |    4096    |        12-bit         //
   /////////////////////////////////////////////////////////////////


module bram_fifo_fpro
 #(parameter DW = 13) // -- # data width (bits per word; 10-18) 
   (
      input logic reset,
      // read port 
      input  logic clk_rd,           // read clock
      output logic empty,            // read port empty 
      output logic almost_empty,     // read port almost empty 
      input  logic rd_ack,           // read acknowledge
      output logic [DW-1:0] rd_data, // read data
      // write port
      input  logic clk_wr,           // write clock
      output logic full,             // write port full 
      output logic almost_full,      // write port almost full 
      input  logic wr_en,            // write enable 
      input  logic [DW-1:0] wr_data, // write data
      // occupancy of fifo
      output logic [9:0] rdcount,    // read count
      output logic [9:0] wrcount     // write count
   );



   FIFO_DUALCLOCK_MACRO  #(
      .ALMOST_EMPTY_OFFSET(9'h080), // Sets the almost empty threshold
      .ALMOST_FULL_OFFSET(9'h080),  // Sets almost full threshold
      .DATA_WIDTH(DW),   // Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      .DEVICE("7SERIES"),  // Target device: "7SERIES" 
      .FIFO_SIZE ("18Kb"), // Target BRAM: "18Kb" or "36Kb" 
      .FIRST_WORD_FALL_THROUGH ("FALSE") // Sets the FIFO FWFT to "TRUE" or "FALSE" 
   ) FIFO_DUALCLOCK (
    .RST(reset), 
    // read port      
    .RDCLK(clk_rd),              // read clock
    .DO(rd_data),                // read data out  
    .RDEN(rd_ack),               // remove word from head
    .EMPTY(empty),               // fifo empty  
    .ALMOSTEMPTY(almost_empty),   
    .RDCOUNT(rdcount),       
    .RDERR(),                    // read error
    // write port
    .WRCLK(clk_wr),              // write clock
    .DI(wr_data),                // write data in
    .WREN(wr_en),                // write enable
    .FULL(full),                 // fifo full 
    .ALMOSTFULL(almost_full),    
    .WRCOUNT(wrcount),   
    .WRERR()      
   );

   // End of FIFO_DUALCLOCK_MACRO_inst instantiation
				
				
endmodule
