`timescale 1ns/1ps
import uvm_pkg::*;
`include "uvm_macros.svh"
import riscv_uvm_pkg::*;
`include "riscv_if.sv"

module tb_uvm_top;
    logic clk;
    logic rst_n;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Reset generation
    initial begin
        rst_n = 0;
        #22 rst_n = 1;
    end

    // DUT Instantiation
    riscv_top dut (
        .clk_en(1'b1),
        .clk(clk),
        .rst_n(rst_n)
    );

    // Bind interface to DUT internal signals
    bind riscv_top riscv_if bound_if (
        .clk(clk),
        .rst_n(rst_n),
        .pc_ex(pc_ex),
        .instruction_ex(instruction_ex),
        .fp_rs1_data_ex(fp_rs1_data_ex),
        .fp_rs3_data_ex(fp_rs3_data_ex),
        .pc_mem(pc_mem),
        .instruction_mem(instruction_mem),
        .reg_write_mem(reg_write_mem),
        .rd_addr_mem(instruction_mem[11:7]),
        .mem_write_mem(mem_write_mem),
        .mem_read_mem(mem_read_mem),
        .alu_result_mem(alu_result_mem),
        .write_data_mem(rs2_data_mem),
        .csr_addr_mem(instruction_mem[31:20]),
        .csr_wdata_mem(csr_wdata_mem),
        .csr_rdata_mem(csr_rdata_mem),
        .csr_op_mem(csr_op_mem),
        .csr_write_mem(csr_write_mem),
        .exception_mem(exception_mem),
        .exception_cause_mem(exception_cause_mem),
        .mret_exec_mem(mret_exec_mem),
        .fp_we_mem(fp_we_mem),
        .fp_rd_addr_mem(instruction_mem[11:7]),
        .fp_rs2_data_mem(fp_rs2_data_mem),
        .fcsr_rm_mem(fcsr_rm_mem),
        .fflags_update_mem(fp_fflags_mem),
        .fp_alu_result_mem(fp_alu_result_mem),
        .amo_en_mem(amo_en_mem),
        .amo_op_mem(amo_op_mem),
        .reservation_valid(u_dmem.reservation_valid),
        .reservation_addr(u_dmem.reservation_addr),
        .rd_data_wb(wb_data_wb),
        .fp_rd_data_wb(fp_wb_data_wb)
    );

    initial begin
        // Pass the bound interface to UVM config DB
        uvm_config_db#(virtual riscv_if)::set(null, "*", "vif", dut.bound_if);
        // Run UVM test
        run_test("riscv_test");
    end

    
endmodule
