`timescale 1ns / 1ps

module tb_ascii_sender();

	reg clk;
	reg rst;
	reg [31:0] digit_data;
	reg status;
	reg [1:0] data_type_sel;
	reg send_stop;
	wire s_ascii_push;
	wire [7:0] s_ascii_data;

	ascii_sender dut(
		.clk(clk),
		.rst(rst),
		.digit_data(digit_data),
		.status(status),
		.data_type_sel(data_type_sel),
		.send_stop(send_stop),
		.s_ascii_push(s_ascii_push),
		.s_ascii_data(s_ascii_data)
    );

	always #5 clk = ~clk;

	initial begin
		clk = 0;
		rst = 1;
		digit_data = 0;
		status = 0;
		data_type_sel = 2'b00;
		send_stop = 0;

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

		// Watch Data Send Simulation
		// Time value is 12:32:42:51
		digit_data = 32'b0001_0010_0011_0010_0100_0010_0101_0001;
		status = 1;
		data_type_sel = 2'b01;
		#11;
		status = 0; 
		repeat (20) @(negedge clk);

		$stop();
	end
endmodule
