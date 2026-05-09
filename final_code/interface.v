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

// =======================================================================
module uart (
    input        clk,
    input        rst,
    input        tx_start,
    input  [7:0] tx_data,
    input        rx,
    output [7:0] rx_data,
    output       rx_done,
    output       tx_busy,
    output       tx
);

    // baud tick generator output to uart tx & rx input
    wire w_b_tick;

    // BAUD Tick generator
    // ======================================================
    baud_tick_gen U_BAUD_TICK_GEN (
        .clk     (clk),
        .rst     (rst),
        .o_b_tick(w_b_tick)
    );
    // ======================================================

    // TX module
    // ======================================================
    uart_tx U_UART_TX (
        .clk     (clk),
        .rst     (rst),
        .b_tick  (w_b_tick),
        .tx_start(tx_start),
        .tx_data (tx_data),   // ASCII Code 0
        .tx_busy (tx_busy),
        .tx      (tx)
    );
    // ======================================================

    // RX module
    // ======================================================
    uart_rx U_UART_RX (
        .clk    (clk),
        .rst    (rst),
        .b_tick (w_b_tick),
        .rx     (rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );
    // ======================================================

endmodule

// UART RX module
// ======================================================
module uart_rx (
    input            clk,
    input            rst,
    input            b_tick,
    input            rx,
    output reg [7:0] rx_data,
    output           rx_done
);

    // State
    parameter [1:0] IDLE = 0;
    parameter [1:0] START = 1;
    parameter [1:0] DATA = 2;
    parameter [1:0] STOP = 3;

    reg [1:0] c_state, n_state;

    // register to count tick
    reg [4:0] b_tick_cnt_reg, b_tick_cnt_next;
    // register to count input bit num
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    // register to receive data
    reg [7:0] data_reg, data_next, rx_data_next;
    // register to make rx done signal
    reg rx_done_reg, rx_done_next;
    assign rx_done = rx_done_reg;

    // Update Logic (SL)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state        <= IDLE;
            b_tick_cnt_reg <= 5'b0_0000;
            bit_cnt_reg    <= 3'b000;
            data_reg       <= 8'b0000_0000;
            rx_done_reg    <= 1'b0;
            rx_data        <= 0;
        end else begin
            c_state        <= n_state;
            b_tick_cnt_reg <= b_tick_cnt_next;
            bit_cnt_reg    <= bit_cnt_next;
            data_reg       <= data_next;
            rx_done_reg    <= rx_done_next;
            rx_data        <= rx_data_next;
        end
    end

    // Next State & Output Logic (CL)
    always @(*) begin
        n_state         = c_state;
        b_tick_cnt_next = b_tick_cnt_reg;
        bit_cnt_next    = bit_cnt_reg;
        data_next       = data_reg;
        rx_done_next    = rx_done_reg;
        rx_data_next    = rx_data;

        case (c_state)
            IDLE: begin
                rx_done_next = 1'b0;
                if (b_tick && ~rx) begin
                    //if (~rx) begin
                    b_tick_cnt_next = 0;
                    n_state         = START;
                end
            end

            START: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 7) begin
                        b_tick_cnt_next = 0;
                        bit_cnt_next    = 0;
                        n_state         = DATA;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end

            DATA: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        data_next       = {rx, data_reg[7:1]};
                        b_tick_cnt_next = 0;
                        if (bit_cnt_reg == 7) begin
                            b_tick_cnt_next = 0;
                            n_state         = STOP;
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end

            STOP: begin
                if (b_tick) begin
                    if ((b_tick_cnt_reg == 23) || (b_tick_cnt_reg > 15 && ~rx)) begin
                        n_state = IDLE;
                        rx_done_next = 1'b1;
                        rx_data_next = data_reg;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
        endcase
    end

endmodule
// ======================================================

