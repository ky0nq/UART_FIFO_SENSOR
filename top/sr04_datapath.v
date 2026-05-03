`timescale 1ns / 1ps

module sr04_datapath (
    input clk,
    input rst,
    input sr04_start,
    input echo,
    input tick_us,

    output trig,
    output [23:0] dist_data
);

    wire [8:0] w_distance;

    sr04_controller U_SR04_CNTL (
        .clk       (clk),
        .rst       (rst),
        .sr04_start(sr04_start),
        .tick_us   (tick_us),
        .echo      (echo),
        .trig      (trig),
        .distance  (w_distance)
    );

    sr04_merge U_SR04_MERGE (
        .distance   (w_distance),
        .dist_data (dist_data)
    );

endmodule

module sr04_controller (
    input clk,
    input rst,
    input sr04_start,
    input tick_us,
    input echo,

    output       trig,
    output [8:0] distance
);

    parameter IDLE = 0, START = 1, WAIT = 2, RESPONSE = 3;
    reg [1:0] c_state, n_state;
    reg trig_reg, trig_next;
    reg [14:0] tick_cnt_reg, tick_cnt_next;
    reg [8:0] distance_reg, distance_next;

    assign trig = trig_reg;
    assign distance = distance_reg;

    always @(posedge clk, posedge rst) begin  //순차논리
        if (rst) begin
            c_state <= IDLE;
            trig_reg <= 1'b0;
            tick_cnt_reg <= 0;
            distance_reg <= 0;
        end else begin
            c_state <= n_state;
            trig_reg <= trig_next;
            tick_cnt_reg <= tick_cnt_next;  // next입력 reg출력
            distance_reg <= distance_next;
        end
    end

    always @(*) begin  //조합논리

        n_state = c_state;
        trig_next = trig_reg;
        tick_cnt_next = tick_cnt_reg;
        distance_next = distance_reg;

        case (c_state)
            IDLE: begin
                trig_next = 1'b0;
                if (sr04_start) begin
                    n_state = START;
                    tick_cnt_next = 0;
                end
            end

            START: begin
                trig_next = 1'b1;
                if (tick_us) begin
                    if (tick_cnt_reg > 11) begin  //10초과
                        n_state = WAIT;
                        tick_cnt_next = 0;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            WAIT: begin
                trig_next = 1'b0;
                if (tick_us) begin
                    if (echo) begin
                        tick_cnt_next = 0;
                        n_state = RESPONSE;
                    end
                end
            end

            RESPONSE: begin
                trig_next = 1'b0;
                if (tick_us) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (echo == 0) begin
                        distance_next = tick_cnt_reg / 58;
                        n_state = IDLE;
                    end
                end
            end
        endcase
    end
endmodule

module sr04_merge (
    input [8:0] distance,
    output [23:0] dist_data
);
    assign dist_data = {15'b0, distance};

endmodule
