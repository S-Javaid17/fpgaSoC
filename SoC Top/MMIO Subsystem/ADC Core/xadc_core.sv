`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/30/2024 12:57:30 AM
// Design Name: 
// Module Name: xadc_core
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

// Xilinx ADC:
//  *in sequence mode
//  * DRP interface is connected to atomtically read out the pres-designated channels
//  * the readout is stored into corresponding registers

module xadc_core
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
        //outside-world --> external signals
        input  logic [3:0] adc_p,
        input  logic [3:0] adc_n// will be connected to GND, since we configured for unipolar mode
    );

                                            //Signal Declaration

    logic [4:0] channel;//out from XADC
    logic [6:0] daddr_in;
    logic eoc;//out from XADC
    logic rdy;//out from XADC
    logic [15:0]  adc_data;//out from XADC 
    logic [15:0] adc0_out_reg, adc1_out_reg, adc2_out_reg, adc3_out_reg;//registers for eaach channel
    logic [15:0] tmp_out_reg , vcc_out_reg ;//temperature and internal/core voltage registers
    logic [31:0] r_data;//to MCS 

                                            //Instantiate XADC

    xadc_fpro xadc_unit (
        // Clk and reset
            .dclk_in(clk),          // input 
            .reset_in(reset),        // input 
        // DRP Interface
            .di_in(16'h0000),              // input wire [15 : 0], data in for dynamic reconfiguration
            .daddr_in(daddr_in),        // input wire [6 : 0], Control and Status register addresses go here
            .den_in(eoc),            // input, register enable (for reading)
            .dwe_in(1'b0),            // input, write enable
            .drdy_out(rdy),        // output, data out is retrieved and ready 
            .do_out(adc_data),            // output wire [15 : 0], data out, read from active reg
        // Dedicated analog input channel (not used)
            .vp_in(1'b0),              // input 
            .vn_in(1'b0),              // input
        // Auxilliary analog input channels
            .vauxp2(adc_p[2]),     // input logic vauxp2
            .vauxn2(adc_n[2]),     // input logic vauxn2
            .vauxp3(adc_p[0]),     // input logic vauxp3
            .vauxn3(adc_n[0]),     // input logic vauxn3
            .vauxp10(adc_p[1]),    // input logic vauxp10
            .vauxn10(adc_n[1]),    // input logic vauxn10
            .vauxp11(adc_p[3]),    // input logic vauxp11
            .vauxn11(adc_n[3]),    // input logic vauxn11
        // Conversion status signals
            .channel_out(channel),  // output wire [4 : 0], the current channel number, which is th same as the 5 LSb of daddr_in 
            .eoc_out(eoc),          // output, end of conversion.  When the conversion result is written into the status register
            .eos_out(),          // output, end of sequence. When the measurement data from the last channel in a channel sequencer is written into the status register
            .busy_out(),        // output, high during an ADC conversion
        // Alarm output (not used)
            .alarm_out()      // output, logic OR of alarms, asserted for any alarm
    );
    
    assign daddr_in = {2'b00, channel};//refer to diagram in notes

                                            //Registers and Decoding Logic

    always_ff @( posedge clk, posedge reset ) 
        if (reset) 
        begin
            adc0_out_reg <= 16'h0000;
            adc1_out_reg <= 16'h0000;
            adc2_out_reg <= 16'h0000;
            adc3_out_reg <= 16'h0000;
            tmp_out_reg <= 16'h0000;
            vcc_out_reg <= 16'h0000;
        end 
        else 
        begin
            //The channel addresses(?) are taken from the XADC user guide
            if (rdy && channel == 5'b10011)//19 -->vaux3
                adc0_out_reg <= adc_data;
            if (rdy && channel == 5'b11010)//25 -->vaux10
                adc1_out_reg <= adc_data;
            if (rdy && channel == 5'b10010)//18 -->vaux2
                adc2_out_reg <= adc_data;
            if (rdy && channel == 5'b11011)//27 -->vaux11
                adc3_out_reg <= adc_data;
            if (rdy && channel == 5'b00000)//0 -->TEMP
                tmp_out_reg <= adc_data;
            if (rdy && channel == 5'b00001)//1 --> Vcc
                vcc_out_reg <= adc_data;
        end

                                            //Read Multiplexing

    always_comb 
        case (addr[2:0])
            3'b000:
                r_data <= {16'h0000, adc0_out_reg};
            3'b001:
                r_data <= {16'h0000, adc1_out_reg};
            3'b010:
                r_data <= {16'h0000, adc2_out_reg};
            3'b011:
                r_data <= {16'h0000, adc3_out_reg};
            3'b100:
                r_data <= {16'h0000, tmp_out_reg};
            default:
                r_data <= {16'h0000, vcc_out_reg};
      endcase
      assign rd_data = r_data;
endmodule
