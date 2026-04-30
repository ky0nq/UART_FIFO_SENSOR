// 26.04.18 22:06 Final code _ optimize 

`timescale 1ns / 1ps

module decoder_2x4 (
    input [1:0] decoder_in,

    output reg [3:0] fnd_com
);
    // FND 4개의 Anode 선택
    // AN4 AN3 AN2 AN1에 대한 거 = 250Hz마다 선택 
    always @(*) begin
        case (decoder_in)
            2'b00:   fnd_com = 4'b1110;
            2'b01:   fnd_com = 4'b1101;
            2'b10:   fnd_com = 4'b1011;
            2'b11:   fnd_com = 4'b0111;
            default: fnd_com = 4'b1111;
        endcase
    end

endmodule
