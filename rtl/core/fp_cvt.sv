`timescale 1ns/1ps
module fp_cvt (
    input  fp_pkg::fp_unpacked_t rs1_unpacked,
    input  logic [63:0]          rs1_raw,
    input  logic [31:0]          int_data,
    input  logic [1:0]           fmt,
    input  logic [4:0]           rs2_addr,
    input  fp_pkg::roundmode_e   rm,
    input  logic                 int_to_fp,
    input  logic                 fp_to_int,
    output logic [63:0]          out,
    output logic [4:0]           fflags
);
    import fp_pkg::*;

    // Int to Float logic
    logic is_unsigned;
    assign is_unsigned = rs2_addr[0];

    logic int_sign;
    assign int_sign = !is_unsigned && int_data[31];

    logic [31:0] abs_int;
    assign abs_int = int_sign ? -int_data : int_data;

    // Inputs to fp_round_pack
    logic        rp_sign;
    logic [12:0] rp_exp;
    logic [55:0] rp_sig;
    logic [1:0]  rp_fmt;
    logic        rp_nv;
    logic        rp_dz;

    always_comb begin
        if (int_to_fp) begin
            rp_sign = int_sign;
            rp_exp  = 13'd55;
            rp_sig  = {24'b0, abs_int};
            rp_fmt  = fmt;
            rp_nv   = 1'b0;
            rp_dz   = 1'b0;
        end else begin // Float to Float
            rp_sign = rs1_unpacked.sign;
            rp_exp  = rs1_unpacked.exp;
            rp_sig  = rs1_unpacked.sig;
            rp_fmt  = fmt;
            rp_nv   = rs1_unpacked.is_snan;
            rp_dz   = 1'b0;
        end
    end

    logic [63:0] rp_out;
    logic [4:0]  rp_fflags;

    fp_round_pack u_fp_round_pack (
        .sign(rp_sign),
        .exp(rp_exp),
        .sig(rp_sig),
        .fmt(rp_fmt),
        .rm(rm),
        .nv(rp_nv),
        .dz(rp_dz),
        .out(rp_out),
        .fflags(rp_fflags)
    );

    // Float to Int logic
    logic signed [13:0] shift;
    assign shift = 14'sd55 - 14'(signed'(rs1_unpacked.exp));

    logic [55:0] shifted_sig;
    logic        sticky;
    logic        round_bit;
    logic        guard_bit;

    always_comb begin
        if (shift <= 0) begin
            shifted_sig = rs1_unpacked.sig << (-shift);
            sticky = 1'b0;
            round_bit = 1'b0;
            guard_bit = 1'b0;
        end else if (shift < 56) begin
            shifted_sig = rs1_unpacked.sig >> shift;
            round_bit = rs1_unpacked.sig[shift - 1];
            guard_bit = shifted_sig[0];
            sticky = (rs1_unpacked.sig << (57 - shift)) != 0;
        end else if (shift == 56) begin
            shifted_sig = '0;
            round_bit = rs1_unpacked.sig[55];
            guard_bit = 1'b0;
            sticky = (rs1_unpacked.sig[54:0] != 0);
        end else begin
            shifted_sig = '0;
            round_bit = 1'b0;
            guard_bit = 1'b0;
            sticky = (rs1_unpacked.sig != 0);
        end
    end

    logic inexact;
    assign inexact = round_bit | sticky;

    logic round_up;
    always_comb begin
        round_up = 1'b0;
        case (rm)
            RNE: round_up = round_bit & (sticky | guard_bit);
            RTZ: round_up = 1'b0;
            RDN: round_up = rs1_unpacked.sign & inexact;
            RUP: round_up = ~rs1_unpacked.sign & inexact;
            RMM: round_up = round_bit;
            default: round_up = 1'b0;
        endcase
    end

    logic [56:0] int_val_mag_ext;
    assign int_val_mag_ext = shifted_sig + round_up;

    logic [31:0] int_val_mag;
    assign int_val_mag = int_val_mag_ext[31:0];

    logic [31:0] int_val;
    assign int_val = rs1_unpacked.sign ? -int_val_mag : int_val_mag;

    // Overflow detection
    logic f2i_nv;
    logic [31:0] final_int;

    always_comb begin
        f2i_nv = 1'b0;
        final_int = int_val;

        if (rs1_unpacked.is_nan) begin
            f2i_nv = 1'b1;
            final_int = is_unsigned ? 32'hFFFFFFFF : 32'h7FFFFFFF;
        end else if (rs1_unpacked.is_inf) begin
            f2i_nv = 1'b1;
            if (is_unsigned) begin
                final_int = rs1_unpacked.sign ? 32'h00000000 : 32'hFFFFFFFF;
            end else begin
                final_int = rs1_unpacked.sign ? 32'h80000000 : 32'h7FFFFFFF;
            end
        end else begin
            // Check range
            if (is_unsigned) begin
                if (rs1_unpacked.sign) begin
                    if (int_val_mag_ext != 0 || shift <= 23) begin
                        f2i_nv = 1'b1;
                        final_int = 32'h00000000;
                    end
                end else if (shift <= 23) begin
                    f2i_nv = 1'b1;
                    final_int = 32'hFFFFFFFF;
                end else if (int_val_mag_ext > 57'hFFFFFFFF) begin
                    f2i_nv = 1'b1;
                    final_int = 32'hFFFFFFFF;
                end
            end else begin
                if (rs1_unpacked.sign) begin
                    if (shift <= 23) begin
                        f2i_nv = 1'b1;
                        final_int = 32'h80000000;
                    end else if (int_val_mag_ext > 57'h80000000) begin
                        f2i_nv = 1'b1;
                        final_int = 32'h80000000;
                    end
                end else begin
                    if (shift <= 23) begin
                        f2i_nv = 1'b1;
                        final_int = 32'h7FFFFFFF;
                    end else if (int_val_mag_ext > 57'h7FFFFFFF) begin
                        f2i_nv = 1'b1;
                        final_int = 32'h7FFFFFFF;
                    end
                end
            end
        end
    end

    logic [4:0] f2i_fflags;
    assign f2i_fflags = {f2i_nv, 3'b000, inexact & ~f2i_nv};

    // Output Mux
    always_comb begin
        if (fp_to_int) begin
            out = {32'b0, final_int};
            fflags = f2i_fflags;
        end else if (!int_to_fp && rs1_unpacked.is_nan) begin
            out = (fmt == 2'b00) ? 64'hFFFFFFFF_7FC00000 : 64'h7FF8000000000000;
            fflags = {rs1_unpacked.is_snan, 4'b0000};
        end else if (!int_to_fp && rs1_unpacked.is_inf) begin
            out = (fmt == 2'b00) ? {32'hFFFFFFFF, rs1_unpacked.sign, 8'hFF, 23'b0} : {rs1_unpacked.sign, 11'h7FF, 52'b0};
            fflags = 5'b00000;
        end else begin
            out = rp_out;
            fflags = rp_fflags;
        end
    end

endmodule