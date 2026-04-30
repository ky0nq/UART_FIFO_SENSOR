// 26.04.19 15:03 Final code _ optimize 

`timescale 1ns / 1ps

module watch_datapath #(
    parameter   MSEC_WIDTH =    7,
                SEC_WIDTH  =    6,
                MIN_WIDTH  =    6,
                HOUR_WIDTH =    5,
                MSEC_INIT =     0,
                SEC_INIT  =     0,
                MIN_INIT  =     0,
                HOUR_INIT =     12 
) (
    input                       clk,
    input                       rst,
    input                       sw2_and_1, // 시계-설정모드
    input  [2:0]                place, // 시계-설정모드일 때, 설정하는 위치 정보

    input                       i_up,
    input                       i_down,

    output [MSEC_WIDTH-1 : 0]   msec,
    output [ SEC_WIDTH-1 : 0]   sec,
    output [ MIN_WIDTH-1 : 0]   min,
    output [HOUR_WIDTH-1 : 0]   hour
);
    wire w_tick_100hz;
    wire w_sec_tick, w_min_tick, w_hour_tick;

    tick_gen_100hz_watch U_TICK_GEN_100HZ_WATCH (
        .clk            (clk),
        .rst            (rst),
        .sw2_and_1      (sw2_and_1), // 시계-설정모드
        .o_tick_100hz   (w_tick_100hz)
    );

    tick_counter_watch #(
        .TIMES          (100), 
        .BIT_WIDTH      (MSEC_WIDTH),
        .INIT           (MSEC_INIT)
    ) U_MSEC_TICK_COUNTER_WATCH (
        .clk            (clk),
        .rst            (rst),
        .i_tick         (w_tick_100hz),
        .sw2_and_1      (sw2_and_1),
        .place          (),
        .i_up           (i_up),
        .i_down         (i_down),
        .times_counter  (msec),
        .o_tick         (w_sec_tick)
    );

    tick_counter_watch #(
        .TIMES          (60), 
        .BIT_WIDTH      (SEC_WIDTH),
        .INIT           (SEC_INIT)
    ) U_SEC_TICK_COUNTER_WATCH (
        .clk            (clk),
        .rst            (rst),
        .i_tick         (w_sec_tick), // from msec o_tick
        .sw2_and_1      (sw2_and_1),
        .place          (place[0]),
        .i_up           (i_up),
        .i_down         (i_down),
        .times_counter  (sec),
        .o_tick         (w_min_tick)
    );

    tick_counter_watch #(
        .TIMES          (60), 
        .BIT_WIDTH      (MIN_WIDTH),
        .INIT           (MIN_INIT)
    ) U_MIN_TICK_COUNTER_WATCH (
        .clk            (clk),
        .rst            (rst),
        .i_tick         (w_min_tick), // from sec o_tick
        .sw2_and_1      (sw2_and_1),
        .place          (place[1]),
        .i_up           (i_up),
        .i_down         (i_down),
        .times_counter  (min),
        .o_tick         (w_hour_tick)
    );

    tick_counter_watch #(
        .TIMES          (24), 
        .BIT_WIDTH      (HOUR_WIDTH),
        .INIT           (HOUR_INIT)
    ) U_HOUR_TICK_COUNTER_WATCH (
        .clk            (clk),
        .rst            (rst),
        .i_tick         (w_hour_tick), // from min o_tick
        .sw2_and_1      (sw2_and_1),
        .place          (place[2]),
        .i_up           (i_up),
        .i_down         (i_down),
        .times_counter  (hour),
        .o_tick         ()
    );

endmodule