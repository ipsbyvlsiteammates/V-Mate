`timescale 1ns/1ps

module tb_fp_alu;
    parameter EXTENSION_F = 1;
    parameter EXTENSION_D = 0;
    localparam FLEN = EXTENSION_D ? 64 : (EXTENSION_F ? 32 : 32);

    reg clk;
    reg rst_n;
    reg [4:0] fp_alu_op;
    reg [1:0] fmt;
    reg [2:0] rm;
    reg [2:0] fcsr_rm;
    reg [FLEN-1:0] rs1_data;
    reg [FLEN-1:0] rs2_data;
    reg [FLEN-1:0] rs3_data;
    wire [FLEN-1:0] result;
    wire [4:0] fflags;

    fp_alu #(
        .EXTENSION_F(EXTENSION_F),
        .EXTENSION_D(EXTENSION_D)
    ) dut (
        .fp_alu_op(fp_alu_op),
        .fmt(fmt),
        .rm(rm),
        .fcsr_rm(fcsr_rm),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .rs3_data(rs3_data),
        .result(result),
        .fflags(fflags)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        fp_alu_op = 0;
        fmt = 0;
        rm = 0;
        fcsr_rm = 0;
        rs1_data = 0;
        rs2_data = 0;
        rs3_data = 0;

        #15 rst_n = 1;

        @(posedge clk);
        fp_alu_op = 5'd0;
        fmt = 2'b00;
        rs1_data = $shortrealtobits(1.5);
        rs2_data = $shortrealtobits(2.5);
        #1;
        $display("FADD: %f + %f = %f", $bitstoshortreal(rs1_data), $bitstoshortreal(rs2_data), $bitstoshortreal(result));

        @(posedge clk);
        fp_alu_op = 5'd2;
        rs1_data = $shortrealtobits(2.0);
        rs2_data = $shortrealtobits(3.0);
        #1;
        $display("FMUL: %f * %f = %f", $bitstoshortreal(rs1_data), $bitstoshortreal(rs2_data), $bitstoshortreal(result));

        #20 $finish;
    end
endmodule
