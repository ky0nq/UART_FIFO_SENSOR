`timescale 1ns / 1ps

module dht11_datapath (
    input clk,
    input rst,
    input dht11_start,
    input tick_us,

    output [23:0] tem_hum_data,
    output valid,
    output dht_done,

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
                    if ((tick_cnt_reg > 40) && (dht11_sync2)) begin
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
                    if ((tick_cnt_reg > 40) && (!dht11_sync2)) begin
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

module tem_hum_merge (
    input [7:0] hum_data,
    input [7:0] tem_data,

    output [23:0] tem_hum_data
);

    assign tem_hum_data = {8'h0, hum_data, tem_data};
endmodule
