// 26.05.03 20:25

`timescale 1ns / 1ps

module stopwatch_datapath #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5,
    MSEC_SET = 0,  // stopwatch set 하려면 어떤 값으로 할지 지정하는 부분
    SEC_SET = 0,
    MIN_SET = 0,
    HOUR_SET = 8
) (
    input clk,
    input rst,

    input i_runstop,
    input i_clear,
    input i_mode,
    input i_set,

    output [23 : 0] st_time_data
);
    wire w_tick_100hz;

    wire w_sec_tick_up, w_min_tick_up, w_hour_tick_up;
    wire w_sec_tick_down, w_min_tick_down, w_hour_tick_down;
    wire [MSEC_WIDTH-1:0] w_msec;
    wire [SEC_WIDTH-1:0] w_sec;
    wire [MIN_WIDTH-1:0] w_min;
    wire [HOUR_WIDTH-1:0] w_hour;

    // i_mode = 1 = down mode ->  00 00 | 00 00 이면 down 안 되게 판단하는 로직
    wire all_zero;
    assign all_zero = ((w_msec == 0) && (w_sec == 0) && (w_min == 0) && (w_hour == 0));

    tick_gen_100hz_stopwatch U_TICK_GEN_100HZ (
        .clk         (clk),
        .rst         (rst),
        .i_runstop   (i_runstop),
        .i_clear     (i_clear),
        .o_tick_100hz(w_tick_100hz)
    );

    //msec
    tick_counter_stopwatch #(
        .TIMES    (100),
        .BIT_WIDTH(MSEC_WIDTH),
        .INIT     (MSEC_SET)
    ) U_MSEC_TICK_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick_up      (i_mode ? 1'b0 : w_tick_100hz), // up mode면 i_tick_up에 clock
        // down 이면 i_tick_down에 clock
        .i_tick_down(i_mode ? (all_zero ? 1'b0 : w_tick_100hz) : 1'b0),
        .i_clear(i_clear),
        .i_mode(i_mode),
        .i_set(i_set),
        .times_counter(w_msec),
        .o_tick_up(w_sec_tick_up),
        // 0 이 되면 tick 이 나와서 앞선 시간 단위에 대해서 수에 -1 해주는 출력값
        .o_tick_down(w_sec_tick_down)
    );

    // sec
    tick_counter_stopwatch #(
        .TIMES    (60),
        .BIT_WIDTH(SEC_WIDTH),
        .INIT     (SEC_SET)
    ) U_SEC_TICK_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick_up(w_sec_tick_up),  // from msec o_tick_up
        .i_tick_down(all_zero ? 1'b0 : w_sec_tick_down),
        .i_clear(i_clear),
        .i_mode(i_mode),
        .i_set(i_set),
        .times_counter(w_sec),
        .o_tick_up(w_min_tick_up),
        .o_tick_down(w_min_tick_down)
    );

    // min
    tick_counter_stopwatch #(
        .TIMES    (60),
        .BIT_WIDTH(MIN_WIDTH),
        .INIT     (MIN_SET)
    ) U_MIN_TICK_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick_up(w_min_tick_up),  // from sec o_tick_up
        .i_tick_down(all_zero ? 1'b0 : w_min_tick_down),
        .i_clear(i_clear),
        .i_mode(i_mode),
        .i_set(i_set),
        .times_counter(w_min),
        .o_tick_up(w_hour_tick_up),
        .o_tick_down(w_hour_tick_down)
    );

    // hour
    tick_counter_stopwatch #(
        .TIMES    (24),
        .BIT_WIDTH(HOUR_WIDTH),
        .INIT     (HOUR_SET)
    ) U_HOUR_TICK_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick_up(w_hour_tick_up),  // from min o_tick_up
        .i_tick_down(all_zero ? 1'b0 : w_hour_tick_down),
        .i_clear(i_clear),
        .i_mode(i_mode),
        .i_set(i_set),
        .times_counter(w_hour),
        .o_tick_up(),
        .o_tick_down()
    );

    stopwatch_merge #(
        .MSEC_WIDTH(7),
        .SEC_WIDTH (6),
        .MIN_WIDTH (6),
        .HOUR_WIDTH(5)
    ) U_ST_MERGE (
        .msec         (w_msec),
        .sec          (w_sec),
        .min          (w_min),
        .hour         (w_hour),
        .fnd_stopwatch(st_time_data)
    );
endmodule

module tick_gen_100hz_stopwatch (
    input clk,
    input rst,

    input i_runstop,
    input i_clear,

    output reg o_tick_100hz
);
    // 100Hz counter number * 1000 for simulation
    parameter F_COUNT = 100_000_000 / 100;
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg  <= 0;
            o_tick_100hz <= 1'b0;
        end else begin
            if (i_runstop) begin  // runstop vs. clear : runstop 우선순위
                counter_reg  <= counter_reg + 1;
                o_tick_100hz <= 1'b0;
                if (counter_reg == F_COUNT - 1) begin
                    counter_reg  <= 0;
                    o_tick_100hz <= 1'b1;
                end else begin
                    o_tick_100hz <= 1'b0;
                end
            end else if (i_clear) begin
                counter_reg  <= 0;
                o_tick_100hz <= 0;
            end else begin
                o_tick_100hz <= 1'b0;
            end
        end
    end
endmodule

module tick_counter_stopwatch #(
    parameter TIMES     = 100,
              BIT_WIDTH = 7,
              INIT      = 0
) (
    input clk,
    input rst,
    input i_tick_up,
    input i_tick_down,

    input i_clear,
    input i_mode,
    input i_set,

    output     [BIT_WIDTH - 1:0] times_counter,
    output reg                   o_tick_up,
    output reg                   o_tick_down
);

    //counter register SL
    reg [BIT_WIDTH-1:0] counter_reg, counter_next;
    assign times_counter = counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
        end else begin
            counter_reg <= counter_next;
        end
    end

    // next counter CL         
    always @(*) begin
        counter_next = counter_reg;
        o_tick_up    = 1'b0;
        o_tick_down  = 1'b0;

        if (i_set) begin // 설정 모드이면 각 tick counter 별 지정 값으로 초기화
            counter_next = INIT;
        end else if (i_mode) begin  // down count
            if (i_tick_down) begin  // 하위에서 전해져 온 tick
                counter_next = counter_reg - 1;
                if (counter_reg == 0) begin
                    counter_next = TIMES - 1;
                    o_tick_down  = 1'b1;
                end
            end
        end else begin  // up count
            if (i_tick_up) begin
                counter_next = counter_reg + 1;
                if (counter_reg == (TIMES - 1)) begin
                    counter_next = 0;
                    o_tick_up    = 1'b1;
                end
            end
        end

        if (i_clear) begin
            counter_next = 0;
        end
    end
endmodule

module stopwatch_merge #(
    parameter   MSEC_WIDTH =    7,
    SEC_WIDTH  =    6,
    MIN_WIDTH  =    6,
    HOUR_WIDTH =    5
) (
    input [MSEC_WIDTH-1 : 0] msec,
    input [SEC_WIDTH-1 : 0] sec,
    input [MIN_WIDTH-1 : 0] min,
    input [HOUR_WIDTH-1 : 0] hour,
    output [23:0] fnd_stopwatch

);
    assign fnd_stopwatch = {hour, min, sec, msec};

endmodule
