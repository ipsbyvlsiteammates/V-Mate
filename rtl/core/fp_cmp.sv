`timescale 1ns/1ps
module fp_cmp (
    input  logic [63:0] rs1_raw,
    input  logic [63:0] rs2_raw,
    input  fp_pkg::fp_unpacked_t rs1_unpacked,
    input  fp_pkg::fp_unpacked_t rs2_unpacked,
    input  logic [1:0]  fmt,
    input  logic [2:0]  rm,
    input  logic        is_min_max,
    output logic [63:0] out,
    output logic [4:0]  fflags
);
    import fp_pkg::*;

    logic is_fp32;
    assign is_fp32 = (fmt == 2'b00);

    localparam logic [31:0] CANONICAL_NAN_FP32 = 32'h7FC00000;
    localparam logic [63:0] CANONICAL_NAN_FP64 = 64'h7FF8000000000000;

    logic rs1_is_nan, rs2_is_nan;
    logic rs1_is_snan, rs2_is_snan;
    logic rs1_is_zero, rs2_is_zero;
    logic rs1_sign, rs2_sign;

    assign rs1_is_nan = rs1_unpacked.is_nan;
    assign rs2_is_nan = rs2_unpacked.is_nan;
    assign rs1_is_snan = rs1_unpacked.is_snan;
    assign rs2_is_snan = rs2_unpacked.is_snan;
    assign rs1_is_zero = rs1_unpacked.is_zero;
    assign rs2_is_zero = rs2_unpacked.is_zero;
    assign rs1_sign = rs1_unpacked.sign;
    assign rs2_sign = rs2_unpacked.sign;

    logic eq, lt;
    
    logic mag_lt;
    logic [62:0] mag1, mag2;
    assign mag1 = is_fp32 ? {31'b0, rs1_raw[30:0]} : rs1_raw[62:0];
    assign mag2 = is_fp32 ? {31'b0, rs2_raw[30:0]} : rs2_raw[62:0];
    
    assign mag_lt = (mag1 < mag2);
    logic mag_eq;
    assign mag_eq = (mag1 == mag2);

    always_comb begin
        if (rs1_is_nan || rs2_is_nan) begin
            eq = 1'b0;
            lt = 1'b0;
        end else if (rs1_is_zero && rs2_is_zero) begin
            eq = 1'b1;
            lt = 1'b0;
        end else if (rs1_sign != rs2_sign) begin
            eq = 1'b0;
            lt = rs1_sign;
        end else begin
            eq = mag_eq;
            if (rs1_sign) begin
                lt = !mag_lt && !mag_eq;
            end else begin
                lt = mag_lt;
            end
        end
    end

    logic nv;
    logic [63:0] cmp_out;
    logic [63:0] minmax_out;

    always_comb begin
        nv = 1'b0;
        cmp_out = '0;
        minmax_out = '0;
        if (!is_min_max) begin
            if (rm == 3'b010) begin
                nv = rs1_is_snan || rs2_is_snan;
                cmp_out = {63'b0, eq};
            end else if (rm == 3'b001) begin
                nv = rs1_is_nan || rs2_is_nan;
                cmp_out = {63'b0, lt};
            end else if (rm == 3'b000) begin
                nv = rs1_is_nan || rs2_is_nan;
                cmp_out = {63'b0, lt | eq};
            end
        end else begin
            nv = rs1_is_snan || rs2_is_snan;
            if (rs1_is_nan && rs2_is_nan) begin
                minmax_out = is_fp32 ? {32'hFFFFFFFF, CANONICAL_NAN_FP32} : CANONICAL_NAN_FP64;
            end else if (rs1_is_nan) begin
                minmax_out = is_fp32 ? {32'hFFFFFFFF, rs2_raw[31:0]} : rs2_raw;
            end else if (rs2_is_nan) begin
                minmax_out = is_fp32 ? {32'hFFFFFFFF, rs1_raw[31:0]} : rs1_raw;
            end else begin
                logic take_rs1;
                if (rm == 3'b000) begin
                    if (rs1_is_zero && rs2_is_zero && (rs1_sign != rs2_sign)) begin
                        take_rs1 = rs1_sign;
                    end else begin
                        take_rs1 = lt;
                    end
                end else begin
                    if (rs1_is_zero && rs2_is_zero && (rs1_sign != rs2_sign)) begin
                        take_rs1 = !rs1_sign;
                    end else begin
                        take_rs1 = !lt && !eq;
                    end
                end
                
                if (take_rs1) begin
                    minmax_out = is_fp32 ? {32'hFFFFFFFF, rs1_raw[31:0]} : rs1_raw;
                end else begin
                    minmax_out = is_fp32 ? {32'hFFFFFFFF, rs2_raw[31:0]} : rs2_raw;
                end
            end
        end
    end

    assign out = is_min_max ? minmax_out : cmp_out;
    assign fflags = {nv, 4'b0000};

endmodule