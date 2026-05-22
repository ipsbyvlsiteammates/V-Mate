`timescale 1ns/1ps
module alu #(
    parameter EXTENSION_M = 1
) (
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    input  wire [4:0]  alu_op,
    output wire [31:0] alu_result,
    output wire        zero_flag
);
    localparam logic [4:0] ALU_ADD    = 5'b00000;
    localparam logic [4:0] ALU_SUB    = 5'b00001;
    localparam logic [4:0] ALU_AND    = 5'b00010;
    localparam logic [4:0] ALU_OR     = 5'b00011;
    localparam logic [4:0] ALU_XOR    = 5'b00100;
    localparam logic [4:0] ALU_SLT    = 5'b00101;
    localparam logic [4:0] ALU_SLTU   = 5'b00110;
    localparam logic [4:0] ALU_SLL    = 5'b00111;
    localparam logic [4:0] ALU_SRL    = 5'b01000;
    localparam logic [4:0] ALU_SRA    = 5'b01001;
    localparam logic [4:0] ALU_PASSB  = 5'b01010;
    localparam logic [4:0] ALU_PASS_A = 5'b01011;
    localparam logic [4:0] ALU_MUL    = 5'b10000;
    localparam logic [4:0] ALU_MULH   = 5'b10001;
    localparam logic [4:0] ALU_MULHSU = 5'b10010;
    localparam logic [4:0] ALU_MULHU  = 5'b10011;
    localparam logic [4:0] ALU_DIV    = 5'b10100;
    localparam logic [4:0] ALU_DIVU   = 5'b10101;
    localparam logic [4:0] ALU_REM    = 5'b10110;
    localparam logic [4:0] ALU_REMU   = 5'b10111;

    logic [31:0] alu_result_reg;

    always_comb begin
        case (alu_op)
            ALU_ADD: alu_result_reg = operand_a + operand_b;
            ALU_SUB: alu_result_reg = operand_a - operand_b;
            ALU_AND: alu_result_reg = operand_a & operand_b;
            ALU_OR:  alu_result_reg = operand_a | operand_b;
            ALU_XOR: alu_result_reg = operand_a ^ operand_b;
            ALU_SLT: alu_result_reg = ($signed(operand_a) < $signed(operand_b)) ? 32'd1 : 32'd0;
            ALU_SLTU: alu_result_reg = (operand_a < operand_b) ? 32'd1 : 32'd0;
            ALU_SLL: alu_result_reg = operand_a << operand_b[4:0];
            ALU_SRL: alu_result_reg = operand_a >> operand_b[4:0];
            ALU_SRA: alu_result_reg = $signed(operand_a) >>> operand_b[4:0];
            ALU_PASSB: alu_result_reg = operand_b;
            ALU_PASS_A: alu_result_reg = operand_a;
            ALU_MUL: begin
                if (EXTENSION_M) alu_result_reg = operand_a * operand_b;
                else alu_result_reg = 32'b0;
            end
            ALU_MULH: begin
                if (EXTENSION_M) begin : mulh_blk
                    logic signed [63:0] prod;
                    prod = $signed(operand_a) * $signed(operand_b);
                    alu_result_reg = prod[63:32];
                end else alu_result_reg = 32'b0;
            end
            ALU_MULHSU: begin
                if (EXTENSION_M) begin : mulhsu_blk
                    logic signed [63:0] prod;
                    prod = $signed(operand_a) * $signed({1'b0, operand_b});
                    alu_result_reg = prod[63:32];
                end else alu_result_reg = 32'b0;
            end
            ALU_MULHU: begin
                if (EXTENSION_M) begin : mulhu_blk
                    logic [63:0] prod;
                    prod = {32'b0, operand_a} * {32'b0, operand_b};
                    alu_result_reg = prod[63:32];
                end else alu_result_reg = 32'b0;
            end
            ALU_DIV: begin
                if (EXTENSION_M) begin
                    if (operand_b == 32'b0) alu_result_reg = 32'hFFFFFFFF;
                    else if (operand_a == 32'h80000000 && operand_b == 32'hFFFFFFFF) alu_result_reg = operand_a;
                    else alu_result_reg = $signed(operand_a) / $signed(operand_b);
                end else alu_result_reg = 32'b0;
            end
            ALU_DIVU: begin
                if (EXTENSION_M) begin
                    if (operand_b == 32'b0) alu_result_reg = 32'hFFFFFFFF;
                    else alu_result_reg = operand_a / operand_b;
                end else alu_result_reg = 32'b0;
            end
            ALU_REM: begin
                if (EXTENSION_M) begin
                    if (operand_b == 32'b0) alu_result_reg = operand_a;
                    else if (operand_a == 32'h80000000 && operand_b == 32'hFFFFFFFF) alu_result_reg = 32'b0;
                    else alu_result_reg = $signed(operand_a) % $signed(operand_b);
                end else alu_result_reg = 32'b0;
            end
            ALU_REMU: begin
                if (EXTENSION_M) begin
                    if (operand_b == 32'b0) alu_result_reg = operand_a;
                    else alu_result_reg = operand_a % operand_b;
                end else alu_result_reg = 32'b0;
            end
            default: alu_result_reg = 32'b0;
        endcase
    end
    assign alu_result = alu_result_reg;
    assign zero_flag = (alu_result == 32'b0);
endmodule
