`timescale 1ns/1ps
module fp_divsqrt (
    input  fp_pkg::fp_unpacked_t rs1_unpacked,
    input  fp_pkg::fp_unpacked_t rs2_unpacked,
    input  logic [1:0]           fmt,
    input  fp_pkg::roundmode_e   rm,
    input  logic                 is_sqrt,
    output logic [63:0]          out,
    output logic [4:0]           fflags
);
    import fp_pkg::*;

    logic is_fp32;
    assign is_fp32 = (fmt == 2'b00);

    // ==========================================
    // Division Logic
    // ==========================================
    logic [5:0] rs1_div_lzc;
    always_comb begin
        rs1_div_lzc = 6'd56;
        for (int i = 55; i >= 0; i--) begin
            if (rs1_unpacked.sig[i]) begin
                rs1_div_lzc = 6'd55 - i[5:0];
                break;
            end
        end
        if (rs1_unpacked.sig == 0) rs1_div_lzc = 6'd56;
    end

    logic [5:0] rs2_div_lzc;
    always_comb begin
        rs2_div_lzc = 6'd56;
        for (int i = 55; i >= 0; i--) begin
            if (rs2_unpacked.sig[i]) begin
                rs2_div_lzc = 6'd55 - i[5:0];
                break;
            end
        end
        if (rs2_unpacked.sig == 0) rs2_div_lzc = 6'd56;
    end

    logic [55:0] rs1_sig_norm_div;
    logic signed [12:0] rs1_exp_norm_div;
    assign rs1_sig_norm_div = rs1_unpacked.sig << rs1_div_lzc;
    assign rs1_exp_norm_div = rs1_unpacked.exp - signed'({7'b0, rs1_div_lzc});

    logic [55:0] rs2_sig_norm_div;
    logic signed [12:0] rs2_exp_norm_div;
    assign rs2_sig_norm_div = rs2_unpacked.sig << rs2_div_lzc;
    assign rs2_exp_norm_div = rs2_unpacked.exp - signed'({7'b0, rs2_div_lzc});

    logic div_sign;
    logic signed [12:0] div_exp;
    logic [112:0] div_sig_full;
    logic [55:0] div_rem;
    
    assign div_sign = rs1_unpacked.sign ^ rs2_unpacked.sign;
    assign div_exp  = rs1_exp_norm_div - rs2_exp_norm_div;
    
    logic [55:0] safe_rs2_sig_norm_div;
    assign safe_rs2_sig_norm_div = (rs2_sig_norm_div != 0) ? rs2_sig_norm_div : 56'd1;
    
    always_comb begin
        if (rs2_sig_norm_div != 0) begin
            div_sig_full = {1'b0, rs1_sig_norm_div, 56'b0} / safe_rs2_sig_norm_div;
            div_rem      = 56'({1'b0, rs1_sig_norm_div, 56'b0} % safe_rs2_sig_norm_div);
        end else begin
            div_sig_full = '0;
            div_rem      = '0;
        end
    end
    
    logic [6:0] div_lzc;
    always_comb begin
        div_lzc = 7'd113;
        for (int i = 112; i >= 0; i--) begin
            if (div_sig_full[i]) begin
                div_lzc = 7'd112 - i[6:0];
                break;
            end
        end
        if (div_sig_full == 0) div_lzc = 7'd113;
    end
    
    logic [6:0] msb_pos;
    assign msb_pos = 7'd112 - div_lzc;
    
    logic [55:0] div_sig;
    logic signed [12:0] div_exp_norm;
    logic [6:0] shift_right_amt;
    logic sticky_div;
    logic [112:0] div_discarded_mask;
    
    assign shift_right_amt = msb_pos - 7'd55;
    
    always_comb begin
        div_discarded_mask = '0;
        sticky_div = 1'b0;
        if (div_sig_full == 0) begin
            div_sig = '0;
            div_exp_norm = div_exp;
        end else if (msb_pos >= 7'd55) begin
            div_discarded_mask = (113'd1 << shift_right_amt) - 113'd1;
            sticky_div = |(div_sig_full & div_discarded_mask) | (div_rem != 0);
            div_sig = 56'(div_sig_full >> shift_right_amt) | {55'b0, sticky_div};
            div_exp_norm = div_exp - 13'sd56 + signed'({6'b0, msb_pos});
        end else begin
            div_sig = 56'(div_sig_full << (7'd55 - msb_pos)) | {55'b0, (div_rem != 0)};
            div_exp_norm = div_exp - 13'sd56 + signed'({6'b0, msb_pos});
        end
    end

    logic div_nv, div_dz;
    logic div_is_nan, div_is_inf, div_is_zero;
    
    always_comb begin
        div_nv = 1'b0;
        div_dz = 1'b0;
        div_is_nan = 1'b0;
        div_is_inf = 1'b0;
        div_is_zero = 1'b0;
        
        if (rs1_unpacked.is_snan || rs2_unpacked.is_snan) begin
            div_nv = 1'b1;
            div_is_nan = 1'b1;
        end else if (rs1_unpacked.is_nan || rs2_unpacked.is_nan) begin
            div_is_nan = 1'b1;
        end else if (rs1_unpacked.is_inf && rs2_unpacked.is_inf) begin
            div_nv = 1'b1;
            div_is_nan = 1'b1;
        end else if (rs1_unpacked.is_zero && rs2_unpacked.is_zero) begin
            div_nv = 1'b1;
            div_is_nan = 1'b1;
        end else if (rs1_unpacked.is_inf) begin
            div_is_inf = 1'b1;
        end else if (rs2_unpacked.is_inf) begin
            div_is_zero = 1'b1;
        end else if (rs2_unpacked.is_zero) begin
            div_dz = 1'b1;
            div_is_inf = 1'b1;
        end else if (rs1_unpacked.is_zero) begin
            div_is_zero = 1'b1;
        end
    end

    // ==========================================
    // Square Root Logic
    // ==========================================
    logic [5:0] rs1_lzc;
    always_comb begin
        rs1_lzc = 6'd56;
        for (int i = 55; i >= 0; i--) begin
            if (rs1_unpacked.sig[i]) begin
                rs1_lzc = 6'd55 - i[5:0];
                break;
            end
        end
        if (rs1_unpacked.sig == 0) rs1_lzc = 6'd56;
    end
    
    logic [55:0] rs1_sig_norm;
    logic signed [12:0] rs1_exp_norm;
    
    assign rs1_sig_norm = rs1_unpacked.sig << rs1_lzc;
    assign rs1_exp_norm = rs1_unpacked.exp - signed'({7'b0, rs1_lzc});
    
    logic [56:0] sqrt_radix;
    logic signed [12:0] sqrt_exp_even;
    
    always_comb begin
        if (rs1_exp_norm[0]) begin
            sqrt_radix = {rs1_sig_norm, 1'b0};
            sqrt_exp_even = rs1_exp_norm - 13'sd1;
        end else begin
            sqrt_radix = {1'b0, rs1_sig_norm};
            sqrt_exp_even = rs1_exp_norm;
        end
    end
    
    logic [113:0] sqrt_radix_padded;
    assign sqrt_radix_padded = {sqrt_radix, 57'b0}; 
    
    logic [56:0] sqrt_q;
    logic [58:0] sqrt_rem;
    logic [58:0] sqrt_rem_next;
    logic [58:0] sqrt_sub;
    
    always_comb begin
        sqrt_q = '0;
        sqrt_rem = '0;
        for (int i = 56; i >= 0; i--) begin
            sqrt_rem_next = {sqrt_rem[56:0], sqrt_radix_padded[i*2 +: 2]};
            sqrt_sub = {sqrt_q, 2'b01};
            if (sqrt_rem_next >= sqrt_sub) begin
                sqrt_rem = sqrt_rem_next - sqrt_sub;
                sqrt_q = {sqrt_q[55:0], 1'b1};
            end else begin
                sqrt_rem = sqrt_rem_next;
                sqrt_q = {sqrt_q[55:0], 1'b0};
            end
        end
    end
    
    logic sqrt_sticky;
    logic [55:0] sqrt_sig_final;
    
    always_comb begin
        sqrt_sticky = sqrt_q[0] | (sqrt_rem != 0);
        sqrt_sig_final = {sqrt_q[56:2], sqrt_q[1] | sqrt_sticky};
    end

    logic sqrt_nv, sqrt_dz;
    logic sqrt_is_nan, sqrt_is_inf, sqrt_is_zero;
    
    always_comb begin
        sqrt_nv = 1'b0;
        sqrt_dz = 1'b0;
        sqrt_is_nan = 1'b0;
        sqrt_is_inf = 1'b0;
        sqrt_is_zero = 1'b0;
        
        if (rs1_unpacked.is_snan) begin
            sqrt_nv = 1'b1;
            sqrt_is_nan = 1'b1;
        end else if (rs1_unpacked.is_nan) begin
            sqrt_is_nan = 1'b1;
        end else if (rs1_unpacked.sign && !rs1_unpacked.is_zero && !rs1_unpacked.is_nan) begin
            sqrt_nv = 1'b1;
            sqrt_is_nan = 1'b1;
        end else if (rs1_unpacked.is_inf) begin
            sqrt_is_inf = 1'b1;
        end else if (rs1_unpacked.is_zero) begin
            sqrt_is_zero = 1'b1;
        end
    end

    // ==========================================
    // Result Multiplexing
    // ==========================================
    logic final_sign;
    logic signed [12:0] final_exp;
    logic [55:0] final_sig;
    logic final_nv;
    logic final_dz;
    
    logic is_nan_res;
    logic is_inf_res;
    logic is_zero_res;
    
    always_comb begin
        if (is_sqrt) begin
            final_sign = rs1_unpacked.sign;
            final_nv   = sqrt_nv;
            final_dz   = sqrt_dz;
            is_nan_res = sqrt_is_nan;
            is_inf_res = sqrt_is_inf;
            is_zero_res = sqrt_is_zero;
            
            final_exp  = sqrt_exp_even >>> 1;
            final_sig  = sqrt_sig_final;
        end else begin
            final_sign = div_sign;
            final_nv   = div_nv;
            final_dz   = div_dz;
            is_nan_res = div_is_nan;
            is_inf_res = div_is_inf;
            is_zero_res = div_is_zero;
            
            final_exp  = div_exp_norm;
            final_sig  = div_sig;
        end
    end

    // ==========================================
    // Rounding and Packing
    // ==========================================
    logic [63:0] rp_out;
    logic [4:0]  rp_fflags;
    
    fp_round_pack u_round_pack (
        .sign(final_sign),
        .exp(final_exp),
        .sig(final_sig),
        .fmt(fmt),
        .rm(rm),
        .nv(final_nv),
        .dz(final_dz),
        .out(rp_out),
        .fflags(rp_fflags)
    );

    // ==========================================
    // Special Cases Bypass
    // ==========================================
    logic [63:0] special_out;
    logic [4:0]  special_fflags;
    
    always_comb begin
        special_fflags = {final_nv, final_dz, 3'b000};
        if (is_nan_res) begin
            if (is_fp32)
                special_out = {32'hFFFFFFFF, 1'b0, 8'hFF, 1'b1, 22'b0};
            else
                special_out = {1'b0, 11'h7FF, 1'b1, 51'b0};
        end else if (is_inf_res) begin
            if (is_fp32)
                special_out = {32'hFFFFFFFF, final_sign, 8'hFF, 23'b0};
            else
                special_out = {final_sign, 11'h7FF, 52'b0};
        end else if (is_zero_res) begin
            if (is_fp32)
                special_out = {32'hFFFFFFFF, final_sign, 8'h00, 23'b0};
            else
                special_out = {final_sign, 11'h000, 52'b0};
        end else begin
            special_out = rp_out;
            special_fflags = rp_fflags;
        end
    end
    
    assign out = (is_nan_res || is_inf_res || is_zero_res) ? special_out : rp_out;
    assign fflags = (is_nan_res || is_inf_res || is_zero_res) ? special_fflags : rp_fflags;

endmodule