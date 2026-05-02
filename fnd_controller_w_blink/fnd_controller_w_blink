`timescale 1ns / 1ps

module fnd_controller #(
    parameter MSEC_WIDTH = 7,
    parameter SEC_WIDTH  = 6,
    parameter MIN_WIDTH  = 6,
    parameter HOUR_WIDTH = 5
) (
    input                   clk,
    input                   rst,
    input                   sw,       // sw=0 -> msec & sec | sw=1 -> min & hour
    input  [           3:0] set_sel,
    input  [MSEC_WIDTH-1:0] msec,
    input  [ SEC_WIDTH-1:0] sec,
    input  [ MIN_WIDTH-1:0] min,
    input  [HOUR_WIDTH-1:0] hour,
    output [           3:0] fnd_com,
    output [           7:0] fnd_data
);
    // clk divider out wire
    wire w_o_1khz;
    // digit wire
    wire [3:0] w_msec_digit_1, w_msec_digit_10;
    wire [3:0] w_sec_digit_1, w_sec_digit_10;
    wire [3:0] w_min_digit_1, w_min_digit_10;
    wire [3:0] w_hour_digit_1, w_hour_digit_10;
    // dot onoff wire
    wire w_onoff;
    // wire for digit split output to blink selector input
    wire w_i_tick;
    wire [6:0] w_i_comp;
    wire [3:0] w_sec_digit_1_selected, w_sec_digit_10_selected;
    wire [3:0] w_min_digit_1_selected, w_min_digit_10_selected;
    wire [3:0] w_hour_digit_1_selected, w_hour_digit_10_selected;
    // mux out & sel wire
    wire [3:0] w_out_mux_msec_sec, w_out_mux_min_hour, w_out_mux;
    wire [2:0] w_digit_sel;


    // CLK Divider
    // ===============================================
    clk_div_1khz U_CLK_Divider (
        .clk(clk),
        .rst(rst),
        .o_1khz(w_o_1khz)
    );
    // ===============================================


    // Counter 8
    // ===============================================
    counter_8 U_Counter_8 (
        .clk(w_o_1khz),
        .rst(rst),
        .digit_sel(w_digit_sel)
    );
    // ===============================================


    // digit split
    // ===============================================
    digit_splitter #(
        .BIT_WIDTH(MSEC_WIDTH)
    ) U_MSEC_DS (
        .digit_in(msec),
        .digit_1 (w_msec_digit_1),
        .digit_10(w_msec_digit_10)
    );

    digit_splitter #(
        .BIT_WIDTH(SEC_WIDTH)
    ) U_SEC_DS (
        .digit_in(sec),
        .digit_1 (w_sec_digit_1),
        .digit_10(w_sec_digit_10)
    );

    digit_splitter #(
        .BIT_WIDTH(MIN_WIDTH)
    ) U_MIN_DS (
        .digit_in(min),
        .digit_1 (w_min_digit_1),
        .digit_10(w_min_digit_10)
    );

    digit_splitter #(
        .BIT_WIDTH(HOUR_WIDTH)
    ) U_HOUR_DS (
        .digit_in(hour),
        .digit_1 (w_hour_digit_1),
        .digit_10(w_hour_digit_10)
    );
    // ===============================================

    // comparator
    // ===============================================
    watch_tick_gen_100hz U_TICK_GEN_FOR_COMP (
        .clk(clk),
        .rst(rst),
        .i_run_stop(1'b1),
        .o_tick_100hz(w_i_tick)
    );

    tick_counter #(
        .TIMES(100),
        .BIT_WIDTH(7)
    ) U_TICK_CNT_FOR_COMP (
        .clk(clk),
        .rst(rst),
        .i_tick(w_i_tick),
        .i_clear(1'b0),
        .i_mode(1'b0),
        .time_counter(w_i_comp),
        .o_tick()
    );

    comparator U_COMP (
        .i_comp(w_i_comp),
        .o_comp(w_onoff)
    );
    // ===============================================

    // blink selector
    // ===============================================
    blink_selector U_SEC_BL_SEL_1 (
        .o_comp(w_onoff),
        .set_sel(set_sel[2]),
        .digit_out(w_sec_digit_1),
        .mux_in(w_sec_digit_1_selected)
    );
    blink_selector U_SEC_BL_SEL_10 (
        .o_comp(w_onoff),
        .set_sel(set_sel[3]),
        .digit_out(w_sec_digit_10),
        .mux_in(w_sec_digit_10_selected)
    );

    blink_selector U_MIN_BL_SEL_1 (
        .o_comp(w_onoff),
        .set_sel(set_sel[0]),
        .digit_out(w_min_digit_1),
        .mux_in(w_min_digit_1_selected)
    );
    blink_selector U_MIN_BL_SEL_10 (
        .o_comp(w_onoff),
        .set_sel(set_sel[1]),
        .digit_out(w_min_digit_10),
        .mux_in(w_min_digit_10_selected)
    );

    blink_selector U_HOUR_BL_SEL_1 (
        .o_comp(w_onoff),
        .set_sel(set_sel[2]),
        .digit_out(w_hour_digit_1),
        .mux_in(w_hour_digit_1_selected)
    );
    blink_selector U_HOUR_BL_SEL_10 (
        .o_comp(w_onoff),
        .set_sel(set_sel[3]),
        .digit_out(w_hour_digit_10),
        .mux_in(w_hour_digit_10_selected)
    );
    // ===============================================

    // mux
    // ===============================================
    mux_8to1 U_MUX_MSEC_SEC (
        .in0(w_msec_digit_1),
        .in1(w_msec_digit_10),
        .in2(w_sec_digit_1_selected),
        .in3(w_sec_digit_10_selected),
        .in4(4'hf),
        .in5(4'hf),
        .in6({3'b111, w_onoff}),
        .in7(4'hf),
        .sel(w_digit_sel),  // Select digit
        .out_mux(w_out_mux_msec_sec)
    );

    mux_8to1 U_MUX_MIN_HOUR (
        .in0(w_min_digit_1_selected),
        .in1(w_min_digit_10_selected),
        .in2(w_hour_digit_1_selected),
        .in3(w_hour_digit_10_selected),
        .in4(4'hf),
        .in5(4'hf),
        .in6({3'b111, w_onoff}),
        .in7(4'hf),
        .sel(w_digit_sel),  // Select digit
        .out_mux(w_out_mux_min_hour)
    );

    mux_2to1 U_MUX_2to1 (
        .in0(w_out_mux_msec_sec),
        .in1(w_out_mux_min_hour),
        .sel(sw),
        .out_mux(w_out_mux)
    );
    // ===============================================


    // BCD
    // ===============================================
    bcd U_BCD (
        .bin(w_out_mux),
        .bcd_data(fnd_data)
    );

    dec_2to4 U_DEC_2to4 (
        .dec_in (w_digit_sel[1:0]),
        .fnd_com(fnd_com)
    );
    // ===============================================

endmodule

module blink_selector (
    input o_comp,
    input set_sel,
    input [3:0] digit_out,
    output [3:0] mux_in
);

    wire w_pass;
    assign w_pass = o_comp & set_sel;

    assign mux_in = digit_out | {4{w_pass}};

endmodule

module comparator (
    input [6:0] i_comp,
    output o_comp
);
    // 0~49: false, 50~99: true
    assign o_comp = (i_comp > 49);

endmodule

module mux_2to1 (
    input  [3:0] in0,
    input  [3:0] in1,
    input        sel,
    output [3:0] out_mux
);

    assign out_mux = sel ? in1 : in0;

endmodule

module mux_2to1_time #(
    parameter BIT_WIDTH = 7
) (
    input [BIT_WIDTH-1:0] in0,
    input [BIT_WIDTH-1:0] in1,
    input sel,
    output [BIT_WIDTH-1:0] out_mux
);

    assign out_mux = sel ? in1 : in0;

endmodule

module clk_div_1khz (
    input      clk,
    input      rst,
    output reg o_1khz
);

    reg [15:0] counter_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_reg <= 16'b0000_0000_0000_0000;
            o_1khz <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1'b1;
            if (counter_reg == (50_000 - 1)) begin
                counter_reg <= 16'b0000_0000_0000_0000;
                o_1khz <= ~o_1khz;
            end
        end
    end

endmodule

module counter_8 (
    input            clk,
    input            rst,
    output reg [2:0] digit_sel
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            digit_sel <= 3'b000;
        end else begin
            digit_sel <= digit_sel + 1'b1;
        end
    end

endmodule

module digit_splitter #(
    parameter BIT_WIDTH = 7
) (
    input  [BIT_WIDTH-1:0] digit_in,
    output [          3:0] digit_1,
    output [          3:0] digit_10
);

    assign digit_1  = digit_in % 10;  // digit 1
    assign digit_10 = (digit_in / 10) % 10;  // digit 10

endmodule

module mux_8to1 (
    input [3:0] in0,
    input [3:0] in1,
    input [3:0] in2,
    input [3:0] in3,
    input [3:0] in4,
    input [3:0] in5,
    input [3:0] in6,
    input [3:0] in7,
    input [2:0] sel,  // Select digit
    output reg [3:0] out_mux
);

    // mux, (*) sensitivity list = all input
    always @(*) begin
        // This case is full case, so we dont need default. 
        // If not full case & no default makes Latch.
        // Latch makes circuit doesn't work properly.
        // Most latch are not intended.
        case (sel)
            3'b000:  out_mux = in0;
            3'b001:  out_mux = in1;
            3'b010:  out_mux = in2;
            3'b011:  out_mux = in3;
            3'b100:  out_mux = in4;
            3'b101:  out_mux = in5;
            3'b110:  out_mux = in6;
            3'b111:  out_mux = in7;
            default: out_mux = 4'b0000;
        endcase
    end

endmodule

module bcd (
    input [3:0] bin,
    output reg [7:0] bcd_data
);

    always @(bin) begin  // Behavioral Modeling -> always watch bin event
        case (bin)
            4'b0000: bcd_data = 8'hc0;
            4'b0001: bcd_data = 8'hf9;
            4'b0010: bcd_data = 8'ha4;
            4'b0011: bcd_data = 8'hb0;
            4'b0100: bcd_data = 8'h99;
            4'b0101: bcd_data = 8'h92;
            4'b0110: bcd_data = 8'h82;
            4'b0111: bcd_data = 8'hf8;
            4'b1000: bcd_data = 8'h80;
            4'b1001: bcd_data = 8'h90;
            4'b1010: bcd_data = 8'h88;  // no use state
            4'b1011: bcd_data = 8'h83;  // no use state
            4'b1100: bcd_data = 8'hc6;  // no use state
            4'b1101: bcd_data = 8'ha1;  // no use state
            4'b1110: bcd_data = 8'h7f;
            4'b1111: bcd_data = 8'hff;
            default:
            bcd_data = 8'hff;  // In this case, every case is handled so we don't need default value
        endcase
    end

endmodule

module dec_2to4 (
    input [1:0] dec_in,
    output reg [3:0] fnd_com
);

    always @(*) begin
        case (dec_in)
            2'b00:   fnd_com = 4'b1110;
            2'b01:   fnd_com = 4'b1101;
            2'b10:   fnd_com = 4'b1011;
            2'b11:   fnd_com = 4'b0111;
            default: fnd_com = 4'b1111;
        endcase
    end
endmodule

