`timescale 1ns / 1ps

module top(
	input clk,
	input rst,
	input btnU,
	input btnR,
	input btnD,
	input btnL,
	input [3:0] sw,
	input sw9,
	input echo,
	input rx,

	output o_led0,
	output o_led1,
	output o_led2,
	output o_led3,
	output o_led9,
	output o_led15,

	output [3:0] fnd_com,
	output [7:0] fnd_data,
	output trig,
	output tx,

	inout dht11
);

	// wire for ASCII Decoder & Button input to Control Unit
	wire w_dataU, w_dataR, w_dataD, w_dataL;

	// wire for Control Unit to Datapath Signal
	// related to Stopwatch
	wire w_run_stop, w_clear, w_mode, w_set;
	// related to Watch
	wire w_up, w_down;
	wire [2:0] w_place;
	// related to Sensor
	wire w_tick_us;
	// related to SR04
	wire w_sr04_start;
	// related to DHT11
	wire w_dht11_start;

	// wire for Datapath to ASCII Sender
	wire [1:0] w_data_type_sel;
	wire w_dht_done;

	// wire for Datapath to FND Controller Signal
	wire [1:0] w_fnddata_type_sel;
	wire [23:0] w_fnd_in;

	// wire for FND Controller to ASCII Sender
	wire [31:0] w_digit_data;

	// LED Output
	// ==========================================================
	assign o_led0 = sw[0];
    assign o_led1 = sw[1];
    assign o_led2 = sw[2];
    assign o_led3 = sw[3];
	// ==========================================================
	
	// Interface module	
	// ==========================================================
	interface U_INTERFACE(
		.clk(clk),
		.rst(rst),
		.rx(rx),
		.btnU(btnU),
		.btnR(btnR),
		.btnD(btnD),
		.btnL(btnL),
		.digit_data(w_digit_data),
		.data_type_sel(w_data_type_sel),
		.tx(tx),
		.dataU(w_dataU),
		.dataR(w_dataR),
		.dataD(w_dataD),
		.dataL(w_dataL)
	);
	// ==========================================================

	// Control Unit
	// ==========================================================
	control_unit U_CONTROL_UNIT(
        .clk             (clk),
        .rst             (rst),
        .dht_done        (w_dht_done),
        .sw              (sw),
        .dataU            (w_dataU),
        .dataR            (w_dataR),
        .dataD            (w_dataD),
        .dataL            (w_dataL),
        .run_stop        (w_run_stop),
        .clear           (w_clear),
        .mode            (w_mode),
        .set             (w_set),
        .up              (w_up),
        .down            (w_down),
        .place           (w_place),
        .sr04_start      (w_sr04_start),
        .tick_us         (w_tick_us),
        .dht11_start     (w_dht11_start),
        .data_type_sel   (w_data_type_sel),
        .fnddata_type_sel(w_fnddata_type_sel)
    );
	// ==========================================================

	// Datapath
	// ==========================================================
	datapath #(
		.MSEC_WIDTH(7),
		.SEC_WIDTH(6),
		.MIN_WIDTH(6),
		.HOUR_WIDTH(5),
		.MSEC_SET(0),
		.SEC_SET(0),
		.MIN_SET(0),
		.HOUR_SET(8),
		.MSEC_INIT(0),
		.SEC_INIT(0),
		.MIN_INIT(0),
		.HOUR_INIT(12)
	) U_DATAPATH (
		.clk(clk),
		.rst(rst),
		.run_stop(w_run_stop),
		.clear(w_clear),
		.mode(w_mode),
		.set(w_set),
		.up(w_up),
		.down(w_down),
		.place(w_place),
		.sr04_start(w_sr04_start),
		.tick_us(w_tick_us),
		.dht11_start(w_dht11_start),
		.data_type_sel(w_data_type_sel),  // sw[3], sw[1]
		.sw2_and_1(sw[2]&sw[1]),
		.echo(echo),
		.trig(trig),
		.o_led15(o_led15),
		.fnd_data(w_fnd_in),
		.dht_done(w_dht_done),
		.dht11(dht11)
	);
	// ==========================================================
	
	// FND Controller
	// ==========================================================
	fnd_controller #(
        .MSEC_WIDTH(7),
        .SEC_WIDTH (6),
        .MIN_WIDTH (6),
        .HOUR_WIDTH(5)
    ) U_FND_CNTL (
        .clk             (clk),
        .rst             (rst),
        .sw9             (sw9),
        // digit data 
        .data_type_sel   (w_data_type_sel),  // sw[3], sw[1] 조합
        // fnd display data
        .fnddata_type_sel(w_fnddata_type_sel),  // sw[3], sw[0] 조합
        .place_sel       (w_place),
        .fnd_in          (w_fnd_in),
        .fnd_com         (fnd_com),
        .fnd_data        (fnd_data),
        .digit_data		 (w_digit_data),
        .o_led9          (o_led9)
    );
	// ==========================================================
endmodule