// UART TX module
// ======================================================
module uart_tx (
    input        clk,
    input        rst,
    input        b_tick,
    input        tx_start,  // start trigger
    input  [7:0] tx_data,
    output       tx_busy,
    output       tx
);
    // 

    // State
    parameter [1:0] IDLE = 0;
    parameter [1:0] START = 1;
    parameter [1:0] DATA = 2;
    parameter [1:0] STOP = 3;

    reg [1:0] c_state, n_state;

    // output register
    reg tx_reg, tx_next;
    assign tx = tx_reg;
    // register to maintain input tx_data
    reg [7:0] data_reg, data_next;
    // register to count tick to baud frequency
    reg [3:0] b_tick_cnt_reg, b_tick_cnt_next;
    // register to count value according to the baud tick
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    // register to get tx busy value
    reg tx_busy_reg, tx_busy_next;
    assign tx_busy = tx_busy_reg;

    // Update logic (SL)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state        <= IDLE;
            tx_reg         <= 1'b1;
            data_reg       <= 8'b0000_0000;
            b_tick_cnt_reg <= 0;
            bit_cnt_reg    <= 3'b000;
            tx_busy_reg    <= 0;
        end else begin
            c_state        <= n_state;
            tx_reg         <= tx_next;
            data_reg       <= data_next;
            b_tick_cnt_reg <= b_tick_cnt_next;
            bit_cnt_reg    <= bit_cnt_next;
            tx_busy_reg    <= tx_busy_next;
        end
    end

    // Next state & Output logic (CL)
    always @(*) begin
        n_state         = c_state;
        tx_next         = tx_reg;
        data_next       = data_reg;
        b_tick_cnt_next = b_tick_cnt_reg;
        bit_cnt_next    = bit_cnt_reg;
        tx_busy_next    = tx_busy_reg;

        case (c_state)
            IDLE: begin
                tx_next      = 1'b1;
                tx_busy_next = 1'b0;
                if (tx_start) begin
                    n_state         = START;
                    data_next       = tx_data;
                    b_tick_cnt_next = 0;
                    tx_busy_next    = 1'b1;
                end
            end
            START: begin
                tx_next = 1'b0;
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        n_state         = DATA;
                        bit_cnt_next    = 3'b000;
                        b_tick_cnt_next = 4'b0000;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            DATA: begin
                tx_next = data_reg[0];

                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 4'b0000;
                        if (bit_cnt_reg == 7) begin
                            n_state = STOP;
                        end else begin
                            // shift operation to input data
                            data_next    = {1'b0, data_reg[7:1]};
                            bit_cnt_next = bit_cnt_reg + 1;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end

            STOP: begin
                tx_next = 1'b1;
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
						tx_busy_next = 1'b0;
                        b_tick_cnt_next = 0;
                        n_state         = IDLE;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
        endcase
    end

endmodule
// ======================================================

// tick generator according to baudrate
// ======================================================
module baud_tick_gen (
    input      clk,
    input      rst,
    output reg o_b_tick
);

    // Parameter for Baudrate and Count value
    // BAUDRATE x 16 to rx can receive data safely
    parameter BAUDRATE = 9600 * 16;
    parameter F_COUNT = 100_000_000 / BAUDRATE;
    parameter BIT_WIDTH = $clog2(F_COUNT);

    // Inner counter
    reg [BIT_WIDTH-1:0] counter_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            o_b_tick    <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            o_b_tick    <= 1'b0;
            if (counter_reg == (F_COUNT - 1)) begin
                counter_reg <= 0;
                o_b_tick    <= 1'b1;
            end
        end
    end

endmodule
// =======================================================================

// =======================================================================
module fifo #(
    parameter DEPTH = 4,
    parameter BIT_WIDTH = $clog2(DEPTH)
) (
    input        clk,
    input        rst,
    input        push,
    input        pop,
    input  [7:0] push_data,
    output [7:0] pop_data,
    output       full,
    output       empty
);

    // wire for ptr to address
    wire [BIT_WIDTH-1:0] w_w_ptr, w_r_ptr;

    // Register FILE
    // ===========================================
    register_file #(
        .DEPTH(DEPTH)
    ) U_REG_FILE (
        .clk   (clk),
        .w_addr(w_w_ptr),
        .r_addr(w_r_ptr),
        .w_data(push_data),
        .we    ((~full) & push),
        .r_data(pop_data)
    );
    // ===========================================

    // Control unit    
    // ===========================================
    fifo_control_unit #(
        .DEPTH(DEPTH)
    ) U_CONTROL_UNIT (
        .clk  (clk),
        .rst  (rst),
        .push (push),
        .pop  (pop),
        .w_ptr(w_w_ptr),
        .r_ptr(w_r_ptr),
        .full (full),
        .empty(empty)
    );
    // ===========================================
