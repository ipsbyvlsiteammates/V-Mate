`ifndef RISCV_FP_TEST_SV
`define RISCV_FP_TEST_SV
import uvm_pkg::*;
`include "uvm_macros.svh"
class riscv_fp_test extends riscv_test;
  `uvm_component_utils(riscv_fp_test)
  function new(string name = "riscv_fp_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  virtual task run_phase(uvm_phase phase);
    riscv_fp_seq seq;
    phase.raise_objection(this);
    seq = riscv_fp_seq::type_id::create("seq");
    seq.start(env.agent.sqr);
    phase.drop_objection(this);
  endtask
endclass
`endif
