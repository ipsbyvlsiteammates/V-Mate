`timescale 1ns/1ps

module tb_fpr;
    parameter EXTENSION_F = 1;
    parameter EXTENSION_D = 0;
    localparam FLEN = EXTENSION_D ? 64 : (EXTENSION_F ? 32 : 32);

    reg clk;
    reg rst_n;
    reg we;
    reg [4:0] rd_addr;
    reg [4:0] rs1_addr;
    reg [4:0] rs2_addr;
    reg [4:0] rs3_addr;
    reg [1:0] fmt;
    reg [FLEN-1:0] write_data;
    wire [FLEN-1:0] rs1_data;
    wire [FLEN-1:0] rs2_data;
    wire [FLEN-1:0] rs3_data;

    fpr #(
        .EXTENSION_F(EXTENSION_F),
        .EXTENSION_D(EXTENSION_D)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .we(we),
        .rd_addr(rd_addr),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rs3_addr(rs3_addr),
        .fmt(fmt),
        .write_data(write_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .rs3_data(rs3_data)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        we = 0;
        rd_addr = 0;
        rs1_addr = 0;
        rs2_addr = 0;
        rs3_addr = 0;
        fmt = 0;
        write_data = 0;

        #15 rst_n = 1;

        @(posedge clk);
        we = 1;
        rd_addr = 5'd1;
        write_data = 32'hDEADBEEF;

        @(posedge clk);
        rd_addr = 5'd2;
        write_data = 32'hCAFEBABE;

        @(posedge clk);
        we = 0;
        rs1_addr = 5'd1;
        rs2_addr = 5'd2;

        @(posedge clk);
        $display("Read RS1 (addr 1): %h", rs1_data);
        $display("Read RS2 (addr 2): %h", rs2_data);

        #20 $finish;
    end
endmodule
