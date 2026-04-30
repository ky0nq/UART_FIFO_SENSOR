// 26.04.18 22:06 Final code _ optimize 

`timescale 1ns / 1ps

module clk_div_1khz (
	input		clk,
	input		rst,

	output		o_1khz
	);
	reg	[15:0]	counter_reg;
	reg		o_1khz_reg;

	assign 	o_1khz = o_1khz_reg;

	always @(posedge clk, posedge rst) begin
		if (rst) begin
			counter_reg <= 16'b0;
			o_1khz_reg <= 1'b0;
		end 
		else begin
			counter_reg <= counter_reg + 1;
			if (counter_reg == (50_000 - 1)) begin 
				o_1khz_reg <= ~o_1khz_reg;
				counter_reg <= 0;
			end
		end
	end

endmodule
