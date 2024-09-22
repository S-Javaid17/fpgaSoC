`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/27/2024 08:55:28 PM
// Design Name: 
// Module Name: frame_counter
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


module frame_counter
#(parameter HMAX = 640,//Incase we want to change the resolution later on
            VMAX = 480)
(
    input logic clk,
    input logic reset,
    input logic inc,//enable signal for counter (it'll iterate at 25Mhz)
    input logic sync_clr, 
    output logic [10:0] hcount,//we may need to view these values later on
    output logic [10:0] vcount,
    output logic frame_start,//designated to pixel 0,0
    output logic frame_end
);

//Internal Siggnal Declaration

logic [10:0] hc_reg, hc_next;
logic [10:0] vc_reg, vc_next;

//Register Logic

//Horizontal & Vertical Counters
always_ff @( posedge clk, posedge reset ) 
begin
    if (reset)
        begin
            vc_reg <= 0;
            hc_reg <= 0;
        end
    else if (sync_clr)
        begin
            vc_reg <= 0;
            hc_reg <= 0;
        end
    else
        begin
            vc_reg <= vc_next;
            hc_reg <= hc_next;
        end
end

//Horiz. Next State Logic

always_comb 
begin
    if (inc)
        begin
            if(hc_reg == (HMAX - 1))
                hc_next = 0; //reset horizontal counter if it reaches the last pixel/column
            else
                hc_next = hc_reg + 1;//iterate otherwise
        end
    else
        hc_next = hc_reg;
end

//Vert. Next State Logic

always_comb 
begin
    if (inc && (hc_reg == (HMAX - 1)))
        begin
            if(vc_reg == (VMAX - 1))
                vc_next = 0; //reset vertical counter if it reaches the last line/row
            else
                vc_next = vc_reg + 1;//iterate otherwise
        end
    else
        vc_next = vc_reg;
end

//Output Logic

assign hcount = hc_reg;
assign vcount = vc_reg;
assign frame_start = vc_reg==0 && hc_reg==0;// (0, 0)
assign frame_end = vc_reg==(VMAX-1) && hc_reg==(HMAX-1); //(639, 479)
endmodule
