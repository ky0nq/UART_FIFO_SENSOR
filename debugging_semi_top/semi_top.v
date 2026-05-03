// 26.05.03 20:25
`timescale 1ns / 1ps

module semi_top (
    input       clk,
    input       rst,
    input [3:0] sw,
    input       sw9,
    input       btnU,
    input       btnR,
    input       btnD,
    input       btnL,
    input       echo,

    output      o_led9,
    output      o_led15,

    output      o_led0,
    output      o_led1,
    output      o_led2,
    output      o_led3,

    output [ 3:0] fnd_com,
    output [ 7:0] fnd_data,
    //output [31:0] digit_data,
    output trig,

    inout dht11
);
    assign o_led0 = sw[0];
    assign o_led1 = sw[1];
    assign o_led2 = sw[2];
    assign o_led3 = sw[3];
    
    wire w_runstop, w_clear, w_mode, w_set, w_up, w_down;
    wire w_dht_done;
    wire w_tick_us, w_dht11_start;
    wire [1:0] w_data_type_sel, w_fnddata_type_sel;
    wire [2:0] w_place;
    wire [23:0] w_fnd_data;

    button_debounce U_BTNU (
        .clk     (clk)      ,
        .rst     (rst)      ,
        .i_Btn   (btnU)      ,
        .o_Btn   (w_btnU)      
    );

    button_debounce U_BTNL (
        .clk     (clk)      ,
        .rst     (rst)      ,
        .i_Btn   (btnL)      ,
        .o_Btn   (w_btnL)      
    );

    button_debounce U_BTNR (
        .clk     (clk)      ,
        .rst     (rst)      ,
        .i_Btn   (btnR)      ,
        .o_Btn   (w_btnR)      
    );

    button_debounce U_BTND (
        .clk     (clk)      ,
        .rst     (rst)      ,
        .i_Btn   (btnD)      ,
        .o_Btn   (w_btnD)      
    );

    control_unit U_CNT (
        .clk             (clk),
        .rst             (rst),
        .dht_done        (w_dht_done),
        .sw              (sw),
        .btnU            (w_btnU),
        .btnR            (w_btnR),
        .btnD            (w_btnD),
        .btnL            (w_btnL),
        .run_stop        (w_runstop),
        .clear           (w_clear),
        .mode            (w_mode),
        .set             (w_set),
        .up              (w_up),
        .down            (w_down),
        .place           (w_place),
        .sr04_start      (w_sr04_start),
        .tick_us         (w_tick_us),
        .dht11_start     (w_dht11_start),
        .data_type_sel   (w_data_type_sel),
        .fnddata_type_sel(w_fnddata_type_sel)
    );

    datapath #(
        .MSEC_WIDTH(7),
        .SEC_WIDTH (6),
        .MIN_WIDTH (6),
        .HOUR_WIDTH(5),
        .MSEC_SET  (0),
        .SEC_SET   (0),
        .MIN_SET   (0),
        .HOUR_SET  (8),
        .MSEC_INIT (0),
        .SEC_INIT  (0),
        .MIN_INIT  (0),
        .HOUR_INIT (12)
    ) U_DATAPATH (
        .clk          (clk),
        .rst          (rst),
        .run_stop     (w_runstop),
        .clear        (w_clear),
        .mode         (w_mode),
        .set          (w_set),
        .up           (w_up),
        .down         (w_down),
        .place        (w_place),
        .sr04_start   (w_sr04_start),
        .tick_us      (w_tick_us),
        .dht11_start  (w_dht11_start),
        .data_type_sel(w_data_type_sel),
        .sw2_and_1    ((sw[2])&(sw[1])),
        .echo         (echo),
        .trig         (trig),
        .o_led15      (o_led15),
        .fnd_data     (w_fnd_data),
        .dht_done     (w_dht_done),
        .dht11        (dht11)
    );

    fnd_controller #(
        .MSEC_WIDTH(7),
        .SEC_WIDTH (6),
        .MIN_WIDTH (6),
        .HOUR_WIDTH(5)
    ) U_FND_CNTL (
        .clk             (clk),
        .rst             (rst),
        .sw9             (sw9),
        // digit data 
        .data_type_sel   (w_data_type_sel),  // sw[3], sw[1] 조합
        // fnd display data
        .fnddata_type_sel(w_fnddata_type_sel),  // sw[3], sw[0] 조합
        .place_sel       (w_place),
        .fnd_in          (w_fnd_data),
        .fnd_com         (fnd_com),
        .fnd_data        (fnd_data),
        //.digit_data    (digit_data),
        .o_led9          (o_led9)
    );

endmodule
