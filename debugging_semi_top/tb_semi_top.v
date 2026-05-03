`timescale 1ns / 1ps

module tb_semi_top ();

	parameter [7:0] HUMI_INT = 8'd60;  // humidity integral
    parameter [7:0] TEMP_INT = 8'd25;  // temperature integral
    reg [39:0] DATA_STREAM = {
        HUMI_INT, 8'h00, TEMP_INT, 8'h00, HUMI_INT + TEMP_INT
    };

    reg        clk;
    reg        rst;
    reg  [3:0] sw;
    reg        sw9;
    reg        btnU;
    reg        btnR;
    reg        btnD;
    reg        btnL;
    reg        echo;

	wire       o_led0;
	wire       o_led1;
	wire       o_led2;
	wire       o_led3;
    wire       o_led9;
    wire       o_led15;
	
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;
    wire       trig;

    // -----------------------------------------------
    // DHT11 tri-state 구동용 추가 선언
    reg        dht11_tb_drive;  // tb가 출력할 값
    reg        dht11_tb_en;     // 1: tb가 제어, 0: DUT가 제어(Hi-Z)
    wire       dht11;
    assign dht11 = dht11_tb_en ? dht11_tb_drive : 1'bz;
    // -----------------------------------------------

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
		.o_led0  (o_led0),
		.o_led1  (o_led1),
		.o_led2  (o_led2),
		.o_led3  (o_led3),
        .o_led9  (o_led9),
        .o_led15 (o_led15),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data),
        .trig    (trig),
        .dht11   (dht11)
    );

    always #5 clk = ~clk;

    // -----------------------------------------------
    // SR04 echo task
    // distance_cm에 해당하는 echo HIGH 펄스를 인가
    // 1cm = 58us → 58_000ns
    task sr04_send_echo;
        input [8:0] distance_cm;
        integer pulse_ns;
        begin
            // trig 상승 대기 (DUT가 trig 올릴 때까지)
            @(posedge trig);
            // trig 하강 대기 (10us trig 펄스 끝날 때까지)
            @(negedge trig);
            // 전파 지연 시뮬레이션 (실제 센서처럼 수 us 대기)
            #500;
            // echo HIGH: 거리 × 58us
            pulse_ns = distance_cm * 58_000;
            echo = 1;
            #(pulse_ns);
            echo = 0;
        end
    endtask
    // -----------------------------------------------

    // -----------------------------------------------
    // DHT11 data send task
    // DATA_STREAM 40비트를 DHT11 프로토콜로 전송
    // dht11_datapath.v FSM 기준:
    //   START: DUT가 18ms LOW 출력
    //   WAIT:  DUT가 Hi-Z → 센서(tb)가 30us LOW 응답
    //   SYNCL: tb가 80us LOW
    //   SYNCH: tb가 80us HIGH
    //   DATA_SYNC: tb가 50us LOW (비트 시작)
    //   DATA_COUNT: tb가 HIGH 유지
    //     → 0비트: 26us HIGH, 1비트: 70us HIGH
    task dht11_send_data;
        input [39:0] data;
        integer i;
        begin
            // DUT START(18ms LOW) + WAIT(30us 후 Hi-Z) 대기
            // DUT가 dht11을 LOW로 당기는 구간 대기
            @(negedge dht11);           // DUT START 시작
            #18_100_000;                // 18ms 경과 대기 (DUT가 Hi-Z로 전환)

            // tb가 제어권 획득
            dht11_tb_en    = 1;

            // WAIT 응답: 센서 응답 LOW 30us
            dht11_tb_drive = 0;
            #30_000;

            // SYNCL: 80us LOW
            dht11_tb_drive = 0;
            #80_000;

            // SYNCH: 80us HIGH
            dht11_tb_drive = 1;
            #80_000;

            // 40비트 전송 (MSB first)
            for (i = 39; i >= 0; i = i - 1) begin
                // DATA_SYNC: 50us LOW (비트 시작 마커)
                dht11_tb_drive = 0;
                #50_000;
                // DATA_COUNT: HIGH 구간으로 0/1 결정
                //   0비트 → 26us HIGH
                //   1비트 → 70us HIGH
                dht11_tb_drive = 1;
                if (data[i])
                    #70_000;
                else
                    #26_000;
            end

            // STOP: 50us LOW 후 Hi-Z 해제
            dht11_tb_drive = 0;
            #50_000;
            dht11_tb_drive = 1;
            #10_000;

            // DUT에 제어권 반환
            dht11_tb_en = 0;
        end
    endtask
    // -----------------------------------------------

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

        // DHT11 초기: tb가 idle HIGH 유지
        dht11_tb_drive = 1;
        dht11_tb_en    = 1;

		#20
		rst = 0;
		repeat (2) @(negedge clk);

		// -----------------------------------------------
		// SR04 Test: 10cm 거리 측정
		// -----------------------------------------------
		sw = 4'b1000;
		repeat (1) @(posedge clk);
		btnR = 1;
		#80_000;
		btnR = 0;

        // echo 응답 인가 (10cm)
        sr04_send_echo(9'd10);

		repeat (7_000_000) @(negedge clk);

		// -----------------------------------------------
		// DHT11 Test: 온도 25도, 습도 60% 전송
		// -----------------------------------------------
		sw = 4'b1010;
		repeat (1) @(posedge clk);

        // dht11_send_data는 DUT의 START 신호를 기다리므로
        // btnR과 fork-join으로 동시에 시작
        fork
            begin
                // btnR로 DHT_START 트리거
                @(posedge clk); #1;
                btnR = 1;
                #80_000;
                btnR = 0;
            end
            begin
                // 프로토콜 응답 전송
                dht11_send_data(DATA_STREAM);
            end
        join

		repeat (1_000) @(negedge clk);

		// -----------------------------------------------
		// IDLE State Transition Test
		// -----------------------------------------------
		sw = 4'b0000;
		repeat (10) @(negedge clk);
		$stop();

	end

endmodule
