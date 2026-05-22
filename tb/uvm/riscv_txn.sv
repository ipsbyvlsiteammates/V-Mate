`ifndef RISCV_TXN_SV
`define RISCV_TXN_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class riscv_txn extends uvm_sequence_item;
    rand logic [31:0] instruction;
    logic [31:0] pc;
    logic reg_write;
    logic [4:0] rd_addr;
    logic [31:0] rd_data;
    logic mem_write;
    logic mem_read;
    logic [31:0] alu_result;
    logic [31:0] write_data;
    string hex_file_path;

    logic [11:0] csr_addr;
    logic [31:0] csr_wdata;
    logic [31:0] csr_rdata;
    logic [1:0]  csr_op;
    logic        csr_write;
    logic        exception;
    logic [3:0]  exception_cause;
    logic        mret_exec;

    logic fp_we;
    logic [4:0] fp_rd_addr;
    logic [63:0] fp_rd_data;
    logic [63:0] fp_rs1_data;
    logic [63:0] fp_rs2_data;
    logic [63:0] fp_rs3_data;
    logic [2:0] fcsr_rm;
    logic [4:0] fflags_update;
    logic [63:0] fp_alu_result;
    logic amo_en;
    logic [4:0] amo_op;
    logic reservation_valid;
    logic [31:0] reservation_addr;

    `uvm_object_utils_begin(riscv_txn)
        `uvm_field_int(instruction, UVM_ALL_ON)
        `uvm_field_int(pc, UVM_ALL_ON)
        `uvm_field_int(reg_write, UVM_ALL_ON)
        `uvm_field_int(rd_addr, UVM_ALL_ON)
        `uvm_field_int(rd_data, UVM_ALL_ON)
        `uvm_field_int(mem_write, UVM_ALL_ON)
        `uvm_field_int(mem_read, UVM_ALL_ON)
        `uvm_field_int(alu_result, UVM_ALL_ON)
        `uvm_field_int(write_data, UVM_ALL_ON)
        `uvm_field_string(hex_file_path, UVM_ALL_ON)
        `uvm_field_int(csr_addr, UVM_ALL_ON)
        `uvm_field_int(csr_wdata, UVM_ALL_ON)
        `uvm_field_int(csr_rdata, UVM_ALL_ON)
        `uvm_field_int(csr_op, UVM_ALL_ON)
        `uvm_field_int(csr_write, UVM_ALL_ON)
        `uvm_field_int(exception, UVM_ALL_ON)
        `uvm_field_int(exception_cause, UVM_ALL_ON)
        `uvm_field_int(mret_exec, UVM_ALL_ON)
        `uvm_field_int(fp_we, UVM_ALL_ON)
        `uvm_field_int(fp_rd_addr, UVM_ALL_ON)
        `uvm_field_int(fp_rd_data, UVM_ALL_ON)
        `uvm_field_int(fp_rs1_data, UVM_ALL_ON)
        `uvm_field_int(fp_rs2_data, UVM_ALL_ON)
        `uvm_field_int(fp_rs3_data, UVM_ALL_ON)
        `uvm_field_int(fcsr_rm, UVM_ALL_ON)
        `uvm_field_int(fflags_update, UVM_ALL_ON)
        `uvm_field_int(fp_alu_result, UVM_ALL_ON)
        `uvm_field_int(amo_en, UVM_ALL_ON)
        `uvm_field_int(amo_op, UVM_ALL_ON)
        `uvm_field_int(reservation_valid, UVM_ALL_ON)
        `uvm_field_int(reservation_addr, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "riscv_txn");
        super.new(name);
    endfunction
endclass

`endif
