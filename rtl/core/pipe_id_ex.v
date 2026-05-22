module pipe_id_ex #(parameter FLEN = 64) (
    input wire clk,
    input wire rst_n,
    input wire stall,
    input wire flush,
    input wire [31:0] pc_id,
    input wire [31:0] pc_plus4_id,
    input wire [31:0] instruction_id,
    input wire [31:0] rs1_data_id,
    input wire [31:0] rs2_data_id,
    input wire [FLEN-1:0] fp_rs1_data_id,
    input wire [FLEN-1:0] fp_rs2_data_id,
    input wire [FLEN-1:0] fp_rs3_data_id,
    input wire [31:0] imm_out_id,
    input wire alu_src_id,
    input wire pc_src_auipc_id,
    input wire [4:0] alu_op_id,
    input wire branch_id,
    input wire jump_id,
    input wire [4:0] fp_alu_op_id,
    input wire [1:0] fmt_id,
    input wire [2:0] rm_id,
    input wire int_to_fp_id,
    input wire fp_to_int_id,
    input wire csr_imm_sel_id,
    input wire mem_write_id,
    input wire mem_read_id,
    input wire [2:0] mem_size_id,
    input wire csr_write_id,
    input wire [1:0] csr_op_id,
    input wire exception_id,
    input wire [3:0] exception_cause_id,
    input wire mret_exec_id,
    input wire amo_en_id,
    input wire [4:0] amo_op_id,
    input wire fp_mem_read_id,
    input wire fp_mem_write_id,
    input wire fp_fflags_we_id,
    input wire reg_write_id,
    input wire [1:0] result_sel_id,
    input wire fp_we_id,
    output reg [31:0] pc_ex,
    output reg [31:0] pc_plus4_ex,
    output reg [31:0] instruction_ex,
    output reg [31:0] rs1_data_ex,
    output reg [31:0] rs2_data_ex,
    output reg [FLEN-1:0] fp_rs1_data_ex,
    output reg [FLEN-1:0] fp_rs2_data_ex,
    output reg [FLEN-1:0] fp_rs3_data_ex,
    output reg [31:0] imm_out_ex,
    output reg alu_src_ex,
    output reg pc_src_auipc_ex,
    output reg [4:0] alu_op_ex,
    output reg branch_ex,
    output reg jump_ex,
    output reg [4:0] fp_alu_op_ex,
    output reg [1:0] fmt_ex,
    output reg [2:0] rm_ex,
    output reg int_to_fp_ex,
    output reg fp_to_int_ex,
    output reg csr_imm_sel_ex,
    output reg mem_write_ex,
    output reg mem_read_ex,
    output reg [2:0] mem_size_ex,
    output reg csr_write_ex,
    output reg [1:0] csr_op_ex,
    output reg exception_ex,
    output reg [3:0] exception_cause_ex,
    output reg mret_exec_ex,
    output reg amo_en_ex,
    output reg [4:0] amo_op_ex,
    output reg fp_mem_read_ex,
    output reg fp_mem_write_ex,
    output reg fp_fflags_we_ex,
    output reg reg_write_ex,
    output reg [1:0] result_sel_ex,
    output reg fp_we_ex
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_ex <= 32'b0; pc_plus4_ex <= 32'b0; instruction_ex <= 32'b0;
            rs1_data_ex <= 32'b0; rs2_data_ex <= 32'b0;
            fp_rs1_data_ex <= {FLEN{1'b0}}; fp_rs2_data_ex <= {FLEN{1'b0}}; fp_rs3_data_ex <= {FLEN{1'b0}};
            imm_out_ex <= 32'b0;
            alu_src_ex <= 1'b0; pc_src_auipc_ex <= 1'b0; alu_op_ex <= 5'b0;
            branch_ex <= 1'b0; jump_ex <= 1'b0; fp_alu_op_ex <= 5'b0;
            fmt_ex <= 2'b0; rm_ex <= 3'b0; int_to_fp_ex <= 1'b0; fp_to_int_ex <= 1'b0; csr_imm_sel_ex <= 1'b0;
            mem_write_ex <= 1'b0; mem_read_ex <= 1'b0; mem_size_ex <= 3'b0;
            csr_write_ex <= 1'b0; csr_op_ex <= 2'b0; exception_ex <= 1'b0; exception_cause_ex <= 4'b0;
            mret_exec_ex <= 1'b0; amo_en_ex <= 1'b0; amo_op_ex <= 5'b0;
            fp_mem_read_ex <= 1'b0; fp_mem_write_ex <= 1'b0; fp_fflags_we_ex <= 1'b0;
            reg_write_ex <= 1'b0; result_sel_ex <= 2'b0; fp_we_ex <= 1'b0;
        end else if (flush) begin
            pc_ex <= 32'b0; pc_plus4_ex <= 32'b0; instruction_ex <= 32'b0;
            rs1_data_ex <= 32'b0; rs2_data_ex <= 32'b0;
            fp_rs1_data_ex <= {FLEN{1'b0}}; fp_rs2_data_ex <= {FLEN{1'b0}}; fp_rs3_data_ex <= {FLEN{1'b0}};
            imm_out_ex <= 32'b0;
            alu_src_ex <= 1'b0; pc_src_auipc_ex <= 1'b0; alu_op_ex <= 5'b0;
            branch_ex <= 1'b0; jump_ex <= 1'b0; fp_alu_op_ex <= 5'b0;
            fmt_ex <= 2'b0; rm_ex <= 3'b0; int_to_fp_ex <= 1'b0; fp_to_int_ex <= 1'b0; csr_imm_sel_ex <= 1'b0;
            mem_write_ex <= 1'b0; mem_read_ex <= 1'b0; mem_size_ex <= 3'b0;
            csr_write_ex <= 1'b0; csr_op_ex <= 2'b0; exception_ex <= 1'b0; exception_cause_ex <= 4'b0;
            mret_exec_ex <= 1'b0; amo_en_ex <= 1'b0; amo_op_ex <= 5'b0;
            fp_mem_read_ex <= 1'b0; fp_mem_write_ex <= 1'b0; fp_fflags_we_ex <= 1'b0;
            reg_write_ex <= 1'b0; result_sel_ex <= 2'b0; fp_we_ex <= 1'b0;
        end else if (!stall) begin
            pc_ex <= pc_id; pc_plus4_ex <= pc_plus4_id; instruction_ex <= instruction_id;
            rs1_data_ex <= rs1_data_id; rs2_data_ex <= rs2_data_id;
            fp_rs1_data_ex <= fp_rs1_data_id; fp_rs2_data_ex <= fp_rs2_data_id; fp_rs3_data_ex <= fp_rs3_data_id;
            imm_out_ex <= imm_out_id;
            alu_src_ex <= alu_src_id; pc_src_auipc_ex <= pc_src_auipc_id; alu_op_ex <= alu_op_id;
            branch_ex <= branch_id; jump_ex <= jump_id; fp_alu_op_ex <= fp_alu_op_id;
            fmt_ex <= fmt_id; rm_ex <= rm_id; int_to_fp_ex <= int_to_fp_id; fp_to_int_ex <= fp_to_int_id; csr_imm_sel_ex <= csr_imm_sel_id;
            mem_write_ex <= mem_write_id; mem_read_ex <= mem_read_id; mem_size_ex <= mem_size_id;
            csr_write_ex <= csr_write_id; csr_op_ex <= csr_op_id; exception_ex <= exception_id; exception_cause_ex <= exception_cause_id;
            mret_exec_ex <= mret_exec_id; amo_en_ex <= amo_en_id; amo_op_ex <= amo_op_id;
            fp_mem_read_ex <= fp_mem_read_id; fp_mem_write_ex <= fp_mem_write_id; fp_fflags_we_ex <= fp_fflags_we_id;
            reg_write_ex <= reg_write_id; result_sel_ex <= result_sel_id; fp_we_ex <= fp_we_id;
        end
    end
endmodule