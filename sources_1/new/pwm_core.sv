`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/30/2024 09:20:15 PM
// Design Name: 
// Module Name: pwm_core
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


//==================================================================
// R: # reolution bit
// duty signal needs 1 extra bit
//   * e.g., 8- bit resolution need 2^8+1 values (0, 1, 2, ..., 
// DIV: frequency Divider 
//   * tick_freq = pwm_freq * (2^resolution_bit) 
//   * DIV = system_freq / tick_freq 
//   * use 32-bit freq divider
//==================================================================
// register map
// 0x10 to 0x1f for pwm duty cycles
// 0x00 for frequency divisor 
//==================================================================


module pwm_core
#(parameter R = 10, //Resolution/granularity of pwm
            W = 8 //width, in bits, of output ports
 )    
    (
        input  logic clk,
        input  logic reset,
        // slot interface
        input  logic cs,
        input  logic read,
        input  logic write,
        input  logic [4:0] addr,
        input  logic [31:0] wr_data,
        output logic [31:0] rd_data,
        // external signal    
        output logic [W-1:0] pwm_out
    );

    //Signal and Register Declaration

    logic [R:0] duty_2d_reg [W-1:0]; //W number of registers which hold the duty. The duty which is R + 1 bits wide
    logic duty_array_en, dvsr_en;//en
    logic [31:0] q_reg;//timer reg
    logic [31:0] q_next;
    logic [R-1:0] d_reg;//duty counter reg
    logic [R-1:0] d_next;
    logic [R:0] d_ext;//extended ^
    logic [W-1:0] pwm_reg;//output reg after comparator
    logic [W-1:0] pwm_next;
    logic tick;//enables the duty counter 
    logic [31:0] dvsr_reg;//stores divisor

    //Wrapping Circuit (no reading)

    //Decoding 

    assign duty_array_en = cs && write && addr[4];//same as saying hex 0x1-  is asserted (bit value 16) ---> 1_----
    assign dvsr_en = cs && write && addr == 5'b00000;//register 0 is addressed

    //Divisor Register

    always_ff @( posedge clk, posedge reset ) 
        if (reset)
            dvsr_reg <= 0;
        else
            if (dvsr_en)
                dvsr_reg <= wr_data;    

    //Duty Cycle Register

    always_ff @( posedge clk) 
        if (duty_array_en)
            duty_2d_reg[addr[3:0]] <= wr_data[R:0]; //only need to decode lower 4 bits  

    //PWM 

    always_ff @(posedge clk, posedge reset)
      if (reset) begin
         q_reg <= 0;
         d_reg <= 0;
         pwm_reg <= 0;
      end 
      else begin
         q_reg <= q_next;
         d_reg <= d_next;
         pwm_reg <= pwm_next;
     end

    //Prescale counter (aka the "timer")

    assign q_next = (q_reg == dvsr_reg) ? 0 : q_reg + 1; //if the dvsr value is reached, the timer/prescale counter resets (sets frequency for the second timer)
    assign tick = q_reg == 0;                       // after the timer resets, it outputs a tick, which enables the second counter

    //Duty Cycle Counter

    assign d_next = (tick) ? d_reg + 1 : d_reg;//this counter only increments when "tick" is asserted (whenever dvsr is reached)
    assign d_ext = {1'b0, d_reg};//to be able to compare it, we add a bit

    //Comparison Circuit

    generate
        genvar i;
        for (i=0; i<W; i=i+1) 
            begin
                assign pwm_next[i] = d_ext < duty_2d_reg[i];//different comparators for different registers/output signals
            end
    endgenerate
    assign pwm_out = pwm_reg;

    //Read for Unused Data

    assign rd_data = 32'b0 ;

endmodule
