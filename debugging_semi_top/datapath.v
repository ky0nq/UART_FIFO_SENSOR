// 26.05.03 20:25

`timescale 1ns / 1ps

module datapath #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5,
    MSEC_SET = 0,
    SEC_SET = 0,
    MIN_SET = 0,
    HOUR_SET = 8,
    MSEC_INIT = 0,
    SEC_INIT = 0,
    MIN_INIT = 0,
    HOUR_INIT = 12
) (
    input       clk,
    input       rst,
    input       run_stop,
    input       clear,
    input       mode,
    input       set,
    input       up,
    input       down,
    input [2:0] place,
    input       sr04_start,
    input       tick_us,
    input       dht11_start,
    input [1:0] data_type_sel,  // sw[3], sw[1]
    input       sw2_and_1,

    input  echo,
    output trig,

    output        o_led15,
    output [23:0] fnd_data,
    output        dht_done,
    inout         dht11
);

    wire [23:0] w_st_fnddata, w_wt_fnddata, w_dist_fnddata, w_temhum_fnddata, w_stwt_fnddata;

    stopwatch_datapath #(
        .MSEC_WIDTH(7),
        .SEC_WIDTH (6),
        .MIN_WIDTH (6),
        .HOUR_WIDTH(5),
        .MSEC_SET  (0),
        .SEC_SET   (0),
        .MIN_SET   (0),
        .HOUR_SET  (8)
    ) U_ST_DATAPATH (
        .clk         (clk),
        .rst         (rst),
        .i_runstop   (run_stop),
        .i_clear     (clear),
        .i_mode      (mode),
        .i_set       (set),
        .st_time_data(w_st_fnddata)
    );

    watch_datapath #(
        .MSEC_WIDTH(7),
        .SEC_WIDTH (6),
        .MIN_WIDTH (6),
        .HOUR_WIDTH(5),
        .MSEC_INIT (0),
        .SEC_INIT  (0),
        .MIN_INIT  (0),
        .HOUR_INIT (12)
    ) U_WT_DATAPATH (
        .clk         (clk),
        .rst         (rst),
        .sw2_and_1   (sw2_and_1),
        .place       (place),
        .i_up        (up),
        .i_down      (down),
        .wt_time_data(w_wt_fnddata)
    );

    sr04_datapath U_SR04_DATAPATH (
        .clk       (clk),
        .rst       (rst),
        .sr04_start(sr04_start),
        .echo      (echo),
        .tick_us   (tick_us),
        .trig      (trig),
        .dist_data (w_dist_fnddata)
    );

    dht11_datapath U_DHT11_DATAPATH (
        .clk         (clk),
        .rst         (rst),
        .dht11_start (dht11_start),
        .tick_us     (tick_us),
        .tem_hum_data(w_temhum_fnddata),
        .valid       (o_led15),
        .dht_done    (dht_done),
        .dht11       (dht11)
    );

    mux_2x1 #(
        .BIT_WIDTH(24)
    ) U_STWT_MUX_2x1 (
        .in0(w_st_fnddata),
        .in1(w_wt_fnddata),
        .sel(data_type_sel[0]),
        .out_mux(w_stwt_fnddata)
    );

    mux_4x1 U_FNDIN_MUX_4x1 (
        .in0    (w_stwt_fnddata),
        .in1    (w_stwt_fnddata),
        .in2    (w_dist_fnddata),
        .in3    (w_temhum_fnddata),
        .sel    (data_type_sel),
        .out_mux(fnd_data)
    );
endmodule

module mux_4x1 #(
    parameter BIT_WIDTH = 24
) (
    input  [BIT_WIDTH-1:0] in0,
    input  [BIT_WIDTH-1:0] in1,
    input  [BIT_WIDTH-1:0] in2,
    input  [BIT_WIDTH-1:0] in3,
    input  [          1:0] sel,     // [sw3, sw0]
    output [BIT_WIDTH-1:0] out_mux
);

    // sel = sw[3] , sw[0]
    assign out_mux = (sel == 2'b00) ? in0 : 
                    (sel == 2'b01) ? in1 : 
                    (sel == 2'b10) ? in2 : in3;
endmodule

module mux_2x1 #(
    parameter BIT_WIDTH = 24
) (
    input  [BIT_WIDTH-1:0] in0,
    input  [BIT_WIDTH-1:0] in1,
    input                  sel,
    output [BIT_WIDTH-1:0] out_mux
);

    // sel = sw[1]
    assign out_mux = (sel) ? in1 : in0;

endmodule
