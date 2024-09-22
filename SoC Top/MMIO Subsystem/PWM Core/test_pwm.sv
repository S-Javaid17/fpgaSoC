`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/30/2024 10:56:14 PM
// Design Name: 
// Module Name: test_pwm
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


module test_pwm
#(parameter R = 10) //Resolution/granularity    
    (
        input logic clk, reset,
        input logic [R: 0] duty,//extra bit because we want 100% duty cycle included
        input logic [31: 0] dvsr,//will ultimately determine the desired pwm freq.
        output logic pwm_out
    );

    //Signal and Register Declaration

    logic [R - 1: 0] counter_reg, counter_next;
    logic [R: 0] counter_ext;//extended, to add to comparison circuit
    logic out_reg, out_next;
    logic [31: 0] q_reg, q_next;
    logic tick;

    //Register Logic

    always_ff @( posedge clk, posedge reset ) 
    begin
        if (reset)
            begin
                counter_reg <= 0;
                out_reg <= 0;
                q_reg <= 0;
            end
        else
            begin
                counter_reg <= counter_next;
                out_reg <= out_next;
                q_reg <= q_next;
            end
    end

    //Prescale counter (aka the "timer")

    assign q_next = (q_reg == dvsr) ? 0 : q_reg + 1; //if the dvsr value is reached, the timer/prescale counter resets (sets frequency for the second timer)
    assign tick = q_reg == 0;                        // after the timer resets, it outputs a tick, which enables the second counter

    //Duty Cycle Counter

    assign counter_next = (tick) ? counter_reg + 1 : counter_reg ;//this counter only increments when "tick" is asserted (whenever dvsr is reached)
    assign counter_ext = {1'b0, counter_reg};//to be able to compare it, we add a bit

    //Comparison Circuit
    assign out_next = counter_ext < duty;
    assign pwm_out = out_reg;
endmodule