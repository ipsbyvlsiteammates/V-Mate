module pipe_mem_wb #(parameter FLEN = 64) (
    input wire clk,
    input wire rst_n,
    input wire stall,
    input wire flush,
    input wire [31:0] pc_plus4_mem,
    input wire [31:0] instruction_mem,
    input wire [31:0] alu_result_mem,
    input wire [FLEN-1:0] dmem_rdata_mem,
    input wire [31:0] csr_rdata_mem,
    input wire [FLEN-1:0] fp_alu_result_mem,
    input wire reg_write_mem,
    input wire [1:0] result_sel_mem,
    input wire fp_we_mem,
    input wire fp_to_int_mem,
    input wire fp_mem_read_mem,
    input wire [2:0] mem_size_mem,
    input wire [1:0] fmt_mem,
    output reg [31:0] pc_plus4_wb,
    output reg [31:0] instruction_wb,
    output reg [31:0] alu_result_wb,
    output reg [FLEN-1:0] dmem_rdata_wb,
    output reg [31:0] csr_rdata_wb,
    output reg [FLEN-1:0] fp_alu_result_wb,
    output reg reg_write_wb,
    output reg [1:0] result_sel_wb,
    output reg fp_we_wb,
    output reg fp_to_int_wb,
    output reg fp_mem_read_wb,
    output reg [2:0] mem_size_wb,
    output reg [1:0] fmt_wb
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_plus4_wb <= 32'b0; instruction_wb <= 32'b0; alu_result_wb <= 32'b0;
            dmem_rdata_wb <= {FLEN{1'b0}}; csr_rdata_wb <= 32'b0; fp_alu_result_wb <= {FLEN{1'b0}};
            reg_write_wb <= 1'b0; result_sel_wb <= 2'b0; fp_we_wb <= 1'b0;
            fp_to_int_wb <= 1'b0; fp_mem_read_wb <= 1'b0; mem_size_wb <= 3'b0; fmt_wb <= 2'b0;
        end else if (flush) begin
            pc_plus4_wb <= 32'b0; instruction_wb <= 32'b0; alu_result_wb <= 32'b0;
            dmem_rdata_wb <= {FLEN{1'b0}}; csr_rdata_wb <= 32'b0; fp_alu_result_wb <= {FLEN{1'b0}};
            reg_write_wb <= 1'b0; result_sel_wb <= 2'b0; fp_we_wb <= 1'b0;
            fp_to_int_wb <= 1'b0; fp_mem_read_wb <= 1'b0; mem_size_wb <= 3'b0; fmt_wb <= 2'b0;
        end else if (!stall) begin
            pc_plus4_wb <= pc_plus4_mem; instruction_wb <= instruction_mem; alu_result_wb <= alu_result_mem;
            dmem_rdata_wb <= dmem_rdata_mem; csr_rdata_wb <= csr_rdata_mem; fp_alu_result_wb <= fp_alu_result_mem;
            reg_write_wb <= reg_write_mem; result_sel_wb <= result_sel_mem; fp_we_wb <= fp_we_mem;
            fp_to_int_wb <= fp_to_int_mem; fp_mem_read_wb <= fp_mem_read_mem; mem_size_wb <= mem_size_mem; fmt_wb <= fmt_mem;
        end
    end
endmodule