endmodule

module register_file #(
    parameter DEPTH = 4,
    parameter BIT_WIDTH = $clog2(DEPTH)
) (
    input                  clk,
    input  [BIT_WIDTH-1:0] w_addr,
    input  [BIT_WIDTH-1:0] r_addr,
    input  [          7:0] w_data,
    input                  we,
    output [          7:0] r_data
);

    reg [7:0] register_file[0:DEPTH-1];

    always @(posedge clk) begin
        if (we) begin
            register_file[w_addr] <= w_data;
        end
    end

    assign r_data = register_file[r_addr];

endmodule

module fifo_control_unit #(
    parameter DEPTH = 4,
    parameter BIT_WIDTH = $clog2(DEPTH)
) (
    input                  clk,
    input                  rst,
    input                  push,
    input                  pop,
    output [BIT_WIDTH-1:0] w_ptr,
    output [BIT_WIDTH-1:0] r_ptr,
    output                 full,
    output                 empty
);

    // SL for w_ptr & r_ptr
    reg [BIT_WIDTH-1:0] w_ptr_reg, w_ptr_next;
    reg [BIT_WIDTH-1:0] r_ptr_reg, r_ptr_next;
    assign w_ptr = w_ptr_reg;
    assign r_ptr = r_ptr_reg;

    // SL for full & empty
    reg full_reg, full_next;
    reg empty_reg, empty_next;
    assign full  = full_reg;
    assign empty = empty_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            w_ptr_reg <= 0;
            r_ptr_reg <= 0;
            full_reg  <= 1'b0;
            empty_reg <= 1'b1;
        end else begin
            w_ptr_reg <= w_ptr_next;
            r_ptr_reg <= r_ptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end

    always @(*) begin
        w_ptr_next = w_ptr_reg;
        r_ptr_next = r_ptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;

        case ({
            push, pop
        })
            // pop op
            2'b01: begin
                if (~empty) begin
                    r_ptr_next = r_ptr_reg + 1;
                    full_next  = 1'b0;
                    if (r_ptr_next == w_ptr_reg) begin
                        empty_next = 1'b1;
                    end
                end
            end

            // push op
            2'b10: begin
                if (~full) begin
                    w_ptr_next = w_ptr_reg + 1;
                    empty_next = 1'b0;
                    if (w_ptr_next == r_ptr_reg) begin
                        full_next = 1'b1;
                    end
                end
            end

            // push & pop operation
            2'b11: begin
                if (full_reg) begin
                    r_ptr_next = r_ptr_reg + 1;
                    full_next  = 1'b0;
                end else if (empty_reg) begin
                    w_ptr_next = w_ptr_reg + 1;
                    empty_next = 1'b0;
                end else begin
                    w_ptr_next = w_ptr_reg + 1;
                    r_ptr_next = r_ptr_reg + 1;
                end
            end
        endcase
    end

endmodule
// =======================================================================

