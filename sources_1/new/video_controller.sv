`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/29/2024 09:01:26 PM
// Design Name: 
// Module Name: video_controller
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


module video_controller
(
    //Inputs from Fpro Bus
    input logic video_cs,//video chip select, activates the video subsystem
    input logic video_wr,//write enable
    input logic [20:0] video_addr,//register/slot address, where bit 20 is the normal core/frame buffer cs
    input logic [31:0] video_wr_data,//write data
    //Memory Mapped frame buffer interface
    output logic frame_cs,//bit that selects or de-selects frame buffer (as opposed to normal core)
    output logic frame_wr,//write enable
    output logic [19:0] frame_addr,//internal address of FB, mapped from video_addr
    output logic [31:0] frame_wr_data,//write data
    //MM Normal Video Core slot interface
    output logic [7:0] slot_cs_array,//select between 8 different slots (1 hot decoding)
    output logic [7:0] slot_mem_wr_array, //write enable, same concept as ^
    output logic [13:0] slot_reg_addr_array [7:0],// 14 address bits for internal registers, 8 slots
    output logic [31:0] slot_wr_data_array [7:0]// 32 bits per reg/word and 8 slots
);

//Internal Signal Declaration
logic [2:0] slot_addr;// the three address bits for choosing the 8 slots
logic [13:0] reg_addr;//stores the extracted internal register addr for the Normal Cores
logic [7:0] slot_cs_tmp;//temp var for decoding chip select
logic [31:0] slot_rd_data_array [63:0];//?? There's no reading

//Address extraction
assign slot_addr = video_addr[16:14];
assign reg_addr = video_addr[13:0];
assign frame_cs = video_cs & video_addr[20];//FB is addressed
assign slot_cs = video_cs & ~video_addr[20];//normal core is addressed

//Address Decoding
always_comb 
begin
    slot_cs_tmp = 0;
    if (slot_cs)
        slot_cs_tmp[slot_addr] = 1;//1 hot the bit/slot corresponding to the slot address    
end

assign slot_cs_array = slot_cs_tmp;

//Frame Buffer
assign frame_addr = video_addr[19:0];
assign frame_wr = video_wr;
assign frame_wr_data = video_wr_data;

//Generate for all Normal Video Slots
generate
    genvar i;
        for (i=0; i<8; i=i+1) 
            begin
               assign slot_reg_addr_array[i] = reg_addr;//these are in genvar as the hardware/logic is being duplicated to create several wires
               assign slot_mem_wr_array[i] = video_wr;
               assign slot_wr_data_array[i] = video_wr_data;
            end
endgenerate
endmodule
