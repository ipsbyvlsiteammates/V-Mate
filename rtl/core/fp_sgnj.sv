`timescale 1ns/1ps
module fp_sgnj (
    input  logic [63:0] rs1_raw,
    input  logic [63:0] rs2_raw,
    input  logic [1:0]  fmt,
    input  logic [2:0]  rm,
    output logic [63:0] out
);
    logic is_fp32;
    assign is_fp32 = (fmt == 2'b00);

    logic rs1_is_boxed, rs2_is_boxed;
    assign rs1_is_boxed = (rs1_raw[63:32] == 32'hFFFFFFFF);
    assign rs2_is_boxed = (rs2_raw[63:32] == 32'hFFFFFFFF);

    logic [63:0] eff_rs1, eff_rs2;
    assign eff_rs1 = (is_fp32 && !rs1_is_boxed) ? 64'hFFFFFFFF_7FC00000 : rs1_raw;
    assign eff_rs2 = (is_fp32 && !rs2_is_boxed) ? 64'hFFFFFFFF_7FC00000 : rs2_raw;

    logic sign1, sign2, out_sign;
    assign sign1 = is_fp32 ? eff_rs1[31] : eff_rs1[63];
    assign sign2 = is_fp32 ? eff_rs2[31] : eff_rs2[63];

    always_comb begin
        case (rm)
            3'b000: out_sign = sign2;          // FSGNJ
            3'b001: out_sign = ~sign2;         // FSGNJN
            3'b010: out_sign = sign1 ^ sign2;  // FSGNJX
            default: out_sign = sign1;
        endcase
    end

    always_comb begin
        if (is_fp32) begin
            out = {32'hFFFFFFFF, out_sign, eff_rs1[30:0]};
        end else begin
            out = {out_sign, eff_rs1[62:0]};
        end
    end
endmodule