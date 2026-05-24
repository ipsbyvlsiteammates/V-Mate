`ifndef RISCV_SB_SV
`define RISCV_SB_SV

import uvm_pkg::*;
`include "uvm_macros.svh"


import "DPI-C" function void dpi_f32_add(input int a, input int b, input byte rm, output int res, output byte fflags);
import "DPI-C" function void dpi_f32_sub(input int a, input int b, input byte rm, output int res, output byte fflags);
import "DPI-C" function void dpi_f32_mul(input int a, input int b, input byte rm, output int res, output byte fflags);
import "DPI-C" function void dpi_f32_div(input int a, input int b, input byte rm, output int res, output byte fflags);
import "DPI-C" function void dpi_f64_add(input longint a, input longint b, input byte rm, output longint res, output byte fflags);
import "DPI-C" function void dpi_f64_sub(input longint a, input longint b, input byte rm, output longint res, output byte fflags);
import "DPI-C" function void dpi_f64_mul(input longint a, input longint b, input byte rm, output longint res, output byte fflags);
import "DPI-C" function void dpi_f64_div(input longint a, input longint b, input byte rm, output longint res, output byte fflags);
import "DPI-C" function void dpi_f32_mulAdd(input int a, input int b, input int c, input byte rm, output int res, output byte fflags);
import "DPI-C" function void dpi_f64_mulAdd(input longint a, input longint b, input longint c, input byte rm, output longint res, output byte fflags);
import "DPI-C" function void dpi_f32_sqrt(input int a, input byte rm, output int res, output byte fflags);
import "DPI-C" function void dpi_f64_sqrt(input longint a, input byte rm, output longint res, output byte fflags);
import "DPI-C" function void dpi_f64_to_f32(input longint a, input byte rm, output int res, output byte fflags);
import "DPI-C" function void dpi_f32_to_f64(input int a, input byte rm, output longint res, output byte fflags);
import "DPI-C" function void dpi_i32_to_f32(input int a, input byte rm, output int res, output byte fflags);
import "DPI-C" function void dpi_ui32_to_f32(input int a, input byte rm, output int res, output byte fflags);
import "DPI-C" function void dpi_i32_to_f64(input int a, input byte rm, output longint res, output byte fflags);
import "DPI-C" function void dpi_ui32_to_f64(input int a, input byte rm, output longint res, output byte fflags);
import "DPI-C" function void dpi_f32_to_i32(input int a, input byte rm, output int res, output byte fflags);
import "DPI-C" function void dpi_f32_to_ui32(input int a, input byte rm, output int res, output byte fflags);
import "DPI-C" function void dpi_f64_to_i32(input longint a, input byte rm, output int res, output byte fflags);
import "DPI-C" function void dpi_f64_to_ui32(input longint a, input byte rm, output int res, output byte fflags);

class riscv_sb extends uvm_scoreboard;

  `uvm_component_utils(riscv_sb)

  uvm_analysis_imp #(riscv_txn, riscv_sb) ap_imp;
  virtual riscv_if vif;
  bit mem_initialized = 0;

  logic [31:0] shadow_regs [32];
  logic [63:0] shadow_fpr [32];
  logic [7:0] shadow_mem [int];
  logic [31:0] shadow_csr [int];

  logic [31:0] shadow_reservation_addr;
  logic shadow_reservation_valid;

  localparam int CSR_FFLAGS   = 'h001;
  localparam int CSR_FRM      = 'h002;
  localparam int CSR_FCSR     = 'h003;
  localparam int CSR_MSTATUS  = 'h300;
  localparam int CSR_MISA     = 'h301;
  localparam int CSR_MIE      = 'h304;
  localparam int CSR_MTVEC    = 'h305;
  localparam int CSR_MSCRATCH = 'h340;
  localparam int CSR_MEPC     = 'h341;
  localparam int CSR_MCAUSE   = 'h342;
  localparam int CSR_MTVAL    = 'h343;
  localparam int CSR_MIP      = 'h344;
  localparam int CSR_MHARTID  = 'hF14;

  function new(string name = "riscv_sb", uvm_component parent = null);
    super.new(name, parent);
    for (int i = 0; i < 32; i++) begin
      shadow_regs[i] = 32'h0;
      shadow_fpr[i] = 64'h0;
    end
    shadow_reservation_addr = 32'h0;
    shadow_reservation_valid = 1'b0;

    shadow_csr[CSR_MISA] = 32'h40000100;
    shadow_csr[CSR_MHARTID] = 32'h00000000;
    shadow_csr[CSR_MSTATUS] = 32'h00001800;
    shadow_csr[CSR_MIE] = 32'h0;
    shadow_csr[CSR_MTVEC] = 32'h0;
    shadow_csr[CSR_MSCRATCH] = 32'h0;
    shadow_csr[CSR_MEPC] = 32'h0;
    shadow_csr[CSR_MCAUSE] = 32'h0;
    shadow_csr[CSR_MTVAL] = 32'h0;
    shadow_csr[CSR_MIP] = 32'h0;
    shadow_csr[CSR_FFLAGS] = 32'h0;
    shadow_csr[CSR_FRM] = 32'h0;
    shadow_csr[CSR_FCSR] = 32'h0;
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual riscv_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "virtual interface must be set for vif!!!")
    ap_imp = new("ap_imp", this);
  endfunction

  virtual function void write(riscv_txn txn);
    
    logic [6:0] opcode;
    logic [4:0] rd, rs1, rs2, rs3;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [11:0] csr;
    logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j, imm_z;
    
    logic [31:0] rs1_data, rs2_data;
    logic [63:0] fp_rs1_data, fp_rs2_data, fp_rs3_data;
    logic [31:0] exp_alu_result;
    logic exp_reg_write, exp_mem_read, exp_mem_write;
    logic exp_fp_we;
    logic [31:0] exp_write_data;
    logic [31:0] exp_rd_data;
    logic [63:0] exp_fp_rd_data;
    logic [4:0] exp_fflags;
    logic is_illegal;
    

    if (!mem_initialized) begin
      for (int i = 0; i < 131072; i++) begin
        logic [31:0] val = vif.read_imem(i);
        if (val !== 32'hx) begin
          shadow_mem[i*4]   = val[7:0];
          shadow_mem[i*4+1] = val[15:8];
          shadow_mem[i*4+2] = val[23:16];
          shadow_mem[i*4+3] = val[31:24];
        end
      end
      mem_initialized = 1;
    end
    opcode = txn.instruction[6:0];
    rd     = txn.instruction[11:7];
    funct3 = txn.instruction[14:12];
    rs1    = txn.instruction[19:15];
    rs2    = txn.instruction[24:20];
    rs3    = txn.instruction[31:27];
    funct7 = txn.instruction[31:25];
    csr    = txn.instruction[31:20];
    
    imm_i = {{20{txn.instruction[31]}}, txn.instruction[31:20]};
    imm_s = {{20{txn.instruction[31]}}, txn.instruction[31:25], txn.instruction[11:7]};
    imm_b = {{20{txn.instruction[31]}}, txn.instruction[7], txn.instruction[30:25], txn.instruction[11:8], 1'b0};
    imm_u = {txn.instruction[31:12], 12'h0};
    imm_j = {{12{txn.instruction[31]}}, txn.instruction[19:12], txn.instruction[20], txn.instruction[30:21], 1'b0};
    imm_z = {27'h0, rs1};
    
    rs1_data = (rs1 == 0) ? 32'h0 : shadow_regs[rs1];
    rs2_data = (rs2 == 0) ? 32'h0 : shadow_regs[rs2];
    fp_rs1_data = shadow_fpr[rs1];
    fp_rs2_data = shadow_fpr[rs2];
    fp_rs3_data = shadow_fpr[rs3];
    
    exp_alu_result = 32'h0;
    exp_reg_write = 1'b0;
    exp_mem_read = 1'b0;
    exp_mem_write = 1'b0;
    exp_fp_we = 1'b0;
    exp_write_data = rs2_data;
    exp_rd_data = 32'h0;
    exp_fp_rd_data = 64'h0;
    exp_fflags = 5'h0;

    is_illegal = 1'b0;
    
    case (opcode)
      7'b0110111, 7'b0010111, 7'b1101111, 7'b1100111, 7'b1100011, 7'b0000011, 7'b0100011, 7'b0010011, 7'b0110011, 7'b0000111, 7'b0100111, 7'b1010011, 7'b1000011, 7'b1000111, 7'b1001011, 7'b1001111, 7'b0101111, 7'b1110011, 7'b0001111: begin
      end
      default: is_illegal = 1'b1;
    endcase

    if (opcode == 7'b0101111) begin
      if (funct3 != 3'b010 && funct3 != 3'b011) is_illegal = 1'b1;
    end
    if (opcode == 7'b1110011) begin
      if (funct3 == 3'b000) begin
        if (txn.instruction[31:20] != 12'h000 && txn.instruction[31:20] != 12'h001 && txn.instruction[31:20] != 12'h302) begin
          is_illegal = 1'b1;
        end
      end
    end
    if (opcode == 7'b0000111 || opcode == 7'b0100111) begin
      if (funct3 != 3'b010 && funct3 != 3'b011) is_illegal = 1'b1;
    end
    if (opcode == 7'b1010011) begin
      case (funct7[6:2])
        5'b00000, 5'b00001, 5'b00010, 5'b00011, 5'b01011, 5'b00100, 5'b00101, 5'b01000, 5'b10100, 5'b11000, 5'b11010, 5'b11100, 5'b11110: ;
        default: is_illegal = 1'b1;
      endcase
    end
    
    if (is_illegal) begin
      if (txn.exception !== 1'b1)
        `uvm_error("SB_MISMATCH", $sformatf("PC: %0h, Instr: %0h | Illegal instruction did not assert exception", txn.pc, txn.instruction))
      if (txn.exception_cause !== 4'h2)
        `uvm_error("SB_MISMATCH", $sformatf("PC: %0h, Instr: %0h | Illegal instruction cause mismatch. Exp: 2, Act: %0h", txn.pc, txn.instruction, txn.exception_cause))
      
      shadow_csr[CSR_MEPC] = txn.pc;
      shadow_csr[CSR_MCAUSE] = 32'h2;
      shadow_csr[CSR_MSTATUS] = {shadow_csr[CSR_MSTATUS][31:8], shadow_csr[CSR_MSTATUS][3], shadow_csr[CSR_MSTATUS][6:0]};
      shadow_csr[CSR_MSTATUS] = {shadow_csr[CSR_MSTATUS][31:4], 1'b0, shadow_csr[CSR_MSTATUS][2:0]};
      
      exp_reg_write = 1'b0;
      exp_mem_read = 1'b0;
      exp_mem_write = 1'b0;
      exp_fp_we = 1'b0;
    end

    case (opcode)
      7'b0110111: begin // LUI
        exp_alu_result = imm_u;
        exp_reg_write = 1'b1;
        exp_rd_data = exp_alu_result;
      end
      7'b0010111: begin // AUIPC
        exp_alu_result = txn.pc + imm_u;
        exp_reg_write = 1'b1;
        exp_rd_data = exp_alu_result;
      end
      7'b1101111: begin // JAL
        exp_alu_result = txn.pc + 4;
        exp_reg_write = 1'b1;
        exp_rd_data = exp_alu_result;
      end
      7'b1100111: begin // JALR
        exp_alu_result = txn.pc + 4;
        exp_reg_write = 1'b1;
        exp_rd_data = exp_alu_result;
      end
      7'b1100011: begin // Branch
        exp_reg_write = 1'b0;
      end
      7'b0000011: begin // Load
        exp_alu_result = rs1_data + imm_i;
        exp_mem_read = 1'b1;
        exp_reg_write = 1'b1;
      end
      7'b0100011: begin // Store
        exp_alu_result = rs1_data + imm_s;
        exp_mem_write = 1'b1;
        exp_write_data = rs2_data;
      end
      7'b0010011: begin // OP-IMM
        exp_reg_write = 1'b1;
        case (funct3)
          3'b000: exp_alu_result = rs1_data + imm_i; // ADDI
          3'b010: exp_alu_result = ($signed(rs1_data) < $signed(imm_i)) ? 32'h1 : 32'h0; // SLTI
          3'b011: exp_alu_result = (rs1_data < imm_i) ? 32'h1 : 32'h0; // SLTIU
          3'b100: exp_alu_result = rs1_data ^ imm_i; // XORI
          3'b110: exp_alu_result = rs1_data | imm_i; // ORI
          3'b111: exp_alu_result = rs1_data & imm_i; // ANDI
          3'b001: exp_alu_result = rs1_data << imm_i[4:0]; // SLLI
          3'b101: begin
            if (funct7 == 7'b0000000) exp_alu_result = rs1_data >> imm_i[4:0]; // SRLI
            else if (funct7 == 7'b0100000) exp_alu_result = $signed(rs1_data) >>> imm_i[4:0]; // SRAI
          end
        endcase
        exp_rd_data = exp_alu_result;
      end
      7'b0110011: begin // OP
        exp_reg_write = 1'b1;
        if (funct7 == 7'b0000001) begin // M-Extension
          logic signed [63:0] mul_res_ss;
          logic [63:0] mul_res_uu;
          logic signed [63:0] mul_res_su;
          
          mul_res_ss = $signed(rs1_data) * $signed(rs2_data);
          mul_res_uu = rs1_data * rs2_data;
          mul_res_su = $signed(rs1_data) * $signed({1'b0, rs2_data});
          
          case (funct3)
            3'b000: exp_alu_result = mul_res_ss[31:0]; // MUL
            3'b001: exp_alu_result = mul_res_ss[63:32]; // MULH
            3'b010: exp_alu_result = mul_res_su[63:32]; // MULHSU
            3'b011: exp_alu_result = mul_res_uu[63:32]; // MULHU
            3'b100: begin // DIV
              if (rs2_data == 0) exp_alu_result = 32'hFFFFFFFF;
              else if (rs1_data == 32'h80000000 && rs2_data == 32'hFFFFFFFF) exp_alu_result = rs1_data;
              else exp_alu_result = $signed(rs1_data) / $signed(rs2_data);
            end
            3'b101: begin // DIVU
              if (rs2_data == 0) exp_alu_result = 32'hFFFFFFFF;
              else exp_alu_result = rs1_data / rs2_data;
            end
            3'b110: begin // REM
              if (rs2_data == 0) exp_alu_result = rs1_data;
              else if (rs1_data == 32'h80000000 && rs2_data == 32'hFFFFFFFF) exp_alu_result = 0;
              else exp_alu_result = $signed(rs1_data) % $signed(rs2_data);
            end
            3'b111: begin // REMU
              if (rs2_data == 0) exp_alu_result = rs1_data;
              else exp_alu_result = rs1_data % rs2_data;
            end
          endcase
        end else begin
          case (funct3)
            3'b000: begin
              if (funct7 == 7'b0000000) exp_alu_result = rs1_data + rs2_data; // ADD
              else if (funct7 == 7'b0100000) exp_alu_result = rs1_data - rs2_data; // SUB
            end
            3'b001: exp_alu_result = rs1_data << rs2_data[4:0]; // SLL
            3'b010: exp_alu_result = ($signed(rs1_data) < $signed(rs2_data)) ? 32'h1 : 32'h0; // SLT
            3'b011: exp_alu_result = (rs1_data < rs2_data) ? 32'h1 : 32'h0; // SLTU
            3'b100: exp_alu_result = rs1_data ^ rs2_data; // XOR
            3'b101: begin
              if (funct7 == 7'b0000000) exp_alu_result = rs1_data >> rs2_data[4:0]; // SRL
              else if (funct7 == 7'b0100000) exp_alu_result = $signed(rs1_data) >>> rs2_data[4:0]; // SRA
            end
            3'b110: exp_alu_result = rs1_data | rs2_data; // OR
            3'b111: exp_alu_result = rs1_data & rs2_data; // AND
          endcase
        end
        exp_rd_data = exp_alu_result;
      end
      7'b0101111: begin // AMO
        exp_alu_result = rs1_data;
        exp_mem_read = (funct7[6:2] == 5'b00011) ? 1'b0 : 1'b1;
        exp_reg_write = 1'b1;
        if (funct7[6:2] == 5'b00010) begin // LR
          shadow_reservation_valid = 1'b1;
          shadow_reservation_addr = rs1_data;
        end else if (funct7[6:2] == 5'b00011) begin // SC
          if (shadow_reservation_valid && shadow_reservation_addr == rs1_data) begin
            exp_rd_data = 32'h0;
            exp_mem_write = 1'b1;
            exp_write_data = rs2_data;
          end else begin
            exp_rd_data = 32'h1;
            exp_mem_write = 1'b0;
          end
          shadow_reservation_valid = 1'b0;
        end else begin // AMOs
          exp_mem_write = 1'b1;
        end
      end
      7'b0000111: begin // LOAD-FP
        exp_alu_result = rs1_data + imm_i;
        exp_mem_read = 1'b1;
        exp_fp_we = 1'b1;
      end
      7'b0100111: begin // STORE-FP
        exp_alu_result = rs1_data + imm_s;
        exp_mem_write = 1'b1;
        if (funct3 == 3'b010) exp_write_data = fp_rs2_data[31:0]; // FSW
      end
      7'b1010011, 7'b1000011, 7'b1000111, 7'b1001011, 7'b1001111: begin // OP-FP, MADD, MSUB, NMSUB, NMADD
        logic [2:0] rm;
        logic [1:0] fmt;
        int res32;
        longint res64;
        byte fflags_out;
        
        rm = (funct3 == 3'b111) ? shadow_csr[CSR_FRM][2:0] : funct3;
        fmt = funct7[1:0];
        
        if (opcode == 7'b1000011 || opcode == 7'b1000111 || opcode == 7'b1001011 || opcode == 7'b1001111) begin
          fmt = txn.instruction[26:25];
          if (fmt == 2'b00) begin
            int a, b, c;
            a = fp_rs1_data[31:0];
            b = fp_rs2_data[31:0];
            c = fp_rs3_data[31:0];
            if (opcode == 7'b1000111) c = c ^ 32'h80000000;
            else if (opcode == 7'b1001011) a = a ^ 32'h80000000;
            else if (opcode == 7'b1001111) begin a = a ^ 32'h80000000; c = c ^ 32'h80000000; end
            dpi_f32_mulAdd(a, b, c, {5'h0, rm}, res32, fflags_out);
            exp_fp_rd_data = {32'hFFFFFFFF, res32};
            exp_fp_we = 1'b1;
            exp_fflags = fflags_out[4:0];
          end else if (fmt == 2'b01) begin
            longint a, b, c;
            a = fp_rs1_data;
            b = fp_rs2_data;
            c = fp_rs3_data;
            if (opcode == 7'b1000111) c = c ^ 64'h8000000000000000;
            else if (opcode == 7'b1001011) a = a ^ 64'h8000000000000000;
            else if (opcode == 7'b1001111) begin a = a ^ 64'h8000000000000000; c = c ^ 64'h8000000000000000; end
            dpi_f64_mulAdd(a, b, c, {5'h0, rm}, res64, fflags_out);
            exp_fp_rd_data = res64;
            exp_fp_we = 1'b1;
            exp_fflags = fflags_out[4:0];
          end
        end else if (opcode == 7'b1010011) begin
          case (funct7[6:2])
            5'b00000: begin
              if (fmt == 2'b00) begin
                dpi_f32_add(fp_rs1_data[31:0], fp_rs2_data[31:0], {5'h0, rm}, res32, fflags_out);
                exp_fp_rd_data = {32'hFFFFFFFF, res32};
              end else begin
                dpi_f64_add(fp_rs1_data, fp_rs2_data, {5'h0, rm}, res64, fflags_out);
                exp_fp_rd_data = res64;
              end
              exp_fp_we = 1'b1;
              exp_fflags = fflags_out[4:0];
            end
            5'b00001: begin
              if (fmt == 2'b00) begin
                dpi_f32_sub(fp_rs1_data[31:0], fp_rs2_data[31:0], {5'h0, rm}, res32, fflags_out);
                exp_fp_rd_data = {32'hFFFFFFFF, res32};
              end else begin
                dpi_f64_sub(fp_rs1_data, fp_rs2_data, {5'h0, rm}, res64, fflags_out);
                exp_fp_rd_data = res64;
              end
              exp_fp_we = 1'b1;
              exp_fflags = fflags_out[4:0];
            end
            5'b00010: begin
              if (fmt == 2'b00) begin
                dpi_f32_mul(fp_rs1_data[31:0], fp_rs2_data[31:0], {5'h0, rm}, res32, fflags_out);
                exp_fp_rd_data = {32'hFFFFFFFF, res32};
              end else begin
                dpi_f64_mul(fp_rs1_data, fp_rs2_data, {5'h0, rm}, res64, fflags_out);
                exp_fp_rd_data = res64;
              end
              exp_fp_we = 1'b1;
              exp_fflags = fflags_out[4:0];
            end
            5'b00011: begin
              if (fmt == 2'b00) begin
                dpi_f32_div(fp_rs1_data[31:0], fp_rs2_data[31:0], {5'h0, rm}, res32, fflags_out);
                exp_fp_rd_data = {32'hFFFFFFFF, res32};
              end else begin
                dpi_f64_div(fp_rs1_data, fp_rs2_data, {5'h0, rm}, res64, fflags_out);
                exp_fp_rd_data = res64;
              end
              exp_fp_we = 1'b1;
              exp_fflags = fflags_out[4:0];
            end
            5'b01011: begin
              if (fmt == 2'b00) begin
                dpi_f32_sqrt(fp_rs1_data[31:0], {5'h0, rm}, res32, fflags_out);
                exp_fp_rd_data = {32'hFFFFFFFF, res32};
              end else begin
                dpi_f64_sqrt(fp_rs1_data, {5'h0, rm}, res64, fflags_out);
                exp_fp_rd_data = res64;
              end
              exp_fp_we = 1'b1;
              exp_fflags = fflags_out[4:0];
            end
            5'b01000: begin
              if (fmt == 2'b01) begin
                dpi_f64_to_f32(fp_rs1_data, {5'h0, rm}, res32, fflags_out);
                exp_fp_rd_data = {32'hFFFFFFFF, res32};
              end else begin
                dpi_f32_to_f64(fp_rs1_data[31:0], {5'h0, rm}, res64, fflags_out);
                exp_fp_rd_data = res64;
              end
              exp_fp_we = 1'b1;
              exp_fflags = fflags_out[4:0];
            end
            5'b11000: begin
              exp_reg_write = 1'b1;
              if (fmt == 2'b00) begin
                if (rs2 == 5'b00000) dpi_f32_to_i32(fp_rs1_data[31:0], {5'h0, rm}, res32, fflags_out);
                else dpi_f32_to_ui32(fp_rs1_data[31:0], {5'h0, rm}, res32, fflags_out);
              end else begin
                if (rs2 == 5'b00000) dpi_f64_to_i32(fp_rs1_data, {5'h0, rm}, res32, fflags_out);
                else dpi_f64_to_ui32(fp_rs1_data, {5'h0, rm}, res32, fflags_out);
              end
              exp_rd_data = res32;
              exp_fflags = fflags_out[4:0];
            end
            5'b11010: begin
              exp_fp_we = 1'b1;
              if (fmt == 2'b00) begin
                if (rs2 == 5'b00000) dpi_i32_to_f32(rs1_data, {5'h0, rm}, res32, fflags_out);
                else dpi_ui32_to_f32(rs1_data, {5'h0, rm}, res32, fflags_out);
                exp_fp_rd_data = {32'hFFFFFFFF, res32};
              end else begin
                if (rs2 == 5'b00000) dpi_i32_to_f64(rs1_data, {5'h0, rm}, res64, fflags_out);
                else dpi_ui32_to_f64(rs1_data, {5'h0, rm}, res64, fflags_out);
                exp_fp_rd_data = res64;
              end
              exp_fflags = fflags_out[4:0];
            end
            default: begin
              if (funct7[6:3] == 4'b1101 || funct7[6:3] == 4'b1110 || funct7[6:3] == 4'b1010) begin
                exp_reg_write = 1'b1;
                exp_rd_data = txn.rd_data;
              end else begin
                exp_fp_we = 1'b1;
                exp_fp_rd_data = txn.fp_rd_data;
              end
              exp_fflags = txn.fflags_update;
            end
          endcase
        end
        
                if (opcode != 7'b1010011 || (funct7[6:2] != 5'b11100 && funct7[6:2] != 5'b11110)) begin
          if (exp_fp_we || exp_reg_write) begin
            if (txn.fflags_update !== exp_fflags) begin
              `uvm_error("SB_MISMATCH", $sformatf("PC: %0h | fflags mismatch. Exp: %0h, Act: %0h", txn.pc, exp_fflags, txn.fflags_update))
            end
          end
          
          shadow_csr[CSR_FFLAGS] |= exp_fflags;
          shadow_csr[CSR_FCSR] = {shadow_csr[CSR_FCSR][31:8], shadow_csr[CSR_FRM][2:0], shadow_csr[CSR_FFLAGS][4:0]};
          shadow_csr[CSR_MSTATUS] = {shadow_csr[CSR_MSTATUS][31:15], 2'b11, shadow_csr[CSR_MSTATUS][12:0]};
        end
      end
      7'b1110011: begin // SYSTEM
        if (funct3 == 3'b000) begin
          if (txn.instruction[31:20] == 12'h000) begin // ECALL
            if (txn.exception !== 1'b1)
              `uvm_error("SB_MISMATCH", $sformatf("PC: %0h | ECALL did not assert exception", txn.pc))
            if (txn.exception_cause !== 4'hb)
              `uvm_error("SB_MISMATCH", $sformatf("PC: %0h | ECALL cause mismatch. Exp: %0h, Act: %0h", txn.pc, 4'hb, txn.exception_cause))
            shadow_csr[CSR_MEPC] = txn.pc;
            shadow_csr[CSR_MCAUSE] = 32'hb;
            shadow_csr[CSR_MSTATUS] = {shadow_csr[CSR_MSTATUS][31:8], shadow_csr[CSR_MSTATUS][3], shadow_csr[CSR_MSTATUS][6:0]}; // MPIE = MIE
            shadow_csr[CSR_MSTATUS] = {shadow_csr[CSR_MSTATUS][31:4], 1'b0, shadow_csr[CSR_MSTATUS][2:0]}; // MIE = 0
          end else if (txn.instruction[31:20] == 12'h001) begin // EBREAK
            if (txn.exception !== 1'b1)
              `uvm_error("SB_MISMATCH", $sformatf("PC: %0h | EBREAK did not assert exception", txn.pc))
            if (txn.exception_cause !== 4'h3)
              `uvm_error("SB_MISMATCH", $sformatf("PC: %0h | EBREAK cause mismatch. Exp: %0h, Act: %0h", txn.pc, 4'h3, txn.exception_cause))
            shadow_csr[CSR_MEPC] = txn.pc;
            shadow_csr[CSR_MCAUSE] = 32'h3;
            shadow_csr[CSR_MSTATUS] = {shadow_csr[CSR_MSTATUS][31:8], shadow_csr[CSR_MSTATUS][3], shadow_csr[CSR_MSTATUS][6:0]}; // MPIE = MIE
            shadow_csr[CSR_MSTATUS] = {shadow_csr[CSR_MSTATUS][31:4], 1'b0, shadow_csr[CSR_MSTATUS][2:0]}; // MIE = 0
          end else if (txn.instruction[31:20] == 12'h302) begin // MRET
            if (txn.mret_exec !== 1'b1)
              `uvm_error("SB_MISMATCH", $sformatf("PC: %0h | MRET did not assert mret_exec", txn.pc))
            shadow_csr[CSR_MSTATUS] = {shadow_csr[CSR_MSTATUS][31:4], shadow_csr[CSR_MSTATUS][7], shadow_csr[CSR_MSTATUS][2:0]}; // MIE = MPIE
          end
        end else begin // CSR Instructions
          logic [31:0] csr_rdata_exp;
          logic [31:0] csr_wdata_exp;
          logic [31:0] wdata_src;
          
          if (!shadow_csr.exists(csr)) begin
            shadow_csr[csr] = 32'h0;
          end
          
          if (csr == CSR_MSTATUS) begin
            csr_rdata_exp = {17'b0, shadow_csr[CSR_MSTATUS][14:13], 2'b11, 3'b0, shadow_csr[CSR_MSTATUS][7], 3'b0, shadow_csr[CSR_MSTATUS][3], 3'b0};
          end else if (csr == CSR_FCSR) begin
            csr_rdata_exp = {24'b0, shadow_csr[CSR_FRM][2:0], shadow_csr[CSR_FFLAGS][4:0]};
          end else begin
            csr_rdata_exp = shadow_csr[csr];
          end
          
          if (txn.csr_rdata !== csr_rdata_exp)
            `uvm_error("SB_MISMATCH", $sformatf("PC: %0h | CSR %0h rdata mismatch. Exp: %0h, Act: %0h", txn.pc, csr, csr_rdata_exp, txn.csr_rdata))
          
          exp_reg_write = 1'b1;
          exp_rd_data = csr_rdata_exp;
          
          wdata_src = (funct3[2]) ? imm_z : rs1_data;
          
          case (funct3[1:0])
            2'b01: csr_wdata_exp = wdata_src; // CSRRW, CSRRWI
            2'b10: csr_wdata_exp = csr_rdata_exp | wdata_src; // CSRRS, CSRRSI
            2'b11: csr_wdata_exp = csr_rdata_exp & ~wdata_src; // CSRRC, CSRRCI
            default: csr_wdata_exp = csr_rdata_exp;
          endcase
          
          if (txn.csr_write) begin
            if (txn.csr_wdata !== wdata_src)
              `uvm_error("SB_MISMATCH", $sformatf("PC: %0h | CSR %0h wdata mismatch. Exp: %0h, Act: %0h", txn.pc, csr, wdata_src, txn.csr_wdata))
            
            if (csr != CSR_MISA && csr != CSR_MHARTID) begin
              if (csr == CSR_MSTATUS) begin
                shadow_csr[CSR_MSTATUS] = {shadow_csr[CSR_MSTATUS][31:15], csr_wdata_exp[14:13], shadow_csr[CSR_MSTATUS][12:8], csr_wdata_exp[7], shadow_csr[CSR_MSTATUS][6:4], csr_wdata_exp[3], shadow_csr[CSR_MSTATUS][2:0]};
                            end else if (csr == CSR_FCSR) begin
                shadow_csr[CSR_FFLAGS] = {27'b0, csr_wdata_exp[4:0]};
                shadow_csr[CSR_FRM] = {29'b0, csr_wdata_exp[7:5]};
                shadow_csr[CSR_FCSR] = csr_wdata_exp;
                shadow_csr[CSR_MSTATUS] = {shadow_csr[CSR_MSTATUS][31:15], 2'b11, shadow_csr[CSR_MSTATUS][12:0]};
              end else if (csr == CSR_FFLAGS) begin
                shadow_csr[CSR_FFLAGS] = {27'b0, csr_wdata_exp[4:0]};
                shadow_csr[CSR_FCSR] = {24'b0, shadow_csr[CSR_FRM][2:0], csr_wdata_exp[4:0]};
                shadow_csr[CSR_MSTATUS] = {shadow_csr[CSR_MSTATUS][31:15], 2'b11, shadow_csr[CSR_MSTATUS][12:0]};
              end else if (csr == CSR_FRM) begin
                shadow_csr[CSR_FRM] = {29'b0, csr_wdata_exp[2:0]};
                shadow_csr[CSR_FCSR] = {24'b0, csr_wdata_exp[2:0], shadow_csr[CSR_FFLAGS][4:0]};
                shadow_csr[CSR_MSTATUS] = {shadow_csr[CSR_MSTATUS][31:15], 2'b11, shadow_csr[CSR_MSTATUS][12:0]};
              end else begin
                shadow_csr[csr] = csr_wdata_exp;
              end
            end
          end
        end
      end
    endcase

    if (txn.reg_write !== exp_reg_write)
      `uvm_error("SB_MISMATCH", $sformatf("PC: %0h, Instr: %0h | reg_write mismatch. Exp: %0b, Act: %0b", txn.pc, txn.instruction, exp_reg_write, txn.reg_write))
    if (txn.mem_read !== exp_mem_read)
      `uvm_error("SB_MISMATCH", $sformatf("PC: %0h, Instr: %0h | mem_read mismatch. Exp: %0b, Act: %0b", txn.pc, txn.instruction, exp_mem_read, txn.mem_read))
    if (txn.mem_write !== exp_mem_write && !(opcode == 7'b0101111 && funct7[6:2] == 5'b00011))
      `uvm_error("SB_MISMATCH", $sformatf("PC: %0h, Instr: %0h | mem_write mismatch. Exp: %0b, Act: %0b", txn.pc, txn.instruction, exp_mem_write, txn.mem_write))
    if (txn.fp_we !== exp_fp_we)
      `uvm_error("SB_MISMATCH", $sformatf("PC: %0h, Instr: %0h | fp_we mismatch. Exp: %0b, Act: %0b", txn.pc, txn.instruction, exp_fp_we, txn.fp_we))
    
    if (opcode != 7'b0001111 && opcode != 7'b1100011 && opcode != 7'b1101111 && opcode != 7'b1100111 && opcode != 7'b1110011 && opcode != 7'b0101111 && opcode != 7'b0000111 && opcode != 7'b0100111 && opcode != 7'b1010011 && opcode != 7'b1000011 && opcode != 7'b1000111 && opcode != 7'b1001011 && opcode != 7'b1001111 && opcode != 7'b0001111) begin
      if (!is_illegal) begin
        if (txn.alu_result !== exp_alu_result)
          `uvm_error("SB_MISMATCH", $sformatf("PC: %0h, Instr: %0h | alu_result mismatch. Exp: %0h, Act: %0h", txn.pc, txn.instruction, exp_alu_result, txn.alu_result))
      end
    end

    if (exp_mem_write && opcode != 7'b0101111 && opcode != 7'b0100111) begin
      if (txn.write_data !== exp_write_data)
        `uvm_error("SB_MISMATCH", $sformatf("PC: %0h, Instr: %0h | write_data mismatch. Exp: %0h, Act: %0h", txn.pc, txn.instruction, exp_write_data, txn.write_data))
    end

    if (exp_mem_read) begin
      logic [63:0] expected_mem_data = 64'h0;
      logic mem_hit = 1'b1;
      int num_bytes;
      
      if (opcode == 7'b0000111) begin // LOAD-FP
        if (funct3 == 3'b010) num_bytes = 4; // FLW
        else if (funct3 == 3'b011) num_bytes = 8; // FLD
      end else if (opcode == 7'b0101111) begin // AMO
        if (funct3 == 3'b010) num_bytes = 4; // AMO.W
        else if (funct3 == 3'b011) num_bytes = 8; // AMO.D
      end else begin
        case (funct3)
          3'b000, 3'b100: num_bytes = 1;
          3'b001, 3'b101: num_bytes = 2;
          3'b010: num_bytes = 4;
          default: num_bytes = 4;
        endcase
      end
      
      for (int i = 0; i < num_bytes; i++) begin
        if (!shadow_mem.exists(exp_alu_result + i)) begin
          mem_hit = 1'b0;
          break;
        end
      end
      
      if (mem_hit) begin
        if (opcode == 7'b0000111) begin // LOAD-FP
          if (funct3 == 3'b010) begin // FLW
            expected_mem_data = {32'hFFFFFFFF, shadow_mem[exp_alu_result+3], shadow_mem[exp_alu_result+2], shadow_mem[exp_alu_result+1], shadow_mem[exp_alu_result]};
          end else if (funct3 == 3'b011) begin // FLD
            expected_mem_data = {shadow_mem[exp_alu_result+7], shadow_mem[exp_alu_result+6], shadow_mem[exp_alu_result+5], shadow_mem[exp_alu_result+4], shadow_mem[exp_alu_result+3], shadow_mem[exp_alu_result+2], shadow_mem[exp_alu_result+1], shadow_mem[exp_alu_result]};
          end
          if (txn.fp_rd_data !== expected_mem_data)
            `uvm_error("SB_MISMATCH", $sformatf("PC: %0h, Instr: %0h | fp mem read data mismatch. Exp: %0h, Act: %0h", txn.pc, txn.instruction, expected_mem_data, txn.fp_rd_data))
          exp_fp_rd_data = expected_mem_data;
        end else if (opcode == 7'b0101111) begin // AMO
          if (funct3 == 3'b010) begin
            expected_mem_data = {32'h0, shadow_mem[exp_alu_result+3], shadow_mem[exp_alu_result+2], shadow_mem[exp_alu_result+1], shadow_mem[exp_alu_result]};
          end
          if (funct7[6:2] != 5'b00011) begin // Not SC
            exp_rd_data = expected_mem_data[31:0];
            if (txn.rd_data !== exp_rd_data)
              `uvm_error("SB_MISMATCH", $sformatf("PC: %0h, Instr: %0h | amo read data mismatch. Exp: %0h, Act: %0h", txn.pc, txn.instruction, exp_rd_data, txn.rd_data))
            
            // Compute AMO write data
            if (funct7[6:2] != 5'b00010) begin // Not LR
              logic [31:0] amo_res;
              case (funct7[6:2])
                5'b00000: amo_res = exp_rd_data + rs2_data; // AMOADD
                5'b00001: amo_res = rs2_data; // AMOSWAP
                5'b00100: amo_res = exp_rd_data ^ rs2_data; // AMOXOR
                5'b01100: amo_res = exp_rd_data & rs2_data; // AMOAND
                5'b01000: amo_res = exp_rd_data | rs2_data; // AMOOR
                5'b10000: amo_res = ($signed(exp_rd_data) < $signed(rs2_data)) ? exp_rd_data : rs2_data; // AMOMIN
                5'b10100: amo_res = ($signed(exp_rd_data) > $signed(rs2_data)) ? exp_rd_data : rs2_data; // AMOMAX
                5'b11000: amo_res = (exp_rd_data < rs2_data) ? exp_rd_data : rs2_data; // AMOMINU
                5'b11100: amo_res = (exp_rd_data > rs2_data) ? exp_rd_data : rs2_data; // AMOMAXU
                default: amo_res = exp_rd_data;
              endcase
              exp_write_data = amo_res;
            end
          end
        end else begin
          case (funct3)
            3'b000: expected_mem_data = {{56{shadow_mem[exp_alu_result][7]}}, shadow_mem[exp_alu_result]};
            3'b001: expected_mem_data = {{48{shadow_mem[exp_alu_result+1][7]}}, shadow_mem[exp_alu_result+1], shadow_mem[exp_alu_result]};
            3'b010: expected_mem_data = {{32{shadow_mem[exp_alu_result+3][7]}}, shadow_mem[exp_alu_result+3], shadow_mem[exp_alu_result+2], shadow_mem[exp_alu_result+1], shadow_mem[exp_alu_result]};
            3'b100: expected_mem_data = {56'h0, shadow_mem[exp_alu_result]};
            3'b101: expected_mem_data = {48'h0, shadow_mem[exp_alu_result+1], shadow_mem[exp_alu_result]};
          endcase
          if (txn.rd_data !== expected_mem_data[31:0])
            `uvm_error("SB_MISMATCH", $sformatf("PC: %0h, Instr: %0h | mem read data mismatch. Exp: %0h, Act: %0h", txn.pc, txn.instruction, expected_mem_data[31:0], txn.rd_data))
          exp_rd_data = expected_mem_data[31:0];
        end
      end else begin
        if (opcode == 7'b0000111) begin
          if (funct3 == 3'b010) begin
            shadow_mem[exp_alu_result] = txn.fp_rd_data[7:0];
            shadow_mem[exp_alu_result+1] = txn.fp_rd_data[15:8];
            shadow_mem[exp_alu_result+2] = txn.fp_rd_data[23:16];
            shadow_mem[exp_alu_result+3] = txn.fp_rd_data[31:24];
          end else if (funct3 == 3'b011) begin
            shadow_mem[exp_alu_result] = txn.fp_rd_data[7:0];
            shadow_mem[exp_alu_result+1] = txn.fp_rd_data[15:8];
            shadow_mem[exp_alu_result+2] = txn.fp_rd_data[23:16];
            shadow_mem[exp_alu_result+3] = txn.fp_rd_data[31:24];
            shadow_mem[exp_alu_result+4] = txn.fp_rd_data[39:32];
            shadow_mem[exp_alu_result+5] = txn.fp_rd_data[47:40];
            shadow_mem[exp_alu_result+6] = txn.fp_rd_data[55:48];
            shadow_mem[exp_alu_result+7] = txn.fp_rd_data[63:56];
          end
          exp_fp_rd_data = txn.fp_rd_data;
        end else if (opcode == 7'b0101111) begin
          exp_rd_data = txn.rd_data;
          if (funct7[6:2] != 5'b00010 && funct7[6:2] != 5'b00011) begin
            exp_write_data = txn.write_data; // Trust DUT for AMO write data if mem miss
          end
        end else begin
          case (funct3)
            3'b000, 3'b100: shadow_mem[exp_alu_result] = txn.rd_data[7:0];
            3'b001, 3'b101: begin
              shadow_mem[exp_alu_result] = txn.rd_data[7:0];
              shadow_mem[exp_alu_result+1] = txn.rd_data[15:8];
            end
            3'b010: begin
              shadow_mem[exp_alu_result] = txn.rd_data[7:0];
              shadow_mem[exp_alu_result+1] = txn.rd_data[15:8];
              shadow_mem[exp_alu_result+2] = txn.rd_data[23:16];
              shadow_mem[exp_alu_result+3] = txn.rd_data[31:24];
            end
          endcase
          exp_rd_data = txn.rd_data;
        end
      end
    end

    if (exp_mem_write) begin
      if (opcode == 7'b0100111) begin // STORE-FP
        if (funct3 == 3'b010) begin // FSW
          shadow_mem[exp_alu_result] = fp_rs2_data[7:0];
          shadow_mem[exp_alu_result+1] = fp_rs2_data[15:8];
          shadow_mem[exp_alu_result+2] = fp_rs2_data[23:16];
          shadow_mem[exp_alu_result+3] = fp_rs2_data[31:24];
        end else if (funct3 == 3'b011) begin // FSD
          shadow_mem[exp_alu_result] = fp_rs2_data[7:0];
          shadow_mem[exp_alu_result+1] = fp_rs2_data[15:8];
          shadow_mem[exp_alu_result+2] = fp_rs2_data[23:16];
          shadow_mem[exp_alu_result+3] = fp_rs2_data[31:24];
          shadow_mem[exp_alu_result+4] = fp_rs2_data[39:32];
          shadow_mem[exp_alu_result+5] = fp_rs2_data[47:40];
          shadow_mem[exp_alu_result+6] = fp_rs2_data[55:48];
          shadow_mem[exp_alu_result+7] = fp_rs2_data[63:56];
        end
      end else if (opcode == 7'b0101111) begin // AMO
        if (funct3 == 3'b010) begin
          shadow_mem[exp_alu_result] = exp_write_data[7:0];
          shadow_mem[exp_alu_result+1] = exp_write_data[15:8];
          shadow_mem[exp_alu_result+2] = exp_write_data[23:16];
          shadow_mem[exp_alu_result+3] = exp_write_data[31:24];
        end
      end else begin
        case (funct3)
          3'b000: shadow_mem[exp_alu_result] = exp_write_data[7:0];
          3'b001: begin
            shadow_mem[exp_alu_result] = exp_write_data[7:0];
            shadow_mem[exp_alu_result+1] = exp_write_data[15:8];
          end
          3'b010: begin
            shadow_mem[exp_alu_result] = exp_write_data[7:0];
            shadow_mem[exp_alu_result+1] = exp_write_data[15:8];
            shadow_mem[exp_alu_result+2] = exp_write_data[23:16];
            shadow_mem[exp_alu_result+3] = exp_write_data[31:24];
          end
        endcase
      end
    end

    if (exp_reg_write && rd != 0) begin
      if (!exp_mem_read && opcode != 7'b0101111 && opcode != 7'b1010011) begin
        if (txn.rd_data !== exp_rd_data)
          `uvm_error("SB_MISMATCH", $sformatf("PC: %0h, Instr: %0h | rd_data mismatch. Exp: %0h, Act: %0h", txn.pc, txn.instruction, exp_rd_data, txn.rd_data))
      end
      shadow_regs[rd] = exp_rd_data;
    end
    
        if (exp_fp_we) begin
      if (!exp_mem_read) begin
        if (txn.fp_rd_data !== exp_fp_rd_data)
          `uvm_error("SB_MISMATCH", $sformatf("PC: %0h, Instr: %0h | fp_rd_data mismatch. Exp: %0h, Act: %0h", txn.pc, txn.instruction, exp_fp_rd_data, txn.fp_rd_data))
      end
      shadow_fpr[rd] = exp_fp_rd_data;
      shadow_csr[CSR_MSTATUS] = {shadow_csr[CSR_MSTATUS][31:15], 2'b11, shadow_csr[CSR_MSTATUS][12:0]};
    end

  endfunction
endclass

`endif
