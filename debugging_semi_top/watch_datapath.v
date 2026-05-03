// 26.05.03 20:25

`timescale 1ns / 1ps

module watch_datapath #(
    parameter   MSEC_WIDTH =    7,
                SEC_WIDTH  =    6,
                MIN_WIDTH  =    6,
                HOUR_WIDTH =    5,
                MSEC_INIT =     0,
                SEC_INIT  =     0,
                MIN_INIT  =     0,
                HOUR_INIT =     12 
) (
    input                       clk,
    input                       rst,
    input                       sw2_and_1, 
    input  [2:0]                place, 

    input                       i_up,
    input                       i_down,

    output [23:0]               wt_time_data
);
    wire w_tick_100hz;
    wire w_sec_tick, w_min_tick, w_hour_tick;
    wire [MSEC_WIDTH-1:0] w_msec;
    wire [SEC_WIDTH-1:0] w_sec;
    wire [MIN_WIDTH-1:0] w_min;
    wire [HOUR_WIDTH-1:0] w_hour;

    tick_gen_100hz_watch U_TICK_GEN_100HZ_WATCH (
        .clk            (clk),
        .rst            (rst),
        .sw2_and_1      (sw2_and_1), // 시계-설정모드
        .o_tick_100hz   (w_tick_100hz)
    );

    tick_counter_watch #(
        .TIMES          (100), 
        .BIT_WIDTH      (MSEC_WIDTH),
        .INIT           (MSEC_INIT)
    ) U_MSEC_TICK_COUNTER_WATCH (
        .clk            (clk),
        .rst            (rst),
        .i_tick         (w_tick_100hz),
        .sw2_and_1      (sw2_and_1),
        .place          (),
        .i_up           (i_up),
        .i_down         (i_down),
        .times_counter  (w_msec),
        .o_tick         (w_sec_tick)
    );

    tick_counter_watch #(
        .TIMES          (60), 
        .BIT_WIDTH      (SEC_WIDTH),
        .INIT           (SEC_INIT)
    ) U_SEC_TICK_COUNTER_WATCH (
        .clk            (clk),
        .rst            (rst),
        .i_tick         (w_sec_tick), // from msec o_tick
        .sw2_and_1      (sw2_and_1),
        .place          (place[0]),
        .i_up           (i_up),
        .i_down         (i_down),
        .times_counter  (w_sec),
        .o_tick         (w_min_tick)
    );

    tick_counter_watch #(
        .TIMES          (60), 
        .BIT_WIDTH      (MIN_WIDTH),
        .INIT           (MIN_INIT)
    ) U_MIN_TICK_COUNTER_WATCH (
        .clk            (clk),
        .rst            (rst),
        .i_tick         (w_min_tick), // from sec o_tick
        .sw2_and_1      (sw2_and_1),
        .place          (place[1]),
        .i_up           (i_up),
        .i_down         (i_down),
        .times_counter  (w_min),
        .o_tick         (w_hour_tick)
    );

    tick_counter_watch #(
        .TIMES          (24), 
        .BIT_WIDTH      (HOUR_WIDTH),
        .INIT           (HOUR_INIT)
    ) U_HOUR_TICK_COUNTER_WATCH (
        .clk            (clk),
        .rst            (rst),
        .i_tick         (w_hour_tick), // from min o_tick
        .sw2_and_1      (sw2_and_1),
        .place          (place[2]),
        .i_up           (i_up),
        .i_down         (i_down),
        .times_counter  (w_hour),
        .o_tick         ()
    );

    watch_merge #(
        .MSEC_WIDTH(7),
        .SEC_WIDTH (6),
        .MIN_WIDTH (6),
        .HOUR_WIDTH(5)
    ) U_WT_MERGE (
        .msec         (w_msec),
        .sec          (w_sec),
        .min          (w_min),
        .hour         (w_hour),
        .fnd_watch(wt_time_data)
    );

endmodule

module tick_gen_100hz_watch (
    input       clk,
    input       rst,
    input       sw2_and_1,

    output reg  o_tick_100hz

);
    // 100Hz counter number * 1000 for simulation
    parameter F_COUNT = 100_000_000 / 100;
    reg [$clog2(F_COUNT)-1:0] counter_reg;  

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg     <= 0;
            o_tick_100hz    <= 1'b0;
        end 
        else begin
            if (!sw2_and_1) begin // 시계이면서 설정모드 예외
                counter_reg     <= counter_reg + 1;
                o_tick_100hz    <= 1'b0;
                if (counter_reg == F_COUNT - 1) begin
                    counter_reg     <= 0;
                    o_tick_100hz    <= 1'b1;
                end else begin 
                    o_tick_100hz    <= 1'b0;
                end
            end
            else begin // 시계이면서 설정모드 (설정을 위해 tick 막기)
                counter_reg     <= 0;
                o_tick_100hz    <= 1'b0;
            end
        end
    end
endmodule

module tick_counter_watch #(
    parameter   TIMES = 100,
                BIT_WIDTH = 7,
                INIT = 0
) (
    input                        clk,
    input                        rst,
    input                        i_tick,
    
    input                        sw2_and_1, 
    input                        place,
    input                        i_up,
    input                        i_down,

    output     [BIT_WIDTH - 1:0] times_counter,
    output reg                   o_tick // 다음 시간 단위로 +1 알려주기 위한 output
);

    //counter register SL
    reg [BIT_WIDTH-1:0] counter_reg, counter_next;
    assign times_counter = counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= INIT;
        end else begin
            counter_reg <= counter_next;
        end
    end

    // next counter CL
    always @(*) begin
        counter_next = counter_reg;
        o_tick = 1'b0;
        if (i_tick) begin // 시계 모드
            counter_next = counter_reg + 1;
            if (counter_reg == (TIMES - 1)) begin
                counter_next    = 0;
                o_tick          = 1'b1;
            end
            else begin
                o_tick = 1'b0;
            end
        end 
        else begin // 설정 모드
            if (sw2_and_1) begin // 설정 모드
                if (place) begin // control_unit_watch에서 받은 위치 정보가 존재하면
                    if (i_up) begin // up
                        counter_next = counter_reg + 1;
                        if (counter_reg == (TIMES - 1)) begin
                            counter_next = 0;
                            o_tick = 1'b0;
                        end
                    end
                    else if (i_down) begin // down
                        counter_next = counter_reg - 1;
                        if (counter_reg == 0) begin
                            counter_next = TIMES - 1;
                            o_tick = 1'b0;
                        end
                    end
                    else begin // 아무것도 안 하면 유지
                        counter_next = counter_reg;
                        o_tick = 1'b0;
                    end 
                end
                else begin // 설정 모드인데 위치가 안 들어오면 그냥 머물기
                    counter_next = counter_reg;
                    o_tick = 1'b0;
                end
            end
        end
    end

endmodule

module watch_merge #(
    parameter   MSEC_WIDTH =    7,
    SEC_WIDTH  =    6,
    MIN_WIDTH  =    6,
    HOUR_WIDTH =    5
) (
    input [MSEC_WIDTH-1 : 0] msec,
    input [SEC_WIDTH-1 : 0] sec,
    input [MIN_WIDTH-1 : 0] min,
    input [HOUR_WIDTH-1 : 0] hour,
    output [23:0] fnd_watch

);
    assign fnd_watch = {hour, min, sec, msec};

endmodule
