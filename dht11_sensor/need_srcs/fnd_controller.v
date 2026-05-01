`timescale 1ns / 1ps

module fnd_controller (
    input 		    clk,
    input 		    rst,
    input	[7:0] 	fnd_in,

    output 	[3:0] 	fnd_com,
    output 	[7:0] 	fnd_data
);
    wire 	[3:0] 	w_out_mux;
    wire 	[3:0] 	w_digit_1, w_digit_10, w_digit_100, w_digit_1000;
    wire 	[1:0] 	w_digit_sel;
    wire 		w_1khz; 

    clk_div_1khz U_CLK_DIV_1KHZ( 
        .clk		(clk),
        .rst		(rst),
        .o_1khz		(w_1khz) 
    );

    digit_splitter U_DIGIT_SPLIT (
        .digit_in	(fnd_in),
        .digit_1	(w_digit_1),
        .digit_10	(w_digit_10),
        .digit_100	(w_digit_100),
        .digit_1000	(w_digit_1000)
    );
    
    mux_4x1 U_MUX_4X1 (
        .in0		(w_digit_1),
        .in1		(w_digit_10),
        .in2		(w_digit_100),
        .in3		(w_digit_1000),
        .sel		(w_digit_sel),  
        .out_mux	(w_out_mux)
    );

    counter_4 U_COUNTER_4(
        .clk		(w_1khz), 
        .rst		(rst),
        .digit_sel	(w_digit_sel)
    );

    decoder_2x4 U_DECODER_2X4 (
        .decoder_in	(w_digit_sel),
        .fnd_com	(fnd_com)
    );

    bcd U_BCD (
        .bin		(w_out_mux),
        .bcd_data	(fnd_data)
    );

endmodule
