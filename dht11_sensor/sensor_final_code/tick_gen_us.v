// tick_gen_us.v
// 26.05.03 09:55 am

`timescale 1ns / 1ps

module tick_gen_us (
    input       clk,
    input       rst,
    output reg  tick_us  // us로 나는 안 쓸 거 같다
);

    parameter F_COUNT = 100_000_000 / 1_000_000; // 1MHz
    reg [$clog2(F_COUNT)-1:0] counter_reg;  // not FSM

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_us <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                tick_us     <= 1'b1;
            end else begin
                tick_us <= 1'b0;
            end
        end
    end

endmodule
