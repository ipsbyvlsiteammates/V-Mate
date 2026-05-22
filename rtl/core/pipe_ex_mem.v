module pipe_ex_mem #(parameter FLEN = 64) (
    input wire clk,
    input wire rst_n,
    input wire stall,
    input wire flush,
    input wire [31:0] pc_ex,
    input wire [31:0] pc_plus4_ex,
    input wire [31:0] instruction_ex,
    input wire [31:0] alu_result_ex,
    input wire [31:0] rs2_data_ex,
    input wire [FLEN-1:0] fp_rs2_data_ex,
    input wire [FLEN-1:0] fp_alu_result_ex,
    input wire [4:0] fp_fflags_ex,
    input wire [31:0] csr_wdata_ex,
    input wire mem_write_ex,
    input wire mem_read_ex,
    input wire [2:0] mem_size_ex,
    input wire csr_write_ex,
    input wire [1:0] csr_op_ex,
    input wire exception_ex,
    input wire [3:0] exception_cause_ex,
    input wire mret_exec_ex,
    input wire amo_en_ex,
    input wire [4:0] amo_op_ex,
    input wire fp_mem_read_ex,
    input wire fp_mem_write_ex,
    input wire fp_fflags_we_ex,
    input wire reg_write_ex,
    input wire [1:0] result_sel_ex,
    input wire fp_we_ex,
    input wire fp_to_int_ex,
    input wire [1:0] fmt_ex,
    output reg [31:0] pc_mem,
    output reg [31:0] pc_plus4_mem,
    output reg [31:0] instruction_mem,
    output reg [31:0] alu_result_mem,
    output reg [31:0] rs2_data_mem,
    output reg [FLEN-1:0] fp_rs2_data_mem,
    output reg [FLEN-1:0] fp_alu_result_mem,
    output reg [4:0] fp_fflags_mem,
    output reg [31:0] csr_wdata_mem,
    output reg mem_write_mem,
    output reg mem_read_mem,
    output reg [2:0] mem_size_mem,
    output reg csr_write_mem,
    output reg [1:0] csr_op_mem,
    output reg exception_mem,
    output reg [3:0] exception_cause_mem,
    output reg mret_exec_mem,
    output reg amo_en_mem,
    output reg [4:0] amo_op_mem,
    output reg fp_mem_read_mem,
    output reg fp_mem_write_mem,
    output reg fp_fflags_we_mem,
    output reg reg_write_mem,
    output reg [1:0] result_sel_mem,
    output reg fp_we_mem,
    output reg fp_to_int_mem,
    output reg [1:0] fmt_mem
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_mem <= 32'b0; pc_plus4_mem <= 32'b0; instruction_mem <= 32'b0;
            alu_result_mem <= 32'b0; rs2_data_mem <= 32'b0;
            fp_rs2_data_mem <= {FLEN{1'b0}}; fp_alu_result_mem <= {FLEN{1'b0}};
            fp_fflags_mem <= 5'b0; csr_wdata_mem <= 32'b0;
            mem_write_mem <= 1'b0; mem_read_mem <= 1'b0; mem_size_mem <= 3'b0;
            csr_write_mem <= 1'b0; csr_op_mem <= 2'b0; exception_mem <= 1'b0; exception_cause_mem <= 4'b0;
            mret_exec_mem <= 1'b0; amo_en_mem <= 1'b0; amo_op_mem <= 5'b0;
            fp_mem_read_mem <= 1'b0; fp_mem_write_mem <= 1'b0; fp_fflags_we_mem <= 1'b0;
            reg_write_mem <= 1'b0; result_sel_mem <= 2'b0; fp_we_mem <= 1'b0;
            fp_to_int_mem <= 1'b0; fmt_mem <= 2'b0;
        end else if (flush) begin
            pc_mem <= 32'b0; pc_plus4_mem <= 32'b0; instruction_mem <= 32'b0;
            alu_result_mem <= 32'b0; rs2_data_mem <= 32'b0;
            fp_rs2_data_mem <= {FLEN{1'b0}}; fp_alu_result_mem <= {FLEN{1'b0}};
            fp_fflags_mem <= 5'b0; csr_wdata_mem <= 32'b0;
            mem_write_mem <= 1'b0; mem_read_mem <= 1'b0; mem_size_mem <= 3'b0;
            csr_write_mem <= 1'b0; csr_op_mem <= 2'b0; exception_mem <= 1'b0; exception_cause_mem <= 4'b0;
            mret_exec_mem <= 1'b0; amo_en_mem <= 1'b0; amo_op_mem <= 5'b0;
            fp_mem_read_mem <= 1'b0; fp_mem_write_mem <= 1'b0; fp_fflags_we_mem <= 1'b0;
            reg_write_mem <= 1'b0; result_sel_mem <= 2'b0; fp_we_mem <= 1'b0;
            fp_to_int_mem <= 1'b0; fmt_mem <= 2'b0;
        end else if (!stall) begin
            pc_mem <= pc_ex; pc_plus4_mem <= pc_plus4_ex; instruction_mem <= instruction_ex;
            alu_result_mem <= alu_result_ex; rs2_data_mem <= rs2_data_ex;
            fp_rs2_data_mem <= fp_rs2_data_ex; fp_alu_result_mem <= fp_alu_result_ex;
            fp_fflags_mem <= fp_fflags_ex; csr_wdata_mem <= csr_wdata_ex;
            mem_write_mem <= mem_write_ex; mem_read_mem <= mem_read_ex; mem_size_mem <= mem_size_ex;
            csr_write_mem <= csr_write_ex; csr_op_mem <= csr_op_ex; exception_mem <= exception_ex; exception_cause_mem <= exception_cause_ex;
            mret_exec_mem <= mret_exec_ex; amo_en_mem <= amo_en_ex; amo_op_mem <= amo_op_ex;
            fp_mem_read_mem <= fp_mem_read_ex; fp_mem_write_mem <= fp_mem_write_ex; fp_fflags_we_mem <= fp_fflags_we_ex;
            reg_write_mem <= reg_write_ex; result_sel_mem <= result_sel_ex; fp_we_mem <= fp_we_ex;
            fp_to_int_mem <= fp_to_int_ex; fmt_mem <= fmt_ex;
        end
    end
endmodule