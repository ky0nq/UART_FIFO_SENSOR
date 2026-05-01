` timescale 1ns / 1ps
module counter_4 (
	input 		clk,
	input 		rst,

	output 	[1:0] 	digit_sel
	);

	reg [1:0] counter_reg;
	
	assign digit_sel = counter_reg;
	
	always @(posedge clk, posedge rst) begin
		if (rst) begin
			counter_reg <= 2'b00;
		end 
		else begin
			counter_reg <= counter_reg + 1;
		end
	end

endmodule