// =======================================================================
module ascii_decoder (
    input clk,
    input rst,
    input [7:0] d_ascii_data,
    input dec_start,
    output ascii_dataU,  //8'h55  
    output ascii_dataR,  //8'h52
    output ascii_dataD,  //8'h44
    output ascii_dataL,  //8'h4c
    output status  //8'h53 - s
);

	// param for state
	parameter IDLE = 0;
	parameter DECODE = 1;

	reg c_state, n_state;
	reg [7:0] d_ascii_data_reg, d_ascii_data_next;

	// wire
	wire [7:0] data_is_u, data_is_r, data_is_d, data_is_l;

	assign data_is_u = (d_ascii_data_reg == 8'h75) | (d_ascii_data_reg == 8'h55);
	assign data_is_r = (d_ascii_data_reg == 8'h72) | (d_ascii_data_reg == 8'h52);
	assign data_is_d = (d_ascii_data_reg == 8'h64) | (d_ascii_data_reg == 8'h44);
	assign data_is_l = (d_ascii_data_reg == 8'h6C) | (d_ascii_data_reg == 8'h4C);
	assign data_is_s = (d_ascii_data_reg == 8'h73) | (d_ascii_data_reg == 8'h53);

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			c_state <= IDLE;
			d_ascii_data_reg <= 0;
		end
		else begin
			c_state <= n_state;
			d_ascii_data_reg <= d_ascii_data_next;
		end
	end

	always @(*) begin
		n_state = c_state;
		d_ascii_data_next = d_ascii_data_reg;

		case (c_state)
			IDLE: begin
				if (dec_start) begin
					n_state = DECODE;
					d_ascii_data_next = d_ascii_data;
				end
			end
			DECODE: begin
				n_state = IDLE;
				d_ascii_data_next = 0;
			end
		endcase
	end

	// output logic
	assign ascii_dataU = ((c_state == DECODE) & data_is_u) ? 1'b1 : 1'b0;
	assign ascii_dataR = ((c_state == DECODE) & data_is_r) ? 1'b1 : 1'b0;
	assign ascii_dataD = ((c_state == DECODE) & data_is_d) ? 1'b1 : 1'b0;
	assign ascii_dataL = ((c_state == DECODE) & data_is_l) ? 1'b1 : 1'b0;
	assign status = ((c_state == DECODE) & data_is_s) ? 1'b1 : 1'b0;

endmodule
// =======================================================================

// =======================================================================
module btn_input(
	input clk,
	input rst,
	input btnU,
	input btnR,
	input btnD,
	input btnL,
	output btn_dataU,
	output btn_dataR,
	output btn_dataD,
	output btn_dataL
    );

	button_debounce U_BD_BTNU(
		.clk(clk),
		.rst(rst),
		.i_btn(btnU),
		.o_btn(btn_dataU)
	);

	button_debounce U_BD_BTNR(
		.clk(clk),
		.rst(rst),
		.i_btn(btnR),
		.o_btn(btn_dataR)
	);
	
	button_debounce U_BD_BTND(
		.clk(clk),
		.rst(rst),
		.i_btn(btnD),
		.o_btn(btn_dataD)
	);

	button_debounce U_BD_BTNL(
		.clk(clk),
		.rst(rst),
		.i_btn(btnL),
		.o_btn(btn_dataL)
	);

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
// =======================================================================

// =======================================================================
module ascii_sender(
	input clk,
	input rst,
	input [31:0] digit_data,
	input status,
	input [1:0] data_type_sel,
	input send_stop,
	output s_ascii_push,
	output [7:0] s_ascii_data
    );

	// wire for control signal
	wire [2:0] w_data_cnt;
	wire [4:0] w_msg_addr;
	wire w_msg_sel;

	ascii_sender_control_unit U_ASCII_SENDER_CONTROL_UNIT(
		.clk(clk),
		.rst(rst),
		.status(status),
		.data_type_sel(data_type_sel),
		.send_stop(send_stop),
		.data_cnt(w_data_cnt),
		.msg_addr(w_msg_addr),
		.msg_sel(w_msg_sel),
		.s_ascii_push(s_ascii_push)
	);

	ascii_sender_datapath U_ASCII_SENDER_DATAPATH(
		.clk(clk),
		.rst(rst),
		.digit_data(digit_data),
		.data_cnt(w_data_cnt),
		.msg_addr(w_msg_addr),
		.msg_sel(w_msg_sel),
		.send_stop(send_stop),
		.s_ascii_data(s_ascii_data)
	);

