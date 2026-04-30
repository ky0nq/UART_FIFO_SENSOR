// 26.04.18 22:06 Final code _ optimize 

` timescale 1ns / 1ps

module counter_8 (
	input 		clk,
	input 		rst,
	
	output 	[2:0] 	digit_sel // 125hz 마다 selection signal
	);
	reg [2:0] counter_reg;
	
	assign digit_sel = counter_reg;
	
	always @(posedge clk, posedge rst) begin
		if (rst) begin
			counter_reg <= 3'b0;
		end 
		else begin
			counter_reg <= counter_reg + 1;
		end
	end

endmodule
