`timescale 1ns / 1ps

module tb_top();

	parameter BAUD_PERIOD = ((100_000_000 / 9600) * 10);
	parameter US_DELAY = 1_000;
	parameter MS_DELAY = 1_000_000;

	reg clk;
	reg rst;
	reg btnU;
	reg btnR;
	reg btnD;
	reg btnL;
	reg [3:0] sw;
	reg sw9;
	reg echo;
	reg rx;

	wire o_led0;
	wire o_led1;
	wire o_led2;
	wire o_led3;
	wire o_led9;
	wire o_led15;

	wire [3:0] fnd_com;
	wire [7:0] fnd_data;
	wire trig;
	wire tx;

	wire dht11;

	integer i;

	reg dht_sensor_data; // sensor data by dht11
	reg io_oe;
	parameter [7:0] HUMI_INT = 8'd60;  // humidity integral
    parameter [7:0] TEMP_INT = 8'd25;  // temperature integral
	reg [39:0] DATA_STREAM = {
        HUMI_INT, 8'h00, TEMP_INT, 8'h00, HUMI_INT + TEMP_INT
    };
	// tb io mode converter signal
    assign dht11 = (io_oe) ? dht_sensor_data : 1'bz;

	// ASCII Input Data to simulate Interface Module
	reg [7:0] ascii_input_data;

	top dut(
		.clk(clk),
		.rst(rst),
		.btnU(btnU),
		.btnR(btnR),
		.btnD(btnD),
		.btnL(btnL),
		.sw(sw),
		.sw9(sw9),
		.echo(echo),
		.rx(rx),

		.o_led0(o_led0),
		.o_led1(o_led1),
		.o_led2(o_led2),
		.o_led3(o_led3),
		.o_led9(o_led9),
		.o_led15(o_led15),

		.fnd_com(fnd_com),
		.fnd_data(fnd_data),
		.trig(trig),
		.tx(tx),

		.dht11(dht11)
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
		btnU = 0;
		btnR = 0;
		btnD = 0;
		btnL = 0;
		sw = 4'b0000;
		sw9 = 0;
		echo = 0;
		rx = 0;
		io_oe = 0;

		//digit_data = 32'b0001_0010_0011_0010_0100_0010_0101_0001; // Indicate 12:32:42:51 Time

		#20;
		rst = 0;
		repeat (3) @(negedge clk);

//		// Stopwatch State
//		// U ASCII Code input simulation
//		// Expect to out 1 clk period dataU output signal
//		ascii_input_data = 8'h55;
//		SENDER_UART(ascii_input_data);
//		repeat (10) #(BAUD_PERIOD);
//
//		// s ASCII Code input simulation
//		// Expect to out 1 clk period status output signal
//		ascii_input_data = 8'h73;
//		SENDER_UART(ascii_input_data);
//		repeat (10) #(BAUD_PERIOD);

		// SR-04 State
		// r ASCII Code input simulation
		// Expect to out 1 clk period dataR output signal
//		sw = 4'b1000;
//		ascii_input_data = 8'h72;
//		SENDER_UART(ascii_input_data);
//		repeat (10) #(BAUD_PERIOD);
//		// echo response
//		#(US_DELAY * 20);
//		echo = 1;
//		repeat (10) #(MS_DELAY);
//		echo = 0;

		// DHT11 State
		// r ASCII Code input simulation
		// Expect to out 1 clk period dataR output signal
		sw = 4'b1010;
		ascii_input_data = 8'h72;
		SENDER_UART(ascii_input_data);
		repeat (10) #(BAUD_PERIOD);

		// start stage ----
		wait (!dht11);
		wait (dht11);

		#30000;
        // input port mode
        io_oe = 1;
        // ---------------

        dht_sensor_data = 1'b0;
        #80000;
        dht_sensor_data = 1'b1;
        #80000;
        

        // sensor data ------------------------
        for (i = 39; i >= 0; i = i - 1) begin
            dht_sensor_data = 0;
            #50000;
            dht_sensor_data = 1'b1;
            #(DATA_STREAM[i] ? 70000 : 26000);
        end
        dht_sensor_data = 0;
        #50000;
        // ------------------------------------

        // output port mode
        io_oe = 0;
        #50000;
		#(MS_DELAY * 3);


		$stop();
	end

endmodule
