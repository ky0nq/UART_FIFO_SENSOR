// 26.04.19 13:08 Final code _ optimize 

`timescale 1ns / 1ps

module top_stopwatch_watch (
    input       clk,
    input       rst,
    input [2:0] sw,
    input       sw9,
    input       btnR,
    input       btnL,
    input       btnU,
    input       btnD,

    output [7:0] fnd_data,
    output [3:0] fnd_com,
    output [2:0] o_led,
    output       o_led9,
    output [3:0] o_led_wt_set
);

    parameter   MSEC_WIDTH =    7,
                SEC_WIDTH  =    6,
                MIN_WIDTH  =    6,
                HOUR_WIDTH =    5,
                MSEC_SET   =    0,  
                SEC_SET    =    0,  
                MIN_SET    =    0,  
                HOUR_SET   =    8,
                MSEC_INIT =     0,
                SEC_INIT  =     0,
                MIN_INIT  =     0,
                HOUR_INIT =     12;

    wire [MSEC_WIDTH-1 : 0] w_msec;
    wire [ SEC_WIDTH-1 : 0] w_sec;
    wire [ MIN_WIDTH-1 : 0] w_min;
    wire [HOUR_WIDTH-1 : 0] w_hour;

    wire [MSEC_WIDTH-1 : 0] w_msec_wt;
    wire [ SEC_WIDTH-1 : 0] w_sec_wt;
    wire [ MIN_WIDTH-1 : 0] w_min_wt;
    wire [HOUR_WIDTH-1 : 0] w_hour_wt;

    wire [MSEC_WIDTH-1 : 0] w_fnd_msec;
    wire [ SEC_WIDTH-1 : 0] w_fnd_sec;
    wire [ MIN_WIDTH-1 : 0] w_fnd_min;
    wire [HOUR_WIDTH-1 : 0] w_fnd_hour;

    wire w_btnR, w_btnL, w_btnD, w_btnU;
    wire w_runstop, w_clear, w_mode, w_set;

    // 시계 설정 모드를 위한 위치 정보
    wire [2:0] w_place;
    button_debounce U_BTNR (
        .clk  (clk),
        .rst  (rst),
        .i_Btn(btnR),
        .o_Btn(w_btnR)
    );

    button_debounce U_BTNL (
        .clk  (clk),
        .rst  (rst),
        .i_Btn(btnL),
        .o_Btn(w_btnL)
    );

    button_debounce U_BTND (
        .clk  (clk),
        .rst  (rst),
        .i_Btn(btnD),
        .o_Btn(w_btnD)
    );

    button_debounce U_BTNU (
        .clk  (clk),
        .rst  (rst),
        .i_Btn(btnU),
        .o_Btn(w_btnU)
    );

    top_cnt U_CNT (
        .clk         (clk),
        .rst         (rst),
        .sw0         (sw[0]),
        .sw1         (sw[1]),
        .sw2         (sw[2]),
        .btnL        (w_btnL),
        .btnR        (w_btnR),
        .btnD        (w_btnD),
        .btnU        (w_btnU),
        .o_st_runstop(w_runstop),
        .o_st_clear  (w_clear),
        .o_st_mode   (w_mode),
        .o_st_set    (w_set),
        .o_wt_place  (w_place)
    );

    stopwatch_datapath #(
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH (SEC_WIDTH),
        .MIN_WIDTH (MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH),
        .MSEC_SET  (MSEC_SET),
        .SEC_SET   (SEC_SET),
        .MIN_SET   (MIN_SET),
        .HOUR_SET  (HOUR_SET)
    ) U_STOPWATCH_DATAPATH (
        .clk      (clk),
        .rst      (rst),
        .i_runstop(w_runstop),
        .i_clear  (w_clear),
        .i_mode   (w_mode),
        .i_set    (w_set),
        .msec     (w_msec),
        .sec      (w_sec),
        .min      (w_min),
        .hour     (w_hour)
    );

    watch_datapath #(
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH (SEC_WIDTH),
        .MIN_WIDTH (MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH),
        .MSEC_INIT (MSEC_INIT),
        .SEC_INIT  (SEC_INIT),
        .MIN_INIT  (MIN_INIT),
        .HOUR_INIT (HOUR_INIT)
    ) U_WATCH_DATAPATH (
        .clk      (clk),
        .rst      (rst),
        .sw2_and_1(sw[2] & sw[1]),
        .place    (w_place),
        .i_up     (sw[1] && w_btnU),
        .i_down   (sw[1] && w_btnD),
        .msec     (w_msec_wt),
        .sec      (w_sec_wt),
        .min      (w_min_wt),
        .hour     (w_hour_wt)
    );

    // sw[1] 에 따라 FND로 stopwatch를 보여줄지 watch를 보여줄지 결정하는 mux 4개
    mux_2x1 #(
        .BIT_WIDTH(MSEC_WIDTH)
    ) U_MUX_MSEC_FND (
        .in0(w_msec),
        .in1(w_msec_wt),
        .sel(sw[1]),
        .out_mux(w_fnd_msec)
    );

    mux_2x1 #(
        .BIT_WIDTH(SEC_WIDTH)
    ) U_MUX_SEC_FND (
        .in0(w_sec),
        .in1(w_sec_wt),
        .sel(sw[1]),
        .out_mux(w_fnd_sec)
    );

    mux_2x1 #(
        .BIT_WIDTH(MIN_WIDTH)
    ) U_MUX_MIN_FND (
        .in0(w_min),
        .in1(w_min_wt),
        .sel(sw[1]),
        .out_mux(w_fnd_min)
    );

    mux_2x1 #(
        .BIT_WIDTH(HOUR_WIDTH)
    ) U_MUX_HOUR_FND (
        .in0(w_hour),
        .in1(w_hour_wt),
        .sel(sw[1]),
        .out_mux(w_fnd_hour)
    );

    fnd_controller U_FND_CNTL (
        .clk     (clk),
        .rst     (rst),
        .sw0     (sw[0]),
        .sw1     (sw[1]),
        .sw9     (sw9),
        .msec    (w_fnd_msec),
        .sec     (w_fnd_sec),
        .min     (w_fnd_min),
        .hour    (w_fnd_hour),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data),
        .o_led0  (o_led[0]),
        .o_led9  (o_led9)
    );

endmodule
