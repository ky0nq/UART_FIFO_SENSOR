`timescale 1ns / 1ps

// controller + datapath + FND controller test module code
module tb_semi_top ();

    // simulation parameter for dht11 sensor input 
    parameter   [7:0]   HUMI_INT = 8'd60;  // humidity integral
    parameter   [7:0]   TEMP_INT = 8'd25;  // temperature integral
    reg         [39:0]  DATA_STREAM = {
                            HUMI_INT, 8'h00, TEMP_INT, 8'h00, HUMI_INT + TEMP_INT
                        };
    // simulation parameter for sr04 sensor input
    parameter US_DELAY = 1000, MS_DELAY = 1_000_000;

    reg        clk;
    reg        rst;
    reg  [3:0] sw;
    reg        sw9;
    reg        btnU;
    reg        btnR;
    reg        btnD;
    reg        btnL;
    reg        echo;

    wire       trig;
    wire       o_led9;
    wire       o_led15;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;

    // dht11 is inout port
    wire       dht11;

    // for dht11 sensor data test
    reg dht_sensor_data; // sensor data by dht11
    reg io_oe;

    // tb io mode converter signal
    // io_oe = 1 : input mode
    // io_oe = 0 : output mode
    assign dht11 = (io_oe) ? dht_sensor_data : 1'bz;

    semi_top dut (
        .clk     (clk),
        .rst     (rst),
        .sw      (sw),
        .sw9     (sw9),
        .btnU    (btnU),
        .btnR    (btnR),
        .btnD    (btnD),
        .btnL    (btnL),
        .echo    (echo),
        .trig    (trig),
        .o_led9  (o_led9),
        .o_led15 (o_led15),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data),
        .dht11   (dht11)
    );

    always #5 clk = ~clk;
    integer i = 0;

    initial begin
		clk = 0;
		rst = 1;
		sw = 0;
        sw9 = 0;
		btnU = 0;
		btnR = 0;
		btnD = 0;
		btnL = 0;
        echo = 0;
        io_oe = 0;

		#20
		rst = 0;
        #100;
    // ------------------ dht11 test -----------------------
        // dht11 display
        sw = 4'b1010;

        // dht11 trigger signal
        btnR = 1;
        #80_000;
        btnR = 0;
        #100;

        // start state ----
        wait (!dht11);
        // 19msec wait
        wait (dht11);
        // ----------------

        #30000;
        // input port mode ---
        io_oe = 1;
        // -------------------

        dht_sensor_data = 1'b0;
        #80000;
        dht_sensor_data = 1'b1;
        #80000;
        
        // send sensor data -------------------
        for (i = 39; i >= 0; i = i - 1) begin
            dht_sensor_data = 0;
            #50000;
            dht_sensor_data = 1'b1;
            #(DATA_STREAM[i] ? 70000 : 26000);
        end
        dht_sensor_data = 0;
        #50000;
        // ------------------------------------

        // output port mode
        io_oe = 0;
        #50000;

        // another sensor data test ----------------
        sw = 4'b1011;
        DATA_STREAM = { 8'h33, 8'h00, 8'h04, 8'h00, (8'h33 + 8'h04) };
        #100;
        btnR = 1;
        #80_000;
        btnR = 0;
        #100;
        wait (!dht11);
        // 18msec wait
        wait (dht11);

        #30000;
        // input port mode ---
        io_oe = 1;
        // -------------------

        dht_sensor_data = 1'b0;
        #80000;
        dht_sensor_data = 1'b1;
        #80000;

	    // another sensor data test
        for (i = 39; i >= 0; i = i - 1) begin
            dht_sensor_data = 0;
            #50000;
            dht_sensor_data = 1'b1;
            #(DATA_STREAM[i] ? 70000 : 26000);
        end
        dht_sensor_data = 0;
        #50000;

        io_oe = 0;
        #50000;
        // ----------------------------------------------------
        // ------------------ sr04 test -----------------------
        @(posedge clk);
        // sr04 display
        sw = 4'b1000;
        // sr04 trigger signal
        btnR = 1;
        #80_000; 
        btnR = 0;

        // echo response 
        #(US_DELAY * 20);
        echo = 1;
        repeat (10) #(MS_DELAY);
        repeat (10) #(MS_DELAY);
        repeat (10) #(MS_DELAY);
        echo = 0;

        repeat (10) #(MS_DELAY);
        repeat (10) #(MS_DELAY);
        repeat (10) #(MS_DELAY);

        // sr04 display
        sw = 4'b1000;
        // sr04 trigger signal
        btnR = 1;
        #80_000; 
        btnR = 0;

        // echo response 
        #(US_DELAY * 20);
        echo = 1;
        repeat (10) #(MS_DELAY);
        repeat (10) #(MS_DELAY);
        repeat (10) #(MS_DELAY);
        echo = 0;


        $stop;
        // ----------------------------------------------------
	end

endmodule