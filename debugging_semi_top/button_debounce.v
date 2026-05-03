// 26.05.03 20:25

`timescale 1ns / 1ps

module button_debounce (
    input  clk,
    input  rst,
    input  i_Btn,
    output o_Btn
);
    // clock divider : 100MHz -> 100KHz 
    parameter F_COUNT = 100_000_000 / 100_000;
    reg [$clog2(F_COUNT)-1:0] r_counter;
    reg clk_100khz;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_counter  <= 0;
            clk_100khz <= 1'b0;
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
    wire w_debounce;
    reg edge_reg;

    always @(posedge clk_100khz, posedge rst) begin
        if (rst) begin
            sync_reg <= 0;
        end else begin
            sync_reg <= sync_next;
        end
    end

    // shifter
    always @(*) begin  
        sync_next = {i_Btn, sync_reg[7:1]};
    end

    // 80us button input 1 -> w_debounce = 1
    assign w_debounce = &sync_reg;

    // rising edge detect
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            edge_reg <= 1'b0;
        end else begin
            edge_reg <= w_debounce;  // 1 clock Delay
        end
    end

    // 1 pulse button output
    assign o_Btn = w_debounce & ~(edge_reg);

endmodule
