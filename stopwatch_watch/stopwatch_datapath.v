// 26.04.18 22:06 Final code _ optimize 

`timescale 1ns / 1ps

module stopwatch_datapath #(
    parameter   MSEC_WIDTH =    7,
                SEC_WIDTH  =    6,
                MIN_WIDTH  =    6,
                HOUR_WIDTH =    5,
                MSEC_SET   =    0,  // stopwatch set 하려면 어떤 값으로 할지 지정하는 부분
                SEC_SET    =    0,  
                MIN_SET    =    0,  
                HOUR_SET   =    8   
) (
    input                       clk,
    input                       rst,

    input                       i_runstop,
    input                       i_clear,
    input                       i_mode,
    input                       i_set,

    output [MSEC_WIDTH-1 : 0]   msec,
    output [ SEC_WIDTH-1 : 0]   sec,
    output [ MIN_WIDTH-1 : 0]   min,
    output [HOUR_WIDTH-1 : 0]   hour
);
    wire w_tick_100hz;

    wire w_sec_tick_up, w_min_tick_up, w_hour_tick_up;
    wire w_sec_tick_down, w_min_tick_down, w_hour_tick_down;

    // i_mode = 1 = down mode ->  00 00 | 00 00 이면 down 안 되게 판단하는 로직
    wire all_zero;
    assign all_zero = ((msec == 0) && (sec == 0) && (min == 0) && (hour == 0));
    
    tick_gen_100hz_stopwatch U_TICK_GEN_100HZ (
        .clk            (clk),
        .rst            (rst),
        .i_runstop      (i_runstop),
        .i_clear        (i_clear),
        .o_tick_100hz   (w_tick_100hz)
    );

    //msec
    tick_counter_stopwatch #(
        .TIMES          (100), 
        .BIT_WIDTH      (MSEC_WIDTH),
        .INIT           (MSEC_SET) 
    ) U_MSEC_TICK_COUNTER (
        .clk            (clk),
        .rst            (rst),
        .i_tick_up      (i_mode ? 1'b0 : w_tick_100hz), // up mode면 i_tick_up에 clock
        // down 이면 i_tick_down에 clock
        .i_tick_down    (i_mode ? (all_zero ? 1'b0 : w_tick_100hz) : 1'b0), 
        .i_clear        (i_clear),
        .i_mode         (i_mode),
        .i_set          (i_set),
        .times_counter  (msec),
        .o_tick_up      (w_sec_tick_up),
        // 0 이 되면 tick 이 나와서 앞선 시간 단위에 대해서 수에 -1 해주는 출력값
        .o_tick_down    (w_sec_tick_down)
    );

    // sec
    tick_counter_stopwatch #(
        .TIMES          (60), 
        .BIT_WIDTH      (SEC_WIDTH),
        .INIT           (SEC_SET)
    ) U_SEC_TICK_COUNTER (
        .clk            (clk),
        .rst            (rst),
        .i_tick_up      (w_sec_tick_up), // from msec o_tick_up
        .i_tick_down    (all_zero ? 1'b0 : w_sec_tick_down),
        .i_clear        (i_clear),
        .i_mode         (i_mode),
        .i_set          (i_set),
        .times_counter  (sec),
        .o_tick_up      (w_min_tick_up),
        .o_tick_down    (w_min_tick_down)
    );

    // min
    tick_counter_stopwatch #(
        .TIMES          (60), 
        .BIT_WIDTH      (MIN_WIDTH),
        .INIT           (MIN_SET)
    ) U_MIN_TICK_COUNTER (
        .clk            (clk),
        .rst            (rst),
        .i_tick_up      (w_min_tick_up), // from sec o_tick_up
        .i_tick_down    (all_zero ? 1'b0 : w_min_tick_down),
        .i_clear        (i_clear),
        .i_mode         (i_mode),
        .i_set          (i_set),
        .times_counter  (min),
        .o_tick_up      (w_hour_tick_up),
        .o_tick_down    (w_hour_tick_down)
    );
    
    // hour
    tick_counter_stopwatch #(
        .TIMES          (24), 
        .BIT_WIDTH      (HOUR_WIDTH),
        .INIT           (HOUR_SET)
    ) U_HOUR_TICK_COUNTER (
        .clk            (clk),
        .rst            (rst),
        .i_tick_up      (w_hour_tick_up), // from min o_tick_up
        .i_tick_down    (all_zero ? 1'b0 : w_hour_tick_down),
        .i_clear        (i_clear),
        .i_mode         (i_mode),
        .i_set          (i_set),
        .times_counter  (hour),
        .o_tick_up      (),
        .o_tick_down    ()
    );

endmodule