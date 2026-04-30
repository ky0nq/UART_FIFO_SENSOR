// 26.04.18 22:06 Final code _ optimize 

`timescale 1ns / 1ps

module mux_8x1 (
    input [3:0] in0,
    input [3:0] in1,
    input [3:0] in2,
    input [3:0] in3,
    input [3:0] in4,
    input [3:0] in5,
    input [3:0] in6,
    input [3:0] in7, 
    input [2:0] sel,

    output [3:0] out_mux
);

    reg [3:0] out_reg;

    assign out_mux = out_reg;

    always @(*) begin
        case (sel) //sel 은 counter_8에서 나온 output
            3'b000:   out_reg = in0;
            3'b001:   out_reg = in1;
            3'b010:   out_reg = in2;
            3'b011:   out_reg = in3;
            3'b100:   out_reg = in4;
            3'b101:   out_reg = in5;
            3'b110:   out_reg = in6;
            3'b111:   out_reg = in7;
            default:  out_reg = 4'b0000;
        endcase
    end

endmodule