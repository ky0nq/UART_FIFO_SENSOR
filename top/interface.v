`timescale 1ns / 1ps

module interface(
	input clk,
	input rst,
	input rx,
	input btnU,
	input btnR,
	input btnD,
	input btnL,
	input [31:0] digit_data,
	input [1:0] data_type_sel,
	output tx,
	output dataU,
	output dataR,
	output dataD,
	output dataL
);
	// wire for UART RX & FIFO RX
	wire [7:0] w_rx_data;
	wire w_rx_done;

	// wire for FIFO RX & ASCII Decoder
	wire [7:0] d_ascii_data;
	wire w_rx_empty;

	// wire for ASCII Decoder output & FPGA button debounce array output
	wire w_btn_dataU, w_btn_dataR, w_btn_dataD, w_btn_dataL;
	wire w_ascii_dataU, w_ascii_dataR, w_ascii_dataD, w_ascii_dataL;

	// wire for ASCII Decoder to ASCII Sender
	wire w_status;

	// wire for FIFO TX & ASCII Sender
	wire w_s_ascii_push;
	wire [7:0] w_s_ascii_data;

	// wire for UART TX & FIFO TX
	wire w_tx_busy;
	wire w_tx_empty;
	wire w_send_stop;
	wire [7:0] w_tx_data;

	// UART Module
	// =============================
	uart U_UART(
		.clk(clk),
		.rst(rst),
		.tx_start(~w_tx_empty),
		.tx_data(w_tx_data),
		.rx(rx),
		.rx_data(w_rx_data),
		.rx_done(w_rx_done),
		.tx_busy(w_tx_busy),
		.tx(tx)
	);
	// =============================

	// FIFO RX
	// Register File Size is 4 Bytes
	// =============================
	fifo #(
		.DEPTH(4)
	) U_FIFO_RX (
		.clk(clk),
		.rst(rst),
		.push(w_rx_done),
		.pop(~w_rx_empty),
		.push_data(w_rx_data),
		.pop_data(d_ascii_data),
		.full(), // fifo rx full signal is open
		.empty(w_rx_empty)
	);
	// =============================

	// ASCII Decoder
	// =============================
	ascii_decoder U_ASCII_DECODER(
		.clk(clk),
		.rst(rst),
		.d_ascii_data(d_ascii_data),
		.dec_start(~w_rx_empty),
		.ascii_dataU(w_ascii_dataU),  //8'h55  
		.ascii_dataR(w_ascii_dataR),  //8'h52
		.ascii_dataD(w_ascii_dataD),  //8'h44
		.ascii_dataL(w_ascii_dataL),  //8'h4c
		.status(w_status)  //8'h53 - s
	);
	// =============================
	
	// FPGA Button input array
	// =============================
	btn_input U_BTN_INPUT(
		.clk(clk),
		.rst(rst),
		.btnU(btnU),
		.btnR(btnR),
		.btnD(btnD),
		.btnL(btnL),
		.btn_dataU(w_btn_dataU),
		.btn_dataR(w_btn_dataR),
		.btn_dataD(w_btn_dataD),
		.btn_dataL(w_btn_dataL)
    );
	// =============================
	
	// Output data of U, R, D, L
	// =============================
	assign dataU = w_btn_dataU | w_ascii_dataU;
	assign dataR = w_btn_dataR | w_ascii_dataR;
	assign dataD = w_btn_dataD | w_ascii_dataD;
	assign dataL = w_btn_dataL | w_ascii_dataL;
	// =============================

	// ASCII SENDER
	// =============================
	ascii_sender U_ASCII_SENDER(
		.clk(clk),
		.rst(rst),
		.digit_data(digit_data),
		.status(w_status),
		.data_type_sel(data_type_sel),
		.send_stop(w_send_stop),
		.s_ascii_push(w_s_ascii_push),
		.s_ascii_data(w_s_ascii_data)
    );
	// =============================

	// FIFO TX
	// Register File Size is 32 Bytes
	// =============================
	fifo #(
		.DEPTH(32)
	) U_FIFO_TX (
		.clk(clk),
		.rst(rst),
		.push(w_s_ascii_push),
		.pop(~w_tx_busy),
		.push_data(w_s_ascii_data),
		.pop_data(w_tx_data),
		.full(w_send_stop),
		.empty(w_tx_empty)
	);
	// =============================

endmodule
