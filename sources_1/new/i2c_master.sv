`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/08/2024 06:33:43 AM
// Design Name: 
// Module Name: i2c_master
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

// i2c single-master 
// * Limitation
//     * only function as I2C master
//     * no arbitration (i.e., no other master allowed)
//     * do not support slave "clock-stretching"
// * Input
//     cmd (command):  000:start, 001:write, 010:read, 011:stop, 100:restart
//     din: write:8-bit data;  read:LSB is ack/nack bit used in read
// * Output:
//     dout: received data
//     ack: received ack in write (should be 0)
// * Basic design
//     * external system
//          * generate proper start-write/read-stop condition
//          * use LSB of din (ack/nack) to indicate last byte in read
//     * FSM 
//          * loop 9 times for read/write (8 bit data + ack)
//          * no distiction between read/write 
//            (data  shift-in/shift-out simultaneously)
//     * Output control circuit   
//          * data out of sdat: loops 0-7 of write and loop 8 of read (send ack/nack)
//          * data into sdat: loops 0-7 of read and loop 8 of write (receive ack)
//    * dvsr: divisor to obtain a quarter of i2c clock period 
//          *  0.5*(# clk in SCK period) 
//         
// during a read operation, the LSB of din is the NACK bit
// i.e., indicate whether the current read is the last one in read cycle

//@aseddin on Github^^^

module i2c_master(
   input  logic clk, reset,
   input  logic [7:0] din,//to be transmitted
   input  logic [15:0] dvsr,//sets (4*)freq for scl  
   input  logic [2:0] cmd, //input which tells us which action to initiate
   input  logic wr_i2c,//enable for offset 2 (write cmd and din)
   output tri scl, //only master controls scl, and it uses a TSB
   inout  tri sda, //both master and slave share this line, which uses a TSB
   output logic ready, //indicates controller is ready for a new aaction
   output logic done_tick, //completed a transaction
   output logic ack, //acknowledge bit from slave
   output logic [7:0] dout//to be read/received
 );

 //cmd modes/constants

localparam START_CMD =   3'b000;
localparam WR_CMD =      3'b001;
localparam RD_CMD =      3'b010;
localparam STOP_CMD =    3'b011;
localparam RESTART_CMD = 3'b100;

//State types

typedef enum { 
    idle, start1, start2, hold, data1, data2, data3,
    data4, data_end, restart, stop1, stop2 
            } state_type;

//Internal signals and register declaration

state_type state_reg, state_next; //stores state
logic [2:0] cmd_reg, cmd_next; // stores the command data corresponding to actions
logic [3:0] bit_reg, bit_next; //stores the number of bits that've been sampled/driven
logic [8:0] tx_reg, tx_next; // stores the data to be transmitted + nack
logic [8:0] rx_reg, rx_next; //stores the data to be received + ack
logic [15:0] c_reg, c_next; // Stores the counter value
logic sda_reg, sda_out; // data out value
logic scl_reg, scl_out; // clock out value
logic data_phase; // does the current action involve transmitting data or not
logic into; // data going into master (Rx shift register) or not
logic nack; // not acknowledge
logic ready_i, done_tick_i; //registered signals
logic [15: 0] qtr, half; // quarter the SCL (corresponds to dvsr), and half the clock (twice the dvsr)

//TSB for SCL and SDA lines

always_ff @( posedge clk, posedge reset ) begin : TriStateBuffers
    if (reset)
        begin
            scl_reg <= 1'b1;//both lines are high on idle
            sda_reg <= 1'b1;
        end
    else
        begin
            scl_reg <= scl_out;
            sda_reg <= sda_out;
        end
end

assign into = (data_phase && cmd == WR_CMD && bit_reg == 8) || (data_phase && cmd == RD_CMD && bit_reg < 8);
//Meaning: Data is being written or read AND
//       [1] if data is being transmitted (WR), AND all 9 (8 data + dummy) bits have been sent [8:0] OR
//       [2] if data is being received (RD), AND all the 8 data bits (out of 9, --> ack bitfrom Tx) have been received [7:0]
//        in either of these cases, the TSB should be high impedance, so that the Tx is blocked off
//        --while the SDA sends data INTO/for the Rx. [1]  for slave to send ack bit after Tx send data, [2] Not High Imped. in the 9th bit because Tx must send an ack bit

assign sda = (into || sda_reg) ? 1'bz : 1'b0 ; //If data HIGH is being received (into) or sent(sda_reg), make SDA high impedance (the line is on high by default)
                                              //if data LOW is being received/sent, make SDA low
                                              //As such, a 1'b1 is the same as 1'bz, since the line is always high 
assign scl = (scl_reg) ? 1'bz : 1'b0; //Same concept

assign dout = rx_reg[8:1];
assign ack = rx_reg[0];//obtained from slave in write
assign nack = din[0];//transmitted by master in read

//Register Logic

always_ff @( posedge clk, posedge reset ) 
begin
    if (reset) 
        begin
            state_reg <= idle;
            c_reg     <= 0;
            bit_reg   <= 0;
            cmd_reg   <= 0;
            tx_reg    <= 0;
            rx_reg    <= 0;
        end
    else 
        begin
            state_reg <= state_next;
            c_reg     <= c_next;
            bit_reg   <= bit_next;
            cmd_reg   <= cmd_next;
            tx_reg    <= tx_next;
            rx_reg    <= rx_next;
        end
end

assign qtr = dvsr;
assign half = {qtr[14:0], 1'b0};// shift left by 1 === multipy by 2

//Next state logic

always_comb 
begin : FSM
    state_next = state_reg;
    c_next = c_reg + 1; //always counting up
    bit_next = bit_reg;
    cmd_next = cmd_reg;
    tx_next = tx_reg;
    rx_next = rx_next;
    done_tick_i = 1'b0;
    ready_i = 1'b0;
    scl_out = 1'b1;
    sda_out = 1'b1;
    data_phase = 1'b0;

    case (state_reg)
        
        idle:
            begin
                ready_i = 1'b1;
                if (wr_i2c && cmd == START_CMD)
                    begin
                        c_next = 0;
                        state_next = start1;
                    end
            end
        start1:
            begin
                sda_out = 1'b0;
                if (c_reg == half)
                    begin
                        c_next = 0;
                        state_next = start2;
                    end
            end
        start2:
            begin
                sda_out = 1'b0;
                scl_out = 1'b0;
                if (c_reg == half)//it said qtr in example, I believe it's an error
                    begin
                        c_next = 0;
                        state_next = hold;
                    end
            end
        hold:
            begin
                ready_i = 1'b1;
                sda_out = 1'b0;
                scl_out = 1'b0;
                if (wr_i2c)
                    begin
                        cmd_next = cmd;
                        c_next = 0;
                        case (cmd)
                            START_CMD, RESTART_CMD : 
                                begin
                                    state_next = restart;
                                end
                            STOP_CMD: 
                                begin
                                    state_next = stop1;
                                end 
                            default: 
                                begin
                                    state_next = data1;
                                    bit_next = 0;
                                    tx_next = {din, nack};//concatenate data and n-ack
                                end
                        endcase
                    end
            end
        data1:
            begin
                sda_out = tx_reg[8];
                scl_out = 1'b0;
                data_phase = 1'b1;
                if (c_reg == qtr)
                    begin
                        c_next = 0;
                        state_next = data2;
                    end
            end
        data2: //reading happens here
            begin
                sda_out = tx_reg[8];
                data_phase = 1'b1;
                if (c_reg == qtr)
                    begin
                        c_next = 0;
                        state_next = data3;
                        rx_next = {rx_reg[7:0], sda};//shift reg
                    end
            end
        data3:
            begin
                sda_out = tx_reg[8];
                data_phase = 1'b1;
                if (c_reg == qtr)
                    begin
                        c_next = 0;
                        state_next = data4;
                    end
            end
        data4:
            begin
                sda_out = tx_reg[8];
                scl_out = 1'b0;
                data_phase = 1'b1;
                if (c_reg == qtr)
                    begin
                        c_next = 0;
                        if (bit_reg == 8)
                            begin
                                state_next = data_end;
                                done_tick_i = 1'b1;
                            end
                        else
                            begin
                                tx_next = {tx_reg[7:0], 1'b0};//shift reg
                                bit_next = bit_reg + 1;
                                state_next = data1;
                            end
                    end
            end
        data_end:
            begin
                scl_out = 1'b0;
                sda_out = 1'b0;
                if (c_reg == qtr)
                    begin
                        c_next = 0;
                        state_next = hold;
                    end
            end
        restart:
            begin
                if (c_reg == half) 
                    begin
                        c_next= 0;
                        state_next = start1;
                    end
            end
        stop1:
            begin
                sda_out = 1'b0;
                if (c_reg == half)
                    c_next = 0;
                    state_next = stop2;
            end
        default: //covers stop2
            begin
                if (c_reg == half) 
                    state_next = idle;
            end     
    endcase
end

//Output logic

assign done_tick = done_tick_i;
assign ready = ready_i;
endmodule
