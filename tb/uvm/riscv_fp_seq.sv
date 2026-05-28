`ifndef RISCV_FP_SEQ_SV
`define RISCV_FP_SEQ_SV
import uvm_pkg::*;
`include "uvm_macros.svh"
class riscv_fp_seq extends uvm_sequence #(riscv_txn);
  `uvm_object_utils(riscv_fp_seq)
  riscv_txn txn;
  int force_next;
  function new(string name = "riscv_fp_seq");
    super.new(name);
    force_next = 0;
  endfunction
  virtual task body();
    for (int i = 0; i < 50; i++) begin
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
      
      if (force_next == 1) begin
        txn.instruction = 32'h00000013; // NOP
        force_next = 0;
      end else if (force_next == 2) begin
        txn.instruction[26:25] = 2'b00; // Single
        force_next = 0;
      end else begin
        // Randomly insert NOPs and interleave single/double
        if ($urandom_range(0, 9) < 2) begin
          txn.instruction = 32'h00000013; // NOP
        end else begin
          if ($urandom_range(0, 1)) begin
            txn.instruction[26:25] = 2'b00; // Single
          end else begin
            txn.instruction[26:25] = 2'b01; // Double
            if ($urandom_range(0, 1)) begin
              force_next = 1; // Force NOP next
            end else begin
              force_next = 2; // Force Single next
            end
          end
        end
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
