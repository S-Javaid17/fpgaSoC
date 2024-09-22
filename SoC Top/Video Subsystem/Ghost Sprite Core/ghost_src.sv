`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/31/2024 06:48:41 PM
// Design Name: 
// Module Name: ghost_src
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


module ghost_src
#(parameter CD = 12,//colour depth
            ADDR = 10,//addr bits
            KEY_COLOR = 0//chroma key --> black
)
(
    input logic clk,
    input logic [10:0] x, y,//x and y coordinates from FC
    input logic [10:0] x0, y0,//origin of sprite
    input logic [4:0] ctrl,//control reg
    //sprite RAM write
    input logic we,//en
    input logic [ADDR - 1: 0] addr_w,
    input logic [1: 0] pixel_in,//encoded pixel data from RAM
    //pixel Output
    output logic [CD - 1: 0] sprite_rgb
);


//Localparams
localparam H_SIZE = 16;//sprite width
localparam V_SIZE = 16;//sprite depth

//Signal Declaration
logic [11: 0] xr, yr;//relative coordinates to sprite origin
logic in_region; //"pixel within sprite image" signal
logic [ADDR - 1: 0] addr_r;//read addr for RAM
logic [CD - 1: 0] full_rgb;// output of pixel RAM
logic [CD - 1: 0] out_rgb; // blender output
logic [CD - 1: 0] out_rgb_d1_reg;//1 clk delayed blender output
logic [CD - 1: 0] ghost_rgb; // the ghost body colour
logic [1:0] sprite_id;//sprite id
logic [1:0] palette_code; //palette code, aka, the output of the RAM 

    //Counters/timers

    //frame_tick ticks @ 60 Hz -->  counter_reg resets to 0, every 10 frame_tick --> animation tick ticks @ 6 Hz (from counter_reg) --> animation_reg is mod 4 counter, every 6 Hz
logic frame_tick;//ticks at 60 Hz, ticker for frame counter
logic [3:0] counter_next, counter_reg;//counts at mod 10 of frame_tick (6 Hz) and asserts 0
logic animation_tick;//asserts high at 6 Hz, ticker for 'counter_reg'
logic [1:0] animation_next, animation_reg;

logic [10:0] x_d1_reg;//delayed output of x coordinate
logic [1:0] gc_color_sel; //ghost body color select        
logic [1:0] gc_id_sel; //ghost sprite id select 
logic auto; //automatic sprite_id iteration or not   

//Register control signals      
assign gc_id_sel = ctrl[1:0]; 
assign auto = ctrl[2];
assign gc_color_sel = ctrl[4:3];

//Instantiate sprite RAM
ghost_ram #(.ADDR_WIDTH(ADDR), .DATA_WIDTH(2)) ram_unit 
(
    .clk(clk), 
    .we(we), 
    .addr_w(addr_w), .din(pixel_in),
    .addr_r(addr_r), .dout(palette_code)
);
assign addr_r = {sprite_id, yr[3:0], xr[3:0]};//RAM read addressing


//Ghost Color selector
always_comb 
begin
    case (gc_color_sel)
        2'b00:   ghost_rgb = 12'hf00;  // red 
        2'b01:   ghost_rgb = 12'hf8b;  // pink 
        2'b10:   ghost_rgb = 12'hfa0;  // orange
        default: ghost_rgb = 12'h0ff;  // cyan
    endcase    
end

//Palette encodings
always_comb
begin
    case (palette_code)
        2'b00:   full_rgb = 12'h000;   // chrome key
        2'b01:   full_rgb = 12'h111;   // dark gray 
        2'b10:   full_rgb = ghost_rgb; // ghost body color
        default: full_rgb = 12'hfff;   // white
    endcase
end


//Relative Coordinates
assign xr = $signed({1'b0, x}) - $signed({1'b0, x0});
assign yr = $signed({1'b0, y}) - $signed({1'b0, y0});

//In-Region Circuit
assign in_region = (0 <= xr) && (xr < H_SIZE) && (0 <= yr) && (yr < V_SIZE);
assign out_rgb = (in_region) ? (full_rgb) : (KEY_COLOR);// If in region, display RAM pixel, otherwise chroma-key.

//Counters/Timers Register Logic
always_ff @(posedge clk)
begin
    x_d1_reg <= x;
    counter_reg <= counter_next;
    animation_reg <= animation_next;
end

//Next State Logic
// 60-Hz tick from frame counter 
assign frame_tick = (x_d1_reg == 0) && (x == 1) && (y == 0);
//6 Hz counter
assign counter_next = (frame_tick && counter_reg == 9) ? 0 :
                (frame_tick) ? counter_reg + 1 :
                counter_reg; 
// sprite animation id tick at 6 Hz from counter_reg 
assign animation_tick  = frame_tick  && (counter_reg == 0); 
assign animation_next = (animation_tick) ? animation_reg + 1 : animation_reg;
// sprite id selection
assign sprite_id = (auto) ? animation_reg : gc_id_sel;


//1 Cycle Delay
always_ff @(posedge clk) 
    out_rgb_d1_reg <= out_rgb;
//Output Logic
assign sprite_rgb = out_rgb_d1_reg;
endmodule
