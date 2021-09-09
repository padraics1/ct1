//////////////////////////////////////////////////////////////////////////////////
// University of Limerick
// Design: EE6621 FPGA counter ct1 (targeting Digilent Cmod A7-15T)
// Author: Padraic Sheehan
// Create Date: 27/05/2020
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

module fpga_wrapper_ct1
(
    input wire                  clk_raw_in,
    input wire [1:0]            btn,    // where btn[0] is closer to the PMOD connector
    output wire [1:0]           led,
    output wire                 led0_b,
    output wire                 led0_g,
    output wire                 led0_r,
    output wire                 pio48,  // wired to cathode g
    output wire                 pio47,  // wired to cathode a
    output wire                 pio46,  // wired to cathode f
    output wire                 pio45,  // wired to anode base an0
    output wire                 pio44,  // wired to anode base an2
    output wire                 pio43,  // provided for cathode dp (not supported by dual display)
    output wire                 pio42,  // provided for anode base an4 (not supported by 4-digit display)
    output wire                 pio41,  // provided for anode base an5 (not supported by 4-digit display)
    output wire                 pio40,  // provided for anode base an6 (not supported by 4-digit display)
    output wire                 pio39,  // provided for anode base an7 (not supported by 4-digit display)
    output wire                 pio8,   // buzzer_n
    output wire                 pio7,   // buzzer_p
    output wire                 pio6,   // wired to anode base an3
    output wire                 pio5,   // wired to anode base an1
    output wire                 pio4,   // wired to cathode b
    output wire                 pio3,   // wired to cathode c
    output wire                 pio2,   // wired to cathode e
    output wire                 pio1    // wired to cathode d
);

    // internal clock signals
    wire    clk_100MHz;
    wire    clk_locked;

    // Turn off RGB LED (cathodes are driven by i/o)
    assign  led0_b=1;
    assign  led0_g=1;
    assign  led0_r=1;

    // Turn off unused green LEDs (anodes are driven by i/o)
    assign  led[1]=0;

    // Instantiate clock generator
    clkgen_cmod_a7 clkgen_cmod_a7
    (
        .clk_raw_in(clk_raw_in),
        .reset_async(1'b0),
        .clk_200MHz(),
        .clk_100MHz(clk_100MHz),
        .clk_50MHz(),
        .clk_20MHz(),
        .clk_12MHz(),
        .clk_10MHz(),
        .clk_5MHz(),
        .clk_locked(clk_locked)
    );

    // Instantiate up1
    ct1 ct1
    (
        .clk(clk_100MHz),
        .reset(btn[0] & btn[1]),
        .turbosim(1'b0),
        .buttons({btn}),
        .d7_cathodes_n({pio43,pio48,pio46,pio2,pio1,pio3,pio4,pio47}),
        .d7_anodes({pio39,pio40,pio41,pio42,pio6,pio44,pio5,pio45}),
        .blink(led[0]),
        .buzzer_p(pio7),
        .buzzer_n(pio8),
        .bcd(),
        .fsm_state()
    );

endmodule
