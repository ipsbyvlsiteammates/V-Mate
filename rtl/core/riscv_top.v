`timescale 1ns/1ps
//============================================================================
// Module: riscv_top
// Description: 5-stage pipelined RISC-V RV32I processor top-level module
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

    localparam FLEN = EXTENSION_D ? 64 : (EXTENSION_F ? 32 : 32);

    wire global_gated_clk;
    icg u_global_icg (
        .clk(clk),
        .en(clk_en),
        .gated_clk(global_gated_clk)
    );

    //========================================================================
    // Hazard Unit Wires
    //========================================================================
    wire stall_pc;
    wire stall_if_id;
    wire flush_if_id;
    wire flush_id_ex;
    wire flush_ex_mem;
    wire flush_mem_wb;

    //========================================================================
    // IF Stage Wires
    //========================================================================
    wire [31:0] pc_if;
    wire [31:0] pc_plus4_if = pc_if + 32'd4;
    wire [31:0] instruction_if;

    //========================================================================
    // ID Stage Wires
    //========================================================================
    wire [31:0] pc_id;
    wire [31:0] instruction_id;
    wire [31:0] pc_plus4_id;

    wire [31:0] rs1_data_id;
    wire [31:0] rs2_data_id;
    wire [FLEN-1:0] fp_rs1_data_id;
    wire [FLEN-1:0] fp_rs2_data_id;
    wire [FLEN-1:0] fp_rs3_data_id;

    wire [31:0] imm_out_id;
    wire [2:0] imm_sel_id;

    wire reg_write_id;
    wire [1:0] result_sel_id;
    wire mem_write_id;
    wire mem_read_id;
    wire alu_src_id;
    wire pc_src_auipc_id;
    wire branch_id;
    wire jump_id;
    wire [4:0] alu_op_id;
    wire [2:0] mem_size_id;
    wire amo_en_id;
    wire [4:0] amo_op_id;
    wire csr_write_id;
    wire [1:0] csr_op_id;
    wire csr_imm_sel_id;
    wire exception_id;
    wire [3:0] exception_cause_id;
    wire mret_exec_id;
    wire fp_we_id;
    wire [4:0] fp_alu_op_id;
    wire [1:0] fmt_id;
    wire [2:0] rm_id;
    wire int_to_fp_id;
    wire fp_to_int_id;
    wire fp_mem_read_id;
    wire fp_mem_write_id;
    wire fp_fflags_we_id;
    wire [1:0] mstatus_fs_id;

    //========================================================================
    // EX Stage Wires
    //========================================================================
    wire [31:0] pc_ex;
    wire [31:0] pc_plus4_ex;
    wire [31:0] instruction_ex;
    wire [31:0] rs1_data_ex;
    wire [31:0] rs2_data_ex;
    wire [FLEN-1:0] fp_rs1_data_ex;
    wire [FLEN-1:0] fp_rs2_data_ex;
    wire [FLEN-1:0] fp_rs3_data_ex;
    wire [31:0] imm_out_ex;
    wire alu_src_ex;
    wire pc_src_auipc_ex;
    wire [4:0] alu_op_ex;
    wire branch_ex;
    wire jump_ex;
    wire [4:0] fp_alu_op_ex;
    wire [1:0] fmt_ex;
    wire [2:0] rm_ex;
    wire int_to_fp_ex;
    wire fp_to_int_ex;
    wire csr_imm_sel_ex;
    wire mem_write_ex;
    wire mem_read_ex;
    wire [2:0] mem_size_ex;
    wire csr_write_ex;
    wire [1:0] csr_op_ex;
    wire exception_ex;
    wire [3:0] exception_cause_ex;
    wire mret_exec_ex;
    wire amo_en_ex;
    wire [4:0] amo_op_ex;
    wire fp_mem_read_ex;
    wire fp_mem_write_ex;
    wire fp_fflags_we_ex;
    wire reg_write_ex;
    wire [1:0] result_sel_ex;
    wire fp_we_ex;

    wire [31:0] alu_result_ex;
    wire zero_flag_ex;
    wire [FLEN-1:0] fp_alu_result_ex;
    wire [4:0] fp_fflags_ex;

    wire [1:0] forward_a;
    wire [1:0] forward_b;
    wire [1:0] forward_fp_a;
    wire [1:0] forward_fp_b;
    wire [1:0] forward_fp_c;

    //========================================================================
    // MEM Stage Wires
    //========================================================================
    wire [31:0] pc_mem;
    wire [31:0] pc_plus4_mem;
    wire [31:0] instruction_mem;
    wire [31:0] alu_result_mem;
    wire [31:0] rs2_data_mem;
    wire [FLEN-1:0] fp_rs2_data_mem;
    wire [FLEN-1:0] fp_alu_result_mem;
    wire [4:0] fp_fflags_mem;
    wire [31:0] csr_wdata_mem;
    wire mem_write_mem;
    wire mem_read_mem;
    wire [2:0] mem_size_mem;
    wire csr_write_mem;
    wire [1:0] csr_op_mem;
    wire exception_mem;
    wire [3:0] exception_cause_mem;
    wire mret_exec_mem;
    wire amo_en_mem;
    wire [4:0] amo_op_mem;
    wire fp_mem_read_mem;
    wire fp_mem_write_mem;
    wire fp_fflags_we_mem;
    wire reg_write_mem;
    wire [1:0] result_sel_mem;
    wire fp_we_mem;
    wire fp_to_int_mem;
    wire [1:0] fmt_mem;

    wire [(EXTENSION_D ? 64 : 32)-1:0] dmem_rdata_mem;
    wire [31:0] csr_rdata_mem;
    wire [31:0] mepc_out_mem;
    wire [31:0] mtvec_out_mem;
    wire [2:0] fcsr_rm_mem;
    wire [1:0] mstatus_fs_mem;

    //========================================================================
    // WB Stage Wires
    //========================================================================
    wire [31:0] pc_plus4_wb;
    wire [31:0] instruction_wb;
    wire [31:0] alu_result_wb;
    wire [FLEN-1:0] dmem_rdata_wb;
    wire [31:0] csr_rdata_wb;
    wire [FLEN-1:0] fp_alu_result_wb;
    wire reg_write_wb;
    wire [1:0] result_sel_wb;
    wire fp_we_wb;
    wire fp_to_int_wb;
    wire fp_mem_read_wb;
    wire [2:0] mem_size_wb;
    wire [1:0] fmt_wb;
    wire [31:0] wb_data_wb;
    wire [63:0] load_fp_data_wb;
    wire [FLEN-1:0] fp_wb_data_wb;

    //========================================================================
    // EX Stage Logic (from prompt)
    //========================================================================
    reg branch_taken_r;
    always @(*) begin
        case (instruction_ex[14:12])
            3'b000:  branch_taken_r = zero_flag_ex;          // BEQ
            3'b001:  branch_taken_r = ~zero_flag_ex;         // BNE
            3'b100:  branch_taken_r = alu_result_ex[0];      // BLT
            3'b101:  branch_taken_r = ~alu_result_ex[0];     // BGE
            3'b110:  branch_taken_r = alu_result_ex[0];      // BLTU
            3'b111:  branch_taken_r = ~alu_result_ex[0];     // BGEU
            default: branch_taken_r = 1'b0;
        endcase
    end
    wire branch_taken_ex = branch_taken_r;
    wire [31:0] branch_target_ex = pc_ex + imm_out_ex;
    wire [31:0] jalr_target_ex = alu_result_ex & ~32'd1;
    wire is_jalr_ex = (instruction_ex[6:0] == 7'b1100111);
    wire [31:0] pc_target_ex = is_jalr_ex ? jalr_target_ex : branch_target_ex;
    wire pc_sel_ex = (branch_ex & branch_taken_ex) | jump_ex;

    // Forwarding muxes in EX stage
    wire [31:0] forward_data_mem = fp_to_int_mem ? fp_alu_result_mem[31:0] :
                                  (result_sel_mem == 2'b00) ? alu_result_mem :
                                  (result_sel_mem == 2'b10) ? pc_plus4_mem :
                                  (result_sel_mem == 2'b11) ? csr_rdata_mem :
                                  alu_result_mem;

    // Forwarding muxes in EX stage
    wire [31:0] forwarded_rs1_data_ex = (forward_a == 2'b10) ? forward_data_mem : (forward_a == 2'b01) ? wb_data_wb : rs1_data_ex;
    wire [31:0] forwarded_rs2_data_ex = (forward_b == 2'b10) ? forward_data_mem : (forward_b == 2'b01) ? wb_data_wb : rs2_data_ex;
    wire [FLEN-1:0] forwarded_fp_rs1_data_ex = (forward_fp_a == 2'b10) ? fp_alu_result_mem : (forward_fp_a == 2'b01) ? fp_wb_data_wb : fp_rs1_data_ex;
    wire [FLEN-1:0] forwarded_fp_rs2_data_ex = (forward_fp_b == 2'b10) ? fp_alu_result_mem : (forward_fp_b == 2'b01) ? fp_wb_data_wb : fp_rs2_data_ex;
    wire [FLEN-1:0] forwarded_fp_rs3_data_ex = (forward_fp_c == 2'b10) ? fp_alu_result_mem : (forward_fp_c == 2'b01) ? fp_wb_data_wb : fp_rs3_data_ex;

    wire [31:0] alu_operand_a_ex = pc_src_auipc_ex ? pc_ex : forwarded_rs1_data_ex;
    wire [31:0] alu_operand_b_ex = alu_src_ex ? imm_out_ex : forwarded_rs2_data_ex;
    wire [31:0] csr_wdata_ex = csr_imm_sel_ex ? imm_out_ex : forwarded_rs1_data_ex;

    //========================================================================
    // WB Stage Logic (from prompt)
    //========================================================================
    assign wb_data_wb = fp_to_int_wb ? fp_alu_result_wb[31:0] :
                       (result_sel_wb == 2'b00) ? alu_result_wb :
                       (result_sel_wb == 2'b01) ? dmem_rdata_wb[31:0] :
                       (result_sel_wb == 2'b10) ? pc_plus4_wb :
                       (result_sel_wb == 2'b11) ? csr_rdata_wb :
                                                 32'b0;
    assign load_fp_data_wb = (mem_size_wb == 3'b010) ? {32'hFFFFFFFF, dmem_rdata_wb[31:0]} : dmem_rdata_wb;
    assign fp_wb_data_wb = fp_mem_read_wb ? load_fp_data_wb[FLEN-1:0] : fp_alu_result_wb;

    //========================================================================
    // MEM Stage Logic (from prompt)
    //========================================================================
    wire [63:0] rs2_data_ext_mem = {32'b0, rs2_data_mem};
    wire [(EXTENSION_D ? 64 : 32)-1:0] dmem_write_data_mem = fp_mem_write_mem ? fp_rs2_data_mem : rs2_data_ext_mem[(EXTENSION_D ? 64 : 32)-1:0];

    //========================================================================
    // IF Stage Instantiations
    //========================================================================
    pc u_pc (
        .clk       (global_gated_clk),
        .rst_n     (rst_n),
        .stall     (stall_pc),
        .pc_sel    (pc_sel_ex),
        .pc_target (pc_target_ex),
        .exception (exception_mem),
        .mtvec     (mtvec_out_mem),
        .mret_exec (mret_exec_mem),
        .mepc      (mepc_out_mem),
        .pc_out    (pc_if)
    );

    imem u_imem (
        .addr        (pc_if),
        .instruction (instruction_if)
    );

    //========================================================================
    // IF/ID Pipeline Register
    //========================================================================
    pipe_if_id u_pipe_if_id (
        .clk            (global_gated_clk),
        .rst_n          (rst_n),
        .stall          (stall_if_id),
        .flush          (flush_if_id),
        .pc_if          (pc_if),
        .instruction_if (instruction_if),
        .pc_plus4_if    (pc_plus4_if),
        .pc_id          (pc_id),
        .instruction_id (instruction_id),
        .pc_plus4_id    (pc_plus4_id)
    );

    //========================================================================
    // ID Stage Instantiations
    //========================================================================
    register_file u_register_file (
        .clk        (global_gated_clk),
        .rst_n      (rst_n),
        .rs1_addr   (instruction_id[19:15]),
        .rs2_addr   (instruction_id[24:20]),
        .rd_addr    (instruction_wb[11:7]),
        .rd_data    (wb_data_wb),
        .we         (reg_write_wb),
        .rs1_data   (rs1_data_id),
        .rs2_data   (rs2_data_id)
    );

    imm_gen u_imm_gen (
        .instruction (instruction_id),
        .imm_sel     (imm_sel_id),
        .imm_out     (imm_out_id)
    );

    control_unit #(
        .PRIVILEGED(PRIVILEGED),
        .EXTENSION_M(EXTENSION_M),
        .EXTENSION_A(EXTENSION_A),
        .EXTENSION_F(EXTENSION_F),
        .EXTENSION_D(EXTENSION_D)
    ) u_control_unit (
        .opcode          (instruction_id[6:0]),
        .funct3          (instruction_id[14:12]),
        .funct7          (instruction_id[31:25]),
        .rs1_addr        (instruction_id[19:15]),
        .rs2_addr        (instruction_id[24:20]),
        .rd_addr         (instruction_id[11:7]),
        .mstatus_fs      (mstatus_fs_mem),
        .reg_write       (reg_write_id),
        .result_sel      (result_sel_id),
        .mem_write       (mem_write_id),
        .mem_read        (mem_read_id),
        .alu_src         (alu_src_id),
        .pc_src_auipc    (pc_src_auipc_id),
        .imm_sel         (imm_sel_id),
        .branch          (branch_id),
        .jump            (jump_id),
        .alu_op          (alu_op_id),
        .mem_size        (mem_size_id),
        .amo_en          (amo_en_id),
        .amo_op          (amo_op_id),
        .csr_write       (csr_write_id),
        .csr_op          (csr_op_id),
        .csr_imm_sel     (csr_imm_sel_id),
        .exception       (exception_id),
        .exception_cause (exception_cause_id),
        .mret_exec       (mret_exec_id),
        .fp_we           (fp_we_id),
        .fp_alu_op       (fp_alu_op_id),
        .fmt             (fmt_id),
        .rm              (rm_id),
        .int_to_fp       (int_to_fp_id),
        .fp_to_int       (fp_to_int_id),
        .fp_mem_read     (fp_mem_read_id),
        .fp_mem_write    (fp_mem_write_id),
        .fp_fflags_we    (fp_fflags_we_id)
    );

    generate
        if (EXTENSION_F || EXTENSION_D) begin : gen_fpr
            fpr #(
                .EXTENSION_F(EXTENSION_F),
                .EXTENSION_D(EXTENSION_D)
            ) u_fpr (
                .clk        (global_gated_clk),
                .rst_n      (rst_n),
                .we         (fp_we_wb),
                .rd_addr    (instruction_wb[11:7]),
                .rs1_addr   (instruction_id[19:15]),
                .rs2_addr   (instruction_id[24:20]),
                .rs3_addr   (instruction_id[31:27]),
                .fmt        (fmt_id),
                .write_data (fp_wb_data_wb),
                .rs1_data   (fp_rs1_data_id),
                .rs2_data   (fp_rs2_data_id),
                .rs3_data   (fp_rs3_data_id)
            );
        end else begin : gen_no_fpr
            assign fp_rs1_data_id = {FLEN{1'b0}};
            assign fp_rs2_data_id = {FLEN{1'b0}};
            assign fp_rs3_data_id = {FLEN{1'b0}};
        end
    endgenerate

    //========================================================================
    // ID/EX Pipeline Register
    //========================================================================
    pipe_id_ex #(
        .FLEN(FLEN)
    ) u_pipe_id_ex (
        .clk                (global_gated_clk),
        .rst_n              (rst_n),
        .stall              (1'b0),
        .flush              (flush_id_ex),
        .pc_id              (pc_id),
        .pc_plus4_id        (pc_plus4_id),
        .instruction_id     (instruction_id),
        .rs1_data_id        (rs1_data_id),
        .rs2_data_id        (rs2_data_id),
        .fp_rs1_data_id     (fp_rs1_data_id),
        .fp_rs2_data_id     (fp_rs2_data_id),
        .fp_rs3_data_id     (fp_rs3_data_id),
        .imm_out_id         (imm_out_id),
        .alu_src_id         (alu_src_id),
        .pc_src_auipc_id    (pc_src_auipc_id),
        .alu_op_id          (alu_op_id),
        .branch_id          (branch_id),
        .jump_id            (jump_id),
        .fp_alu_op_id       (fp_alu_op_id),
        .fmt_id             (fmt_id),
        .rm_id              (rm_id),
        .int_to_fp_id       (int_to_fp_id),
        .fp_to_int_id       (fp_to_int_id),
        .csr_imm_sel_id     (csr_imm_sel_id),
        .mem_write_id       (mem_write_id),
        .mem_read_id        (mem_read_id),
        .mem_size_id        (mem_size_id),
        .csr_write_id       (csr_write_id),
        .csr_op_id          (csr_op_id),
        .exception_id       (exception_id),
        .exception_cause_id (exception_cause_id),
        .mret_exec_id       (mret_exec_id),
        .amo_en_id          (amo_en_id),
        .amo_op_id          (amo_op_id),
        .fp_mem_read_id     (fp_mem_read_id),
        .fp_mem_write_id    (fp_mem_write_id),
        .fp_fflags_we_id    (fp_fflags_we_id),
        .reg_write_id       (reg_write_id),
        .result_sel_id      (result_sel_id),
        .fp_we_id           (fp_we_id),
        
        .pc_ex              (pc_ex),
        .pc_plus4_ex        (pc_plus4_ex),
        .instruction_ex     (instruction_ex),
        .rs1_data_ex        (rs1_data_ex),
        .rs2_data_ex        (rs2_data_ex),
        .fp_rs1_data_ex     (fp_rs1_data_ex),
        .fp_rs2_data_ex     (fp_rs2_data_ex),
        .fp_rs3_data_ex     (fp_rs3_data_ex),
        .imm_out_ex         (imm_out_ex),
        .alu_src_ex         (alu_src_ex),
        .pc_src_auipc_ex    (pc_src_auipc_ex),
        .alu_op_ex          (alu_op_ex),
        .branch_ex          (branch_ex),
        .jump_ex            (jump_ex),
        .fp_alu_op_ex       (fp_alu_op_ex),
        .fmt_ex             (fmt_ex),
        .rm_ex              (rm_ex),
        .int_to_fp_ex       (int_to_fp_ex),
        .fp_to_int_ex       (fp_to_int_ex),
        .csr_imm_sel_ex     (csr_imm_sel_ex),
        .mem_write_ex       (mem_write_ex),
        .mem_read_ex        (mem_read_ex),
        .mem_size_ex        (mem_size_ex),
        .csr_write_ex       (csr_write_ex),
        .csr_op_ex          (csr_op_ex),
        .exception_ex       (exception_ex),
        .exception_cause_ex (exception_cause_ex),
        .mret_exec_ex       (mret_exec_ex),
        .amo_en_ex          (amo_en_ex),
        .amo_op_ex          (amo_op_ex),
        .fp_mem_read_ex     (fp_mem_read_ex),
        .fp_mem_write_ex    (fp_mem_write_ex),
        .fp_fflags_we_ex    (fp_fflags_we_ex),
        .reg_write_ex       (reg_write_ex),
        .result_sel_ex      (result_sel_ex),
        .fp_we_ex           (fp_we_ex)
    );

    //========================================================================
    // EX Stage Instantiations
    //========================================================================
    alu #(
        .EXTENSION_M(EXTENSION_M)
    ) u_alu (
        .operand_a  (alu_operand_a_ex),
        .operand_b  (alu_operand_b_ex),
        .alu_op     (alu_op_ex),
        .alu_result (alu_result_ex),
        .zero_flag  (zero_flag_ex)
    );

    generate
        if (EXTENSION_F || EXTENSION_D) begin : gen_fp_alu
            fp_alu u_fp_alu (
                .fp_alu_op    (fp_alu_op_ex),
                .fmt          (fmt_ex),
                .rm           (rm_ex),
                .fcsr_rm      (fcsr_rm_mem),
                .rs1_data     (forwarded_fp_rs1_data_ex),
                .rs2_data     (forwarded_fp_rs2_data_ex),
                .rs3_data     (forwarded_fp_rs3_data_ex),
                .int_rs1_data (forwarded_rs1_data_ex),
                .int_to_fp    (int_to_fp_ex),
                .fp_to_int    (fp_to_int_ex),
                .rs2_addr     (instruction_ex[24:20]),
                .result       (fp_alu_result_ex),
                .fflags       (fp_fflags_ex)
            );
        end else begin : gen_no_fp_alu
            assign fp_alu_result_ex = {FLEN{1'b0}};
            assign fp_fflags_ex = 5'b0;
        end
    endgenerate

    forwarding_unit #(
        .FLEN(FLEN)
    ) u_forwarding_unit (
        .rs1_addr_ex   (instruction_ex[19:15]),
        .rs2_addr_ex   (instruction_ex[24:20]),
        .rs3_addr_ex   (instruction_ex[31:27]),
        .rd_addr_mem   (instruction_mem[11:7]),
        .reg_write_mem (reg_write_mem),
        .fp_we_mem     (fp_we_mem),
        .rd_addr_wb    (instruction_wb[11:7]),
        .reg_write_wb  (reg_write_wb),
        .fp_we_wb      (fp_we_wb),
        .forward_a     (forward_a),
        .forward_b     (forward_b),
        .forward_fp_a  (forward_fp_a),
        .forward_fp_b  (forward_fp_b),
        .forward_fp_c  (forward_fp_c)
    );

    //========================================================================
    // EX/MEM Pipeline Register
    //========================================================================
    pipe_ex_mem #(
        .FLEN(FLEN)
    ) u_pipe_ex_mem (
        .clk                 (global_gated_clk),
        .rst_n               (rst_n),
        .stall               (1'b0),
        .flush               (flush_ex_mem),
        .pc_ex               (pc_ex),
        .pc_plus4_ex         (pc_plus4_ex),
        .instruction_ex      (instruction_ex),
        .alu_result_ex       (alu_result_ex),
        .rs2_data_ex         (forwarded_rs2_data_ex),
        .fp_rs2_data_ex      (forwarded_fp_rs2_data_ex),
        .fp_alu_result_ex    (fp_alu_result_ex),
        .fp_fflags_ex        (fp_fflags_ex),
        .csr_wdata_ex        (csr_wdata_ex),
        .mem_write_ex        (mem_write_ex),
        .mem_read_ex         (mem_read_ex),
        .mem_size_ex         (mem_size_ex),
        .csr_write_ex        (csr_write_ex),
        .csr_op_ex           (csr_op_ex),
        .exception_ex        (exception_ex),
        .exception_cause_ex  (exception_cause_ex),
        .mret_exec_ex        (mret_exec_ex),
        .amo_en_ex           (amo_en_ex),
        .amo_op_ex           (amo_op_ex),
        .fp_mem_read_ex      (fp_mem_read_ex),
        .fp_mem_write_ex     (fp_mem_write_ex),
        .fp_fflags_we_ex     (fp_fflags_we_ex),
        .reg_write_ex        (reg_write_ex),
        .result_sel_ex       (result_sel_ex),
        .fp_we_ex            (fp_we_ex),
        .fp_to_int_ex        (fp_to_int_ex),
        .fmt_ex              (fmt_ex),
        
        .pc_mem              (pc_mem),
        .pc_plus4_mem        (pc_plus4_mem),
        .instruction_mem     (instruction_mem),
        .alu_result_mem      (alu_result_mem),
        .rs2_data_mem        (rs2_data_mem),
        .fp_rs2_data_mem     (fp_rs2_data_mem),
        .fp_alu_result_mem   (fp_alu_result_mem),
        .fp_fflags_mem       (fp_fflags_mem),
        .csr_wdata_mem       (csr_wdata_mem),
        .mem_write_mem       (mem_write_mem),
        .mem_read_mem        (mem_read_mem),
        .mem_size_mem        (mem_size_mem),
        .csr_write_mem       (csr_write_mem),
        .csr_op_mem          (csr_op_mem),
        .exception_mem       (exception_mem),
        .exception_cause_mem (exception_cause_mem),
        .mret_exec_mem       (mret_exec_mem),
        .amo_en_mem          (amo_en_mem),
        .amo_op_mem          (amo_op_mem),
        .fp_mem_read_mem     (fp_mem_read_mem),
        .fp_mem_write_mem    (fp_mem_write_mem),
        .fp_fflags_we_mem    (fp_fflags_we_mem),
        .reg_write_mem       (reg_write_mem),
        .result_sel_mem      (result_sel_mem),
        .fp_we_mem           (fp_we_mem),
        .fp_to_int_mem       (fp_to_int_mem),
        .fmt_mem             (fmt_mem)
    );

    //========================================================================
    // MEM Stage Instantiations
    //========================================================================
    dmem #(
        .EXTENSION_A(EXTENSION_A)
    ) u_dmem (
        .clk        (global_gated_clk),
        .rst_n      (rst_n),
        .mem_write  (mem_write_mem | fp_mem_write_mem),
        .mem_read   (mem_read_mem | fp_mem_read_mem),
        .amo_en     (amo_en_mem),
        .amo_op     (amo_op_mem),
        .addr       (alu_result_mem),
        .write_data (dmem_write_data_mem),
        .mem_size   (mem_size_mem),
        .read_data  (dmem_rdata_mem)
    );

    generate
        if (PRIVILEGED) begin : gen_csr
            csr_file #(
                .EXTENSION_F(EXTENSION_F)
            ) u_csr_file (
                .clk             (global_gated_clk),
                .rst_n           (rst_n),
                .csr_addr        (instruction_mem[31:20]),
                .csr_wdata       (csr_wdata_mem),
                .csr_op          (csr_op_mem),
                .csr_write       (csr_write_mem),
                .exception       (exception_mem),
                .exception_cause (exception_cause_mem),
                .exception_pc    (pc_mem),
                .exception_addr  (instruction_mem),
                .mret_exec       (mret_exec_mem),
                .fp_fflags_update(fp_fflags_mem),
                .fp_fflags_we    (fp_fflags_we_mem),
                .csr_rdata       (csr_rdata_mem),
                .mepc_out        (mepc_out_mem),
                .mtvec_out       (mtvec_out_mem),
                .fcsr_rm         (fcsr_rm_mem),
                .mstatus_fs_out  (mstatus_fs_mem)
            );
        end else begin : gen_no_csr
            assign csr_rdata_mem = 32'b0;
            assign mepc_out_mem  = 32'b0;
            assign mtvec_out_mem = 32'b0;
            assign fcsr_rm_mem   = 3'b000;
            assign mstatus_fs_mem = 2'b00;
        end
    endgenerate

    //========================================================================
    // MEM/WB Pipeline Register
    //========================================================================
    pipe_mem_wb #(
        .FLEN(FLEN)
    ) u_pipe_mem_wb (
        .clk               (global_gated_clk),
        .rst_n             (rst_n),
        .stall             (1'b0),
        .flush             (flush_mem_wb),
        .pc_plus4_mem      (pc_plus4_mem),
        .instruction_mem   (instruction_mem),
        .alu_result_mem    (alu_result_mem),
        .dmem_rdata_mem    (dmem_rdata_mem),
        .csr_rdata_mem     (csr_rdata_mem),
        .fp_alu_result_mem (fp_alu_result_mem),
        .reg_write_mem     (reg_write_mem),
        .result_sel_mem    (result_sel_mem),
        .fp_we_mem         (fp_we_mem),
        .fp_to_int_mem     (fp_to_int_mem),
        .fp_mem_read_mem   (fp_mem_read_mem),
        .mem_size_mem      (mem_size_mem),
        .fmt_mem           (fmt_mem),
        
        .pc_plus4_wb       (pc_plus4_wb),
        .instruction_wb    (instruction_wb),
        .alu_result_wb     (alu_result_wb),
        .dmem_rdata_wb     (dmem_rdata_wb),
        .csr_rdata_wb      (csr_rdata_wb),
        .fp_alu_result_wb  (fp_alu_result_wb),
        .reg_write_wb      (reg_write_wb),
        .result_sel_wb     (result_sel_wb),
        .fp_we_wb          (fp_we_wb),
        .fp_to_int_wb      (fp_to_int_wb),
        .fp_mem_read_wb    (fp_mem_read_wb),
        .mem_size_wb       (mem_size_wb),
        .fmt_wb            (fmt_wb)
    );

    //========================================================================
    // Hazard Unit
    //========================================================================
    hazard_unit u_hazard_unit (
        .rs1_addr_id    (instruction_id[19:15]),
        .rs2_addr_id    (instruction_id[24:20]),
        .rs3_addr_id    (instruction_id[31:27]),
        .rd_addr_ex     (instruction_ex[11:7]),
        .mem_read_ex    (mem_read_ex),
        .fp_mem_read_ex (fp_mem_read_ex),
        .pc_sel_ex      (pc_sel_ex),
        .exception_mem  (exception_mem),
        .mret_exec_mem  (mret_exec_mem),
        .stall_pc       (stall_pc),
        .stall_if_id    (stall_if_id),
        .flush_if_id    (flush_if_id),
        .flush_id_ex    (flush_id_ex),
        .flush_ex_mem   (flush_ex_mem),
        .flush_mem_wb   (flush_mem_wb)
    );

endmodule
