`ifndef RISCV_IF_SV
`define RISCV_IF_SV

interface riscv_if(
    input logic clk,
    input logic rst_n,
    
    // EX Stage
    input logic [31:0] pc_ex,
    input logic [31:0] instruction_ex,
    input logic [63:0] fp_rs1_data_ex,
    input logic [63:0] fp_rs3_data_ex,
    
    // MEM Stage
    input logic [31:0] pc_mem,
    input logic [31:0] instruction_mem,
    input logic reg_write_mem,
    input logic [4:0] rd_addr_mem,
    input logic mem_write_mem,
    input logic mem_read_mem,
    input logic [31:0] alu_result_mem,
    input logic [31:0] write_data_mem,
    input logic [11:0] csr_addr_mem,
    input logic [31:0] csr_wdata_mem,
    input logic [31:0] csr_rdata_mem,
    input logic [1:0]  csr_op_mem,
    input logic        csr_write_mem,
    input logic        exception_mem,
    input logic [3:0]  exception_cause_mem,
    input logic        mret_exec_mem,
    input logic fp_we_mem,
    input logic [4:0] fp_rd_addr_mem,
    input logic [63:0] fp_rs2_data_mem,
    input logic [2:0] fcsr_rm_mem,
    input logic [4:0] fflags_update_mem,
    input logic [63:0] fp_alu_result_mem,
    input logic amo_en_mem,
    input logic [4:0] amo_op_mem,
    input logic reservation_valid,
    input logic [31:0] reservation_addr,
    
    // WB Stage
    input logic [31:0] rd_data_wb,
    input logic [63:0] fp_rd_data_wb
);

    clocking mon_cb @(posedge clk);
        default input #1step output #1ns;
        input rst_n;
        input pc_ex;
        input instruction_ex;
        input fp_rs1_data_ex;
        input fp_rs3_data_ex;
        input pc_mem;
        input instruction_mem;
        input reg_write_mem;
        input rd_addr_mem;
        input mem_write_mem;
        input mem_read_mem;
        input alu_result_mem;
        input write_data_mem;
        input csr_addr_mem;
        input csr_wdata_mem;
        input csr_rdata_mem;
        input csr_op_mem;
        input csr_write_mem;
        input exception_mem;
        input exception_cause_mem;
        input mret_exec_mem;
        input fp_we_mem;
        input fp_rd_addr_mem;
        input fp_rs2_data_mem;
        input fcsr_rm_mem;
        input fflags_update_mem;
        input fp_alu_result_mem;
        input amo_en_mem;
        input amo_op_mem;
        input reservation_valid;
        input reservation_addr;
        input rd_data_wb;
        input fp_rd_data_wb;
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
