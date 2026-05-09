`timescale 1ns / 1ps

module tb_fifo_ascii_sender();

	reg clk;
	reg rst;
	reg [31:0] digit_data;
	reg status;
	reg [1:0] data_type_sel;
	wire tx;

	// wire for UART TX & FIFO TX
	wire w_tx_busy;
	wire w_empty;
	wire [7:0] w_tx_data;

	// wire for FIFO TX & ASCII Sender
	wire w_s_ascii_push;
	wire w_send_stop;
	wire [7:0] w_s_ascii_data;

	// UART Module
	// =============================
	uart U_UART(
		.clk(clk),
		.rst(rst),
		.tx_start(~w_empty),
		.tx_data(w_tx_data),
		.rx(),
		.rx_data(),
		.rx_done(),
		.tx_busy(w_tx_busy),
		.tx(tx)
	);
	// =============================

	// FIFO TX
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
		.empty(w_empty)
	);
	// =============================

	// ASCII SENDER
	// =============================
	ascii_sender U_ASCII_SENDER(
		.clk(clk),
		.rst(rst),
		.digit_data(digit_data),
		.status(status),
		.data_type_sel(data_type_sel),
		.send_stop(w_send_stop),
		.s_ascii_push(w_s_ascii_push),
		.s_ascii_data(w_s_ascii_data)
    );
	// =============================
	
	always #5 clk = ~clk;

	initial begin
		clk = 0;
		rst = 1;
		digit_data = 0;
		status = 0;
		data_type_sel = 2'b00;

		#20;
		rst = 0;

		repeat (3) @(negedge clk);
		// SR-04 Data Send Simulation
		// Value is 127cm
		// status is 1 clk period signal
		digit_data = 32'b0000_0000_0000_0000_0000_0001_0010_0111;
		status = 1;
		data_type_sel = 2'b10;
		#11;
		status = 0; 
		repeat (20) @(negedge clk);

		// DHT11 Data Send Simulation
		// Temp value is 18, Hum value is 28
		digit_data = 32'b0000_0000_0000_0000_0001_1000_0010_1000;
		status = 1;
		data_type_sel = 2'b11;
		#11;
		status = 0; 
		repeat (20) @(negedge clk);

		// Stopwatch Data Send Simulation
		// Time value is 12:32:42:51
		digit_data = 32'b0001_0010_0011_0010_0100_0010_0101_0001;
		status = 1;
		data_type_sel = 2'b00;
		#11;
		status = 0; 
		repeat (20) @(negedge clk);

//		// Watch Data Send Simulation
//		// Time value is 12:32:42:59
//		digit_data = 32'b0001_0010_0011_0010_0100_0010_0101_1001;
//		status = 1;
//		data_type_sel = 2'b01;
//		#11;
//		status = 0; 
//		repeat (20) @(negedge clk);

		$stop();
	end
endmodule
