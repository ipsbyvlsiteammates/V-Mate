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
    for (int i = 0; i < 1000000; i++) begin
      txn = riscv_txn::type_id::create("txn");
      start_item(txn);
      if (!txn.randomize() with {
        if (i % 5 == 0) {
          fp_rs1_data inside {
            64'h0000000000000000,
            64'h8000000000000000,
            64'h7FF0000000000000,
            64'hFFF0000000000000,
            64'h7FF8000000000000,
            64'h7FF0000000000001,
            64'h000FFFFFFFFFFFFF,
            64'h800FFFFFFFFFFFFF
          };
          fp_rs2_data inside {
            64'h0000000000000000,
            64'h8000000000000000,
            64'h7FF0000000000000,
            64'hFFF0000000000000,
            64'h7FF8000000000000,
            64'h7FF0000000000001,
            64'h000FFFFFFFFFFFFF,
            64'h800FFFFFFFFFFFFF
          };
        }
      }) begin
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
