`timescale 1ns / 1ps

module control_unit(
	input clk,
	input rst,
	input dht_done,
	input [3:0] sw,
	input dataU,
	input dataR,
	input dataD,
	input dataL,

	output run_stop,
	output clear,
	output mode,
	output set,
	output up,
	output down,
	output [2:0] place,
	output sr04_start,
	output tick_us,
	output dht11_start,
	output [1:0] data_type_sel,
	output [1:0] fnddata_type_sel
);

	// wire for tick en signal
	wire w_tick_en;

	// us tick generator
	// ========================================
	tick_gen_us U_TICK_GEN_US(
		.clk(clk),
		.rst(rst),
		.tick_en(w_tick_en),
		.tick_us(tick_us)
	);
	// ========================================

	// Main Control logic
	// ========================================
	control_logic U_CONTROL_LOGIC(
		.clk(clk),
		.rst(rst),
		.tick_us(tick_us),
		.dht_done(dht_done),
		.sw(sw),
		.btnU(dataU),
		.btnR(dataR),
		.btnD(dataD),
		.btnL(dataL),
		.run_stop(run_stop),
		.clear(clear),
		.mode(mode),
		.set(set),
		.up(up),
		.down(down),
		.place(place),
		.sr04_start(sr04_start),
		.tick_en(w_tick_en),
		.dht11_start(dht11_start),
		.data_type_sel(data_type_sel),
		.fnddata_type_sel(fnddata_type_sel)
    );
	// ========================================

endmodule

module control_logic(
	input clk,
	input rst,
	input tick_us,
	input dht_done,
	input [3:0] sw,
	input btnU,
	input btnR,
	input btnD,
	input btnL,

	output run_stop,
	output clear,
	output mode,
	output set,
	output up,
	output down,
	output reg [2:0] place,
	output sr04_start,
	output tick_en,
	output dht11_start,
	output [1:0] data_type_sel,
	output [1:0] fnddata_type_sel
    );

	// param for state
	// Stopwatch & Watch State
	// IDLE State is needed to Reset the state
	// After 1 CLK Period, IDLE state transition to Sensor or ST/WT FSM depend on sw[3]
	parameter [3:0] IDLE = 0;
	parameter [3:0] STOP = 1;
	parameter [3:0] RUN = 2;
	parameter [3:0] CLEAR = 3;
	parameter [3:0] MODE = 4;
	parameter [3:0] WATCH = 5;
	parameter [3:0] HOUR = 6;
	parameter [3:0] MIN = 7;
	parameter [3:0] SEC = 8;
	// Sensor State
	parameter [3:0] SR04_WAIT = 9;
	parameter [3:0] SR04_START = 10;
	parameter [3:0] SR04_STOP = 11;
	parameter [3:0] DHT_WAIT = 12;
	parameter [3:0] DHT_START = 13;
	parameter [3:0] DHT_STOP = 14;

	reg [3:0] c_state, n_state;

	// Inner Wire & Register
	// wire for n to 1 MUX, to reduce 2 to 1 mux
	// for STOP state
	wire [3:0] stop_sel; 
	assign stop_sel = {sw[1], btnR, btnL, btnD}; 

	// tick enable signal to reduce power consumption
	reg tick_en_reg, tick_en_next;
	assign tick_en = tick_en_reg;
	// count input tick signal to wait 60ms for SR04 sensor
	reg [$clog2(60_000)-1:0] tick_cnt_reg, tick_cnt_next;

	// Output Wire & Register
	// stopwatch control signal
	reg run_stop_reg, run_stop_next;
	reg clear_reg, clear_next;
	reg mode_reg, mode_next;
	assign run_stop = run_stop_reg;
	assign clear = clear_reg;
	assign mode = mode_reg;


	// State Logic (SL)
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			// Reset State value
			c_state <= IDLE;
			// Reset tick related signal
			tick_en_reg <= 0;
			tick_cnt_reg <= 0;
			// Reset Stopwatch Control output
			run_stop_reg <= 0;
			clear_reg <= 0;
			mode_reg <= 0;
		end
		else begin
			// Update State value
			c_state <= n_state;
			// Update tick related signal
			tick_en_reg <= tick_en_next;
			tick_cnt_reg <= tick_cnt_next;
			// Update Stopwatch Control output
			run_stop_reg <= run_stop_next;
			clear_reg <= clear_next;
			mode_reg <= mode_next;
		end
	end

	// Next State Logic (CL)
	always @(*) begin
		// Initialize State value
		n_state = c_state;
		// Initialize tick related signal
		tick_en_next = tick_en_reg;
		tick_cnt_next = tick_cnt_reg;
		// Initialize Stopwatch Control output
		run_stop_next = run_stop_reg;
		clear_next = clear_reg;
		mode_next = mode_reg;

		case (c_state)
			// IDLE State is for Reset the System
			// When switching ST/WT to Sensor, State becomes IDLE & vice versa
			IDLE: begin
				if (sw[3]) begin
					if (sw[1]) begin
						n_state = DHT_WAIT;
					end
					else begin
						n_state = SR04_WAIT;
					end
				end
				else begin
					n_state = STOP;
				end
			end

			// State for Stopwatch
			STOP: begin
				tick_en_next = 1'b0;
				run_stop_next = 1'b0;
				clear_next = 1'b0;

				if (sw[3]) begin
					n_state = IDLE;
				end
				else begin
					case (stop_sel) 
						4'b1000: begin
							n_state = WATCH;
						end
						4'b0100: begin
							n_state = RUN;
						end
						4'b0010: begin
							n_state = CLEAR;
						end
						4'b0001: begin
							n_state = MODE;
						end
					endcase
				end
            end

            RUN: begin
				// tick_en signal should be changed
				// Because Sensor to RUN state is possible
				tick_en_next = 1'b0;
                run_stop_next = 1'b1; 
				if (sw[3]) begin
					n_state = IDLE;
				end
                else if (sw[1]) begin 
                    n_state = WATCH;
                end 
                else if (btnR) begin
                    n_state = STOP;
                end
            end

            CLEAR: begin 
                clear_next = 1'b1; 
                n_state = STOP;
            end

            MODE: begin 
                mode_next = ~mode_reg;
                n_state = STOP;
            end

			// State for Watch
            WATCH : begin
				if (sw[3]) begin
					n_state = IDLE;
				end
                else if (~sw[1]) begin
                    if (run_stop_reg) begin
                        n_state = RUN;
                    end
                    else begin
                        n_state = STOP;
                    end
                end
				else if (sw[2]) begin
					if (sw[0]) begin
						n_state = HOUR;
					end
					else begin
						n_state = SEC;
					end
				end
            end
            HOUR: begin
				if (sw[3]) begin
					n_state = IDLE;
				end
                else if (~sw[2]) begin
                    n_state = WATCH;
                end
                else if (~sw[1]) begin
                    if (run_stop_reg) begin
                        n_state = RUN;
                    end
                    else begin
                        n_state = STOP;
                    end
                end
                else if (~sw[0]) begin
                    n_state = SEC;
                end
                else if (btnL | btnR) begin
                    n_state = MIN;
                end
            end
            MIN: begin
				if (sw[3]) begin
					n_state = IDLE;
				end
                else if (~sw[2]) begin
                    n_state = WATCH;
                end
                else if (~sw[1]) begin
                    if (run_stop_reg) begin
                        n_state = RUN;
                    end
                    else begin
                        n_state = STOP;
                    end
                end
                else if (~sw[0]) begin
                    n_state = SEC;
                end
                else if (btnL | btnR) begin
                    n_state = HOUR;
                end
            end
            SEC: begin
				if (sw[3]) begin
					n_state = IDLE;
				end
                if (~sw[2]) begin
                    n_state = WATCH;
                end
                else if (~sw[1]) begin
                    if (run_stop_reg) begin
                        n_state = RUN;
                    end
                    else begin
                        n_state = STOP;
                    end
                end
                else if (sw[0]) begin
                    n_state = HOUR;
                end
            end

			// Sensor State
			// In every state (except start state) should have path to return to IDLE state
			// Ultrasound sensor
			SR04_WAIT: begin
				tick_en_next = 1;
				if (~sw[3]) begin
					if (run_stop_reg) begin
						n_state = RUN;
					end
					else begin
						n_state = IDLE;
					end
				end
				else if (sw[1]) begin
					n_state = DHT_WAIT;
				end
				else if (btnR) begin
					n_state = SR04_START;
				end
			end
			SR04_START: begin
				n_state = SR04_STOP;
				tick_cnt_next = 0;
			end
			SR04_STOP: begin
				if (~sw[3]) begin
					if (run_stop_reg) begin
						n_state = RUN;
					end
					else begin
						n_state = IDLE;
					end
				end
				else if (sw[1]) begin
					n_state = DHT_WAIT;
				end
				else begin
					if (tick_us == 1) begin
						tick_cnt_next = tick_cnt_reg + 1;
						if (tick_cnt_reg == 60_000) begin
							n_state = SR04_WAIT;
							tick_cnt_next = 0;
						end
					end
				end
			end

			// DHT11 Sensor
			DHT_WAIT: begin
				tick_en_next = 1;
				if (~sw[3]) begin
					if (run_stop_reg) begin
						n_state = RUN;
					end
					else begin
						n_state = IDLE;
					end
				end
				else if (~sw[1]) begin
					n_state = SR04_WAIT;
				end
				else if (btnR) begin
					n_state = DHT_START;
				end
			end
			DHT_START: begin
				n_state = DHT_STOP;
			end
			DHT_STOP: begin
				if (~sw[3]) begin
					if (run_stop_reg) begin
						n_state = RUN;
					end
					else begin
						n_state = IDLE;
					end
				end
				else if (~sw[1]) begin
					n_state = SR04_WAIT;
				end
				else if (dht_done) begin
					n_state = DHT_WAIT;
				end
			end
		endcase
	end

	// Output Logic (CL)
	// Stopwatch Set control signal
	assign set = ((c_state == STOP) && btnU) ? 1'b1 : 1'b0;

	// Watch Place control signal
	always @(*) begin
		case (c_state)
            WATCH : place = 3'b000;
            HOUR : place = 3'b100;
            MIN  : place = 3'b010;
            SEC  : place = 3'b001;
            default: place = 3'b000;
		endcase
	end
	// Watch Up/Down signal
	assign up = btnU & sw[1];
	assign down = btnD & sw[1];

	// SR-04 Control Signal
	assign sr04_start = (c_state == SR04_START) ? 1'b1 : 1'b0;
	// DHT11 Control Signal
	assign dht11_start = (c_state == DHT_START) ? 1'b1 : 1'b0;

	// fnddata_type_sel is signal to indicate which data is shown
	assign fnddata_type_sel[0] = (~sw[3] & sw[0]) | (sw[3] & sw[1]);
	assign fnddata_type_sel[1] = sw[3];
	// data_type_sel is signal to indicate which kind of data is shown
	assign data_type_sel = {sw[3], sw[1]};
endmodule

// us tick generator for tick count & sensor input tick_us
// tick enable signal to reduce power consumption
module tick_gen_us (
	input clk,
	input rst,
	input tick_en,
	output reg tick_us
);
	// parameter for counter bit width
	parameter F_COUNT = 100_000_000 / 1_000_000;
	//register for counter
	reg [$clog2(F_COUNT)-1:0] counter_reg;

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			counter_reg <= 0;
			tick_us <= 1'b0;
		end
		else begin
			if (tick_en) begin
				counter_reg <= counter_reg + 1;
				tick_us <= 1'b0;
				if (counter_reg == F_COUNT-1) begin
					counter_reg <= 0;
					tick_us <= 1'b1;
				end
			end
		end
	end

endmodule
