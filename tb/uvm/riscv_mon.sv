`ifndef RISCV_MON_SV
`define RISCV_MON_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class riscv_mon extends uvm_monitor;
  `uvm_component_utils(riscv_mon)

  virtual riscv_if vif;
  uvm_analysis_port #(riscv_txn) ap;

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
        txn = riscv_txn::type_id::create("txn");
        txn.pc = vif.mon_cb.pc_out;
        txn.instruction = vif.mon_cb.instruction;
        txn.reg_write = vif.mon_cb.reg_write;
        txn.rd_addr = vif.mon_cb.rd_addr;
        txn.rd_data = vif.mon_cb.rd_data;
        txn.mem_write = vif.mon_cb.mem_write;
        txn.mem_read = vif.mon_cb.mem_read;
        txn.alu_result = vif.mon_cb.alu_result;
        txn.write_data = vif.mon_cb.write_data;
        txn.csr_addr = vif.mon_cb.csr_addr;
        txn.csr_wdata = vif.mon_cb.csr_wdata;
        txn.csr_rdata = vif.mon_cb.csr_rdata;
        txn.csr_op = vif.mon_cb.csr_op;
        txn.csr_write = vif.mon_cb.csr_write;
        txn.exception = vif.mon_cb.exception;
        txn.exception_cause = vif.mon_cb.exception_cause;
        txn.mret_exec = vif.mon_cb.mret_exec;
        txn.fp_we = vif.mon_cb.fp_we;
        txn.fp_rd_addr = vif.mon_cb.fp_rd_addr;
        txn.fp_rd_data = vif.mon_cb.fp_rd_data;
        txn.fp_rs1_data = vif.mon_cb.fp_rs1_data;
        txn.fp_rs2_data = vif.mon_cb.fp_rs2_data;
        txn.fp_rs3_data = vif.mon_cb.fp_rs3_data;
        txn.fcsr_rm = vif.mon_cb.fcsr_rm;
        txn.fflags_update = vif.mon_cb.fflags_update;
        txn.fp_alu_result = vif.mon_cb.fp_alu_result;
        txn.amo_en = vif.mon_cb.amo_en;
        txn.amo_op = vif.mon_cb.amo_op;
        txn.reservation_valid = vif.mon_cb.reservation_valid;
        txn.reservation_addr = vif.mon_cb.reservation_addr;
        ap.write(txn);
      end
    end
  endtask
endclass

`endif
