`ifndef RISCV_SQR_SV
`define RISCV_SQR_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class riscv_sqr extends uvm_sequencer #(riscv_txn);
  `uvm_component_utils(riscv_sqr)

  function new(string name = "riscv_sqr", uvm_component parent = null);
    super.new(name, parent);
  endfunction
endclass

`endif
