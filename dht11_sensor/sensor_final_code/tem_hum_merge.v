// tem_hum_merge.v
// 26.05.03 09:55 am

`timescale 1ns / 1ps

module tem_hum_merge (
    input [7:0] hum_data,
    input [7:0] tem_data,

    output [23:0] tem_hum_data
);

    assign tem_hum_data = {8'h0, tem_data, hum_data};

endmodule
