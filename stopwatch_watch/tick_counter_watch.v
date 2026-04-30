// 26.04.19 15:03 Final code _ optimize 

`timescale 1ns / 1ps

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
