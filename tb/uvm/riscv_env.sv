`ifndef RISCV_ENV_SV
`define RISCV_ENV_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class riscv_env extends uvm_env;
  `uvm_component_utils(riscv_env)

  riscv_agent agent;
  riscv_sb sb;
  riscv_cov cov;

  function new(string name = "riscv_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = riscv_agent::type_id::create("agent", this);
    sb = riscv_sb::type_id::create("sb", this);
    cov = riscv_cov::type_id::create("cov", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.ap.connect(sb.ap_imp);
    agent.ap.connect(cov.analysis_export);
  endfunction
endclass

`endif
