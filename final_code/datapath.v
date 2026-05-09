`timescale 1ns / 1ps

module datapath #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5,
    MSEC_SET = 0,
    SEC_SET = 0,
    MIN_SET = 0,
    HOUR_SET = 8,
    MSEC_INIT = 0,
    SEC_INIT = 0,
    MIN_INIT = 0,
    HOUR_INIT = 12
) (
    input       clk,
    input       rst,
    input       run_stop,
    input       clear,
    input       mode,
    input       set,
    input       up,
    input       down,
    input [2:0] place,
    input       sr04_start,
    input       tick_us,
    input       dht11_start,
    input [1:0] data_type_sel,  // {sw[3], sw[1]}
    input       sw2_and_1,

    input  echo,
    output trig,

    output        o_led15,
    output [23:0] fnd_data,
    output        dht_done,
    inout         dht11
);

    wire [23:0] w_st_fnddata, w_wt_fnddata, w_dist_fnddata, w_temhum_fnddata;

    stopwatch_datapath #(
        .MSEC_WIDTH(7),
        .SEC_WIDTH (6),
        .MIN_WIDTH (6),
        .HOUR_WIDTH(5),
        .MSEC_SET  (0),
        .SEC_SET   (0),
        .MIN_SET   (0),
        .HOUR_SET  (8)
    ) U_ST_DATAPATH (
        .clk         (clk),
        .rst         (rst),
        .i_runstop   (run_stop),
        .i_clear     (clear),
        .i_mode      (mode),
        .i_set       (set),
        .st_time_data(w_st_fnddata)
    );

    watch_datapath #(
        .MSEC_WIDTH(7),
        .SEC_WIDTH (6),
        .MIN_WIDTH (6),
        .HOUR_WIDTH(5),
        .MSEC_INIT (0),
        .SEC_INIT  (0),
        .MIN_INIT  (0),
        .HOUR_INIT (12)
    ) U_WT_DATAPATH (
        .clk         (clk),
        .rst         (rst),
        .sw2_and_1   (sw2_and_1),
        .place       (place),
        .i_up        (up),
        .i_down      (down),
        .wt_time_data(w_wt_fnddata)
    );

    sr04_datapath U_SR04_DATAPATH (
        .clk       (clk),
        .rst       (rst),
        .sr04_start(sr04_start),
        .echo      (echo),
        .tick_us   (tick_us),
        .trig      (trig),
        .dist_data (w_dist_fnddata)
    );

    dht11_datapath U_DHT11_DATAPATH (
        .clk         (clk),
        .rst         (rst),
        .dht11_start (dht11_start),
        .tick_us     (tick_us),
        .tem_hum_data(w_temhum_fnddata),
        .valid       (o_led15),
        .dht_done    (dht_done),
        .dht11       (dht11)
    );

    // FND Controller Select MUX
    mux_4x1 U_FNDIN_MUX_4x1 (
        .in0    (w_st_fnddata),
        .in1    (w_wt_fnddata),
        .in2    (w_dist_fnddata),
        .in3    (w_temhum_fnddata),
        .sel    (data_type_sel),
        .out_mux(fnd_data)
    );
endmodule

module mux_4x1 #(
    parameter BIT_WIDTH = 24
) (
    input  [BIT_WIDTH-1:0] in0,
    input  [BIT_WIDTH-1:0] in1,
    input  [BIT_WIDTH-1:0] in2,
    input  [BIT_WIDTH-1:0] in3,
    input  [          1:0] sel,     // [sw3, sw1]
    output [BIT_WIDTH-1:0] out_mux
);

    // sel = sw[3] , sw[1]
    assign out_mux = (sel == 2'b00) ? in0 : 
                    (sel == 2'b01) ? in1 : 
                    (sel == 2'b10) ? in2 : in3;
endmodule

// =================================================================
// =================================================================

// datapath module

// =================================================================
// =================================================================
// stopwatch datapath module

module stopwatch_datapath #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5,
    MSEC_SET = 0,  // stopwatch setting value 
    SEC_SET = 0,
    MIN_SET = 0,
    HOUR_SET = 8
) (
    input clk,
    input rst,

    input i_runstop,
    input i_clear,
    input i_mode,
    input i_set,

    output [23 : 0] st_time_data
);
    wire w_tick_100hz;

    wire w_sec_tick_up, w_min_tick_up, w_hour_tick_up;
    wire w_sec_tick_down, w_min_tick_down, w_hour_tick_down;
    wire [MSEC_WIDTH-1:0] w_msec;
    wire [SEC_WIDTH-1:0] w_sec;
    wire [MIN_WIDTH-1:0] w_min;
    wire [HOUR_WIDTH-1:0] w_hour;

    // i_mode = 1 = down mode ->  00 00 | 00 00 Not down count
    wire all_zero;
    assign all_zero = ((w_msec == 0) && (w_sec == 0) && (w_min == 0) && (w_hour == 0));

    tick_gen_100hz_stopwatch U_TICK_GEN_100HZ (
        .clk         (clk),
        .rst         (rst),
        .i_runstop   (i_runstop),
        .i_clear     (i_clear),
        .o_tick_100hz(w_tick_100hz)
    );

    //msec
    tick_counter_stopwatch #(
        .TIMES    (100),
        .BIT_WIDTH(MSEC_WIDTH),
        .INIT     (MSEC_SET)
    ) U_MSEC_TICK_COUNTER (
        .clk(clk),
        .rst(rst),
        // up count mode
        .i_tick_up      (i_mode ? 1'b0 : w_tick_100hz), 
        // down count mode
        .i_tick_down(i_mode ? (all_zero ? 1'b0 : w_tick_100hz) : 1'b0),
        .i_clear(i_clear),
        .i_mode(i_mode),
        .i_set(i_set),
        .times_counter(w_msec),
        // up count mode
        .o_tick_up(w_sec_tick_up),
        // down count mode
        .o_tick_down(w_sec_tick_down)
    );

    // sec
    tick_counter_stopwatch #(
        .TIMES    (60),
        .BIT_WIDTH(SEC_WIDTH),
        .INIT     (SEC_SET)
    ) U_SEC_TICK_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick_up(w_sec_tick_up),  // from msec o_tick_up
        .i_tick_down(all_zero ? 1'b0 : w_sec_tick_down),
        .i_clear(i_clear),
        .i_mode(i_mode),
        .i_set(i_set),
        .times_counter(w_sec),
        .o_tick_up(w_min_tick_up),
        .o_tick_down(w_min_tick_down)
    );

    // min
    tick_counter_stopwatch #(
        .TIMES    (60),
        .BIT_WIDTH(MIN_WIDTH),
        .INIT     (MIN_SET)
    ) U_MIN_TICK_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick_up(w_min_tick_up),  // from sec o_tick_up
        .i_tick_down(all_zero ? 1'b0 : w_min_tick_down),
        .i_clear(i_clear),
        .i_mode(i_mode),
        .i_set(i_set),
        .times_counter(w_min),
        .o_tick_up(w_hour_tick_up),
        .o_tick_down(w_hour_tick_down)
    );

    // hour
    tick_counter_stopwatch #(
        .TIMES    (24),
        .BIT_WIDTH(HOUR_WIDTH),
        .INIT     (HOUR_SET)
    ) U_HOUR_TICK_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick_up(w_hour_tick_up),  // from min o_tick_up
        .i_tick_down(all_zero ? 1'b0 : w_hour_tick_down),
        .i_clear(i_clear),
        .i_mode(i_mode),
        .i_set(i_set),
        .times_counter(w_hour),
        .o_tick_up(),
        .o_tick_down()
    );

    stopwatch_merge #(
        .MSEC_WIDTH(7),
        .SEC_WIDTH (6),
        .MIN_WIDTH (6),
        .HOUR_WIDTH(5)
    ) U_ST_MERGE (
        .msec         (w_msec),
        .sec          (w_sec),
        .min          (w_min),
        .hour         (w_hour),
        .fnd_stopwatch(st_time_data)
    );
endmodule

module tick_gen_100hz_stopwatch (
    input clk,
    input rst,

    input i_runstop,
    input i_clear,

    output reg o_tick_100hz
);
    // 100Hz counter number * 1000 for simulation
    parameter F_COUNT = 100_000_000 / 100;
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg  <= 0;
            o_tick_100hz <= 1'b0;
        end else begin
            if (i_runstop) begin  // runstop vs. clear : runstop first condition
                counter_reg  <= counter_reg + 1;
                o_tick_100hz <= 1'b0;
                if (counter_reg == F_COUNT - 1) begin
                    counter_reg  <= 0;
                    o_tick_100hz <= 1'b1;
                end else begin
                    o_tick_100hz <= 1'b0;
                end
            end else if (i_clear) begin
                counter_reg  <= 0;
                o_tick_100hz <= 0;
            end else begin
                o_tick_100hz <= 1'b0;
            end
        end
    end
endmodule

module tick_counter_stopwatch #(
    parameter TIMES     = 100,
              BIT_WIDTH = 7,
              INIT      = 0
) (
    input clk,
    input rst,
    input i_tick_up,
    input i_tick_down,

    input i_clear,
    input i_mode,
    input i_set,

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

        if (i_set) begin // stopwatch - setting mode
            counter_next = INIT;
        end else if (i_mode) begin  // down count
            if (i_tick_down) begin  
                counter_next = counter_reg - 1;
                if (counter_reg == 0) begin
                    counter_next = TIMES - 1;
                    o_tick_down  = 1'b1;
                end
            end
        end else begin  // up count
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

// merge module for fnd input format
module stopwatch_merge #(
    parameter   MSEC_WIDTH =    7,
    SEC_WIDTH  =    6,
    MIN_WIDTH  =    6,
    HOUR_WIDTH =    5
) (
    input [MSEC_WIDTH-1 : 0] msec,
    input [SEC_WIDTH-1 : 0] sec,
    input [MIN_WIDTH-1 : 0] min,
    input [HOUR_WIDTH-1 : 0] hour,
    output [23:0] fnd_stopwatch

);
    assign fnd_stopwatch = {hour, min, sec, msec};

endmodule
// =================================================================

// =================================================================
// watch datapath module

module watch_datapath #(
    parameter   MSEC_WIDTH =    7,
                SEC_WIDTH  =    6,
                MIN_WIDTH  =    6,
                HOUR_WIDTH =    5,
                // initialize value
                MSEC_INIT =     0,
                SEC_INIT  =     0,
                MIN_INIT  =     0,
                HOUR_INIT =     12 
) (
    input                       clk,
    input                       rst,
    input                       sw2_and_1, // watch - setting mode
    input  [2:0]                place,     // watch - setting time place

    input                       i_up,
    input                       i_down,

    output [23:0]               wt_time_data
);

    // wire 
    wire w_tick_100hz;
    wire w_sec_tick, w_min_tick, w_hour_tick;
    wire [MSEC_WIDTH-1:0] w_msec;
    wire [SEC_WIDTH-1:0] w_sec;
    wire [MIN_WIDTH-1:0] w_min;
    wire [HOUR_WIDTH-1:0] w_hour;

    tick_gen_100hz_watch U_TICK_GEN_100HZ_WATCH (
        .clk            (clk),
        .rst            (rst),
        .sw2_and_1      (sw2_and_1),  // watch - setting mode
        .o_tick_100hz   (w_tick_100hz)
    );

    tick_counter_watch #(
        .TIMES          (100), 
        .BIT_WIDTH      (MSEC_WIDTH),
        .INIT           (MSEC_INIT)
    ) U_MSEC_TICK_COUNTER_WATCH (
        .clk            (clk),
        .rst            (rst),
        .i_tick         (w_tick_100hz),
        .sw2_and_1      (sw2_and_1),
        .place          (),
        .i_up           (i_up),
        .i_down         (i_down),
        .times_counter  (w_msec),
        .o_tick         (w_sec_tick)
    );

    tick_counter_watch #(
        .TIMES          (60), 
        .BIT_WIDTH      (SEC_WIDTH),
        .INIT           (SEC_INIT)
    ) U_SEC_TICK_COUNTER_WATCH (
        .clk            (clk),
        .rst            (rst),
        .i_tick         (w_sec_tick), // from msec o_tick
        .sw2_and_1      (sw2_and_1),
        .place          (place[0]),
        .i_up           (i_up),
        .i_down         (i_down),
        .times_counter  (w_sec),
        .o_tick         (w_min_tick)
    );

    tick_counter_watch #(
        .TIMES          (60), 
        .BIT_WIDTH      (MIN_WIDTH),
        .INIT           (MIN_INIT)
    ) U_MIN_TICK_COUNTER_WATCH (
        .clk            (clk),
        .rst            (rst),
        .i_tick         (w_min_tick), // from sec o_tick
        .sw2_and_1      (sw2_and_1),
        .place          (place[1]),
        .i_up           (i_up),
        .i_down         (i_down),
        .times_counter  (w_min),
        .o_tick         (w_hour_tick)
    );

    tick_counter_watch #(
        .TIMES          (24), 
        .BIT_WIDTH      (HOUR_WIDTH),
        .INIT           (HOUR_INIT)
    ) U_HOUR_TICK_COUNTER_WATCH (
        .clk            (clk),
        .rst            (rst),
        .i_tick         (w_hour_tick), // from min o_tick
        .sw2_and_1      (sw2_and_1),
        .place          (place[2]),
        .i_up           (i_up),
        .i_down         (i_down),
        .times_counter  (w_hour),
        .o_tick         ()
    );

    // merge module for fnd input format
    watch_merge #(
        .MSEC_WIDTH(7),
        .SEC_WIDTH (6),
        .MIN_WIDTH (6),
        .HOUR_WIDTH(5)
    ) U_WT_MERGE (
        .msec         (w_msec),
        .sec          (w_sec),
        .min          (w_min),
        .hour         (w_hour),
        .fnd_watch    (wt_time_data)
    );

endmodule

module tick_gen_100hz_watch (
    input       clk,
    input       rst,
    input       sw2_and_1,

    output reg  o_tick_100hz

);
    // 100Hz counter number * 1000 for simulation
    parameter F_COUNT = 100_000_000 / 100;
    reg [$clog2(F_COUNT)-1:0] counter_reg;  

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg     <= 0;
            o_tick_100hz    <= 1'b0;
        end 
        else begin
            if (!sw2_and_1) begin 
                counter_reg     <= counter_reg + 1;
                o_tick_100hz    <= 1'b0;
                if (counter_reg == F_COUNT - 1) begin
                    counter_reg     <= 0;
                    o_tick_100hz    <= 1'b1;
                end else begin 
                    o_tick_100hz    <= 1'b0;
                end
            end
            else begin // sw2_and_1 == 1
                counter_reg     <= 0;
                o_tick_100hz    <= 1'b0;
            end
        end
    end
endmodule

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
    output reg                   o_tick 
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
        if (i_tick) begin // watch - time mode
            counter_next = counter_reg + 1;
            if (counter_reg == (TIMES - 1)) begin
                counter_next    = 0;
                o_tick          = 1'b1;
            end
            else begin
                o_tick = 1'b0;
            end
        end 
        else begin // watch - setting mode
            if (sw2_and_1) begin
                if (place) begin 
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
                    else begin 
                        counter_next = counter_reg;
                        o_tick = 1'b0;
                    end 
                end
                else begin 
                    counter_next = counter_reg;
                    o_tick = 1'b0;
                end
            end
        end
    end

endmodule

// merge module for fnd input format
module watch_merge #(
    parameter   MSEC_WIDTH =    7,
    SEC_WIDTH  =    6,
    MIN_WIDTH  =    6,
    HOUR_WIDTH =    5
) (
    input [MSEC_WIDTH-1 : 0] msec,
    input [SEC_WIDTH-1 : 0] sec,
    input [MIN_WIDTH-1 : 0] min,
    input [HOUR_WIDTH-1 : 0] hour,
    output [23:0] fnd_watch

);
    assign fnd_watch = {hour, min, sec, msec};

endmodule

// =================================================================
// sr04 datapath module

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

    reg [8:0] dist_reg, dist_next;

    assign trig = trig_reg;
    assign distance = dist_reg;

    always @(posedge clk, posedge rst) begin 
        if (rst) begin
            c_state <= IDLE;
            trig_reg <= 1'b0;
            tick_cnt_reg <= 0;
            dist_reg <= 0;
        end else begin
            c_state <= n_state;
            trig_reg <= trig_next;
            tick_cnt_reg <= tick_cnt_next;  
            dist_reg <= dist_next;
        end
    end

    always @(*) begin  
        n_state = c_state;
        trig_next = trig_reg;
        tick_cnt_next = tick_cnt_reg;
        dist_next = dist_reg;

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
                    if (tick_cnt_reg > 10) begin 
                        n_state = WAIT;
                        tick_cnt_next = 0;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            WAIT: begin
                trig_next = 1'b0;
                if (tick_us && echo) begin
					n_state = RESPONSE;
					tick_cnt_next = 0;
					dist_next = 0;
                end
            end

            RESPONSE : begin
            if (tick_us) begin
				tick_cnt_next = tick_cnt_reg + 1;
				if (tick_cnt_reg == 58) begin
					dist_next = dist_reg + 1;
					tick_cnt_next = 0;
					if (dist_reg == 400) begin
						dist_next = 400;
                        n_state = IDLE;
					end
				end
				if (echo == 0) begin
					n_state = IDLE;
				end
            end
        end
        endcase
    end
endmodule

// merge module for fnd input format
module sr04_merge (
    input [8:0] distance,
    output [23:0] dist_data
);
    assign dist_data = {15'b0, distance};

endmodule

// =================================================================
// dht11 datapath module

module dht11_datapath (
    input clk,
    input rst,
    input dht11_start,
    input tick_us,

    output [23:0] tem_hum_data,
    output valid,
    output dht_done,

    // inout port 
    inout dht11
);
    wire [7:0] w_humidity, w_temperature;
    
    dht11_controller U_DHT11_CNTL (
        .clk        (clk),
        .rst        (rst),
        .dht11_start(dht11_start),
        .tick_us    (tick_us),
        .humidity   (w_humidity),
        .temperature(w_temperature),
        .valid      (valid),
        .dht_done   (dht_done),
        .dht11      (dht11)
    );

    tem_hum_merge U_TEM_HUM_MERGE (
        .hum_data    (w_humidity),
        .tem_data    (w_temperature),
        .tem_hum_data(tem_hum_data)
    );
endmodule


module dht11_controller (
    input           clk,
    input           rst,
    input           dht11_start,
    input           tick_us,
    output [7:0]    humidity,
    output [7:0]    temperature,
    output          valid,  // for check sum (valid == 1 -> led == 1)
    output          dht_done,
    inout           dht11
);

    // state parameter list
    parameter IDLE = 0, START = 1, WAIT = 2, SYNCL = 3, SYNCH = 4, // Prof High = 3, Low = 4
    DATA_SYNC = 5, DATA_COUNT = 6, DATA_DECISION = 7, STOP = 8;

    reg [3:0] c_state, n_state;
    reg [5:0] bit_cnt_reg, bit_cnt_next;  // receive bit counter
    reg [$clog2(19_000)-1:0] tick_cnt_reg, tick_cnt_next;  // general tick count

    reg out_sel_reg, out_sel_next;  // dht11 io 3 state control
    reg dht11_reg, dht11_next;  // dht11 output drive

    // 40-bit data register
    reg [39:0] data_reg, data_next; 

    // data decision 0 or 1
    reg data_decision_reg, data_decision_next;

    //dht11 output 3 state control
    assign dht11 = (out_sel_reg) ? dht11_reg : 1'bz;
    
    assign humidity = data_reg[39:32];
    assign temperature = data_reg[23:16];

    // dht11 synchronizer 
    reg dht11_sync1, dht11_sync2; // dht11 synchronizer 

    // 8-bit * 4 = max 10-bit -> we use only 8-bit
    assign valid = (data_reg [7:0] == (data_reg[39:32] + data_reg[31:24] + data_reg[23:16] + data_reg [15:8])) ? 1 : 0;
    
    // we need control unit dht11_done signal
    reg dht_done_reg, dht_done_next; 
    assign dht_done = dht_done_reg;
    
    // synchronizer for stable input
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            dht11_sync1 <= 1'b1;
            dht11_sync2 <= 1'b1;
        end else begin
            dht11_sync1 <= dht11;       
            dht11_sync2 <= dht11_sync1; 
        end
    end
    
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
            bit_cnt_reg <= 0;
            tick_cnt_reg <= 0;
            out_sel_reg <= 1;   // when IDLE dht11 output mode
            dht11_reg <= 1;     // default high state
            data_reg <= 1;
            data_decision_reg <= 0;
            dht_done_reg <= 0;
        end else begin
            c_state <= n_state;
            bit_cnt_reg <= bit_cnt_next;
            tick_cnt_reg <= tick_cnt_next;
            out_sel_reg <= out_sel_next;
            dht11_reg <= dht11_next;
            data_reg <= data_next;
            data_decision_reg <= data_decision_next;
            dht_done_reg <= dht_done_next;
        end
    end

    always @(*) begin
        n_state       = c_state;
        bit_cnt_next  = bit_cnt_reg;
        tick_cnt_next = tick_cnt_reg;
        out_sel_next  = out_sel_reg;
        dht11_next    = dht11_reg;
        data_next      = data_reg;
        data_decision_next = data_decision_reg;
        dht_done_next = dht_done_reg;

        case (c_state)
            IDLE: begin
                dht_done_next = 1'b0;
                dht11_next = 1'b1;
                out_sel_next = 1'b1;
                if (dht11_start) begin
                    bit_cnt_next = 0;
                    tick_cnt_next = 0;
                    n_state = START;
                end
            end

            START: begin
                dht11_next = 1'b0;
                if (tick_us) begin
                    if (tick_cnt_reg > 19_000) begin    
                        n_state = WAIT;
                        tick_cnt_next = 0;
                    end
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            WAIT: begin
                dht11_next = 1'b1;
                if (tick_us) begin
                    if (tick_cnt_reg > 30) begin    
                        n_state = SYNCL;
                        tick_cnt_next = 0;
                    end
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            SYNCL: begin
                // output is high impedance "z" -> input mode
                out_sel_next = 1'b0; 
                if (tick_us) begin
                    if ((tick_cnt_reg > 80) && (dht11_sync2)) begin
                        n_state = SYNCH;
                        tick_cnt_next = 0;
                    end
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            SYNCH: begin
                if (tick_us) begin
                    if ((tick_cnt_reg > 80) && (!dht11_sync2)) begin
                        n_state = DATA_SYNC;
                        tick_cnt_next = 0;
                    end
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            DATA_SYNC: begin
                if (tick_us) begin
                    if (dht11_sync2) begin
                        n_state = DATA_COUNT;
                        tick_cnt_next = 0;
                    end
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            DATA_COUNT: begin
                if (tick_us) begin
                    if (!dht11_sync2) begin
                        n_state = DATA_DECISION;
                        // data decision value save
                        if (tick_cnt_reg >= 45) begin
                            data_decision_next = 1'b1;
                        end
                        else begin
                            data_decision_next = 1'b0;
                        end
                        tick_cnt_next = 0;
                    end
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            DATA_DECISION: begin 
                bit_cnt_next = bit_cnt_reg + 1;
                // dht11 data = MSB -> LSB drive & shift
                data_next = {data_reg, data_decision_reg};
                if (bit_cnt_reg == 39) begin
                    n_state = STOP;
                    bit_cnt_next = 0;
                end
                else begin
                    n_state = DATA_SYNC;
                end
                data_decision_next = 0;
            end

            STOP: begin
                dht_done_next = 1'b1;
                if (tick_us) begin
                    if (tick_cnt_reg > 50) begin
                        n_state = IDLE;
                        // auto IDLE output out_sel
                        tick_cnt_next = 0;
                    end
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule

// merge module for fnd input format
module tem_hum_merge (
    input [7:0] hum_data,
    input [7:0] tem_data,

    output [23:0] tem_hum_data
);

    assign tem_hum_data = {8'h0, tem_data, hum_data};
endmodule
// =================================================================