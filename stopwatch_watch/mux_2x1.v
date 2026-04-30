// 26.04.18 22:06 Final code _ optimize 

`timescale 1ns / 1ps
module mux_2x1 # (
    parameter BIT_WIDTH = 4
)(
    input   [BIT_WIDTH-1:0]   in0,
    input   [BIT_WIDTH-1:0]   in1,
    input                     sel,
    output  [BIT_WIDTH-1:0]   out_mux
    );
    
    // sel = sw[1]
    assign out_mux = (sel) ? in1 : in0;

endmodule
