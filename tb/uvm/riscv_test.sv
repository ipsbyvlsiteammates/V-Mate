`ifndef RISCV_TEST_SV
`define RISCV_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class riscv_test extends uvm_test;
  `uvm_component_utils(riscv_test)

  riscv_env env;

  function new(string name = "riscv_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = riscv_env::type_id::create("env", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    riscv_base_seq seq;
    phase.raise_objection(this);
    seq = riscv_base_seq::type_id::create("seq");
    seq.start(env.agent.sqr);
    phase.drop_objection(this);
  endtask
endclass

`endif
