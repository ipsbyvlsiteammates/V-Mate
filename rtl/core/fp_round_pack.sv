`timescale 1ns/1ps
module fp_round_pack (
    input  logic        sign,
    input  logic signed [12:0] exp,
    input  logic [55:0] sig,
    input  logic [1:0]  fmt,
    input  fp_pkg::roundmode_e rm,
    input  logic        nv,
    input  logic        dz,
    output logic [63:0] out,
    output logic [4:0]  fflags
);
    import fp_pkg::*;

    logic is_fp32;
    assign is_fp32 = (fmt == 2'b00);

    logic [5:0] lzc;
    always_comb begin
        lzc = 6'd0;
        for (int i = 55; i >= 0; i--) begin
            if (sig[i]) begin
                lzc = 6'd55 - i[5:0];
                break;
            end
        end
        if (sig == 0) lzc = 6'd0;
    end

    logic [55:0] norm_sig;
    logic signed [12:0] norm_exp;
    
    always_comb begin
        if (sig[55]) begin
            norm_sig = sig;
            norm_exp = exp;
        end else begin
            norm_sig = sig << lzc;
            norm_exp = exp - signed'({7'b0, lzc});
        end
    end

    logic signed [13:0] unbounded_exp;
    always_comb begin
        if (is_fp32) begin
            unbounded_exp = 14'(norm_exp) + 14'sd127;
        end else begin
            unbounded_exp = 14'(norm_exp) + 14'sd1023;
        end
    end

    logic [55:0] denorm_sig;
    logic signed [12:0] denorm_exp;
    logic denorm_sticky;
    logic is_tiny;

    always_comb begin
        if (sig == 0) begin
            denorm_sig = '0;
            denorm_exp = '0;
            denorm_sticky = 1'b0;
            is_tiny = 1'b0;
        end else if (unbounded_exp <= 0) begin
            logic signed [13:0] shift_amt_signed;
            logic [5:0] shift_amt;
            shift_amt_signed = 14'sd1 - unbounded_exp;
            shift_amt = (shift_amt_signed > 14'sd63) ? 6'd63 : shift_amt_signed[5:0];
            
            denorm_sig = norm_sig >> shift_amt;
            denorm_sticky = |(norm_sig & 56'((64'd1 << shift_amt) - 1));
            denorm_exp = is_fp32 ? -13'sd127 : -13'sd1023;
            is_tiny = 1'b1;
        end else begin
            denorm_sig = norm_sig;
            denorm_exp = norm_exp;
            denorm_sticky = 1'b0;
            is_tiny = 1'b0;
        end
    end

    logic guard, round, sticky;
    logic [52:0] frac_to_round;
    
    always_comb begin
        if (is_fp32) begin
            frac_to_round = {29'b0, denorm_sig[55:32]};
            guard = denorm_sig[31];
            round = denorm_sig[30];
            sticky = |denorm_sig[29:0] | denorm_sticky;
        end else begin
            frac_to_round = denorm_sig[55:3];
            guard = denorm_sig[2];
            round = denorm_sig[1];
            sticky = denorm_sig[0] | denorm_sticky;
        end
    end

    logic round_up;
    always_comb begin
        round_up = 1'b0;
        case (rm)
            RNE: round_up = guard && (round || sticky || frac_to_round[0]);
            RTZ: round_up = 1'b0;
            RDN: round_up = sign && (guard || round || sticky);
            RUP: round_up = !sign && (guard || round || sticky);
            RMM: round_up = guard;
            default: round_up = 1'b0;
        endcase
    end

    logic [53:0] rounded_frac;
    assign rounded_frac = frac_to_round + round_up;

    logic unbounded_guard, unbounded_round, unbounded_sticky;
    logic unbounded_round_up;
    logic unbounded_tiny;
    
    always_comb begin
        if (is_fp32) begin
            unbounded_guard = norm_sig[31];
            unbounded_round = norm_sig[30];
            unbounded_sticky = |norm_sig[29:0];
        end else begin
            unbounded_guard = norm_sig[2];
            unbounded_round = norm_sig[1];
            unbounded_sticky = norm_sig[0];
        end
        
        unbounded_round_up = 1'b0;
        case (rm)
            RNE: unbounded_round_up = unbounded_guard && (unbounded_round || unbounded_sticky || norm_sig[is_fp32 ? 32 : 3]);
            RTZ: unbounded_round_up = 1'b0;
            RDN: unbounded_round_up = sign && (unbounded_guard || unbounded_round || unbounded_sticky);
            RUP: unbounded_round_up = !sign && (unbounded_guard || unbounded_round || unbounded_sticky);
            RMM: unbounded_round_up = unbounded_guard;
            default: unbounded_round_up = 1'b0;
        endcase
        
        if (sig == 0) begin
            unbounded_tiny = 1'b0;
        end else if (unbounded_exp < 0) begin
            unbounded_tiny = 1'b1;
        end else if (unbounded_exp == 0) begin
            if (is_fp32) begin
                unbounded_tiny = !((norm_sig[54:32] == 23'h7FFFFF) && unbounded_round_up);
            end else begin
                unbounded_tiny = !((norm_sig[54:3] == 52'hFFFFFFFFFFFFF) && unbounded_round_up);
            end
        end else begin
            unbounded_tiny = 1'b0;
        end
    end

    logic signed [12:0] final_exp;
    logic [52:0] final_sig;
    
    always_comb begin
        if (is_fp32) begin
            if (rounded_frac[24]) begin
                final_exp = denorm_exp + 1;
                final_sig = rounded_frac >> 1;
            end else begin
                final_exp = denorm_exp;
                final_sig = rounded_frac;
            end
        end else begin
            if (rounded_frac[53]) begin
                final_exp = denorm_exp + 1;
                final_sig = rounded_frac >> 1;
            end else begin
                final_exp = denorm_exp;
                final_sig = rounded_frac;
            end
        end
    end

    logic of, uf, nx;
    logic [10:0] out_exp;
    logic [51:0] out_frac;
    
    always_comb begin
        of = 1'b0;
        uf = 1'b0;
        nx = guard | round | sticky;
        out_exp = '0;
        out_frac = '0;

        if (sig == 0) begin
            out_exp = '0;
            out_frac = '0;
        end else if (is_fp32) begin
            logic signed [13:0] biased_exp;
            biased_exp = 14'(final_exp) + 14'sd127;
            
            if (biased_exp >= 255) begin
                of = 1'b1;
                nx = 1'b1;
                if ((rm == RNE) || (rm == RMM) || (rm == RUP && !sign) || (rm == RDN && sign)) begin
                    out_exp = 8'hFF;
                    out_frac = '0;
                end else begin
                    out_exp = 8'hFE;
                    out_frac = {23{1'b1}};
                end
            end else if (biased_exp <= 0) begin
                if (final_sig[23]) begin
                    uf = unbounded_tiny & nx;
                    out_exp = 8'h01;
                    out_frac = final_sig[22:0];
                end else begin
                    uf = unbounded_tiny & nx;
                    out_exp = 8'h00;
                    out_frac = final_sig[22:0];
                end
            end else begin
                out_exp = biased_exp[10:0];
                out_frac = {29'b0, final_sig[22:0]};
            end
        end else begin
            logic signed [13:0] biased_exp;
            biased_exp = 14'(final_exp) + 14'sd1023;
            
            if (biased_exp >= 2047) begin
                of = 1'b1;
                nx = 1'b1;
                if ((rm == RNE) || (rm == RMM) || (rm == RUP && !sign) || (rm == RDN && sign)) begin
                    out_exp = 11'h7FF;
                    out_frac = '0;
                end else begin
                    out_exp = 11'h7FE;
                    out_frac = {52{1'b1}};
                end
            end else if (biased_exp <= 0) begin
                if (final_sig[52]) begin
                    uf = unbounded_tiny & nx;
                    out_exp = 11'h001;
                    out_frac = final_sig[51:0];
                end else begin
                    uf = unbounded_tiny & nx;
                    out_exp = 11'h000;
                    out_frac = final_sig[51:0];
                end
            end else begin
                out_exp = biased_exp[10:0];
                out_frac = final_sig[51:0];
            end
        end
    end

    always_comb begin
        if (is_fp32) begin
            out = {32'hFFFFFFFF, sign, out_exp[7:0], out_frac[22:0]};
        end else begin
            out = {sign, out_exp[10:0], out_frac[51:0]};
        end
        fflags = {nv, dz, of, uf, nx};
    end
endmodule
