`timescale 1ns/1ps
module icg (
    input  wire clk,
    input  wire en,
    output wire gated_clk
);
    reg latch_en;
    always @(*) begin
        if (!clk) latch_en = en;
    end
    assign gated_clk = clk & latch_en;
endmodule
