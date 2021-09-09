//////////////////////////////////////////////////////////////////////////////////
// University of Limerick
// Design: 4-digit BCD up counter, with clr input, stopping at full-scale
// Author: Karl Rinne
// Create Date: 29/05/2020
// Design Name: generic
// Revision: 1.0
//////////////////////////////////////////////////////////////////////////////////

// References
// [1] IEEE Standard Verilog Hardware Description Language, IEEE Std 1364-2001
// [2] Verilog Quickstart, 3rd edition, James M. Lee, ISBN 0-7923-7672-2
// [3] S. Palnitkar, "Verilog HDL: A Guide to Digital Design and Synthesis", 2nd Edition

// [10] Digilent "Nexys4 DDR FPGA Board Reference Manual", 11/04/2016, Rev C
// [11] Digilent "Nexys4 DDR Schematic", 06/10/2014, Rev C.1

`include "timing.v"

module bcd_counter_4d
(
    input wire          clk,                // clock input
    input wire          reset,              // reset input (synchronous)
    input wire          en,                 // counting enabled
    input wire          clr,                // clears counter (to 0)
    output wire         zero,               // flag indicating that 0 was reached
    output wire [15:0]  bcd                 // bcd out (4 digits)
);

// wires and regs
wire [3:0]      co;
wire [3:0]      zero_digits;
wire            en_cnt;

// create zero-scale signal
assign zero=&zero_digits;

// create a count enable signal
assign en_cnt=en&(~zero);

// instantiate the digits
bcd_counter_digit bcd0
(
    .clk(clk),
    .reset(reset),
    .up(1'b0),
    .en(en_cnt),
    .load(clr),
    .value(4'd5),
    .bcd(bcd[3:0]),
    .co(co[0]),
    .fs(zero_digits[0])
);

bcd_counter_digit bcd1
(
    .clk(clk),
    .reset(reset),
    .up(1'b0),
    .en(co[0]),
    .load(clr),
    .value(4'd2),
    .bcd(bcd[7:4]),
    .co(co[1]),
    .fs(zero_digits[1])
);

bcd_counter_digit bcd2
(
    .clk(clk),
    .reset(reset),
    .up(1'b0),
    .en(co[1]),
    .load(clr),
    .value(4'd3),
    .bcd(bcd[11:8]),
    .co(co[2]),
    .fs(zero_digits[2])
);

bcd_counter_digit bcd3
(
    .clk(clk),
    .reset(reset),
    .up(1'b0),
    .en(co[2]),
    .load(clr),
    .value(4'd0),
    .bcd(bcd[15:12]),
    .co(co[3]),
    .fs(zero_digits[3])
);

endmodule
