// 26.04.18 22:06 Final code _ optimize 

`timescale 1ns / 1ps

module tick_counter_stopwatch #(
    parameter   TIMES       = 100,
                BIT_WIDTH   = 7,
                INIT        = 0
) (
    input                        clk,
    input                        rst,
    input                        i_tick_up,
    input                        i_tick_down,
    
    input                        i_clear,
    input                        i_mode,
    input                        i_set,

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
        end

        else if (i_mode) begin // down count
            if (i_tick_down) begin  // 하위에서 전해져 온 tick
                counter_next = counter_reg - 1;
                if (counter_reg == 0) begin
                    counter_next = TIMES - 1;
                    o_tick_down  = 1'b1; 
                end
            end
        end
        else begin // up count
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
