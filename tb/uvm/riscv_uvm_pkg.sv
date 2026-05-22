`ifndef RISCV_UVM_PKG_SV
`define RISCV_UVM_PKG_SV

package riscv_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "riscv_txn.sv"
  `include "riscv_base_seq.sv"
  `include "riscv_priv_seq.sv"
  `include "riscv_ext_seq.sv"
  `include "riscv_fp_seq.sv"
  `include "riscv_sqr.sv"
  `include "riscv_drv.sv"
  `include "riscv_mon.sv"
  `include "riscv_agent.sv"
  `include "riscv_sb.sv"
  `include "riscv_env.sv"
  `include "riscv_test.sv"
  `include "riscv_priv_test.sv"
  `include "riscv_ext_test.sv"
  `include "riscv_fp_test.sv"
endpackage

`endif
