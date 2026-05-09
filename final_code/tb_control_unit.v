`timescale 1ns / 1ps

module tb_control_unit();

	reg clk;
	reg rst;
	reg dht_done;
	reg [3:0] sw;
	reg dataU;
	reg dataR;
	reg dataD;
	reg dataL;

	wire run_stop;
	wire clear;
	wire mode;
	wire set;
	wire up;
	wire down;
	wire [2:0] place;
	wire sr04_start;
	wire tick_us;
	wire dht11_start;
	wire [1:0] data_type_sel;
	wire [1:0] fnddata_type_sel;

	// wire
	wire w_dataR;

	button_debounce U_BD(
		.clk(clk),
		.rst(rst),
		.i_btn(dataR),
		.o_btn(w_dataR)
	);

	control_unit dut(
		.clk(clk),
		.rst(rst),
		.dht_done(dht_done),
		.sw(sw),
		.dataU(dataU),
		.dataR(w_dataR),
		.dataD(dataD),
		.dataL(dataL),

		.run_stop(run_stop),
		.clear(clear),
		.mode(mode),
		.set(set),
		.up(up),
		.down(down),
		.place(place),
		.sr04_start(sr04_start),
		.tick_us(tick_us),
		.dht11_start(dht11_start),
		.data_type_sel(data_type_sel),
		.fnddata_type_sel(fnddata_type_sel)
	);

	always #5 clk = ~clk;
	
	initial begin
		clk = 0;
		rst = 1;
		dht_done = 0;
		sw = 4'b0000;
		dataU = 0;
		dataR = 0;
		dataD = 0;
		dataL = 0;

		#20
		rst = 0;
		repeat (2) @(negedge clk);

		// Stopwatch FSM Test
		// Setting at stopwatch
//		dataU = 1;
//		#20;
//		dataU = 0;
//		repeat (10) @(posedge clk);
		// Run Test
//		dataR = 1;
//		#11;
//		dataR = 0;
//		repeat (10) @(posedge clk);
//		// Stop Test
//		dataR = 1;
//		#11;
//		dataR = 0;
//		repeat (10) @(posedge clk);
//		// Clear Test
//		dataL = 1;
//		#11;
//		dataL = 0;
//		repeat (10) @(posedge clk);
//		// Mode Test
//		dataD = 1;
//		#11;
//		dataD = 0;
//		repeat (10) @(posedge clk);

		// Watch FSM Test
		// Setting at watch
		// Check that initial setting value is hour
//		sw = 4'b0111;
//		repeat (10) @(posedge clk);
//		// setting value change by input btnL or btnR
//		dataR = 1;
//		#11;
//		dataR = 0;
//		repeat (10) @(posedge clk);
//		dataL = 1;
//		#11;
//		dataL = 0;
//		repeat (10) @(posedge clk);
//
//		// Setting at sec
//		sw = 4'b0110;
//		repeat (10) @(posedge clk);
//

//		// Sensor FSM Test
//		// SR-04 Test
		sw = 4'b1000;
		repeat (1) @(posedge clk);
		dataR = 1;
		#80_000; // button input for 1 clk period
		dataR = 0;

		repeat (7_000_000) @(negedge clk);
//
//		// DHT11 Test
//		sw = 4'b1010;
//		// IDLE
//		repeat (1) @(posedge clk);
//		// DHT11 WAIT
//		repeat (1) @(posedge clk);
//		//repeat (1) @(posedge clk);
//		dataR = 1;
//		#80_000; // button input for 1 clk period
//		dataR = 0;
//		repeat (1_000) @(negedge clk);
//		dht_done = 1;
//		#11;
//		dht_done = 0;

		// IDLE State Transition Test
		sw = 4'b0000;
		repeat (10) @(negedge clk);
		$stop();

	end


endmodule

module button_debounce (
    input  clk,
    input  rst,
    input  i_btn,
    output o_btn
);
    // clock divider
    // 100MHz -> 100kHz
    parameter F_COUNT = 100_000_000 / 100_000;
    reg [$clog2(F_COUNT)-1:0] r_counter;
    reg clk_100khz;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_counter  <= 0;
            clk_100khz <= 0;
        end else begin
            r_counter <= r_counter + 1;
            if (r_counter == F_COUNT - 1) begin
                r_counter  <= 0;
                clk_100khz <= 1'b1;
            end else begin
                clk_100khz <= 1'b0;
            end
        end
    end

    // synchronizer
    reg [7:0] sync_reg, sync_next;
    wire debounce;

    always @(posedge clk_100khz or posedge rst) begin
        if (rst) begin
            sync_reg <= 8'h00;
        end else begin
            sync_reg <= sync_next;
        end
    end

    always @(*) begin
        sync_next = {sync_reg[6:0], i_btn};  // shift reg function
    end

    // 8 input to 1 output AND gate
    assign debounce = &sync_reg;

    // rising edge detect
    reg edge_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            edge_reg <= 1'b0;
        end else begin
            edge_reg <= debounce;
        end
    end

    // tick out
    assign o_btn = debounce & ~edge_reg;

endmodule
