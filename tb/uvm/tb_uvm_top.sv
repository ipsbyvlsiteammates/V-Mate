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
        .pc_out(pc_out_w),
        .instruction(instruction_w),
        .reg_write(reg_write_w),
        .rd_addr(instruction_w[11:7]),
        .rd_data(wb_data_w),
        .mem_write(mem_write_w),
        .mem_read(mem_read_w),
        .alu_result(alu_result_w),
        .write_data(rs2_data_w),
        .csr_addr(instruction_w[31:20]),
        .csr_wdata(csr_wdata_w),
        .csr_rdata(csr_rdata_w),
        .csr_op(csr_op_w),
        .csr_write(csr_write_w),
        .exception(exception_w),
        .exception_cause(exception_cause_w),
        .mret_exec(mret_exec_w),
        .fp_we(fp_we_w),
        .fp_rd_addr(instruction_w[11:7]),
        .fp_rd_data(fp_wb_data_w),
        .fp_rs1_data(fp_rs1_data_w),
        .fp_rs2_data(fp_rs2_data_w),
        .fp_rs3_data(fp_rs3_data_w),
        .fcsr_rm(fcsr_rm_w),
        .fflags_update(fp_fflags_w),
        .fp_alu_result(fp_alu_result_w),
        .amo_en(amo_en_w),
        .amo_op(amo_op_w),
        .reservation_valid(u_dmem.reservation_valid),
        .reservation_addr(u_dmem.reservation_addr)
    );

    initial begin
        // Pass the bound interface to UVM config DB
        uvm_config_db#(virtual riscv_if)::set(null, "*", "vif", dut.bound_if);
        
        // Run UVM test
        run_test("riscv_test");
    end

    initial begin
        $monitor("Time: %0t | PC: %h | Instr: %h | imm_sel: %b | imm_out: %h | alu_a: %h | alu_b: %h | alu_res: %h | rs1: %h",
                 $time, dut.pc_out_w, dut.instruction_w, dut.imm_sel_w, dut.imm_out_w, dut.alu_operand_a_w, dut.alu_operand_b_w, dut.alu_result_w, dut.rs1_data_w);
    end
endmodule