endmodule

module ascii_sender_control_unit(
	input clk,
	input rst,
	input status,
	input [1:0] data_type_sel,
	input send_stop,
	output [2:0] data_cnt,
	output [4:0] msg_addr,
	output msg_sel,
	output s_ascii_push
);
	// Parameter for State
	parameter [3:0] IDLE = 0;
	parameter [3:0] TIME_MSG = 1;
	parameter [3:0] BS_TIME = 2;
	parameter [3:0] TIME_DATA = 3;
	parameter [3:0] COLON = 4;
	parameter [3:0] SR04_MSG = 5;
	parameter [3:0] BS_SR04 = 6;
	parameter [3:0] SR04_DATA = 7;
	parameter [3:0] TEMP_MSG = 8;
	parameter [3:0] BS_TEMP = 9;
	parameter [3:0] TEMP_DATA = 10;
	parameter [3:0] TEMP_BS_HUM = 11;
	parameter [3:0] HUM_MSG = 12;
	parameter [3:0] BS_HUM = 13;
	parameter [3:0] HUM_DATA = 14;
	parameter [3:0] STOP = 15;

	reg [3:0] c_state, n_state;

	// Select Signal for sender datapath
	reg [2:0] data_cnt_reg, data_cnt_next;
	assign data_cnt = data_cnt_reg;
	reg [4:0] msg_addr_reg, msg_addr_next;
	assign msg_addr = msg_addr_reg;
	reg msg_sel_reg, msg_sel_next;
	assign msg_sel = msg_sel_reg;

	// Singal to send Colon ASCII Code when sending time value
	reg [2:0] time_cnt_reg, time_cnt_next;

	// Output Signal of ASCII Sender Module
	reg s_ascii_push_reg, s_ascii_push_next;
	assign s_ascii_push = s_ascii_push_reg;

	// Sequential Logic
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			c_state <= IDLE;
			data_cnt_reg <= 0;
			time_cnt_reg <= 0;
			msg_addr_reg <= 0;
			msg_sel_reg <= 0;
			s_ascii_push_reg <= 0;
		end
		else begin
			if (~send_stop) begin
				c_state <= n_state;
				data_cnt_reg <= data_cnt_next;
				time_cnt_reg <= time_cnt_next;
				msg_addr_reg <= msg_addr_next;
				msg_sel_reg <= msg_sel_next;
				s_ascii_push_reg <= s_ascii_push_next;
			end
		end
	end

	// Next State Logic & Output Logic (CL)
	always @(*) begin
		// initialize register value
		n_state = c_state;
		data_cnt_next = data_cnt_reg;
		time_cnt_next = time_cnt_reg;
		msg_addr_next = msg_addr_reg;
		msg_sel_next = msg_sel_reg;
		s_ascii_push_next = s_ascii_push_reg;

		// Logic
		case (c_state)
			IDLE: begin
				s_ascii_push_next = 0;
				msg_sel_next = 0;

				if (status) begin
					msg_sel_next = 1;
					s_ascii_push_next = 1;
					case (data_type_sel)
						2'b00: begin
							msg_addr_next = 0;
							n_state = TIME_MSG;
						end
						2'b01: begin
							msg_addr_next = 4;
							n_state = TIME_MSG;
						end
						// sr-04 state
						2'b10: begin
							msg_addr_next = 9;
							data_cnt_next = 5;
							n_state = SR04_MSG;
						end
						// dht11 state
						2'b11: begin
							msg_addr_next = 13;
							data_cnt_next = 4;
							n_state = TEMP_MSG;
						end
					endcase
				end
			end
			// Stopwatch & Watch Data Related State
			TIME_MSG: begin
				if (msg_addr_reg == 8) begin
					data_cnt_next = 0;
					msg_addr_next = 21;
					n_state = BS_TIME;
				end
				else begin
					msg_addr_next = msg_addr_reg + 1;
				end
			end
			BS_TIME: begin
				msg_sel_next = 0;
				time_cnt_next = 1;
				n_state = TIME_DATA;
			end
			TIME_DATA: begin
				if (data_cnt_reg == time_cnt_reg) begin
					msg_sel_next = 1;
					if (time_cnt_reg == 7) begin
						msg_addr_next = 22;
						n_state = STOP;
					end
					else begin
						msg_addr_next = 20;
						n_state = COLON;
					end
				end
				else begin
					data_cnt_next = data_cnt_reg + 1;
				end
			end
			// Colon State to seperate time
			COLON: begin
				time_cnt_next = time_cnt_reg + 2;
				data_cnt_next = data_cnt_reg + 1;
				msg_sel_next = 0;
				n_state = TIME_DATA;
			end

			// SR04 Data Related State
			SR04_MSG: begin
				if (msg_addr_reg == 12) begin
					msg_addr_next = 21;
					n_state = BS_SR04;
				end
				else begin
					msg_addr_next = msg_addr_reg + 1;
				end
			end
			BS_SR04: begin
				msg_sel_next = 0;
				n_state = SR04_DATA;
			end
			SR04_DATA: begin
				if (data_cnt_reg == 7) begin
					msg_sel_next = 1;
					msg_addr_next = 22;
					n_state = STOP;
				end
				else begin
					data_cnt_next = data_cnt_reg + 1;
				end
			end
			// DHT11 Data Related State
			// Temperature Data is printed first
			TEMP_MSG: begin
				if (msg_addr_reg == 16) begin
					msg_addr_next = 21;
					n_state = BS_TEMP;
				end
				else begin
					msg_addr_next = msg_addr_reg + 1;
				end
			end
			BS_TEMP: begin
				msg_sel_next = 0;
				n_state = TEMP_DATA;
			end
			TEMP_DATA: begin
				if (data_cnt_reg == 5) begin
					msg_addr_next = 21;
					msg_sel_next = 1;
					data_cnt_next = data_cnt_reg + 1;
					n_state = TEMP_BS_HUM;
				end
				else begin
					data_cnt_next = data_cnt_reg + 1;
				end
			end
			// Blank space to seperate temp and hum data
			TEMP_BS_HUM: begin
				msg_addr_next = 17;
				n_state = HUM_MSG;
			end
			// Humidity Data is printed first
			HUM_MSG: begin
				if (msg_addr_reg == 19) begin
					msg_addr_next = 21;
					n_state = BS_HUM;
				end
				else begin
					msg_addr_next = msg_addr_reg + 1;
				end
			end
			BS_HUM: begin
				msg_sel_next = 0;
				n_state = HUM_DATA;
			end
			HUM_DATA: begin
				if (data_cnt_reg == 7) begin
					msg_sel_next = 1;
					msg_addr_next = 22;
					n_state = STOP;
				end
				else begin
					data_cnt_next = data_cnt_reg + 1;
				end
			end
			STOP: begin
				s_ascii_push_next = 0;
				n_state = IDLE;
			end
		endcase
	end

