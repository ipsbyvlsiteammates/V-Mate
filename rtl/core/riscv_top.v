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
    parameter EXTENSION_D = 1,
    parameter RESET_VECTOR = 32'h80000000
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
    wire stall_pc_hz;
    wire stall_if_id_hz;
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
    // OoO Interconnect Wires & Instantiations
    //========================================================================
    wire ooo_en;
    wire [3:0] rob_idx_disp, rs1_rob_idx, rs2_rob_idx, rs3_rob_idx;
    wire rob_full, iq_full, rs1_in_rob, rs2_in_rob, rs3_in_rob;
    wire commit_en, commit_dest_type, commit_exception, commit_is_store, commit_is_branch, commit_branch_mispredicted;
    wire [4:0] commit_dest_reg;
    wire [63:0] commit_result;
    wire [31:0] commit_pc, commit_branch_target, commit_instruction;
    wire [3:0] commit_exception_cause;


    wire final_exception;
    wire [3:0] final_exception_cause;
    wire [31:0] final_exception_pc;
    wire [31:0] final_exception_addr;
    wire final_pc_sel;
    wire [31:0] final_pc_target;
    wire final_flush;
    wire final_mret_exec;

    wire [3:0] commit_rob_idx;
    wire [3:0] rob_head;
    wire [3:0] rob_idx_disp;

    wire issue_en;
    wire [3:0] issue_rob_idx;
    wire [9:0] issue_op_type;
    wire [4:0] issue_alu_op;
    wire [31:0] issue_pc, issue_imm;
    wire [63:0] issue_rs1_data, issue_rs2_data, issue_rs3_data;

    wire cdb_en;
    wire [3:0] cdb_rob_idx;
    wire [63:0] cdb_data;

    
    wire valid_inst_id_no_stall = (instruction_id != 32'b0) && !flush_id_ex;
    wire is_load_id = (instruction_id[6:0] == 7'b0000011);
    wire is_store_id = (instruction_id[6:0] == 7'b0100011);
    wire is_fp_load_id = (instruction_id[6:0] == 7'b0000111);
    wire is_fp_store_id = (instruction_id[6:0] == 7'b0100111);
    wire is_amo_id = (instruction_id[6:0] == 7'b0101111);
    wire is_system_id = (instruction_id[6:0] == 7'b1110011);
    wire is_fence_id = (instruction_id[6:0] == 7'b0001111);
    wire is_serialization_req = is_load_id | is_store_id | is_fp_load_id | is_fp_store_id | is_amo_id | is_system_id | is_fence_id | exception_id;
    
    wire rob_empty = (rob_head == rob_idx_disp) && !rob_full;
    wire stall_dispatch = ooo_en & ( (is_serialization_req & !rob_empty) | rob_full | iq_full ) & valid_inst_id_no_stall;
    
    assign stall_pc = stall_pc_hz | stall_dispatch;
    assign stall_if_id = stall_if_id_hz | stall_dispatch;

    wire valid_inst_id = valid_inst_id_no_stall && !stall_if_id;
    wire dispatch_en = ooo_en & valid_inst_id;

    

    // OoO Branch Evaluation
    wire ooo_branch_mispredicted = 1'b0;
    wire [31:0] ooo_branch_target = 32'b0;

    reg exception_wb;
    reg [3:0] exception_cause_wb;

    wire cdb_exception;
    wire [3:0] cdb_exception_cause;
    wire cdb_pc_sel;
    wire [31:0] cdb_pc_target;
    reg pc_sel_mem, pc_sel_wb;
    reg [31:0] pc_target_mem, pc_target_wb;
    wire [31:0] commit_instruction;
        wire [31:0] cdb_instruction;
    rob #(.ROB_DEPTH(16), .ROB_IDX_W(4)) u_rob (
        .clk(global_gated_clk), .rst_n(rst_n), .ooo_en(ooo_en),
        .dispatch_en(dispatch_en), .dest_reg(instruction_id[11:7]), .dest_type(fp_we_id), .pc(pc_id), .is_store(mem_write_id | is_fp_store_id), .is_branch(branch_id | jump_id), .instruction(instruction_id), .dispatch_exception(exception_id), .dispatch_exception_cause(exception_cause_id), .rob_idx(rob_idx_disp), .rob_full(rob_full), .rob_head(rob_head),
        .complete_en(cdb_en), .complete_idx(cdb_rob_idx), .complete_instruction(cdb_instruction), .result(cdb_data), .exception(cdb_exception), .exception_cause(cdb_exception_cause), .branch_mispredicted(cdb_pc_sel), .branch_target(cdb_pc_target),
        .commit_en(commit_en), .commit_dest_reg(commit_dest_reg), .commit_dest_type(commit_dest_type), .commit_result(commit_result), .commit_pc(commit_pc), .commit_exception(commit_exception), .commit_exception_cause(commit_exception_cause), .commit_is_store(commit_is_store), .commit_is_branch(commit_is_branch), .commit_instruction(commit_instruction), .commit_branch_mispredicted(commit_branch_mispredicted), .commit_branch_target(commit_branch_target), .commit_rob_idx(commit_rob_idx), .commit_ack(commit_en), .flush(final_flush)
    );

    rat u_rat (
        .clk(global_gated_clk), .rst_n(rst_n), .ooo_en(ooo_en),
        .rs1(instruction_id[19:15]), .rs2(instruction_id[24:20]), .rs3(instruction_id[31:27]), .rs1_type(1'b0), .rs2_type(1'b0), .rs3_type(1'b1),
        .rs1_rob_idx(rs1_rob_idx), .rs1_in_rob(rs1_in_rob), .rs2_rob_idx(rs2_rob_idx), .rs2_in_rob(rs2_in_rob), .rs3_rob_idx(rs3_rob_idx), .rs3_in_rob(rs3_in_rob),
        .dispatch_en(dispatch_en), .dest_reg(instruction_id[11:7]), .dest_type(fp_we_id), .rob_idx(rob_idx_disp),
        .commit_en(commit_en), .commit_dest_reg(commit_dest_reg), .commit_dest_type(commit_dest_type), .commit_rob_idx(commit_rob_idx),
        .flush(final_flush)
    );

    iq #(.IQ_DEPTH(8)) u_iq (
        .clk(global_gated_clk), .rst_n(rst_n), .ooo_en(ooo_en), .flush(final_flush),
        .dispatch_en(dispatch_en), .rob_idx(rob_idx_disp), .op_type({instruction_id[31:25], instruction_id[14:12]}), .alu_op(alu_op_id), .pc(pc_id), .imm(imm_out_id),
        .rs1_wait(1'b0), .rs1_rob_idx(rs1_rob_idx), .rs1_data({32'b0, rs1_data_id}),
        .rs2_wait(1'b0), .rs2_rob_idx(rs2_rob_idx), .rs2_data({32'b0, rs2_data_id}),
        .rs3_wait(1'b0), .rs3_rob_idx(rs3_rob_idx), .rs3_data( FLEN == 64 ? fp_rs3_data_id : {32'b0, fp_rs3_data_id[31:0]} ),
        .iq_full(iq_full), .rob_head(rob_head),
        .cdb_en(cdb_en), .cdb_rob_idx(cdb_rob_idx), .cdb_data(cdb_data),
        .issue_en(issue_en), .issue_rob_idx(issue_rob_idx), .issue_op_type(issue_op_type), .issue_alu_op(issue_alu_op), .issue_pc(issue_pc), .issue_imm(issue_imm), .issue_rs1_data(issue_rs1_data), .issue_rs2_data(issue_rs2_data), .issue_rs3_data(issue_rs3_data), .issue_ack(issue_en)
    );
    reg rob_reg_write_array [0:15];
    always @(posedge global_gated_clk) begin
        if (dispatch_en) begin
            rob_reg_write_array[rob_idx_disp] <= reg_write_id | fp_we_id;
        end
    end
    wire commit_reg_write = rob_reg_write_array[commit_rob_idx];
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
                                  (result_sel_mem == 2'b01) ? dmem_rdata_mem[31:0] :
                                  (result_sel_mem == 2'b10) ? pc_plus4_mem :
                                  (result_sel_mem == 2'b11) ? csr_rdata_mem :
                                  alu_result_mem;

    // Forwarding muxes in EX stage
    wire commit_fwd_match_rs1 = ooo_en && commit_en && commit_reg_write && !commit_dest_type && (commit_dest_reg == instruction_ex[19:15]) && (commit_dest_reg != 5'b0);
    wire commit_fwd_match_rs2 = ooo_en && commit_en && commit_reg_write && !commit_dest_type && (commit_dest_reg == instruction_ex[24:20]) && (commit_dest_reg != 5'b0);
    wire commit_fwd_match_fp_rs1 = ooo_en && commit_en && commit_reg_write && commit_dest_type && (commit_dest_reg == instruction_ex[19:15]);
    wire commit_fwd_match_fp_rs2 = ooo_en && commit_en && commit_reg_write && commit_dest_type && (commit_dest_reg == instruction_ex[24:20]);
    wire commit_fwd_match_fp_rs3 = ooo_en && commit_en && commit_reg_write && commit_dest_type && (commit_dest_reg == instruction_ex[31:27]);

    wire [31:0] forwarded_rs1_data_ex = (forward_a == 2'b10) ? forward_data_mem : (forward_a == 2'b01) ? wb_data_wb : commit_fwd_match_rs1 ? commit_result[31:0] : rs1_data_ex;
    wire [31:0] forwarded_rs2_data_ex = (forward_b == 2'b10) ? forward_data_mem : (forward_b == 2'b01) ? wb_data_wb : commit_fwd_match_rs2 ? commit_result[31:0] : rs2_data_ex;
    wire [FLEN-1:0] forwarded_fp_rs1_data_ex = (forward_fp_a == 2'b10) ? fp_alu_result_mem : (forward_fp_a == 2'b01) ? fp_wb_data_wb : commit_fwd_match_fp_rs1 ? commit_result[FLEN-1:0] : fp_rs1_data_ex;
    wire [FLEN-1:0] forwarded_fp_rs2_data_ex = (forward_fp_b == 2'b10) ? fp_alu_result_mem : (forward_fp_b == 2'b01) ? fp_wb_data_wb : commit_fwd_match_fp_rs2 ? commit_result[FLEN-1:0] : fp_rs2_data_ex;
    wire [FLEN-1:0] forwarded_fp_rs3_data_ex = (forward_fp_c == 2'b10) ? fp_alu_result_mem : (forward_fp_c == 2'b01) ? fp_wb_data_wb : commit_fwd_match_fp_rs3 ? commit_result[FLEN-1:0] : fp_rs3_data_ex;

    wire [31:0] alu_operand_a_ex = pc_src_auipc_ex ? pc_ex : forwarded_rs1_data_ex;
    wire [31:0] alu_operand_b_ex = alu_src_ex ? imm_out_ex : forwarded_rs2_data_ex;
    wire [31:0] csr_wdata_ex = csr_imm_sel_ex ? imm_out_ex : forwarded_rs1_data_ex;

    //========================================================================
    // WB Stage Logic (from prompt)
    //========================================================================
        wire [31:0] complete_instruction;
    wire [31:0] final_instruction_wb = ooo_en ? cdb_instruction : instruction_wb;
    wire [1:0] final_fmt_wb = ooo_en ? cdb_instruction[26:25] : fmt_wb;
    wire is_single_precision_wb = (final_instruction_wb[6:0] == 7'b1010011 && final_instruction_wb[31:25] == 7'b0100000) ? (final_instruction_wb[24:20] == 5'b00000) : (final_fmt_wb == 2'b00);
    assign wb_data_wb = fp_to_int_wb ? fp_alu_result_wb[31:0] :
                       (result_sel_wb == 2'b00) ? alu_result_wb :
                       (result_sel_wb == 2'b01) ? dmem_rdata_wb[31:0] :
                       (result_sel_wb == 2'b10) ? pc_plus4_wb :
                       (result_sel_wb == 2'b11) ? csr_rdata_wb :
                                                 32'b0;
    assign load_fp_data_wb = (mem_size_wb == 3'b010) ? {32'hFFFFFFFF, dmem_rdata_wb[31:0]} : dmem_rdata_wb;
    wire [FLEN-1:0] nan_boxed_fp_alu_result = (FLEN == 64 && is_single_precision_wb) ? (fp_alu_result_wb | 64'hFFFFFFFF00000000) : fp_alu_result_wb;
    assign fp_wb_data_wb = fp_mem_read_wb ? load_fp_data_wb[FLEN-1:0] : nan_boxed_fp_alu_result;

    //========================================================================
    // MEM Stage Logic (from prompt)
    //========================================================================
    wire [63:0] rs2_data_ext_mem = {32'b0, rs2_data_mem};
    wire [(EXTENSION_D ? 64 : 32)-1:0] dmem_write_data_mem = fp_mem_write_mem ? fp_rs2_data_mem : rs2_data_ext_mem[(EXTENSION_D ? 64 : 32)-1:0];

    //========================================================================
    // IF Stage Instantiations
    //========================================================================
    
    wire [31:0] final_pc_target = pc_target_ex;

    pc #(
        .RESET_VECTOR(RESET_VECTOR)
    ) u_pc (
        .clk       (global_gated_clk),
        .rst_n     (rst_n),
        .stall     (stall_pc),
        .pc_sel    (final_pc_sel),
        .pc_target (final_pc_target),
        .exception (exception_mem),
        .mtvec     (mtvec_out_mem),
        .mret_exec (final_mret_exec),
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
        .flush(flush_if_id | final_flush),
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

    wire final_reg_write = ooo_en ? (commit_en & commit_reg_write & ~commit_dest_type & ~commit_exception) : reg_write_wb;
    wire [4:0] final_rd_addr = ooo_en ? commit_dest_reg : instruction_wb[11:7];
    wire [31:0] final_rd_data = ooo_en ? commit_result[31:0] : wb_data_wb;

    register_file u_register_file (
        .clk        (global_gated_clk),
        .rst_n      (rst_n),
        .rs1_addr   (instruction_id[19:15]),
        .rs2_addr   (instruction_id[24:20]),
        .rd_addr    (final_rd_addr),
        .rd_data    (final_rd_data),
        .we         (final_reg_write),
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
        .fcsr_rm         (fcsr_rm_mem),
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
            wire final_fp_we = ooo_en ? (commit_en & commit_reg_write & commit_dest_type & ~commit_exception) : fp_we_wb;
            wire [4:0] final_fp_rd_addr = ooo_en ? commit_dest_reg : instruction_wb[11:7];
            wire [FLEN-1:0] final_fp_write_data = ooo_en ? commit_result[FLEN-1:0] : fp_wb_data_wb;

            fpr #(
                .EXTENSION_F(EXTENSION_F),
                .EXTENSION_D(EXTENSION_D)
            ) u_fpr (
                .clk        (global_gated_clk),
                .rst_n      (rst_n),
                .we         (final_fp_we),
                .rd_addr    (final_fp_rd_addr),
                .rs1_addr   (instruction_id[19:15]),
                .rs2_addr   (instruction_id[24:20]),
                .rs3_addr   (instruction_id[31:27]),
                .fmt        (fmt_id),
                .write_data (final_fp_write_data),
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
        .flush(flush_id_ex | final_flush | stall_dispatch),
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
    wire [31:0] final_alu_operand_a = alu_operand_a_ex;
    wire [31:0] final_alu_operand_b = alu_operand_b_ex;
    wire [4:0]  final_alu_op        = alu_op_ex;

    alu #(
        .EXTENSION_M(EXTENSION_M)
    ) u_alu (
        .operand_a  (final_alu_operand_a),
        .operand_b  (final_alu_operand_b),
        .alu_op     (final_alu_op),
        .alu_result (alu_result_ex),
        .zero_flag  (zero_flag_ex)
    );

// CDB Broadcast
    reg [3:0] rob_idx_ex, rob_idx_mem, rob_idx_wb;
    reg valid_ex, valid_mem, valid_wb;
    
    reg cdb_done_mem, cdb_done_wb;

    wire ex_ready = !(mem_read_ex || mem_write_ex || fp_mem_read_ex || fp_mem_write_ex || csr_write_ex || result_sel_ex == 2'b11 || amo_en_ex);
    wire ex_wants_cdb = valid_ex && (ex_ready || exception_ex);
    wire mem_ready = !(mem_read_mem || fp_mem_read_mem || csr_write_mem || result_sel_mem == 2'b11 || amo_en_mem);
    wire mem_wants_cdb = valid_mem && ((!cdb_done_mem && mem_ready) || exception_mem);
    wire wb_wants_cdb = valid_wb && (!cdb_done_wb || exception_wb);

    wire grant_wb  = wb_wants_cdb;
    wire grant_mem = mem_wants_cdb && !grant_wb;
    wire grant_ex  = ex_wants_cdb && !grant_wb && !grant_mem;

    always @(posedge global_gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_ex <= 0;
            valid_mem <= 0;
            valid_wb <= 0;
            exception_wb <= 0;
            exception_cause_wb <= 0;
            pc_sel_mem <= 0;
            pc_sel_wb <= 0;
            pc_target_mem <= 0;
            pc_target_wb <= 0;
            rob_idx_ex <= 0;
            rob_idx_mem <= 0;
            rob_idx_wb <= 0;
            cdb_done_mem <= 0;
            cdb_done_wb <= 0;
        end else begin
            if (flush_id_ex | final_flush) begin
                valid_ex <= 0;
            end else begin
                valid_ex <= dispatch_en;
                rob_idx_ex <= rob_idx_disp;
            end

            if (flush_ex_mem | final_flush) begin
                valid_mem <= 0;
                cdb_done_mem <= 0;
                pc_sel_mem <= 0;
                pc_target_mem <= 0;
            end else begin
                valid_mem <= valid_ex;
                rob_idx_mem <= rob_idx_ex;
                cdb_done_mem <= grant_ex;
                pc_sel_mem <= pc_sel_ex;
                pc_target_mem <= pc_target_ex;
            end

            if (flush_mem_wb | final_flush) begin
                valid_wb <= 0;
                cdb_done_wb <= 0;
                exception_wb <= 0;
                exception_cause_wb <= 0;
                pc_sel_wb <= 0;
                pc_target_wb <= 0;
            end else begin
                valid_wb <= valid_mem;
                rob_idx_wb <= rob_idx_mem;
                cdb_done_wb <= cdb_done_mem | grant_mem;
                exception_wb <= exception_mem;
                exception_cause_wb <= exception_cause_mem;
                pc_sel_wb <= pc_sel_mem;
                pc_target_wb <= pc_target_mem;
            end
        end
    end

    // EX Stage CDB Data
    wire [31:0] ex_int_data = (result_sel_ex == 2'b10) ? pc_plus4_ex : alu_result_ex;
    wire [63:0] ex_fp_data = (FLEN == 64) ? fp_alu_result_ex : {32'b0, fp_alu_result_ex[31:0]};
    wire [63:0] ex_cdb_data = fp_we_ex ? ex_fp_data : {32'b0, ex_int_data};

    // MEM Stage CDB Data
    wire [31:0] mem_int_data = fp_to_int_mem ? fp_alu_result_mem[31:0] :
                               (result_sel_mem == 2'b00) ? alu_result_mem :
                               (result_sel_mem == 2'b01) ? dmem_rdata_mem[31:0] :
                               (result_sel_mem == 2'b10) ? pc_plus4_mem :
                               (result_sel_mem == 2'b11) ? csr_rdata_mem :
                               alu_result_mem;
    
    wire [31:0] final_instruction_mem = ooo_en ? complete_instruction : instruction_mem;
    wire [1:0] final_fmt_mem = ooo_en ? complete_instruction[26:25] : fmt_mem;
    wire is_single_precision_mem = (final_instruction_mem[6:0] == 7'b1010011 && final_instruction_mem[31:25] == 7'b0100000) ? (final_instruction_mem[24:20] == 5'b00000) : (final_fmt_mem == 2'b00);
    wire [63:0] load_fp_data_mem = (mem_size_mem == 3'b010) ? {32'hFFFFFFFF, dmem_rdata_mem[31:0]} : dmem_rdata_mem;
    wire [FLEN-1:0] nan_boxed_fp_alu_result_mem = (FLEN == 64 && is_single_precision_mem) ? (fp_alu_result_mem | 64'hFFFFFFFF00000000) : fp_alu_result_mem;
    wire [FLEN-1:0] mem_fp_data_raw = fp_mem_read_mem ? load_fp_data_mem[FLEN-1:0] : nan_boxed_fp_alu_result_mem;
    wire [63:0] mem_fp_data = (FLEN == 64) ? mem_fp_data_raw : {32'b0, mem_fp_data_raw[31:0]};
    
    wire [63:0] mem_cdb_data = fp_we_mem ? mem_fp_data : {32'b0, mem_int_data};

    // WB Stage CDB Data
    wire [63:0] cdb_data_fp;
    generate
        if (FLEN == 64) begin : gen_cdb_fp64
            assign cdb_data_fp = fp_wb_data_wb;

    assign cdb_exception = grant_wb ? exception_wb : (grant_mem ? exception_mem : (grant_ex ? exception_ex : 1'b0));
    assign cdb_exception_cause = grant_wb ? exception_cause_wb : (grant_mem ? exception_cause_mem : (grant_ex ? exception_cause_ex : 4'b0));
    assign cdb_pc_sel = grant_wb ? pc_sel_wb : (grant_mem ? pc_sel_mem : (grant_ex ? pc_sel_ex : 1'b0));
    assign cdb_pc_target = grant_wb ? pc_target_wb : (grant_mem ? pc_target_mem : (grant_ex ? pc_target_ex : 32'b0));

        end else begin : gen_cdb_fp32
            assign cdb_data_fp = {32'b0, fp_wb_data_wb};
        end
    endgenerate
    wire [63:0] wb_cdb_data = fp_we_wb ? cdb_data_fp : {32'b0, wb_data_wb};

    assign cdb_en = ooo_en & (grant_wb | grant_mem | grant_ex);
    
    assign cdb_rob_idx = grant_wb  ? rob_idx_wb :
                         grant_mem ? rob_idx_mem :
                                     rob_idx_ex;

    assign cdb_data = grant_wb  ? wb_cdb_data :
                      grant_mem ? mem_cdb_data :
                                  ex_cdb_data;

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
        .flush(flush_ex_mem | final_flush),
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
                .exception       (final_exception),
                .exception_cause (final_exception_cause),
                .exception_pc    (final_exception_pc),
                .exception_addr  (final_exception_addr),
                .mret_exec       (final_mret_exec),
                .fp_fflags_update(fp_fflags_mem),
                .fp_fflags_we    (fp_fflags_we_mem),
                .csr_rdata       (csr_rdata_mem),
                .mepc_out        (mepc_out_mem),
                .mtvec_out       (mtvec_out_mem),
                .fcsr_rm         (fcsr_rm_mem),
                .mstatus_fs_out  (mstatus_fs_mem),
                .ooo_en          (ooo_en)
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
        .flush(flush_mem_wb | final_flush),
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
    
    assign final_exception = ooo_en ? commit_exception : exception_mem;
    assign final_exception_cause = ooo_en ? commit_exception_cause : exception_cause_mem;
    assign final_exception_pc = ooo_en ? commit_pc : pc_mem;
    assign final_exception_addr = ooo_en ? commit_instruction : instruction_mem;
    
    assign final_pc_sel = ooo_en ? (commit_en & commit_branch_mispredicted) : pc_sel_ex;
    assign final_pc_target = ooo_en ? commit_branch_target : pc_target_ex;
    
    wire commit_is_mret = (commit_instruction == 32'h30200073);
    assign final_mret_exec = ooo_en ? (commit_en & commit_is_mret) : mret_exec_mem;
    assign final_flush = final_exception | (ooo_en & commit_en & commit_branch_mispredicted) | final_mret_exec;

    hazard_unit u_hazard_unit (
        .rs1_addr_id    (instruction_id[19:15]),
        .rs2_addr_id    (instruction_id[24:20]),
        .rs3_addr_id    (instruction_id[31:27]),
        .rd_addr_ex     (instruction_ex[11:7]),
        .mem_read_ex    (mem_read_ex),
        .fp_mem_read_ex (fp_mem_read_ex),
        .pc_sel_ex      (final_pc_sel),
        .exception_mem  (final_exception),
        .mret_exec_mem  (final_mret_exec),
        .csr_write_ex   (csr_write_ex),
        .csr_write_mem  (csr_write_mem),
        .csr_op_id      (csr_op_id),
        .fp_fflags_we_ex(fp_fflags_we_ex),
        .fp_fflags_we_mem(fp_fflags_we_mem),
        .stall_pc       (stall_pc_hz),
        .stall_if_id    (stall_if_id_hz),
        .flush_if_id    (flush_if_id),
        .flush_id_ex    (flush_id_ex),
        .flush_ex_mem   (flush_ex_mem),
        .flush_mem_wb   (flush_mem_wb)
    );

endmodule