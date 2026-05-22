`ifndef RISCV_PRIV_TEST_SV
`define RISCV_PRIV_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class riscv_priv_test extends riscv_test;
    `uvm_component_utils(riscv_priv_test)

    function new(string name = "riscv_priv_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        riscv_priv_seq seq;
        phase.raise_objection(this);
        seq = riscv_priv_seq::type_id::create("seq");
        seq.start(env.agent.sqr);
        phase.drop_objection(this);
    endtask
endclass

`endif