endmodule

module ascii_sender_datapath(
	input clk,
	input rst,
	input [31:0] digit_data,
	input [2:0] data_cnt,
	input [4:0] msg_addr,
	input msg_sel,
	input send_stop,
	output [7:0] s_ascii_data
);
	// 32bit Register
	// output value is splitted to make 8 number of 4 bit data
	reg [31:0] digit_data_reg;

	// 8to1 Mux output wire
	reg [3:0] w_mux_out;

	// Bit ot ASCII Decoder output wire
	// it indicate data value
	wire [7:0] ascii_num_data;

	// Message ASCII code wire
	wire [7:0] ascii_msg_data;

	// Register Logic (SL)
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			digit_data_reg <= 0;
		end
		else begin
			digit_data_reg <= digit_data;
		end
	end

	// 8to1 Mux (CL)
	always @(*) begin
		case (data_cnt)
			3'b000: w_mux_out = digit_data_reg[31:28];
			3'b001: w_mux_out = digit_data_reg[27:24];
			3'b010: w_mux_out = digit_data_reg[23:20];
			3'b011: w_mux_out = digit_data_reg[19:16];
			3'b100: w_mux_out = digit_data_reg[15:12];
			3'b101: w_mux_out = digit_data_reg[11:8];
			3'b110: w_mux_out = digit_data_reg[7:4];
			3'b111: w_mux_out = digit_data_reg[3:0];
		endcase
	end

	// Decoder Module Instanciation
	bit_to_ascii_decoder U_BIT_TO_ASCII_DEC(
		.ascii_dec_in(w_mux_out),
		.ascii_num_data(ascii_num_data)
	);

	// Message ROM Instanciation
	msg_rom U_MSG_ROM(
		.r_addr(msg_addr),
		.r_data(ascii_msg_data)
	);

	// Output 2to1 MUX
	assign s_ascii_data = (msg_sel) ? ascii_msg_data : ascii_num_data;

