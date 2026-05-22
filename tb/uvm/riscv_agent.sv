`ifndef RISCV_AGENT_SV
`define RISCV_AGENT_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class riscv_agent extends uvm_agent;
  `uvm_component_utils(riscv_agent)

  riscv_sqr sqr;
  riscv_drv drv;
  riscv_mon mon;

  uvm_analysis_port #(riscv_txn) ap;

  function new(string name = "riscv_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (get_is_active() == UVM_ACTIVE) begin
      sqr = riscv_sqr::type_id::create("sqr", this);
      drv = riscv_drv::type_id::create("drv", this);
    end
    mon = riscv_mon::type_id::create("mon", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE) begin
      drv.seq_item_port.connect(sqr.seq_item_export);
    end
    mon.ap.connect(ap);
  endfunction
endclass

`endif
