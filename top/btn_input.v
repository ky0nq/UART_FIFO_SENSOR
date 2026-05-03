`timescale 1ns / 1ps

module btn_input(
	input clk,
	input rst,
	input btnU,
	input btnR,
	input btnD,
	input btnL,
	output btn_dataU,
	output btn_dataR,
	output btn_dataD,
	output btn_dataL
    );

	button_debounce U_BD_BTNU(
		.clk(clk),
		.rst(rst),
		.i_btn(btnU),
		.o_btn(btn_dataU)
	);

	button_debounce U_BD_BTNR(
		.clk(clk),
		.rst(rst),
		.i_btn(btnR),
		.o_btn(btn_dataR)
	);
	
	button_debounce U_BD_BTND(
		.clk(clk),
		.rst(rst),
		.i_btn(btnD),
		.o_btn(btn_dataD)
	);

	button_debounce U_BD_BTNL(
		.clk(clk),
		.rst(rst),
		.i_btn(btnL),
		.o_btn(btn_dataL)
	);

endmodule
