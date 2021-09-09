//////////////////////////////////////////////////////////////////////////////////
// University of Limerick
// Design: EE6621 rt2. Test bench for the FPGA wrapper
// Author: Karl Rinne
// Create Date: 23/07/2020
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

module tb01_fpga_wrapper_rt2;

    reg         clk;

    reg [1:0]   btn;            // L, R

    wire        led_l;          // led[1]
    wire        led_r;          // led[0]

    wire        led0_b, led0_g, led0_r;

    // 7-segment display (dp, g..a)
    wire [7:0]  d7_cathodes;    // pio's 43,48,46,2,1,3,4,47
    wire [7:0]  d7_anodes;      // pio's 39,40,41,42,6,44,5,45

    // buzzer
    wire        buzzer_p;       // pio7
    wire        buzzer_n;       // pio8

	// tb general purpose integer variables
	integer		i0;

	// tb error counter
    integer     error_counter;

    // Generate 100MHz clock signal (Nexys4 uses a 100MHz clock oscillator)
    initial begin
        clk = 0;                    // Signal clk starts at 0.
        #41.666;
        forever #41.666 clk=~clk;
    end

    // Generate simulation output (to screen)
    initial begin
        // Set the format used by the %t text format specifier. unit/precision/"suffix"/min_field_width
        // $timeformat(-9, 1, " ns", 12);
        $timeformat(-3, 3, " ms", 12);
        // $timeformat(-6, 3, " us", 12);
        $strobe("Sim Info: Welcome to EE6621 wrapper test. Module %m. Starting simulation at time %0t.",$time);
    end

    // Take DUT through test steps
    initial begin
        #2                          // ensure that this procedure starts after the initial welcome message
        error_counter=0;
        $strobe("========================================================");
        $strobe("Sim Info: Request reset, and wait for MMCM clocks to arrive");

        btn=2'b11;
        for(i0=0;i0<5;i0=i0+1) begin
            @(posedge dut.clk_100MHz);
        end
        #2
        btn=2'b00;
        $strobe("          MMCM clock is running. Released from reset...");

        $strobe("Sim Info: Test 1. Run one complete display cycle, check for string 'UL    '");

        wait ( d7_anodes==8'b0001_0000 )
        #10
        if ( d7_cathodes==8'b1100_0111 ) begin
        end else begin
            $strobe("FAIL: wrong character in display position 4, expected 'L'");
            $strobe("========================================================");
            error_counter=error_counter+1;
        end

        wait ( d7_anodes==8'b0010_0000 )
        #10
        if ( d7_cathodes==8'b1100_0001 ) begin
            $strobe("Sim Info: Test 1. *** PASS ***");

        end else begin
            $strobe("FAIL: wrong character in display position 4, expected 'U'");
            $strobe("========================================================");
            error_counter=error_counter+1;
        end

        #1_000

        $strobe();
        $strobe("========================================================");
        $strobe("Sim Info: Simulation finished normally with %0d error(s) at time %0t",error_counter,$time);
        $strobe("========================================================");

        #10 $finish;
    end

    // Instantiate the Unit Under Test (UUT) with turbosim asserted, for much increased simulation speed
    fpga_wrapper_rt2 dut
    (
        .clk_raw_in(clk),
        .btn(btn),
        .led({led_l,led_r}),
        .led0_b(led0_b),
        .led0_g(led0_g),
        .led0_r(led0_r),
        .pio48(d7_cathodes[6]),
        .pio47(d7_cathodes[0]),
        .pio46(d7_cathodes[5]),
        .pio45(d7_anodes[0]),
        .pio44(d7_anodes[2]),
        .pio43(d7_cathodes[7]),
        .pio42(d7_anodes[4]),
        .pio41(d7_anodes[5]),
        .pio40(d7_anodes[6]),
        .pio39(d7_anodes[7]),
        .pio8(buzzer_n),
        .pio7(buzzer_p),
        .pio6(d7_anodes[3]),
        .pio5(d7_anodes[1]),
        .pio4(d7_cathodes[1]),
        .pio3(d7_cathodes[2]),
        .pio2(d7_cathodes[4]),
        .pio1(d7_cathodes[3])
    );

    // Good practice: Set a hard-stop simulation time (in case simulation runs into no other $finish system call prior to this)
    initial begin
        #1_000_000_000      // define hard-stop time for simulation
        $strobe("Sim Info: Simulation hard-stopped at time %0t",$time);
        $finish;
    end

  // Generate output data for visual inspection (required for Icarus compiler/simulator and GtkWave graphical tool)
    //initial begin
        //$dumpfile("tb01_ct1.lxt2");
        //$dumpvars(0,tb01_ct1);
    //end

endmodule
