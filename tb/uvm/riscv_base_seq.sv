`ifndef RISCV_BASE_SEQ_SV
`define RISCV_BASE_SEQ_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class riscv_base_seq extends uvm_sequence #(riscv_txn);
    `uvm_object_utils(riscv_base_seq)

    function new(string name = "riscv_base_seq");
        super.new(name);
    endfunction

    task body();
        riscv_txn txn;
        int count = 0;
        repeat(50) begin
            txn = riscv_txn::type_id::create("txn");
            start_item(txn);
            if(!txn.randomize()) begin
                `uvm_error("SEQ", "Randomization failed")
            end
            if (count == 0) begin
                txn.hex_file_path = "/home/guy/Sagi/riscv_processor/tb/top/test_programs/full_isa_test.hex";
            end else begin
                txn.hex_file_path = "";
            end
            finish_item(txn);
            count++;
        end
    endtask
endclass

`endif
