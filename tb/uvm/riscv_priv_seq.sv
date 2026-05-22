`ifndef RISCV_PRIV_SEQ_SV
`define RISCV_PRIV_SEQ_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class riscv_priv_seq extends uvm_sequence #(riscv_txn);
    `uvm_object_utils(riscv_priv_seq)

    function new(string name = "riscv_priv_seq");
        super.new(name);
    endfunction

    task body();
        riscv_txn txn;
        for (int i = 0; i < 20; i++) begin
            txn = riscv_txn::type_id::create("txn");
            start_item(txn);
            if (!txn.randomize()) begin
                `uvm_error("SEQ", "Randomization failed")
            end
            if (i == 0) begin
                txn.hex_file_path = "/home/guy/Sagi/riscv_processor/tb/top/test_programs/priv_isa_test.hex";
            end
            finish_item(txn);
        end
    endtask
endclass

`endif
