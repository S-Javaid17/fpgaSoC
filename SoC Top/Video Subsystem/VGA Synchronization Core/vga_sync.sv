`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/31/2024 06:42:25 PM
// Design Name: 
// Module Name: vga_sync
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

//Enhanced VGA synchronization circuit

module vga_sync 
#(parameter CD =12)//colour depth
(
    input logic clk, reset,
//Stream Input
    input logic [CD: 0] vga_si_data, //vga stream input data + start bit
    input logic vga_si_valid,
    input logic vga_si_ready,
//To VGA monitor
    output logic hsync, vsync,
    output logic [CD - 1: 0] rgb
);

//Local parameter declaration for a 640x480 vga

localparam HD = 640;  // horizontal display area
localparam HF = 16;   // h. front porch
localparam HB = 48;   // h. back porch
localparam HR = 96;   // h. retrace
localparam HT = HD+HF+HB+HR; // horizontal total (800)

localparam VD = 480;  // vertical display area
localparam VF = 10;   // v. front porch
localparam VB = 33;   // v. back porch
localparam VR = 2;    // v. retrace
localparam VT = VD+VF+VB+VR; // vertical total (525)

//FSM state type
typedef enum  { frame_sync, disp } state_type;

// Internal Signal Declaration
state_type state_reg, state_next;
logic vga_st_in_start;//extracted from vga_si_rgb
logic [CD - 1: 0] vga_st_in_color;//extracted from vga_si_rgb
logic [10:0] x, y;
logic hsync_i, vsync_i; 
logic video_on_i;//pixel display area en
logic scan_end;
logic vsync_reg, hsync_reg;
logic [CD-1:0] rgb_reg;//output reg
logic vga_si_ready_i;//?

assign vga_st_in_start = vga_si_data[0];
assign vga_st_in_color = vga_si_data[CD:1];

//Instantiate frame counter
frame_counter #(.HMAX(HT), .VMAX(VT)) frame_unit 
(
    .clk(clk), .reset(reset), .sync_clr(0), 
    .hcount(x), .vcount(y), 
    .inc(1), .frame_start(), .frame_end(scan_end)
);

//Horizontal and Vertical Sync
assign hsync_i = ((x >= (HD + HF)) && (x <= (HD + HF + HR - 1))) ? 0 : 1;
assign vsync_i = ((y >= (VD + VF)) && (y <= (VD + VF + VR - 1))) ? 0 : 1;
// Display on/off
assign video_on_i = ((x < HD) && (y < VD)) ? 1: 0;

//Stream Control Unit / Buffered output to VGA
always_ff @(posedge clk) 
begin
    vsync_reg <= vsync_i;
    hsync_reg <= hsync_i;

    if (video_on_i)//multiplexer circuit
        rgb_reg <= vga_st_in_color;
    else
        rgb_reg <= 0; //Black when display is off
end

//FSM for Control Circuit

//Register logic
always_ff @( posedge clk, posedge reset ) begin
    if (reset)
        state_reg <= frame_sync;
    else
        state_reg <= state_next;
end

//Next-State Logic

always_comb 
begin
    state_next = state_reg;//default
    vga_si_ready_i = 1'b0;
    case (state_reg)
        
        frame_sync : 
            begin
            //Wait for the end of the current scan/frame...until retarce us done
                if (scan_end)
                    begin
                        if (vga_st_in_start)
                            state_next = disp;
                        else
                            state_next = frame_sync;
                    end
            //If the new frame doesn't start at (0,0), flush out the frame
                if (~vga_st_in_start)
                    vga_si_ready_i = 1'b1;
            end
        default ://Covers 'disp' state
            begin
                if ((x == HD - 1) && (y == VD - 1))//on the last pixel
                    state_next = frame_sync;
                if (video_on_i)// if still in the pixel display area
                    vga_si_ready_i = 1'b1;// move on to (displaying) the next pixel
            end
    endcase
end

//Output Logic

assign hsync = hsync_reg;
assign vsync = vsync_reg;
assign vga_si_ready = vga_si_ready_i;
assign rgb = rgb_reg;
endmodule
