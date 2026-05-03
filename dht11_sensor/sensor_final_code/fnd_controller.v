// fnd_controller.v
// 26.05.03 09:55 am

`timescale 1ns / 1ps

module fnd_controller (
    input 		    clk,
    input 		    rst,
    input	[23:0] 	fnd_in,

    output 	[3:0] 	fnd_com,
    output 	[7:0] 	fnd_data
);
    wire 	[23:0] 	w_out_mux;
    wire 	[23:0] 	w_digit_1_hum, w_digit_10_hum, w_digit_1_tem, w_digit_10_tem;
    wire 	[1:0] 	w_digit_sel;
    wire 		    w_1khz; 

    clk_div_1khz U_CLK_DIV_1KHZ( 
        .clk		(clk),
        .rst		(rst),
        .o_1khz		(w_1khz) 
    );

    digit_split_10 U_DIGIT_SPLIT_TEM (
        .digit_in	(fnd_in[15:8]),
        .digit_1	(w_digit_1_tem),
        .digit_10	(w_digit_10_tem)
    );

    digit_split_10 U_DIGIT_SPLIT_HUM (
        .digit_in	(fnd_in[7:0]),
        .digit_1	(w_digit_1_hum),
        .digit_10	(w_digit_10_hum)
    );

    counter_4 U_COUNTER_4(
        .clk		(w_1khz), 
        .rst		(rst),
        .digit_sel	(w_digit_sel)
    );
    
    mux_4x1_select U_FND_MUX_4X1 (
        .in0		(w_digit_1_hum),
        .in1		(w_digit_10_hum),
        .in2		(w_digit_1_tem),
        .in3		(w_digit_10_tem),
        .sel		(w_digit_sel),  
        .out_mux	(w_out_mux)
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

// ==================================================
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
			end
		end
	end

endmodule
// ==================================================

// ==================================================
module digit_split_10 (
    input [7:0] digit_in,

    output [3:0] digit_1,
    output [3:0] digit_10
);

    assign digit_1 = digit_in % 10;
    assign digit_10 = (digit_in / 10) % 10;

endmodule
// ==================================================
module mux_4x1_select (
    input [3:0] in0,
    input [3:0] in1,
    input [3:0] in2,
    input [3:0] in3,
    input [1:0] sel,

    output [3:0] out_mux
);

    reg [3:0] out_reg;

    assign out_mux = out_reg;

    always @(*) begin
        case (sel)
            2'b00:   out_reg = in0;
            2'b01:   out_reg = in1;
            2'b10:   out_reg = in2;
            2'b11:   out_reg = in3;
            default: out_reg = 4'b0000;
        endcase
    end

endmodule
// ==================================================

// ==================================================
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
// ==================================================

// ==================================================
module decoder_2x4 (
    input [1:0] decoder_in,

    output reg [3:0] fnd_com
);

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
// ==================================================

// ==================================================
module bcd(
	input 		[3:0]	bin,

	output reg	[7:0]	bcd_data
    );

    always @(bin) begin
        case (bin)
            4'b0000: bcd_data = 8'hC0;
            4'b0001: bcd_data = 8'hF9;
            4'b0010: bcd_data = 8'hA4;
            4'b0011: bcd_data = 8'hB0;
            4'b0100: bcd_data = 8'h99;
            4'b0101: bcd_data = 8'h92;
            4'b0110: bcd_data = 8'h82;
            4'b0111: bcd_data = 8'hF8;
            4'b1000: bcd_data = 8'h80;
            4'b1001: bcd_data = 8'h90;
            4'b1010: bcd_data = 8'h88;
            4'b1011: bcd_data = 8'h83;
            4'b1100: bcd_data = 8'hC6;
            4'b1101: bcd_data = 8'hA1;
            4'b1110: bcd_data = 8'h86;
            4'b1111: bcd_data = 8'h8E;
            default: bcd_data = 8'hFF; 
        endcase
    end

endmodule
// ==================================================