endmodule

module msg_rom(
	input [4:0] r_addr,
	output reg [7:0] r_data
);

	always @(*) begin
		case (r_addr)
			5'b0_0000: r_data = 8'h73;
			5'b0_0001: r_data = 8'h74;
			5'b0_0010: r_data = 8'h6f;
			5'b0_0011: r_data = 8'h70;
			5'b0_0100: r_data = 8'h77;
			5'b0_0101: r_data = 8'h61;
			5'b0_0110: r_data = 8'h74;
			5'b0_0111: r_data = 8'h63;
			5'b0_1000: r_data = 8'h68;
			5'b0_1001: r_data = 8'h73;
			5'b0_1010: r_data = 8'h72;
			5'b0_1011: r_data = 8'h30;
			5'b0_1100: r_data = 8'h34;
			5'b0_1101: r_data = 8'h74;
			5'b0_1110: r_data = 8'h65;
			5'b0_1111: r_data = 8'h6d;
			5'b1_0000: r_data = 8'h70;
			5'b1_0001: r_data = 8'h68;
			5'b1_0010: r_data = 8'h75;
			5'b1_0011: r_data = 8'h6d;
			5'b1_0100: r_data = 8'h3a;
			5'b1_0101: r_data = 8'h20;
			5'b1_0110: r_data = 8'h0a;
			default: r_data = 8'h00;
		endcase
	end
endmodule

module bit_to_ascii_decoder(
	input [3:0] ascii_dec_in,
	output reg [7:0] ascii_num_data
);

	always @(*) begin
		case (ascii_dec_in)
			4'b0000: ascii_num_data = 8'h30;
			4'b0001: ascii_num_data = 8'h31;
			4'b0010: ascii_num_data = 8'h32;
			4'b0011: ascii_num_data = 8'h33;
			4'b0100: ascii_num_data = 8'h34;
			4'b0101: ascii_num_data = 8'h35;
			4'b0110: ascii_num_data = 8'h36;
			4'b0111: ascii_num_data = 8'h37;
			4'b1000: ascii_num_data = 8'h38;
			4'b1001: ascii_num_data = 8'h39;
			4'b1010: ascii_num_data = 8'h41;
			4'b1011: ascii_num_data = 8'h42;
			4'b1100: ascii_num_data = 8'h43;
			4'b1101: ascii_num_data = 8'h44;
			4'b1110: ascii_num_data = 8'h45;
			4'b1111: ascii_num_data = 8'h46;
		endcase
	end

endmodule
// =======================================================================