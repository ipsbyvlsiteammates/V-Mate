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
    force dut.ooo_en = 1'b1;
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Reset generation
    initial begin
        rst_n = 0;
        #22 rst_n = 1;
    end
    // Load memories
    initial begin
        foreach (dut.u_imem.mem[i]) dut.u_imem.mem[i] = 32'b0;
        $readmemh("imem.hex", dut.u_imem.mem);
        foreach (dut.u_dmem.mem[i]) dut.u_dmem.mem[i] = 8'b0;
        $readmemh("dmem.hex", dut.u_dmem.mem);
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
        .valid_ex(valid_ex),
    .rob_idx_ex(rob_idx_ex),
    .pc_ex(pc_ex),
        .instruction_ex(instruction_ex),
        .fp_rs1_data_ex(fp_rs1_data_ex),
        .fp_rs3_data_ex(fp_rs3_data_ex),
        .valid_mem(valid_mem),
    .rob_idx_mem(rob_idx_mem),
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

        .fp_rd_data_wb(fp_wb_data_wb),
        
        // OoO Signals
        .ooo_en(ooo_en),
        .dispatch_en(dispatch_en),
        .dispatch_pc(pc_id),
        .dispatch_instruction(instruction_id),
        .dispatch_rob_idx(rob_idx_disp),
        .commit_en(commit_en),
        .commit_pc(commit_pc),
        .commit_result(commit_result),
        .commit_dest_reg(commit_dest_reg),
        .commit_dest_type(commit_dest_type),
        .commit_exception(commit_exception),
        .commit_exception_cause(commit_exception_cause),
        .commit_rob_idx(commit_rob_idx),
        .commit_is_store(commit_is_store),
        .commit_instruction(commit_instruction),
        .commit_reg_write(commit_reg_write)

    );

    bind riscv_top riscv_sva sva_inst (
        .clk(clk),
        .rst_n(rst_n),
        .pc_out(pc_if),
        .instruction(instruction_ex),
        .exception_mem(exception_mem),
        .amo_en_mem(amo_en_mem),
        .reservation_valid(u_dmem.reservation_valid),
        .mem_read_mem(mem_read_mem),
        .mem_write_mem(mem_write_mem),
        .fp_we_mem(fp_we_mem),
        .reg_write_mem(reg_write_mem)
    );

    initial begin
        // Pass the bound interface to UVM config DB
        uvm_config_db#(virtual riscv_if)::set(null, "*", "vif", dut.bound_if);
        // Run UVM test
        run_test("riscv_test");
    end

    

    longint tohost_addr;
    initial begin
        if (!$value$plusargs("TOHOST_ADDR=%x", tohost_addr)) begin
            $display("WARNING: +TOHOST_ADDR not provided. Using default.");
            tohost_addr = 64'h80001000;
        end
    end

    always @(posedge clk) begin
        if (dut.bound_if.mem_write_mem && dut.bound_if.alu_result_mem == tohost_addr) begin
            $display("TOHOST WRITE: %0h", dut.bound_if.write_data_mem);
            if (dut.bound_if.write_data_mem == 1) begin
                $display("TEST PASSED");
            end else begin
                $display("TEST FAILED with code %0d", dut.bound_if.write_data_mem);
            end
            $finish;
        end
    end

    initial begin
        #500000000; // 500ms timeout
        $display("TEST TIMEOUT");
        $finish;
    end


    integer inst_cnt = 0;
    logic [31:0] last_pc = 32'hFFFFFFFF;
    integer exc_cnt = 0;
    always @(posedge clk) begin
        if (rst_n && dut.bound_if.pc_ex != last_pc) begin
            if (inst_cnt < 100) begin
                $display("Time %0t: Executing PC=%08x, Inst=%08x", $time, dut.bound_if.pc_ex, dut.bound_if.instruction_ex);
                inst_cnt = inst_cnt + 1;
            end
            last_pc <= dut.bound_if.pc_ex;
        end
        if (rst_n && dut.bound_if.exception_mem) begin
            if (exc_cnt < 50) begin
                $display("Time %0t: EXCEPTION at PC=%08x, cause=%0x", $time, dut.bound_if.pc_mem, dut.bound_if.exception_cause_mem);
                exc_cnt = exc_cnt + 1;
            end
        end
    end

  initial begin
    wait(rst_n === 1'b1);
    #10;
    force dut.gen_csr.u_csr_file.moooctrl_ooo_en = 1'b1;
  end
endmodule
