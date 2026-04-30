// 26.04.18 22:06 Final code _ optimize 

`timescale 1ns / 1ps

module digit_splitter # (
    parameter BIT_WIDTH = 7
)(
    input [BIT_WIDTH-1:0] digit_in,

    output [3:0] digit_1,
    output [3:0] digit_10
);
    // tick counter 에서 각 나온 결과값을 FND에 한 자리씩 보여주기 위해 자릿수 별 분리 로직
    assign digit_1 = digit_in % 10; 
    assign digit_10 = (digit_in / 10) % 10;

endmodule
