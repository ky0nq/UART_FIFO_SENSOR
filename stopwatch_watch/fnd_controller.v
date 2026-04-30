// 26.04.18 22:06 Final code _ optimize 

`timescale 1ns / 1ps

module fnd_controller #(
    parameter   MSEC_WIDTH =    7,
                SEC_WIDTH  =    6,
                MIN_WIDTH  =    6,
                HOUR_WIDTH =    5
) (
    input 		                clk,
    input                       rst,
    input                       sw0,
    input                       sw1,
    input                       sw9,
    input   [MSEC_WIDTH-1 : 0]  msec,
    input   [ SEC_WIDTH-1 : 0]  sec,
    input   [ MIN_WIDTH-1 : 0]  min,
    input   [HOUR_WIDTH-1 : 0]  hour,

    output 	[3:0] 	            fnd_com,
    output 	[7:0] 	            fnd_data,
    output                      o_led0,
    output                      o_led9
);
    // 각 자릿수에 대한 digit을 받기 위한 wire 선언
    wire 	[3:0] 	            w_msec_digit_1, w_msec_digit_10;
    wire 	[3:0] 	            w_sec_digit_1, w_sec_digit_10;
    wire 	[3:0] 	            w_min_digit_1, w_min_digit_10;
    wire 	[3:0] 	            w_hour_digit_1, w_hour_digit_10;

    wire 	[3:0] 	            w_hour_digit_1_out, w_hour_digit_10_out;
    wire 	[2:0] 	            w_digit_sel;
    wire 	[3:0] 	            w_out_mux_msec_sec, w_out_mux_min_hour, w_out_mux;
    wire 		                w_1khz; 
    wire                        w_dot_onff;
    

    assign o_led0 = sw0;

    clk_div_1khz U_CLK_DIV_1KHZ( 
        .clk		(clk),
        .rst		(rst),
        .o_1khz		(w_1khz) 
    );

    counter_8 U_COUNTER_8(
        .clk		(w_1khz), 
        .rst		(rst),
        .digit_sel	(w_digit_sel)
    );

    decoder_2x4 U_DECODER_2X4 (
        .decoder_in	(w_digit_sel[1:0]),
        .fnd_com	(fnd_com)
    );

    // tick counter에서 나오는 각 시간 단위 별 결과를 십진수로 자릿수 별 쪼개기 위한 digit splitter
    digit_splitter # (
        .BIT_WIDTH(MSEC_WIDTH)
    ) U_MSEC_DS (
        .digit_in    (msec),
        .digit_1     (w_msec_digit_1),
        .digit_10    (w_msec_digit_10)
    );

    digit_splitter # (
        .BIT_WIDTH(SEC_WIDTH)
    ) U_SEC_DS (
        .digit_in    (sec),
        .digit_1     (w_sec_digit_1),
        .digit_10    (w_sec_digit_10)
    );

    digit_splitter # (
        .BIT_WIDTH(MIN_WIDTH)
    ) U_MIN_DS (
        .digit_in    (min),
        .digit_1     (w_min_digit_1),
        .digit_10    (w_min_digit_10)
    );

    digit_splitter # (
        .BIT_WIDTH(HOUR_WIDTH)
    ) U_HOUR_DS (
        .digit_in    (hour),
        .digit_1     (w_hour_digit_1),
        .digit_10    (w_hour_digit_10)
    );

    // 12시간제 변환을 위한 hour converter 로직 구현
    hour_converter #(
        .HOUR_WIDTH(HOUR_WIDTH)
    ) U_HOUR_CONV (
        .hour_digit_1       (w_hour_digit_1),
        .hour_digit_10      (w_hour_digit_10),
        .hour               (hour),
        .sw9                (sw9),
        .sw1                (sw1),
        .o_hour_digit_1     (w_hour_digit_1_out),
        .o_hour_digit_10    (w_hour_digit_10_out),
        .o_led9_pm          (o_led9)
    );

    // msec를 이용하여 1/2초를 인식 -> DP (dot) 깜빡이게 하기 위한 비교기
    comparator # (
    .MSEC_WIDTH(MSEC_WIDTH)
    ) U_CMP_DOTONOFF (
        .comp_in(msec),
        .dot_onoff(w_dot_onff)
    );
    
    // counter_8에서 125hz마다 변화하는 w_digit_sel(counter_8에서는 digit_sel이라는 output)에 의해 각 입력 별 125hz마다 출력
    mux_8x1 U_MUX_MSEC_SEC (
        .in0		(w_msec_digit_1),
        .in1		(w_msec_digit_10),
        .in2		(w_sec_digit_1),
        .in3		(w_sec_digit_10),
        .in4		(4'hF),
        .in5		(4'hF),
        .in6		({3'b111, w_dot_onff}), // 1/2초마다 DP 깜빡이게
        .in7        (4'hF),
        .sel		(w_digit_sel),  
        .out_mux	(w_out_mux_msec_sec)
    );

    // hour converter에서 나온 출력을 연결
    mux_8x1 U_MUX_MIN_HOUR (
        .in0		(w_min_digit_1),
        .in1		(w_min_digit_10),
        .in2		(w_hour_digit_1_out),   // 해당 부분
        .in3		(w_hour_digit_10_out),  // 해당 부분
        .in4		(4'hF),
        .in5		(4'hF),
        .in6		({3'b111, w_dot_onff}), // 1/2초마다 DP 깜빡이게
        .in7        (4'hF),
        .sel		(w_digit_sel),  
        .out_mux	(w_out_mux_min_hour)
    );

    // mux에 꽂히는 sel (selection signal = sw0) 에 의해 선택
    mux_2x1 # (
        .BIT_WIDTH(4)
    ) U_MUX_OUT (
        .in0		(w_out_mux_msec_sec),
        .in1		(w_out_mux_min_hour),
        .sel		(sw0),  
        .out_mux	(w_out_mux)
    );

    // 각 수 별 7-segment 에 매핑되는 8-bit 출력 
    bcd U_BCD (
        .bin		(w_out_mux),
        .bcd_data	(fnd_data)
    );

endmodule
