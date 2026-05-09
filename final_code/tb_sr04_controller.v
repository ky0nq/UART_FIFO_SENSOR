`timescale 1ns / 1ps

// SR04 Controller test module code
module tb_sr04_controller ();
    parameter US_DELAY = 1000, MS_DELAY = 1_000_000;

    reg        clk;
    reg        rst;
    reg        sr04_start;
    reg        echo;
    wire       trig;
    wire [8:0] distance;

    wire       w_tick_us;
    
    tick_gen_us dut2 (
        .clk    (clk),
        .rst    (rst),
        .tick_us(w_tick_us)
    );

    sr04_controller dut (
        .clk       (clk),
        .rst       (rst),
        .sr04_start(sr04_start),
        .tick_us   (w_tick_us),
        .trig      (trig),
        .echo      (echo),
        .distance  (distance)
    );


    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        sr04_start = 0;
        echo = 0;
        #20;

        rst = 0;
        @(posedge clk);
        sr04_start = 1;
        @(posedge clk);
        sr04_start = 0;

        // echo response 
        #(US_DELAY * 20);
        //@(negedge trig); 
        echo = 1;
        repeat (10) #(MS_DELAY);
        repeat (10) #(MS_DELAY);
        repeat (10) #(MS_DELAY);
        echo = 0;

        #1000;

        @(posedge clk);
        sr04_start = 1;
        @(posedge clk);
        sr04_start = 0;

        // echo response 
        #(US_DELAY * 20);
        //@(negedge trig); 
        echo = 1;
        repeat (5) #(MS_DELAY);
        echo = 0;

        $stop;
    end

endmodule

module tick_gen_us (
	input clk,
	input rst,
	output reg tick_us
);
	// parameter for counter bit width
	parameter F_COUNT = 100_000_000 / 1_000_000;
	//register for counter
	reg [$clog2(F_COUNT)-1:0] counter_reg;

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			counter_reg <= 0;
			tick_us <= 1'b0;
		end
		else begin
			counter_reg <= counter_reg + 1;
			tick_us <= 1'b0;
			if (counter_reg == F_COUNT-1) begin
				counter_reg <= 0;
				tick_us <= 1'b1;
			end
		end
	end

endmodule
