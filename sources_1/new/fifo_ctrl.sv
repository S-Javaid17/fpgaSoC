`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/20/2024 01:58:36 AM
// Design Name: 
// Module Name: fifo_ctrl
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

//doesn't deal with the data itself, just the flow of the data
//basically a FSM
module fifo_ctrl
#(parameter ADDR_WIDTH = 3)
(
    input logic clk, reset,
    input logic wr, rd, //write and read commands
    output logic empty, full, // empty and full flags
    output logic [ADDR_WIDTH - 1: 0] w_addr,//write address (pointer)
    output logic [ADDR_WIDTH - 1: 0] r_addr//read address (POINTER), is the same number of bits wide, as there are addresses
);

//define the pointers as registers

logic [ADDR_WIDTH - 1: 0] wr_ptr, wr_ptr_next;//write pointer, as a register, current and next state
logic [ADDR_WIDTH - 1: 0] rd_ptr, rd_ptr_next;//read pointer, as a register 

//Internal signals, to avoid dealing with the (external) full/empty flags directly
logic full_next;
logic empty_next;

//State Register Logic

always_ff @( posedge clk, posedge reset ) 
begin
    if (reset)
    begin
        wr_ptr <= 0;
        rd_ptr <= 0;
        full <= 1'b0;
        empty <= 1'b1; //will initially be empty
    end   
    else
    begin
        wr_ptr <= wr_ptr_next;
        rd_ptr <= rd_ptr_next;
        full <= full_next;
        empty <= empty_next;
    end
end

//Next State Logic

always_comb 
begin
    //default values, will cover the lack of "else" statements
    wr_ptr_next = wr_ptr;
    rd_ptr_next = rd_ptr;
    full_next = full;
    empty_next = empty;

    unique case ({wr, rd})//the wr and rd signals control the behaviour of the controller

        2'b01: //read
            begin
                if (~empty)
                begin
                    rd_ptr_next = rd_ptr + 1;
                    full_next = 1'b0; //since the location, the rd pointer is at, was read from, it's no longer a full fifo
                    if (rd_ptr_next == wr_ptr)// if the read pointer location is the same as the write pointer (aka it read the last value)
                        empty_next = 1'b1;//then the fifo is empty
                end
            end

        2'b10: //write
            begin
                if (~full)
                begin
                    wr_ptr_next = wr_ptr + 1;
                    empty_next = 1'b0; //since the location, the wr pointer is at, was written to, it's no longer an empty fifo
                    if (wr_ptr_next == rd_ptr)// if the write pointer location is the same as the read pointer (aka it wrote the last available value)
                        full_next = 1'b1;//then the fifo is full
                end
            end

        2'b11: //read and write simultaneously --- possible, since it's a dual port ram
            begin   
                    //if it's empty, and you're reading/writing at the same time,---
                    // --- you don't want the rd pointer to move up, you want it to ---
                    //--- read from the same location that is being written to
                if (empty)  
                begin
                    wr_ptr_next = wr_ptr;
                    rd_ptr_next = rd_ptr;
                end
                else
                begin
                    wr_ptr_next = wr_ptr + 1;
                    rd_ptr_next = rd_ptr + 1;
                end    
            end

        default: ;//2'b00 case is included here (neither read nor write)
    endcase
end

//Output Logic

assign w_addr = wr_ptr;
assign r_addr = rd_ptr;

endmodule
