// 26.04.18 22:06 Final code _ optimize 

` timescale 1ns / 1ps

module bcd(
	input 		[3:0]	bin,

	output reg	[7:0]	bcd_data
    );

    always @(bin) begin
        case (bin)
            // 숫자 별 display
            4'b0000: bcd_data = 8'hC0; // 0
            4'b0001: bcd_data = 8'hF9; // 1
            4'b0010: bcd_data = 8'hA4; // 2
            4'b0011: bcd_data = 8'hB0; // 3
            4'b0100: bcd_data = 8'h99; // 4
            4'b0101: bcd_data = 8'h92; // 5
            4'b0110: bcd_data = 8'h82; // 6
            4'b0111: bcd_data = 8'hF8; // 7
            4'b1000: bcd_data = 8'h80; // 8
            4'b1001: bcd_data = 8'h90; // 9
            4'b1010: bcd_data = 8'h88; // A (사용 x)
            4'b1011: bcd_data = 8'h83; // B (사용 x)
            4'b1100: bcd_data = 8'hC6; // C (사용 x)
            4'b1101: bcd_data = 8'hA1; // D (사용 x)
            4'b1110: bcd_data = 8'h7F; // dot 켜졌을 때
            4'b1111: bcd_data = 8'hFF; // dot 꺼졌을 때
            default: bcd_data = 8'hFF; 
        endcase
    end

endmodule