`timescale 1ns/1ps
//============================================================================
// Module: riscv_top
// Description: Single-cycle RISC-V RV32I processor top-level module
// Integrates: PC, IMEM, Register File, Immediate Generator, ALU,
//             Control Unit, Data Memory, CSR File, FPR, FP ALU
//============================================================================

module riscv_top #(
    parameter PRIVILEGED = 1,
    parameter EXTENSION_M = 1,
    parameter EXTENSION_A = 1,
    parameter EXTENSION_F = 1,
    parameter EXTENSION_D = 1
) (
    input  wire        clk,
    input  wire        clk_en,
    input  wire        rst_n
);

    //========================================================================
    // Internal Wire Declarations
    //========================================================================

    localparam FLEN = EXTENSION_D ? 64 : (EXTENSION_F ? 32 : 32);

    wire global_gated_clk;
    icg u_global_icg (
        .clk(clk),
        .en(clk_en),
        .gated_clk(global_gated_clk)
    );

    // PC wires
    wire [31:0] pc_out_w;
    wire [31:0] pc_plus4_w;
    wire        pc_sel_w;
    wire [31:0] pc_target_w;

    // Instruction fetch
    wire [31:0] instruction_w;

    // Control signals
    wire        reg_write_w;
    wire [1:0]  result_sel_w;
    wire        mem_write_w;
    wire        mem_read_w;
    wire        alu_src_w;
    wire        pc_src_auipc_w;
    wire [2:0]  imm_sel_w;
    wire        branch_w;
    wire        jump_w;
    wire [4:0]  alu_op_w;
    wire [2:0]  mem_size_w;
    
    // AMO signals
    wire        amo_en_w;
    wire [4:0]  amo_op_w;

    // Privileged control signals
    wire        csr_write_w;
    wire [1:0]  csr_op_w;
    wire        csr_imm_sel_w;
    wire        exception_w;
    wire [3:0]  exception_cause_w;
    wire        mret_exec_w;

    // FP Control signals
    wire        fp_we_w;
    wire [4:0]  fp_alu_op_w;
    wire [1:0]  fmt_w;
    wire [2:0]  rm_w;
    wire        int_to_fp_w;
    wire        fp_to_int_w;
    wire        fp_mem_read_w;
    wire        fp_mem_write_w;
    wire        fp_fflags_we_w;

    // Register file outputs
    wire [31:0] rs1_data_w;
    wire [31:0] rs2_data_w;

    // FP Data signals
    wire [FLEN-1:0] fp_rs1_data_w;
    wire [FLEN-1:0] fp_rs2_data_w;
    wire [FLEN-1:0] fp_rs3_data_w;
    wire [FLEN-1:0] fp_alu_result_w;
    wire [4:0]      fp_fflags_w;
    wire [2:0]      fcsr_rm_w;
    wire [FLEN-1:0] fp_wb_data_w;

    // Immediate generator output
    wire [31:0] imm_out_w;

    // ALU signals
    wire [31:0] alu_operand_a_w;
    wire [31:0] alu_operand_b_w;
    wire [31:0] alu_result_w;
    wire        zero_flag_w;

    // Data memory output
    wire [(EXTENSION_D ? 64 : 32)-1:0] dmem_rdata_w;

    // Write-back data
    wire [31:0] wb_data_w;

    // Branch/Jump resolution
    wire        branch_taken_w;
    wire [31:0] branch_target_w;
    wire [31:0] jalr_target_w;
    wire        is_jalr_w;

    // CSR wires
    wire [31:0] csr_rdata_w;
    wire [31:0] mepc_out_w;
    wire [31:0] mtvec_out_w;
    wire [31:0] csr_wdata_w;
    wire [1:0]  mstatus_fs_w;

    //========================================================================
    // PC + 4 Calculation
    //========================================================================
    assign pc_plus4_w = pc_out_w + 32'd4;

    //========================================================================
    // ALU Operand A Mux
    //========================================================================
    assign alu_operand_a_w = pc_src_auipc_w ? pc_out_w : rs1_data_w;

    //========================================================================
    // ALU Operand B Mux
    //========================================================================
    assign alu_operand_b_w = alu_src_w ? imm_out_w : rs2_data_w;

    //========================================================================
    // CSR Write Data Mux
    //========================================================================
    assign csr_wdata_w = csr_imm_sel_w ? imm_out_w : rs1_data_w;

    //========================================================================
    // Write-Back Mux (Integer RF)
    //========================================================================
    assign wb_data_w = fp_to_int_w ? fp_alu_result_w[31:0] :
                       (result_sel_w == 2'b00) ? alu_result_w :
                       (result_sel_w == 2'b01) ? dmem_rdata_w[31:0] :
                       (result_sel_w == 2'b10) ? pc_plus4_w :
                       (result_sel_w == 2'b11) ? csr_rdata_w :
                                                 32'b0;

    //========================================================================
    // Write-Back Mux (FPR)
    //========================================================================
    wire [63:0] load_fp_data = (mem_size_w == 3'b010) ? {32'hFFFFFFFF, dmem_rdata_w[31:0]} : dmem_rdata_w;
    assign fp_wb_data_w = fp_mem_read_w ? load_fp_data[FLEN-1:0] : fp_alu_result_w;

    //========================================================================
    // Data Memory Write Data Mux
    //========================================================================
    wire [63:0] rs2_data_ext = {32'b0, rs2_data_w};
    wire [(EXTENSION_D ? 64 : 32)-1:0] dmem_write_data_w;
    assign dmem_write_data_w = fp_mem_write_w ? fp_rs2_data_w : rs2_data_ext[(EXTENSION_D ? 64 : 32)-1:0];

    //========================================================================
    // PC Target Calculation
    //========================================================================
    assign branch_target_w = pc_out_w + imm_out_w;
    assign jalr_target_w   = alu_result_w & ~32'd1;
    assign is_jalr_w       = (instruction_w[6:0] == 7'b1100111);
    assign pc_target_w     = is_jalr_w ? jalr_target_w : branch_target_w;

    //========================================================================
    // PC Select Logic
    //========================================================================
    assign pc_sel_w = (branch_w & branch_taken_w) | jump_w;

    //========================================================================
    // Branch Resolution Logic
    //========================================================================
    reg branch_taken_r;
    always @(*) begin
        case (instruction_w[14:12])
            3'b000:  branch_taken_r = zero_flag_w;          // BEQ
            3'b001:  branch_taken_r = ~zero_flag_w;         // BNE
            3'b100:  branch_taken_r = alu_result_w[0];      // BLT
            3'b101:  branch_taken_r = ~alu_result_w[0];     // BGE
            3'b110:  branch_taken_r = alu_result_w[0];      // BLTU
            3'b111:  branch_taken_r = ~alu_result_w[0];     // BGEU
            default: branch_taken_r = 1'b0;
        endcase
    end
    assign branch_taken_w = branch_taken_r;

    //========================================================================
    // Sub-module Instantiations
    //========================================================================

    // Program Counter
    pc u_pc (
        .clk       (global_gated_clk),
        .rst_n     (rst_n),
        .pc_sel    (pc_sel_w),
        .pc_target (pc_target_w),
        .exception (exception_w),
        .mtvec     (mtvec_out_w),
        .mret_exec (mret_exec_w),
        .mepc      (mepc_out_w),
        .pc_out    (pc_out_w)
    );

    // Instruction Memory
    imem u_imem (
        .addr        (pc_out_w),
        .instruction (instruction_w)
    );

    // Register File
    register_file u_register_file (
        .clk        (global_gated_clk),
        .rst_n      (rst_n),
        .rs1_addr   (instruction_w[19:15]),
        .rs2_addr   (instruction_w[24:20]),
        .rd_addr    (instruction_w[11:7]),
        .rd_data    (wb_data_w),
        .we         (reg_write_w),
        .rs1_data   (rs1_data_w),
        .rs2_data   (rs2_data_w)
    );

    // Immediate Generator
    imm_gen u_imm_gen (
        .instruction (instruction_w),
        .imm_sel    (imm_sel_w),
        .imm_out    (imm_out_w)
    );

    // ALU
    alu #(
        .EXTENSION_M(EXTENSION_M)
    ) u_alu (
        .operand_a  (alu_operand_a_w),
        .operand_b  (alu_operand_b_w),
        .alu_op     (alu_op_w),
        .alu_result (alu_result_w),
        .zero_flag  (zero_flag_w)
    );

    // Control Unit
    control_unit #(
        .PRIVILEGED(PRIVILEGED),
        .EXTENSION_M(EXTENSION_M),
        .EXTENSION_A(EXTENSION_A),
        .EXTENSION_F(EXTENSION_F),
        .EXTENSION_D(EXTENSION_D)
    ) u_control_unit (
        .opcode          (instruction_w[6:0]),
        .funct3          (instruction_w[14:12]),
        .funct7          (instruction_w[31:25]),
        .rs1_addr        (instruction_w[19:15]),
        .rs2_addr        (instruction_w[24:20]),
        .rd_addr         (instruction_w[11:7]),
        .mstatus_fs      (mstatus_fs_w),
        .reg_write       (reg_write_w),
        .result_sel      (result_sel_w),
        .mem_write       (mem_write_w),
        .mem_read        (mem_read_w),
        .alu_src         (alu_src_w),
        .pc_src_auipc    (pc_src_auipc_w),
        .imm_sel         (imm_sel_w),
        .branch          (branch_w),
        .jump            (jump_w),
        .alu_op          (alu_op_w),
        .mem_size        (mem_size_w),
        .amo_en          (amo_en_w),
        .amo_op          (amo_op_w),
        .csr_write       (csr_write_w),
        .csr_op          (csr_op_w),
        .csr_imm_sel     (csr_imm_sel_w),
        .exception       (exception_w),
        .exception_cause (exception_cause_w),
        .mret_exec       (mret_exec_w),
        .fp_we           (fp_we_w),
        .fp_alu_op       (fp_alu_op_w),
        .fmt             (fmt_w),
        .rm              (rm_w),
        .int_to_fp       (int_to_fp_w),
        .fp_to_int       (fp_to_int_w),
        .fp_mem_read     (fp_mem_read_w),
        .fp_mem_write    (fp_mem_write_w),
        .fp_fflags_we    (fp_fflags_we_w)
    );

    // Data Memory
    dmem #(
        .EXTENSION_A(EXTENSION_A)
    ) u_dmem (
        .clk        (global_gated_clk),
        .rst_n      (rst_n),
        .mem_write  (mem_write_w | fp_mem_write_w),
        .mem_read   (mem_read_w | fp_mem_read_w),
        .amo_en     (amo_en_w),
        .amo_op     (amo_op_w),
        .addr       (alu_result_w),
        .write_data (dmem_write_data_w),
        .mem_size   (mem_size_w),
        .read_data  (dmem_rdata_w)
    );

    // CSR File
    generate
        if (PRIVILEGED) begin : gen_csr
            csr_file #(
                .EXTENSION_F(EXTENSION_F)
            ) u_csr_file (
                .clk             (global_gated_clk),
                .rst_n           (rst_n),
                .csr_addr        (instruction_w[31:20]),
                .csr_wdata       (csr_wdata_w),
                .csr_op          (csr_op_w),
                .csr_write       (csr_write_w),
                .exception       (exception_w),
                .exception_cause (exception_cause_w),
                .exception_pc    (pc_out_w),
                .exception_addr  (instruction_w),
                .mret_exec       (mret_exec_w),
                .fp_fflags_update(fp_fflags_w),
                .fp_fflags_we    (fp_fflags_we_w),
                .csr_rdata       (csr_rdata_w),
                .mepc_out        (mepc_out_w),
                .mtvec_out       (mtvec_out_w),
                .fcsr_rm         (fcsr_rm_w),
                .mstatus_fs_out  (mstatus_fs_w)
            );
        end else begin : gen_no_csr
            assign csr_rdata_w = 32'b0;
            assign mepc_out_w  = 32'b0;
            assign mtvec_out_w = 32'b0;
            assign fcsr_rm_w   = 3'b000;
            assign mstatus_fs_w = 2'b00;
        end
    endgenerate

    // Floating-Point Register File and ALU
    generate
        if (EXTENSION_F || EXTENSION_D) begin : gen_fp
            fpr #(
                .EXTENSION_F(EXTENSION_F),
                .EXTENSION_D(EXTENSION_D)
            ) u_fpr (
                .clk        (global_gated_clk),
                .rst_n      (rst_n),
                .we         (fp_we_w),
                .rd_addr    (instruction_w[11:7]),
                .rs1_addr   (instruction_w[19:15]),
                .rs2_addr   (instruction_w[24:20]),
                .rs3_addr   (instruction_w[31:27]),
                .fmt        (fmt_w),
                .write_data (fp_wb_data_w),
                .rs1_data   (fp_rs1_data_w),
                .rs2_data   (fp_rs2_data_w),
                .rs3_data   (fp_rs3_data_w)
            );

            fp_alu u_fp_alu (
                .fp_alu_op  (fp_alu_op_w),
                .fmt        (fmt_w),
                .rm         (rm_w),
                .fcsr_rm    (fcsr_rm_w),
                .rs1_data   (fp_rs1_data_w),
                .rs2_data   (fp_rs2_data_w),
                .rs3_data   (fp_rs3_data_w),
                .int_rs1_data (rs1_data_w),
                .int_to_fp  (int_to_fp_w),
                .fp_to_int  (fp_to_int_w),
                .rs2_addr   (instruction_w[24:20]),
                .result     (fp_alu_result_w),
                .fflags     (fp_fflags_w)
            );
        end else begin : gen_no_fp
            assign fp_rs1_data_w   = {FLEN{1'b0}};
            assign fp_rs2_data_w   = {FLEN{1'b0}};
            assign fp_rs3_data_w   = {FLEN{1'b0}};
            assign fp_alu_result_w = {FLEN{1'b0}};
            assign fp_fflags_w     = 5'b0;
        end
    endgenerate

endmodule
