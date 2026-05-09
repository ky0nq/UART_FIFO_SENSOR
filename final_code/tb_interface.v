`timescale 1ns / 1ps

// UART + FIFO + ASCII Decoder + ASCII Sender test module code
module tb_interface();

	parameter BAUD_PERIOD = ((100_000_000 / 9600) * 10);

	reg clk;
	reg rst;
	reg rx;
	reg btnU;
	reg btnR;
	reg btnD;
	reg btnL;
//	reg [31:0] digit_data;
	reg [1:0] data_type_sel;
	wire tx;
	wire dataU;
	wire dataR;
	wire dataD;
	wire dataL;

	integer i;

	// ASCII Input Data to simulate Interface Module
	reg [7:0] ascii_input_data;

	interface dut(
		.clk(clk),
		.rst(rst),
		.rx(rx),
		.btnU(btnU),
		.btnR(btnR),
		.btnD(btnD),
		.btnL(btnL),
		//.digit_data(digit_data),
		.data_type_sel(data_type_sel),
		.tx(tx),
		.dataU(dataU),
		.dataR(dataR),
		.dataD(dataD),
		.dataL(dataL)
	);

	// Task to simulate Serial input to RX module
	// =============================
    task SENDER_UART(input [7:0] send_data);
        begin
            // pc tx
            // start
            rx = 0;
            // start bit
            #(BAUD_PERIOD);
            // data bit
            for (i = 0; i < 8; i = i + 1) begin
                // rx, send_data[0 - 7]
                rx = send_data[i];
                #(BAUD_PERIOD);
            end
            // stop bit
            rx = 1;
            #(BAUD_PERIOD);
        end
    endtask
	// =============================

	always #5 clk = ~clk;

	initial begin
		clk = 0;
		rst = 1;
		rx = 1;
		btnU = 0;
		btnR = 0;
		btnD = 0;
		btnL = 0;

		ascii_input_data = 8'h55;
		//digit_data = 32'b0001_0010_0011_0010_0100_0010_0101_0001; // Indicate 12:32:42:51 Time
		data_type_sel = 2'b00;

		#20;
		rst = 0;
		repeat (3) @(negedge clk);

		// U ASCII Code input simulation
		// Expect to out 1 clk period btnU output signal
		SENDER_UART(ascii_input_data);
		repeat (10) #(BAUD_PERIOD);

		// s ASCII Code input simulation
		// Expect to out 1 clk period btnU output signal
		ascii_input_data = 8'h73;
		SENDER_UART(ascii_input_data);
		repeat (10) #(BAUD_PERIOD);

		$stop();
	end

endmodule
