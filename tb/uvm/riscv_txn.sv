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

    rand logic [11:0] csr_addr;
    logic [31:0] csr_wdata;
    logic [31:0] csr_rdata;
    rand logic [1:0]  csr_op;
    rand logic        csr_write;
    logic        exception;
    logic [3:0]  exception_cause;
    logic        mret_exec;

    logic fp_we;
    logic [4:0] fp_rd_addr;
    logic [63:0] fp_rd_data;
    rand logic [63:0] fp_rs1_data;
    rand logic [63:0] fp_rs2_data;
    rand logic [63:0] fp_rs3_data;
    rand logic [2:0] fcsr_rm;
    logic [4:0] fflags_update;
    logic [63:0] fp_alu_result;
    rand logic amo_en;
    rand logic [4:0] amo_op;
    rand logic reservation_valid;
    logic [31:0] reservation_addr;

    constraint c_instruction {
        instruction[6:0] dist {
            7'b0110011 := 10,
            7'b0010011 := 10,
            7'b0000011 := 10,
            7'b1100111 := 10,
            7'b0100011 := 10,
            7'b1100011 := 10,
            7'b0110111 := 10,
            7'b0010111 := 10,
            7'b1101111 := 10,
            7'b0000111 := 10,
            7'b0100111 := 10,
            7'b1000011 := 10,
            7'b1000111 := 10,
            7'b1001011 := 10,
            7'b1001111 := 10,
            7'b1010011 := 10,
            7'b0101111 := 10
        };
    }

    constraint c_csr {
        csr_op dist {
            2'b00 := 10,
            2'b01 := 10,
            2'b10 := 10,
            2'b11 := 10
        };
    }

    constraint c_fcsr_rm {
        fcsr_rm dist {
            3'b000 := 10,
            3'b001 := 10,
            3'b010 := 10,
            3'b011 := 10,
            3'b100 := 10
        };
    }

    constraint c_amo_op {
        amo_op dist {
            5'b00010 := 10,
            5'b00011 := 10,
            5'b00001 := 10,
            5'b00000 := 10,
            5'b00100 := 10,
            5'b01100 := 10,
            5'b01000 := 10,
            5'b10000 := 10,
            5'b10100 := 10,
            5'b11000 := 10,
            5'b11100 := 10
        };
    }

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
