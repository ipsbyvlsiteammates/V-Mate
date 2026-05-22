`ifndef RISCV_IF_SV
`define RISCV_IF_SV

interface riscv_if(
    input logic clk,
    input logic rst_n,
    input logic [31:0] pc_out,
    input logic [31:0] instruction,
    input logic reg_write,
    input logic [4:0] rd_addr,
    input logic [31:0] rd_data,
    input logic mem_write,
    input logic mem_read,
    input logic [31:0] alu_result,
    input logic [31:0] write_data,
    input logic [11:0] csr_addr,
    input logic [31:0] csr_wdata,
    input logic [31:0] csr_rdata,
    input logic [1:0]  csr_op,
    input logic        csr_write,
    input logic        exception,
    input logic [3:0]  exception_cause,
    input logic        mret_exec,
    input logic fp_we,
    input logic [4:0] fp_rd_addr,
    input logic [63:0] fp_rd_data,
    input logic [63:0] fp_rs1_data,
    input logic [63:0] fp_rs2_data,
    input logic [63:0] fp_rs3_data,
    input logic [2:0] fcsr_rm,
    input logic [4:0] fflags_update,
    input logic [63:0] fp_alu_result,
    input logic amo_en,
    input logic [4:0] amo_op,
    input logic reservation_valid,
    input logic [31:0] reservation_addr
);

    clocking mon_cb @(posedge clk);
        default input #1step output #1ns;
        input rst_n;
        input pc_out;
        input instruction;
        input reg_write;
        input rd_addr;
        input rd_data;
        input mem_write;
        input mem_read;
        input alu_result;
        input write_data;
        input csr_addr;
        input csr_wdata;
        input csr_rdata;
        input csr_op;
        input csr_write;
        input exception;
        input exception_cause;
        input mret_exec;
        input fp_we;
        input fp_rd_addr;
        input fp_rd_data;
        input fp_rs1_data;
        input fp_rs2_data;
        input fp_rs3_data;
        input fcsr_rm;
        input fflags_update;
        input fp_alu_result;
        input amo_en;
        input amo_op;
        input reservation_valid;
        input reservation_addr;
    endclocking

    task load_hex(string hex_file_path);
        int i;
        $readmemh(hex_file_path, tb_uvm_top.dut.u_imem.mem);
        for (i = 0; i < 131072; i++) begin
            if (tb_uvm_top.dut.u_imem.mem[i] !== 32'hx) begin
                tb_uvm_top.dut.u_dmem.mem[i*4]   = tb_uvm_top.dut.u_imem.mem[i][7:0];
                tb_uvm_top.dut.u_dmem.mem[i*4+1] = tb_uvm_top.dut.u_imem.mem[i][15:8];
                tb_uvm_top.dut.u_dmem.mem[i*4+2] = tb_uvm_top.dut.u_imem.mem[i][23:16];
                tb_uvm_top.dut.u_dmem.mem[i*4+3] = tb_uvm_top.dut.u_imem.mem[i][31:24];
            end
        end
    endtask

    function logic [31:0] read_imem(int index);
        return tb_uvm_top.dut.u_imem.mem[index];
    endfunction

endinterface

`endif
