// mux_4x1.v
// 26.05.03 09:55 am

`timescale 1ns / 1ps

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
