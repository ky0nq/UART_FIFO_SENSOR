// tb_fnd_controller.v
// 26.05.02 05:57 pm

`timescale 1ns / 1ps

module tb_fnd_controller ();

    reg         clk;
    reg         rst;
    reg         sw9;
    reg  [ 1:0] data_type_sel;  // sw[3], sw[0]
    reg  [ 1:0] fnddata_type_sel;  // sw[3], sw[1] 
    reg  [ 2:0] place_sel;
    reg  [23:0] fnd_in;

    wire [ 3:0] fnd_com;
    wire [ 7:0] fnd_data;
    wire [31:0] digit_data;
    wire        o_led9;

    fnd_controller #(
        .MSEC_WIDTH(7),
        .SEC_WIDTH (6),
        .MIN_WIDTH (6),
        .HOUR_WIDTH(5)
    ) dut (
        .clk             (clk),
        .rst             (rst),
        .sw9             (sw9),
        .data_type_sel   (data_type_sel),
        .fnddata_type_sel(fnddata_type_sel),
        .place_sel       (place_sel),
        .fnd_in          (fnd_in),
        .fnd_com         (fnd_com),
        .fnd_data        (fnd_data),
        .digit_data      (digit_data),
        .o_led9          (o_led9)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        sw9 = 0;

        // sw[3], sw[1]
        data_type_sel = 2'b00;
        // sw[3], sw[0] 
        fnddata_type_sel = 2'b00;

        // dp on off (watch - setting mode)
        place_sel = 3'b0;
        
        // 24-bit data input
        fnd_in = 23'b0;


        #20;
        rst = 0;
        // --- data_type -> 32-bit digit data ---
        fnd_in = 23'b0111_0000_1111_0000_1100_0011; 
        fnddata_type_sel = 2'b00; // fnd msec sec
        data_type_sel = 2'b00; // digit_data = hour10 hour1 min10 min1 sec10 sec1 msec10 msec1
        repeat (8) #1_000_000;
        data_type_sel = 2'b01; // digit_data = hour10 hour1 min10 min1 sec10 sec1 msec10 msec1
        repeat (8) #1_000_000;
        data_type_sel = 2'b10; // digit_data = sr04_1000 sr04_100 sr04_10 sr04_1 0000 0000
        repeat (8) #1_000_000;      
        data_type_sel = 2'b11; // digit_data = tem10 tem1 hum10 hum1 0000 0000
        // --------------------------------------
        repeat (8) #1_000_000;     
        fnddata_type_sel = 2'b01; // fnd hour min
        repeat (8) #1_000_000;     
        fnddata_type_sel = 2'b10; // fnd ultrasound      
        repeat (8) #1_000_000;     
        fnddata_type_sel = 2'b11; // fnd temperature / humidity
        repeat (8) #1_000_000;  

        repeat (10) @(posedge clk);

        sw9 = 1;
        repeat (8) #1_000_000; 

        $stop;


    end

endmodule
