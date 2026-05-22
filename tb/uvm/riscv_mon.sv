`ifndef RISCV_MON_SV
`define RISCV_MON_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class riscv_mon extends uvm_monitor;
  `uvm_component_utils(riscv_mon)

  virtual riscv_if vif;
  uvm_analysis_port #(riscv_txn) ap;

  riscv_txn mem_queue[$];
  logic [63:0] fp_rs1_data_mem;
  logic [63:0] fp_rs3_data_mem;

  function new(string name = "riscv_mon", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual riscv_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    riscv_txn txn;
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.rst_n === 1'b1) begin
        // 1. WB stage: complete the transaction from the previous cycle
        if (mem_queue.size() > 0) begin
          riscv_txn retiring_txn = mem_queue.pop_front();
          if (retiring_txn.instruction !== 32'h00000000) begin
            retiring_txn.rd_data = vif.mon_cb.rd_data_wb;
            retiring_txn.fp_rd_data = vif.mon_cb.fp_rd_data_wb;
            ap.write(retiring_txn);
          end
        end

        // 2. MEM stage: create new transaction
        if (vif.mon_cb.instruction_mem !== 32'h00000000) begin
          txn = riscv_txn::type_id::create("txn");
          txn.pc = vif.mon_cb.pc_mem;
          txn.instruction = vif.mon_cb.instruction_mem;
          txn.reg_write = vif.mon_cb.reg_write_mem;
          txn.rd_addr = vif.mon_cb.rd_addr_mem;
          txn.mem_write = vif.mon_cb.mem_write_mem;
          txn.mem_read = vif.mon_cb.mem_read_mem;
          txn.alu_result = vif.mon_cb.alu_result_mem;
          txn.write_data = vif.mon_cb.write_data_mem;
          txn.csr_addr = vif.mon_cb.csr_addr_mem;
          txn.csr_wdata = vif.mon_cb.csr_wdata_mem;
          txn.csr_rdata = vif.mon_cb.csr_rdata_mem;
          txn.csr_op = vif.mon_cb.csr_op_mem;
          txn.csr_write = vif.mon_cb.csr_write_mem;
          txn.exception = vif.mon_cb.exception_mem;
          txn.exception_cause = vif.mon_cb.exception_cause_mem;
          txn.mret_exec = vif.mon_cb.mret_exec_mem;
          txn.fp_we = vif.mon_cb.fp_we_mem;
          txn.fp_rd_addr = vif.mon_cb.fp_rd_addr_mem;
          txn.fp_rs1_data = fp_rs1_data_mem; // from previous cycle's EX stage
          txn.fp_rs2_data = vif.mon_cb.fp_rs2_data_mem;
          txn.fp_rs3_data = fp_rs3_data_mem; // from previous cycle's EX stage
          txn.fcsr_rm = vif.mon_cb.fcsr_rm_mem;
          txn.fflags_update = vif.mon_cb.fflags_update_mem;
          txn.fp_alu_result = vif.mon_cb.fp_alu_result_mem;
          txn.amo_en = vif.mon_cb.amo_en_mem;
          txn.amo_op = vif.mon_cb.amo_op_mem;
          txn.reservation_valid = vif.mon_cb.reservation_valid;
          txn.reservation_addr = vif.mon_cb.reservation_addr;
          
          mem_queue.push_back(txn);
        end else begin
          // Push a dummy to keep pipeline in sync
          txn = riscv_txn::type_id::create("txn_dummy");
          txn.instruction = 32'h00000000;
          mem_queue.push_back(txn);
        end

        // 3. Shift EX signals to MEM for next cycle
        fp_rs1_data_mem = vif.mon_cb.fp_rs1_data_ex;
        fp_rs3_data_mem = vif.mon_cb.fp_rs3_data_ex;

      end else begin
        mem_queue.delete();
        fp_rs1_data_mem = 64'h0;
        fp_rs3_data_mem = 64'h0;
      end
    end
  endtask
endclass

`endif
