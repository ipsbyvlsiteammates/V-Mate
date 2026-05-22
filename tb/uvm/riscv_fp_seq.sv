`ifndef RISCV_FP_SEQ_SV
`define RISCV_FP_SEQ_SV
import uvm_pkg::*;
`include "uvm_macros.svh"
class riscv_fp_seq extends uvm_sequence #(riscv_txn);
  `uvm_object_utils(riscv_fp_seq)
  riscv_txn txn;
  function new(string name = "riscv_fp_seq");
    super.new(name);
  endfunction
  virtual task body();
    for (int i = 0; i < 50; i++) begin
      txn = riscv_txn::type_id::create("txn");
      start_item(txn);
      if (!txn.randomize()) begin
        `uvm_error("SEQ", "Randomization failed")
      end
      if (i == 0) begin
        txn.hex_file_path = "/home/guy/Sagi/riscv_processor/tb/top/test_programs/fp_uvm_test.hex";
      end else begin
        txn.hex_file_path = "";
      end
      finish_item(txn);
    end
  endtask
endclass
`endif
