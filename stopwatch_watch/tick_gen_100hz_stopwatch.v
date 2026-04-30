// 26.04.18 22:06 Final code _ optimize 

`timescale 1ns / 1ps

module tick_gen_100hz_stopwatch (
    input       clk,
    input       rst,

    input       i_runstop,
    input       i_clear,
    
    output reg  o_tick_100hz
);
    // 100Hz counter number * 1000 for simulation
    parameter F_COUNT = 100_000_000 / 100;
    reg [$clog2(F_COUNT)-1:0] counter_reg;  

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg     <= 0;
            o_tick_100hz    <= 1'b0;
        end else begin
            if (i_runstop) begin // runstop vs. clear : runstop 우선순위
                counter_reg     <= counter_reg + 1;
                o_tick_100hz    <= 1'b0;
                if (counter_reg == F_COUNT - 1) begin
                    counter_reg     <= 0;
                    o_tick_100hz    <= 1'b1;
                end else begin
                    o_tick_100hz    <= 1'b0;
                end
            end 
            else if (i_clear) begin
                counter_reg <= 0;
                o_tick_100hz <= 0;
            end else begin
            o_tick_100hz    <= 1'b0;
        end
        end
    end
endmodule