// 26.04.18 22:06 Final code _ optimize 

`timescale 1ns / 1ps

module comparator #(
    parameter MSEC_WIDTH = 7
) (
    input  [MSEC_WIDTH-1:0] comp_in,
    output                  dot_onoff
);

    // 0~49 : false 0, 50~99 : true 1
    assign dot_onoff = (comp_in > 49);

endmodule
