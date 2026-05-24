`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////
// Module:      control_unit
// Description: Control Unit for RV32I single-cycle processor.
//              Decodes instruction opcode, funct3, and funct7 fields to
//              generate all datapath control signals.
//              Internal structure: Main Decoder + ALU Decoder.
// Author:      Sagi
// Date:        2024
//////////////////////////////////////////////////////////////////////////////

module control_unit #(
    parameter PRIVILEGED = 1,
    parameter EXTENSION_M = 1,
    parameter EXTENSION_A = 1,
    parameter EXTENSION_F = 1,
    parameter EXTENSION_D = 1
) (
    // Inputs
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    input  wire [4:0] rs1_addr,
    input  wire [4:0] rs2_addr,
    input  wire [4:0] rd_addr,
    input  wire [1:0] mstatus_fs,
    input  wire [2:0] fcsr_rm,

    // Outputs
    output reg        reg_write,
    output reg  [1:0] result_sel,
    output reg        mem_write,
    output reg        mem_read,
    output reg        alu_src,
    output reg        pc_src_auipc,
    output reg  [2:0] imm_sel,
    output reg        branch,
    output reg        jump,
    output reg  [4:0] alu_op,
    output reg  [2:0] mem_size,
    output reg        csr_write,
    output reg  [1:0] csr_op,
    output reg        csr_imm_sel,
    output reg        exception,
    output reg  [3:0] exception_cause,
    output reg        mret_exec,
    output reg        amo_en,
    output reg  [4:0] amo_op,

    // FP Outputs
    output reg        fp_we,
    output reg  [4:0] fp_alu_op,
    output reg  [1:0] fmt,
    output reg  [2:0] rm,
    output reg        int_to_fp,
    output reg        fp_to_int,
    output reg        fp_mem_read,
    output reg        fp_mem_write,
    output reg        fp_fflags_we
);

    //////////////////////////////////////////////////////////////////////////
    // Opcode Constants
    //////////////////////////////////////////////////////////////////////////
    localparam logic [6:0] OP_R_TYPE   = 7'b0110011;
    localparam logic [6:0] OP_I_TYPE   = 7'b0010011;
    localparam logic [6:0] OP_LOAD     = 7'b0000011;
    localparam logic [6:0] OP_STORE    = 7'b0100011;
    localparam logic [6:0] OP_BRANCH   = 7'b1100011;
    localparam logic [6:0] OP_JAL      = 7'b1101111;
    localparam logic [6:0] OP_JALR     = 7'b1100111;
    localparam logic [6:0] OP_LUI      = 7'b0110111;
    localparam logic [6:0] OP_AUIPC    = 7'b0010111;
    localparam logic [6:0] OP_FENCE    = 7'b0001111;
    localparam logic [6:0] OP_SYSTEM   = 7'b1110011;
    localparam logic [6:0] OP_AMO      = 7'b0101111;

    // FP Opcodes
    localparam logic [6:0] OP_LOAD_FP  = 7'b0000111;
    localparam logic [6:0] OP_STORE_FP = 7'b0100111;
    localparam logic [6:0] OP_FMADD    = 7'b1000011;
    localparam logic [6:0] OP_FMSUB    = 7'b1000111;
    localparam logic [6:0] OP_FNMSUB   = 7'b1001011;
    localparam logic [6:0] OP_FNMADD   = 7'b1001111;
    localparam logic [6:0] OP_FP       = 7'b1010011;

    //////////////////////////////////////////////////////////////////////////
    // ALU Operation Constants
    //////////////////////////////////////////////////////////////////////////
    localparam logic [4:0] ALU_ADD     = 5'b00000;
    localparam logic [4:0] ALU_SUB     = 5'b00001;
    localparam logic [4:0] ALU_AND     = 5'b00010;
    localparam logic [4:0] ALU_OR      = 5'b00011;
    localparam logic [4:0] ALU_XOR     = 5'b00100;
    localparam logic [4:0] ALU_SLT     = 5'b00101;
    localparam logic [4:0] ALU_SLTU    = 5'b00110;
    localparam logic [4:0] ALU_SLL     = 5'b00111;
    localparam logic [4:0] ALU_SRL     = 5'b01000;
    localparam logic [4:0] ALU_SRA     = 5'b01001;
    localparam logic [4:0] ALU_PASS_B  = 5'b01010;
    localparam logic [4:0] ALU_PASS_A  = 5'b01011;

    // M-Extension ALU Operations
    localparam logic [4:0] ALU_MUL     = 5'b10000;
    localparam logic [4:0] ALU_MULH    = 5'b10001;
    localparam logic [4:0] ALU_MULHSU  = 5'b10010;
    localparam logic [4:0] ALU_MULHU   = 5'b10011;
    localparam logic [4:0] ALU_DIV     = 5'b10100;
    localparam logic [4:0] ALU_DIVU    = 5'b10101;
    localparam logic [4:0] ALU_REM     = 5'b10110;
    localparam logic [4:0] ALU_REMU    = 5'b10111;

    // FP ALU Operations
    localparam logic [4:0] FP_ALU_FADD   = 5'd0;
    localparam logic [4:0] FP_ALU_FSUB   = 5'd1;
    localparam logic [4:0] FP_ALU_FMUL   = 5'd2;
    localparam logic [4:0] FP_ALU_FDIV   = 5'd3;
    localparam logic [4:0] FP_ALU_FSQRT  = 5'd4;
    localparam logic [4:0] FP_ALU_FSGNJ  = 5'd5;
    localparam logic [4:0] FP_ALU_FMIN   = 5'd6;
    localparam logic [4:0] FP_ALU_FCVT   = 5'd7;
    localparam logic [4:0] FP_ALU_FMV    = 5'd8;
    localparam logic [4:0] FP_ALU_FCMP   = 5'd9;
    localparam logic [4:0] FP_ALU_FMADD  = 5'd10;
    localparam logic [4:0] FP_ALU_FMSUB  = 5'd11;
    localparam logic [4:0] FP_ALU_FNMSUB = 5'd12;
    localparam logic [4:0] FP_ALU_FNMADD = 5'd13;
    localparam logic [4:0] FP_ALU_FCLASS = 5'd14;

    //////////////////////////////////////////////////////////////////////////
    // Internal Signals
    //////////////////////////////////////////////////////////////////////////
    reg [1:0] alu_op_type;

    //////////////////////////////////////////////////////////////////////////
    // Main Decoder: Generates control signals based on opcode
    //////////////////////////////////////////////////////////////////////////
    always @(*) begin
        // Default values (safe: no writes, no branches, no jumps)
        reg_write       = 1'b0;
        result_sel      = 2'b00;
        mem_write       = 1'b0;
        mem_read        = 1'b0;
        alu_src         = 1'b0;
        pc_src_auipc    = 1'b0;
        imm_sel         = 3'b000;
        branch          = 1'b0;
        jump            = 1'b0;
        alu_op_type     = 2'b00;
        mem_size        = 3'b000;
        csr_write       = 1'b0;
        csr_op          = 2'b00;
        csr_imm_sel     = 1'b0;
        exception       = 1'b0;
        exception_cause = 4'b0000;
        mret_exec       = 1'b0;
        amo_en          = 1'b0;
        amo_op          = 5'b00000;

        // FP Default values
        fp_we           = 1'b0;
        fp_alu_op       = 5'b00000;
        fmt             = 2'b00;
        rm              = 3'b000;
        int_to_fp       = 1'b0;
        fp_to_int       = 1'b0;
        fp_mem_read     = 1'b0;
        fp_mem_write    = 1'b0;
        fp_fflags_we    = 1'b0;

        case (opcode)
            7'b0000000: begin
                // Bubble / NOP (inserted by pipeline flushes)
                // Keep all control signals at their default 0 values
                exception = 1'b0;
            end
            OP_R_TYPE: begin
                reg_write    = 1'b1;
                result_sel   = 2'b00;
                mem_write    = 1'b0;
                mem_read     = 1'b0;
                alu_src      = 1'b0;
                pc_src_auipc = 1'b0;
                imm_sel      = 3'b000;
                branch       = 1'b0;
                jump         = 1'b0;
                alu_op_type  = 2'b10;
                mem_size     = 3'b000;
            end

            OP_I_TYPE: begin
                reg_write    = 1'b1;
                result_sel   = 2'b00;
                mem_write    = 1'b0;
                mem_read     = 1'b0;
                alu_src      = 1'b1;
                pc_src_auipc = 1'b0;
                imm_sel      = 3'b000;
                branch       = 1'b0;
                jump         = 1'b0;
                alu_op_type  = 2'b11;
                mem_size     = 3'b000;
            end

            OP_LOAD: begin
                reg_write    = 1'b1;
                    mem_write    = 1'b0;
                mem_read     = 1'b1;
                alu_src      = 1'b1;
                pc_src_auipc = 1'b0;
                imm_sel      = 3'b000;
                branch       = 1'b0;
                jump         = 1'b0;
                alu_op_type  = 2'b00;
                mem_size     = funct3;
                result_sel = 2'b01;
            end

            OP_STORE: begin
                reg_write    = 1'b0;
                result_sel   = 2'b00;
                mem_write    = 1'b1;
                mem_read     = 1'b0;
                alu_src      = 1'b1;
                pc_src_auipc = 1'b0;
                imm_sel      = 3'b001;
                branch       = 1'b0;
                jump         = 1'b0;
                alu_op_type  = 2'b00;
                mem_size     = funct3;
            end

            OP_BRANCH: begin
                reg_write    = 1'b0;
                result_sel   = 2'b00;
                mem_write    = 1'b0;
                mem_read     = 1'b0;
                alu_src      = 1'b0;
                pc_src_auipc = 1'b0;
                imm_sel      = 3'b010;
                branch       = 1'b1;
                jump         = 1'b0;
                alu_op_type  = 2'b01;
                mem_size     = 3'b000;
            end

            OP_JAL: begin
                reg_write    = 1'b1;
                result_sel   = 2'b10;
                mem_write    = 1'b0;
                mem_read     = 1'b0;
                alu_src      = 1'b0;
                pc_src_auipc = 1'b0;
                imm_sel      = 3'b100;
                branch       = 1'b0;
                jump         = 1'b1;
                alu_op_type  = 2'b00;
                mem_size     = 3'b000;
            end

            OP_JALR: begin
                reg_write    = 1'b1;
                result_sel   = 2'b10;
                mem_write    = 1'b0;
                mem_read     = 1'b0;
                alu_src      = 1'b1;
                pc_src_auipc = 1'b0;
                imm_sel      = 3'b000;
                branch       = 1'b0;
                jump         = 1'b1;
                alu_op_type  = 2'b00;
                mem_size     = 3'b000;
            end

            OP_LUI: begin
                reg_write    = 1'b1;
                result_sel   = 2'b00;
                mem_write    = 1'b0;
                mem_read     = 1'b0;
                alu_src      = 1'b1;
                pc_src_auipc = 1'b0;
                imm_sel      = 3'b011;
                branch       = 1'b0;
                jump         = 1'b0;
                alu_op_type  = 2'b00;
                mem_size     = 3'b000;
            end

            OP_AUIPC: begin
                reg_write    = 1'b1;
                result_sel   = 2'b00;
                mem_write    = 1'b0;
                mem_read     = 1'b0;
                alu_src      = 1'b1;
                pc_src_auipc = 1'b1;
                imm_sel      = 3'b011;
                branch       = 1'b0;
                jump         = 1'b0;
                alu_op_type  = 2'b00;
                mem_size     = 3'b000;
            end

            OP_AMO: begin
                if (EXTENSION_A) begin
                    if (funct3 == 3'b010 || funct3 == 3'b011) begin
                        amo_en = 1'b1;
                        amo_op = funct7[6:2];
                        mem_size = funct3;
                        if (amo_op == 5'b00010) begin // LR
                            mem_read   = 1'b1;
                            mem_write  = 1'b0;
                            reg_write  = 1'b1;
                            result_sel = 2'b01;
                        end else if (amo_op == 5'b00011) begin // SC
                            mem_read   = 1'b0;
                            mem_write  = 1'b1;
                            reg_write  = 1'b1;
                            result_sel = 2'b01;
                        end else begin // Other AMOs
                            mem_read   = 1'b1;
                            mem_write  = 1'b1;
                            reg_write  = 1'b1;
                            result_sel = 2'b01;
                        end
                    end else begin
                        exception = 1'b1;
                        exception_cause = 4'd2;
                    end
                end else begin
                    exception = 1'b1;
                    exception_cause = 4'd2;
                end
            end

            OP_FENCE: begin
                // NOP - all defaults (zeros)
            end

            OP_SYSTEM: begin
                if (PRIVILEGED) begin
                    if (funct3 == 3'b000) begin
                        if (funct7 == 7'b0000000 && rs2_addr == 5'b00000) begin
                            // ECALL
                            exception = 1'b1;
                            exception_cause = 4'd11;
                        end else if (funct7 == 7'b0000000 && rs2_addr == 5'b00001) begin
                            // EBREAK
                            exception = 1'b1;
                            exception_cause = 4'd3;
                        end else if (funct7 == 7'b0011000 && rs2_addr == 5'b00010) begin
                            // MRET
                            mret_exec = 1'b1;
                        end else begin
                            exception = 1'b1;
                            exception_cause = 4'd2;
                        end
                    end else begin
                        // Zicsr
                        reg_write   = 1'b1;
                        result_sel  = 2'b11;
                        csr_imm_sel = funct3[2];
                        
                        if (funct3[2]) begin
                            imm_sel = 3'b101; // IMM_Z
                        end
                        
                        case (funct3[1:0])
                            2'b01: begin // CSRRW / CSRRWI
                                csr_op = 2'b01;
                                csr_write = 1'b1;
                            end
                            2'b10: begin // CSRRS / CSRRSI
                                csr_op = 2'b10;
                                csr_write = (rs1_addr != 5'b00000);
                            end
                            2'b11: begin // CSRRC / CSRRCI
                                csr_op = 2'b11;
                                csr_write = (rs1_addr != 5'b00000);
                            end
                            default: begin
                                csr_op = 2'b00;
                                csr_write = 1'b0;
                                exception = 1'b1;
                                exception_cause = 4'd2;
                            end
                        endcase
                    end
                end else begin
                    exception = 1'b1;
                    exception_cause = 4'd2;
                end
            end

            OP_LOAD_FP: begin
                if (EXTENSION_F || EXTENSION_D) begin
                    if (funct3 == 3'b010 || funct3 == 3'b011) begin
                        mem_read     = 1'b1;
                        fp_we        = 1'b1;
                        fp_mem_read  = 1'b1;
                        alu_src      = 1'b1;
                        imm_sel      = 3'b000; // IMM_I
                        alu_op_type  = 2'b00;  // ADD
                        mem_size     = funct3;
                        fmt          = (funct3 == 3'b011) ? 2'b01 : 2'b00;
                    end else begin
                        exception = 1'b1;
                        exception_cause = 4'd2;
                    end
                end else begin
                    exception = 1'b1;
                    exception_cause = 4'd2;
                end
                result_sel = 2'b01;
            end

            OP_STORE_FP: begin
                if (EXTENSION_F || EXTENSION_D) begin
                    if (funct3 == 3'b010 || funct3 == 3'b011) begin
                        mem_write    = 1'b1;
                        fp_mem_write = 1'b1;
                        alu_src      = 1'b1;
                        imm_sel      = 3'b001; // IMM_S
                        alu_op_type  = 2'b00;  // ADD
                        mem_size     = funct3;
                    end else begin
                        exception = 1'b1;
                        exception_cause = 4'd2;
                    end
                end else begin
                    exception = 1'b1;
                    exception_cause = 4'd2;
                end
            end

            OP_FMADD: begin
                if (EXTENSION_F || EXTENSION_D) begin
                    fp_we        = 1'b1;
                    fmt          = funct7[1:0];
                    rm           = funct3;
                    fp_fflags_we = 1'b1;
                    fp_alu_op    = FP_ALU_FMADD;
                end
            end

            OP_FMSUB: begin
                if (EXTENSION_F || EXTENSION_D) begin
                    fp_we        = 1'b1;
                    fmt          = funct7[1:0];
                    rm           = funct3;
                    fp_fflags_we = 1'b1;
                    fp_alu_op    = FP_ALU_FMSUB;
                end
            end

            OP_FNMSUB: begin
                if (EXTENSION_F || EXTENSION_D) begin
                    fp_we        = 1'b1;
                    fmt          = funct7[1:0];
                    rm           = funct3;
                    fp_fflags_we = 1'b1;
                    fp_alu_op    = FP_ALU_FNMSUB;
                end
            end

            OP_FNMADD: begin
                if (EXTENSION_F || EXTENSION_D) begin
                    fp_we        = 1'b1;
                    fmt          = funct7[1:0];
                    rm           = funct3;
                    fp_fflags_we = 1'b1;
                    fp_alu_op    = FP_ALU_FNMADD;
                end
            end

            OP_FP: begin
                if (EXTENSION_F || EXTENSION_D) begin
                    fmt = funct7[1:0];
                    rm  = funct3;
                    case (funct7[6:2])
                        5'b00000: begin // FADD
                            fp_we        = 1'b1;
                            fp_alu_op    = FP_ALU_FADD;
                            fp_fflags_we = 1'b1;
                        end
                        5'b00001: begin // FSUB
                            fp_we        = 1'b1;
                            fp_alu_op    = FP_ALU_FSUB;
                            fp_fflags_we = 1'b1;
                        end
                        5'b00010: begin // FMUL
                            fp_we        = 1'b1;
                            fp_alu_op    = FP_ALU_FMUL;
                            fp_fflags_we = 1'b1;
                        end
                        5'b00011: begin // FDIV
                            fp_we        = 1'b1;
                            fp_alu_op    = FP_ALU_FDIV;
                            fp_fflags_we = 1'b1;
                        end
                        5'b01011: begin // FSQRT
                            fp_we        = 1'b1;
                            fp_alu_op    = FP_ALU_FSQRT;
                            fp_fflags_we = 1'b1;
                        end
                        5'b00100: begin // FSGNJ
                            fp_we        = 1'b1;
                            fp_alu_op    = FP_ALU_FSGNJ;
                        end
                        5'b00101: begin // FMIN/MAX
                            fp_we        = 1'b1;
                            fp_alu_op    = FP_ALU_FMIN;
                            fp_fflags_we = 1'b1;
                        end
                        5'b01000: begin // FCVT.S.D/D.S
                            fp_we        = 1'b1;
                            fp_alu_op    = FP_ALU_FCVT;
                            fp_fflags_we = 1'b1;
                        end
                        5'b10100: begin // FCMP
                            reg_write    = 1'b1;
                            fp_to_int    = 1'b1;
                            fp_alu_op    = FP_ALU_FCMP;
                            fp_fflags_we = 1'b1;
                        end
                        5'b11000: begin // FCVT.W.S/D
                            reg_write    = 1'b1;
                            fp_to_int    = 1'b1;
                            fp_alu_op    = FP_ALU_FCVT;
                            fp_fflags_we = 1'b1;
                        end
                        5'b11010: begin // FCVT.S/D.W
                            fp_we        = 1'b1;
                            int_to_fp    = 1'b1;
                            fp_alu_op    = FP_ALU_FCVT;
                            fp_fflags_we = 1'b1;
                        end
                        5'b11100: begin // FMV.X.W/D or FCLASS
                            reg_write    = 1'b1;
                            fp_to_int    = 1'b1;
                            if (funct3 == 3'b001) begin
                                fp_alu_op = FP_ALU_FCLASS;
                            end else begin
                                fp_alu_op = FP_ALU_FMV;
                            end
                        end
                        5'b11110: begin // FMV.W/D.X
                            fp_we        = 1'b1;
                            int_to_fp    = 1'b1;
                            fp_alu_op    = FP_ALU_FMV;
                        end
                        default: begin
                            exception = 1'b1;
                            exception_cause = 4'd2;
                        end
                    endcase
                end else begin
                    exception = 1'b1;
                    exception_cause = 4'd2;
                end
            end

            default: begin
                // Unknown opcode - safe defaults (all zeros)
                exception = 1'b1;
                exception_cause = 4'd2;
            end
        endcase

        if (opcode == OP_LOAD_FP || opcode == OP_STORE_FP || opcode == OP_FMADD || opcode == OP_FMSUB || opcode == OP_FNMSUB || opcode == OP_FNMADD || opcode == OP_FP) begin
            if (mstatus_fs == 2'b00) begin
                exception = 1'b1;
                exception_cause = 4'd2;
            end else if (opcode != OP_LOAD_FP && opcode != OP_STORE_FP && (funct3 == 3'b101 || funct3 == 3'b110)) begin
                exception = 1'b1;
                exception_cause = 4'd2;
            end else if (opcode != OP_LOAD_FP && opcode != OP_STORE_FP && funct3 == 3'b111 && fcsr_rm >= 3'b101) begin
                exception = 1'b1;
                exception_cause = 4'd2;
            end
            result_sel = 2'b01;
        end
    end

    //////////////////////////////////////////////////////////////////////////
    // ALU Decoder: Generates alu_op based on alu_op_type, funct3, funct7[5]
    //////////////////////////////////////////////////////////////////////////
    always @(*) begin
        // Default ALU operation
        alu_op = ALU_ADD;

        // Special case: LUI forces PASS_B regardless of alu_op_type
        if (opcode == OP_LUI) begin
            alu_op = ALU_PASS_B;
        end
        else if (opcode == OP_AMO) begin
            alu_op = ALU_PASS_A;
        end
        else begin
            case (alu_op_type)
                2'b00: begin
                    // Fixed ADD (Load, Store, JALR, JAL, AUIPC)
                    alu_op = ALU_ADD;
                end

                2'b01: begin
                    // Branch comparison
                    case (funct3)
                        3'b000:  alu_op = ALU_SUB;   // BEQ
                        3'b001:  alu_op = ALU_SUB;   // BNE
                        3'b100:  alu_op = ALU_SLT;   // BLT
                        3'b101:  alu_op = ALU_SLT;   // BGE
                        3'b110:  alu_op = ALU_SLTU;  // BLTU
                        3'b111:  alu_op = ALU_SLTU;  // BGEU
                        default: alu_op = ALU_SUB;   // Safe default
                    endcase
                end

                2'b10: begin
                    // R-type: decode from funct3 + funct7
                    if (EXTENSION_M && funct7 == 7'b0000001) begin
                        case (funct3)
                            3'b000: alu_op = ALU_MUL;
                            3'b001: alu_op = ALU_MULH;
                            3'b010: alu_op = ALU_MULHSU;
                            3'b011: alu_op = ALU_MULHU;
                            3'b100: alu_op = ALU_DIV;
                            3'b101: alu_op = ALU_DIVU;
                            3'b110: alu_op = ALU_REM;
                            3'b111: alu_op = ALU_REMU;
                            default: alu_op = ALU_ADD;
                        endcase
                    end else begin
                        case (funct3)
                            3'b000:  alu_op = funct7[5] ? ALU_SUB : ALU_ADD;  // ADD/SUB
                            3'b001:  alu_op = ALU_SLL;                        // SLL
                            3'b010:  alu_op = ALU_SLT;                        // SLT
                            3'b011:  alu_op = ALU_SLTU;                       // SLTU
                            3'b100:  alu_op = ALU_XOR;                        // XOR
                            3'b101:  alu_op = funct7[5] ? ALU_SRA : ALU_SRL;  // SRL/SRA
                            3'b110:  alu_op = ALU_OR;                         // OR
                            3'b111:  alu_op = ALU_AND;                        // AND
                            default: alu_op = ALU_ADD;                        // Safe default
                        endcase
                    end
                end

                2'b11: begin
                    // I-type: decode from funct3 + funct7[5] (shifts only)
                    case (funct3)
                        3'b000:  alu_op = ALU_ADD;                        // ADDI
                        3'b001:  alu_op = ALU_SLL;                        // SLLI
                        3'b010:  alu_op = ALU_SLT;                        // SLTI
                        3'b011:  alu_op = ALU_SLTU;                       // SLTIU
                        3'b100:  alu_op = ALU_XOR;                        // XORI
                        3'b101:  alu_op = funct7[5] ? ALU_SRA : ALU_SRL;  // SRLI/SRAI
                        3'b110:  alu_op = ALU_OR;                         // ORI
                        3'b111:  alu_op = ALU_AND;                        // ANDI
                        default: alu_op = ALU_ADD;                        // Safe default
                    endcase
                end

                default: begin
                    alu_op = ALU_ADD;
                end
            endcase
        end
    end

endmodule
