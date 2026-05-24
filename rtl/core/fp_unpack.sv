`timescale 1ns/1ps
module fp_unpack (
    input  logic [63:0] in,
    input  logic [1:0]  fmt,
    output fp_pkg::fp_unpacked_t out
);
    import fp_pkg::*;

    logic is_fp32;
    assign is_fp32 = (fmt == 2'b00);

    logic is_boxed;
    assign is_boxed = (in[63:32] == 32'hFFFFFFFF);

    logic [63:0] eff_in;
    assign eff_in = (is_fp32 && !is_boxed) ? 64'hFFFFFFFF_7FC00000 : in;

    logic sign;
    logic [10:0] exp_raw;
    logic [51:0] frac_raw;

    always_comb begin
        if (is_fp32) begin
            sign     = eff_in[31];
            exp_raw  = {3'b0, eff_in[30:23]};
            frac_raw = {eff_in[22:0], 29'b0};
        end else begin
            sign     = eff_in[63];
            exp_raw  = eff_in[62:52];
            frac_raw = eff_in[51:0];
        end
    end

    logic exp_zero, exp_max, frac_zero;
    assign exp_zero  = (is_fp32) ? (exp_raw[7:0] == 8'h00) : (exp_raw == 11'h000);
    assign exp_max   = (is_fp32) ? (exp_raw[7:0] == 8'hFF) : (exp_raw == 11'h7FF);
    assign frac_zero = (frac_raw == 52'b0);

    always_comb begin
        out.sign = sign;
        out.is_zero = exp_zero && frac_zero;
        out.is_inf  = exp_max && frac_zero;
        out.is_nan  = exp_max && !frac_zero;
        out.is_subnormal = exp_zero && !frac_zero;
        
        out.is_qnan = out.is_nan && frac_raw[51];
        out.is_snan = out.is_nan && !frac_raw[51];

        if (out.is_zero) begin
            out.exp = 13'sd0;
            out.sig = 56'b0;
        end else if (out.is_subnormal) begin
            out.exp = is_fp32 ? 13'sd1 - 13'sd127 : 13'sd1 - 13'sd1023;
            out.sig = is_fp32 ? {1'b0, frac_raw[51:29], 32'b0} : {1'b0, frac_raw, 3'b0};
        end else if (out.is_inf || out.is_nan) begin
            out.exp = 13'sd0;
            out.sig = is_fp32 ? {1'b1, frac_raw[51:29], 32'b0} : {1'b1, frac_raw, 3'b0};
        end else begin
            out.exp = is_fp32 ? signed'({2'b0, exp_raw}) - 13'sd127 : signed'({2'b0, exp_raw}) - 13'sd1023;
            out.sig = is_fp32 ? {1'b1, frac_raw[51:29], 32'b0} : {1'b1, frac_raw, 3'b0};
        end
    end
endmodule