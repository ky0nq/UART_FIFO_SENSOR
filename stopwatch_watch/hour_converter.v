// 26.04.18 22:06 Final code _ optimize 

`timescale 1ns / 1ps

module hour_converter #(
    parameter HOUR_WIDTH = 5
) (
    input  [3:0]            hour_digit_1,
    input  [3:0]            hour_digit_10,
    input  [HOUR_WIDTH-1:0] hour,
    input                   sw9,
    input                   sw1,

    output [3:0]            o_hour_digit_1,
    output [3:0]            o_hour_digit_10,
    output                  o_led9_pm
);
    wire [HOUR_WIDTH-1:0] w_hour_12;
    wire [HOUR_WIDTH-1:0] w_hour_disp;
    
    assign o_led9_pm    = sw9 && sw1 && (hour >= 5'd12) && (hour != 5'd0);
    assign w_hour_12    = (hour == 5'd0)  ? 5'd12 :
                          (hour <= 5'd12) ? hour   :
                                            hour - 5'd12;

    // sw9 = 1 : 12시간제 , sw9 = 0 : 24시간제
    // sw1 = 1 : watch , sw1 = 0 : stopwatch
    // 12시간제 + watch 면 12시간제로 계산한 값을 출력
    assign w_hour_disp = (sw9 && sw1) ? w_hour_12 : hour;

    // digit splitter 구현을 내부에 포함
    assign o_hour_digit_1  = w_hour_disp % 10;
    assign o_hour_digit_10 = w_hour_disp / 10;

endmodule