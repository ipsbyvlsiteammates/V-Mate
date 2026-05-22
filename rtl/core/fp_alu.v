`timescale 1ns/1ps

module fp_alu #(
    parameter EXTENSION_F = 0,
    parameter EXTENSION_D = 0
)(
    input  wire [4:0]  fp_alu_op,
    input  wire [1:0]  fmt,
    input  wire [2:0]  rm,
    input  wire [2:0]  fcsr_rm,
    input  wire [63:0] rs1_data,
    input  wire [63:0] rs2_data,
    input  wire [63:0] rs3_data,
    input  wire [31:0] int_rs1_data,
    input  wire        int_to_fp,
    input  wire        fp_to_int,
    input  wire [4:0]  rs2_addr,
    output reg  [63:0] result,
    output reg  [4:0]  fflags
);

    import fp_pkg::*;

    localparam logic [4:0] OP_FADD   = 5'd0;
    localparam logic [4:0] OP_FSUB   = 5'd1;
    localparam logic [4:0] OP_FMUL   = 5'd2;
    localparam logic [4:0] OP_FDIV   = 5'd3;
    localparam logic [4:0] OP_FSQRT  = 5'd4;
    localparam logic [4:0] OP_FSGNJ  = 5'd5;
    localparam logic [4:0] OP_FMIN   = 5'd6;
    localparam logic [4:0] OP_FCVT   = 5'd7;
    localparam logic [4:0] OP_FMV    = 5'd8;
    localparam logic [4:0] OP_FCMP   = 5'd9;
    localparam logic [4:0] OP_FMADD  = 5'd10;
    localparam logic [4:0] OP_FMSUB  = 5'd11;
    localparam logic [4:0] OP_FNMSUB = 5'd12;
    localparam logic [4:0] OP_FNMADD = 5'd13;
    localparam logic [4:0] OP_FCLASS = 5'd14;

    roundmode_e eff_rm;
    assign eff_rm = roundmode_e'((rm == 3'b111) ? fcsr_rm : rm);

    fp_unpacked_t rs1_unpacked, rs2_unpacked, rs3_unpacked;

        logic [1:0] rs1_fmt;
assign rs1_fmt = (fp_alu_op == OP_FCVT && !int_to_fp && !fp_to_int) ? rs2_addr[1:0] : fmt;

fp_unpack u_fp_unpack_rs1 (
        .in(rs1_data),
        .fmt(rs1_fmt),
        .out(rs1_unpacked)
    );

    fp_unpack u_fp_unpack_rs2 (
        .in(rs2_data),
        .fmt(fmt),
        .out(rs2_unpacked)
    );

    fp_unpack u_fp_unpack_rs3 (
        .in(rs3_data),
        .fmt(fmt),
        .out(rs3_unpacked)
    );

    reg [2:0] fma_op;
    always_comb begin
        case (fp_alu_op)
            OP_FADD:   fma_op = 3'd0;
            OP_FSUB:   fma_op = 3'd1;
            OP_FMUL:   fma_op = 3'd2;
            OP_FMADD:  fma_op = 3'd4;
            OP_FMSUB:  fma_op = 3'd5;
            OP_FNMSUB: fma_op = 3'd6;
            OP_FNMADD: fma_op = 3'd7;
            default:   fma_op = 3'd0;
        endcase
    end

    wire [63:0] fma_result;
    wire [4:0]  fma_fflags;
    fp_fma u_fp_fma (
        .op(fma_op),
        .fmt(fmt),
        .rm(eff_rm),
        .rs1_unpacked(rs1_unpacked),
        .rs2_unpacked(rs2_unpacked),
        .rs3_unpacked(rs3_unpacked),
        .out(fma_result),
        .fflags(fma_fflags)
    );

    wire is_sqrt = (fp_alu_op == OP_FSQRT);
    wire [63:0] divsqrt_result;
    wire [4:0]  divsqrt_fflags;
    fp_divsqrt u_fp_divsqrt (
        .is_sqrt(is_sqrt),
        .fmt(fmt),
        .rm(eff_rm),
        .rs1_unpacked(rs1_unpacked),
        .rs2_unpacked(rs2_unpacked),
        .out(divsqrt_result),
        .fflags(divsqrt_fflags)
    );

    wire is_min_max = (fp_alu_op == OP_FMIN);
    wire [63:0] cmp_result;
    wire [4:0]  cmp_fflags;
    fp_cmp u_fp_cmp (
        .is_min_max(is_min_max),
        .fmt(fmt),
        .rm(eff_rm),
        .rs1_raw(rs1_data),
        .rs2_raw(rs2_data),
        .rs1_unpacked(rs1_unpacked),
        .rs2_unpacked(rs2_unpacked),
        .out(cmp_result),
        .fflags(cmp_fflags)
    );

    wire [63:0] sgnj_result;
    fp_sgnj u_fp_sgnj (
        .rm(eff_rm),
        .fmt(fmt),
        .rs1_raw(rs1_data),
        .rs2_raw(rs2_data),
        .out(sgnj_result)
    );

    wire [63:0] cvt_result;
    wire [4:0]  cvt_fflags;
    fp_cvt u_fp_cvt (
        .rs1_unpacked(rs1_unpacked),
        .rs1_raw(rs1_data),
        .int_data(int_rs1_data),
        .fmt(fmt),
        .rs2_addr(rs2_addr),
        .rm(eff_rm),
        .int_to_fp(int_to_fp),
        .fp_to_int(fp_to_int),
        .out(cvt_result),
        .fflags(cvt_fflags)
    );

    reg [63:0] fmv_result;
    always_comb begin
        if (int_to_fp) begin
            fmv_result = {32'hFFFFFFFF, int_rs1_data};
        end else if (fp_to_int) begin
            fmv_result = {32'b0, rs1_data[31:0]};
        end else begin
            fmv_result = 64'b0;
        end
    end

    reg [9:0] fclass_mask;
    always_comb begin
        fclass_mask = 10'b0;
        if (rs1_unpacked.is_nan) begin
            if (rs1_unpacked.is_snan) fclass_mask[8] = 1'b1;
            else fclass_mask[9] = 1'b1;
        end else if (rs1_unpacked.is_inf) begin
            if (rs1_unpacked.sign) fclass_mask[0] = 1'b1;
            else fclass_mask[7] = 1'b1;
        end else if (rs1_unpacked.is_zero) begin
            if (rs1_unpacked.sign) fclass_mask[3] = 1'b1;
            else fclass_mask[4] = 1'b1;
        end else begin
            logic is_subnormal;
            if (fmt == 2'b00) begin
                is_subnormal = (rs1_data[30:23] == 8'b0);
            end else begin
                is_subnormal = (rs1_data[62:52] == 11'b0);
            end
            
            if (is_subnormal) begin
                if (rs1_unpacked.sign) fclass_mask[2] = 1'b1;
                else fclass_mask[5] = 1'b1;
            end else begin
                if (rs1_unpacked.sign) fclass_mask[1] = 1'b1;
                else fclass_mask[6] = 1'b1;
            end
        end
    end

    always_comb begin
        result = 64'b0;
        fflags = 5'b0;
        case (fp_alu_op)
            OP_FADD, OP_FSUB, OP_FMUL, OP_FMADD, OP_FMSUB, OP_FNMSUB, OP_FNMADD: begin
                result = fma_result;
                fflags = fma_fflags;
            end
            OP_FDIV, OP_FSQRT: begin
                result = divsqrt_result;
                fflags = divsqrt_fflags;
            end
            OP_FCMP, OP_FMIN: begin
                result = cmp_result;
                fflags = cmp_fflags;
            end
            OP_FSGNJ: begin
                result = sgnj_result;
                fflags = 5'b0;
            end
            OP_FCVT: begin
                result = cvt_result;
                fflags = cvt_fflags;
            end
            OP_FMV: begin
                result = fmv_result;
                fflags = 5'b0;
            end
            OP_FCLASS: begin
                result = {54'b0, fclass_mask};
                fflags = 5'b0;
            end
            default: begin
                result = 64'b0;
                fflags = 5'b0;
            end
        endcase
    end

endmodule
