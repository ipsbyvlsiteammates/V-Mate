`timescale 1ns/1ps
module pc (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        pc_sel,
    input  wire [31:0] pc_target,
    input  wire        exception,
    input  wire [31:0] mtvec,
    input  wire        mret_exec,
    input  wire [31:0] mepc,
    output reg  [31:0] pc_out
);

    localparam logic [31:0] RESET_VECTOR = 32'h8000_0000;
    localparam logic [31:0] PC_INCREMENT = 32'd4;

    always @(posedge clk) begin
        if (!rst_n) begin
            pc_out <= RESET_VECTOR;
        end else begin
            if (exception) begin
                pc_out <= mtvec;
            end else if (mret_exec) begin
                pc_out <= mepc;
            end else if (pc_sel) begin
                pc_out <= pc_target;
            end else begin
                pc_out <= pc_out + PC_INCREMENT;
            end
        end
    end
endmodule
