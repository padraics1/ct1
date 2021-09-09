//////////////////////////////////////////////////////////////////////////////////
// University of Limerick
// Design: FSM reaction timer game
// Author: Karl Rinne
// Create Date: 31/05/2020
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

module fsm_game
#(
    parameter           WAIT_2_SECONDS=2_000,
    parameter           WAIT_VLONG=3999,
    parameter           WAIT_LONG=1999,
    parameter           WAIT_MEDIUM=999,
    parameter           WAIT_SHORT=199,
    parameter           RND_MIN=200,
    parameter           RND_MAX=2999
)
(
    input wire          clk,                // clock input (rising edge)
    input wire          reset,              // reset input (synchronous)
    input wire          timebase,           // clock time base event (1ms expected)
    input wire          button,             // button to operate game (starts game sequence, stops reaction timer)
    output reg [2:0]    dis_sel,            // display select driving display mux
    output reg          beep,
    output reg          counter_clr,
    output reg          counter_en,
    input wire          counter_z,
    output wire [3:0]   fsm_state
);

`include "wordlength.v"
`include "fsm_game_states.v"

reg [S_NOB-1:0]         state;
reg [S_NOB-1:0]         next_state;

// Definitions of display strings
localparam              D_UL=0;
localparam              D_ECE=1;
localparam              D_MODULE=2;
localparam              D_LAB=3;
localparam              D_ID=4;
localparam              D_BCD=5;

// FSM timing
reg [wordlength(WAIT_VLONG)-1:0] counter;    // counter vector
reg [wordlength(WAIT_VLONG)-1:0] counter_load_value;
reg                     counter_load;       // counter load instruction
wire                    counter_zero;       // counter zero flag

reg [wordlength(WAIT_VLONG)-1:0] rnd_counter;    // pseudo-random up counter
wire                    rnd_counter_max;
reg                     counter_load_rnd;

// button logging (for the detection of cheating during state S_STEADY)
reg                     button_prev;
reg                     button_logged;
reg                     button_logged_clr;

// make FSM state accessible
assign fsm_state=state;

// general timing
always @ (posedge clk) begin
    if (reset) begin
        counter<=0;
    end
    else begin
        if (counter_load) begin
            counter<=counter_load_value;
        end else begin
            if (counter_load_rnd) begin
                counter<=rnd_counter;
            end else begin
                if ( (~counter_zero) & timebase) begin
                    counter<=counter-1'b1;
                end
            end
        end
    end
end
assign counter_zero=(counter==0);

// counter for generation of pseudo-random timing
always @ (posedge clk) begin
    if (reset) begin
        rnd_counter<=RND_MIN;
    end
    else begin
        if (timebase) begin
            if (rnd_counter_max) begin
                rnd_counter<=RND_MIN;
            end else begin
                rnd_counter<=rnd_counter+1;
            end
        end
    end
end
assign rnd_counter_max=(rnd_counter==RND_MAX);

// log button turn-on activity
always @ (posedge clk) begin
    if ( reset ) begin
        button_logged<=0;
    end
    else begin
        if (button_logged_clr) begin
            button_logged<=0; button_prev<=button;
        end else begin
            if ( button & (~button_prev) ) begin
                // log a button pressed event
                button_logged<=1;
            end
            button_prev<=button;
        end
    end
end

// Management of state register:
// Clock-synchronous progression from current state to next state. Also define reset state.
always @(posedge clk) begin
    if (reset) begin 
        state<=S_RESET;
    end else begin
        state<=next_state;
    end
end

// Next-state and output logic. Purely combinational.
always @(*) begin
    // define default next state, and default outputs
    next_state=state;
    counter_en=0;
    dis_sel=D_BCD; beep=0;
    counter_load=0; counter_load_value=WAIT_LONG; counter_load_rnd=0;
    button_logged_clr=0;
    case (state)
        S_RESET: begin
            counter_clr = 1;
            counter_load=1; counter_load_value=WAIT_LONG; 
            next_state=S_SHOW_UL;
        end
        S_SHOW_UL: begin
            dis_sel=D_UL;
            if ( counter_zero & (~button) ) begin
                counter_load=1; counter_load_value=WAIT_LONG;
                next_state=S_SHOW_ECE;
            end
        end
        S_SHOW_ECE: begin
            counter_clr=0;
            dis_sel=D_ECE;
            if ( counter_zero & (~button) ) begin
                counter_load=1; counter_load_value=WAIT_LONG;
                next_state=S_SHOW_MODULE;
            end
        end
        S_SHOW_MODULE: begin
            dis_sel=D_MODULE;
            if ( counter_zero & (~button) ) begin
                counter_load=1; counter_load_value=WAIT_LONG;
                next_state=S_SHOW_DESIGN;
            end
        end
        S_SHOW_DESIGN: begin
            dis_sel=D_LAB;
            if ( counter_zero & (~button) ) begin
                counter_load=1; counter_load_value=WAIT_LONG;
                next_state=S_SHOW_ID;
            end
        end
        S_SHOW_ID: begin
            dis_sel=D_ID;
            if ( counter_zero & (~button)) begin
                counter_load=1; counter_load_value=WAIT_LONG;
                next_state=S_STOP;
            end
        end
        S_STOP: begin
            dis_sel=D_BCD; counter_en=0;
            if (counter_zero & button ) begin
            counter_load=1; 
            next_state=S_COUNT;
            end
        end
        S_COUNT: begin
            dis_sel=D_BCD; counter_en=1;
            if ( counter_zero & button ) begin
            counter_load=1;
            next_state=S_STOP;
            end
            else if (counter_z) begin
            counter_load=1;
            next_state=S_ALARM;
            end
        end
        S_ALARM: begin
            beep=1;
            counter_clr=1; //reset to reload default time
            counter_clr=0;
            next_state = S_STOP;
        end
        default: begin
            next_state=S_RESET;	    // unexpected, but best to handle this event gracefully (e.g. single event upsets SEU's)
        end
    endcase
end

endmodule
