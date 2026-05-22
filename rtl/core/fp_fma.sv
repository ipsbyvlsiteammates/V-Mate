`timescale 1ns/1ps
module fp_fma (
    input  fp_pkg::fp_unpacked_t rs1_unpacked,
    input  fp_pkg::fp_unpacked_t rs2_unpacked,
    input  fp_pkg::fp_unpacked_t rs3_unpacked,
    input  logic [1:0]           fmt,
    input  fp_pkg::roundmode_e   rm,
    input  logic [2:0]           op,
    output logic [63:0]          out,
    output logic [4:0]           fflags
);
    import fp_pkg::*;

    fp_unpacked_t eff_rs1, eff_rs2, eff_rs3;

    always_comb begin
        eff_rs1 = rs1_unpacked;
        if (op == 3'b000 || op == 3'b001) begin
            eff_rs2 = '0;
            eff_rs2.sig = {1'b1, 55'b0};
            eff_rs2.exp = 13'sd0;
            eff_rs2.is_zero = 1'b0;
            eff_rs2.is_inf = 1'b0;
            eff_rs2.is_nan = 1'b0;
            eff_rs2.is_snan = 1'b0;
            eff_rs2.is_qnan = 1'b0;
            eff_rs2.is_subnormal = 1'b0;
            eff_rs2.sign = 1'b0;
            eff_rs3 = rs2_unpacked;
        end else if (op == 3'b010) begin
            eff_rs2 = rs2_unpacked;
            eff_rs3 = '0;
            eff_rs3.is_zero = 1'b1;
            eff_rs3.is_inf = 1'b0;
            eff_rs3.is_nan = 1'b0;
            eff_rs3.is_snan = 1'b0;
            eff_rs3.is_qnan = 1'b0;
            eff_rs3.is_subnormal = 1'b0;
            eff_rs3.exp = 13'sd0;
            eff_rs3.sig = 56'b0;
            eff_rs3.sign = eff_rs1.sign ^ eff_rs2.sign;
        end else begin
            eff_rs2 = rs2_unpacked;
            eff_rs3 = rs3_unpacked;
        end
    end

    logic prod_sign;
    always_comb begin
        prod_sign = eff_rs1.sign ^ eff_rs2.sign;
        if (op == 3'b110 || op == 3'b111) prod_sign = ~prod_sign;
    end

    logic add_sign;
    always_comb begin
        add_sign = eff_rs3.sign;
        if (op == 3'b001 || op == 3'b101 || op == 3'b111) add_sign = ~add_sign;
    end

    logic [111:0] prod_sig;
    assign prod_sig = {56'b0, eff_rs1.sig} * {56'b0, eff_rs2.sig};

    logic signed [13:0] P_exp_ext, A_exp_ext;
    assign P_exp_ext = 14'(signed'(eff_rs1.exp)) + 14'(signed'(eff_rs2.exp));
    assign A_exp_ext = 14'(signed'(eff_rs3.exp));

    logic signed [13:0] exp_diff;
    assign exp_diff = P_exp_ext - A_exp_ext;

    logic [111:0] P_sig_val;
    logic [111:0] A_sig_val;
    assign P_sig_val = (eff_rs1.is_zero || eff_rs2.is_zero) ? 112'b0 : prod_sig;
    assign A_sig_val = eff_rs3.is_zero ? 112'b0 : (112'(eff_rs3.sig) << 55);

    logic [111:0] P_sig_shifted;
    logic [111:0] A_sig_shifted;
    logic P_sticky, A_sticky;
    logic signed [13:0] final_exp;

    logic [6:0] shamt_A, shamt_P;
    assign shamt_A = exp_diff[6:0];
    logic [13:0] neg_exp_diff;
    assign neg_exp_diff = -exp_diff;
    assign shamt_P = neg_exp_diff[6:0];

    always_comb begin
        if (P_sig_val == 0 && A_sig_val == 0) begin
            final_exp = 14'sd0;
            P_sig_shifted = 112'b0;
            P_sticky = 1'b0;
            A_sig_shifted = 112'b0;
            A_sticky = 1'b0;
        end else if (P_sig_val == 0) begin
            final_exp = A_exp_ext;
            A_sig_shifted = A_sig_val;
            A_sticky = 1'b0;
            P_sig_shifted = 112'b0;
            P_sticky = 1'b0;
        end else if (A_sig_val == 0) begin
            final_exp = P_exp_ext;
            P_sig_shifted = P_sig_val;
            P_sticky = 1'b0;
            A_sig_shifted = 112'b0;
            A_sticky = 1'b0;
        end else if (exp_diff > 0) begin
            final_exp = P_exp_ext;
            P_sig_shifted = P_sig_val;
            P_sticky = 1'b0;
            if (exp_diff >= 14'sd112) begin
                A_sig_shifted = 112'b0;
                A_sticky = |A_sig_val;
            end else begin
                A_sig_shifted = A_sig_val >> shamt_A;
                A_sticky = |(A_sig_val & ((112'b1 << shamt_A) - 1'b1));
            end
        end else if (exp_diff < 0) begin
            final_exp = A_exp_ext;
            A_sig_shifted = A_sig_val;
            A_sticky = 1'b0;
            if ((-exp_diff) >= 14'sd112) begin
                P_sig_shifted = 112'b0;
                P_sticky = |P_sig_val;
            end else begin
                P_sig_shifted = P_sig_val >> shamt_P;
                P_sticky = |(P_sig_val & ((112'b1 << shamt_P) - 1'b1));
            end
        end else begin
            final_exp = P_exp_ext;
            P_sig_shifted = P_sig_val;
            P_sticky = 1'b0;
            A_sig_shifted = A_sig_val;
            A_sticky = 1'b0;
        end
    end

    logic [113:0] P_ext, A_ext;
    assign P_ext = {1'b0, P_sig_shifted, P_sticky};
    assign A_ext = {1'b0, A_sig_shifted, A_sticky};

    logic [113:0] sum_ext;
    logic res_sign;
    logic [113:0] abs_sum;

    always_comb begin
        if (prod_sign == add_sign) begin
            sum_ext = P_ext + A_ext;
            res_sign = prod_sign;
            abs_sum = sum_ext;
        end else begin
            if (P_ext > A_ext) begin
                sum_ext = P_ext - A_ext;
                res_sign = prod_sign;
                abs_sum = sum_ext;
            end else if (A_ext > P_ext) begin
                sum_ext = A_ext - P_ext;
                res_sign = add_sign;
                abs_sum = sum_ext;
            end else begin
                sum_ext = '0;
                res_sign = (rm == fp_pkg::RDN) ? 1'b1 : 1'b0;
                abs_sum = '0;
            end
        end
    end

    logic [6:0] lzc;
    always_comb begin
        lzc = 7'd113;
        for (int i = 113; i >= 1; i--) begin
            if (abs_sum[i]) begin
                lzc = 7'd113 - i[6:0];
                break;
            end
        end
        if (abs_sum[113:1] == 0) lzc = 7'd113;
    end

    logic [113:0] norm_sum;
    assign norm_sum = abs_sum << lzc;

    logic signed [13:0] out_exp_ext;
    logic signed [12:0] out_exp;
    logic [55:0] out_sig;

    always_comb begin
        out_exp_ext = final_exp - 14'(signed'({7'b0, lzc})) + 14'sd2;
        out_exp = out_exp_ext[12:0];
        out_sig = {norm_sum[113:59], norm_sum[58] | (|norm_sum[57:0])};
    end

    logic rs1_is_snan, rs2_is_snan, rs3_is_snan;
    logic rs1_is_qnan, rs2_is_qnan, rs3_is_qnan;
    logic rs1_is_inf, rs2_is_inf, rs3_is_inf;
    logic rs1_is_zero, rs2_is_zero, rs3_is_zero;

    assign rs1_is_snan = eff_rs1.is_snan;
    assign rs2_is_snan = eff_rs2.is_snan;
    assign rs3_is_snan = eff_rs3.is_snan;

    assign rs1_is_qnan = eff_rs1.is_qnan;
    assign rs2_is_qnan = eff_rs2.is_qnan;
    assign rs3_is_qnan = eff_rs3.is_qnan;

    assign rs1_is_inf = eff_rs1.is_inf;
    assign rs2_is_inf = eff_rs2.is_inf;
    assign rs3_is_inf = eff_rs3.is_inf;

    assign rs1_is_zero = eff_rs1.is_zero;
    assign rs2_is_zero = eff_rs2.is_zero;
    assign rs3_is_zero = eff_rs3.is_zero;

    logic any_snan;
    assign any_snan = rs1_is_snan | rs2_is_snan | rs3_is_snan;

    logic any_qnan;
    assign any_qnan = rs1_is_qnan | rs2_is_qnan | rs3_is_qnan;

    logic inf_mul_zero;
    assign inf_mul_zero = (rs1_is_inf & rs2_is_zero) | (rs1_is_zero & rs2_is_inf);

    logic prod_is_inf;
    assign prod_is_inf = rs1_is_inf | rs2_is_inf;

    logic inf_add_opp;
    assign inf_add_opp = prod_is_inf & rs3_is_inf & (prod_sign != add_sign);

    logic nv, dz;
    assign nv = any_snan | inf_mul_zero | inf_add_opp;
    assign dz = 1'b0;

    logic is_nan_res;
    assign is_nan_res = any_snan | any_qnan | inf_mul_zero | inf_add_opp;

    logic is_inf_res;
    assign is_inf_res = prod_is_inf | rs3_is_inf;

    logic final_sign;
    always_comb begin
        if (is_nan_res) begin
            final_sign = 1'b0;
        end else if (prod_is_inf && rs3_is_inf) begin
            final_sign = prod_sign;
        end else if (prod_is_inf) begin
            final_sign = prod_sign;
        end else if (rs3_is_inf) begin
            final_sign = add_sign;
        end else begin
            final_sign = res_sign;
        end
    end

    logic [63:0] rp_out;
    logic [4:0] rp_fflags;

    fp_round_pack u_round_pack (
        .sign(final_sign),
        .exp(out_exp),
        .sig(out_sig),
        .fmt(fmt),
        .rm(rm),
        .nv(nv),
        .dz(dz),
        .out(rp_out),
        .fflags(rp_fflags)
    );

    always_comb begin
        if (is_nan_res) begin
            out = (fmt == 2'b00) ? 64'hFFFFFFFF_7FC00000 : 64'h7FF8000000000000;
            fflags = {nv, 4'b0000};
        end else if (is_inf_res) begin
            out = (fmt == 2'b00) ? {32'hFFFFFFFF, final_sign, 8'hFF, 23'b0} : {final_sign, 11'h7FF, 52'b0};
            fflags = 5'b00000;
        end else begin
            out = rp_out;
            fflags = rp_fflags;
        end
    end

endmodule