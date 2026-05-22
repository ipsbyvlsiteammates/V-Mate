# RISC-V RV32IMAFD Single-Cycle Processor Architecture Specification

| Field | Value |
|-------|-------|
| **Project** | RISC-V RV32IMAFD Single-Cycle Processor |
| **Version** | 2.0 |
| **Date** | 2024-05-20 |
| **Author** | Sagi |
| **ISA Version** | RV32IMAFD Base + Extensions, Machine-Level Privileged Architecture |
| **Toolchain** | Synopsys VCS (simulation), Verdi (waveform viewing) |

---

## 1. Overview

This document specifies the architecture of a single-cycle implementation of the RISC-V RV32IMAFD Instruction Set Architecture. The processor executes each instruction in exactly one clock cycle, representing a comprehensive implementation of the RV32 ISA with advanced extensions and privileged architecture.

### Design Philosophy

- **Correctness first:** Every instruction must produce architecturally correct results.
- **Simplicity:** Single-cycle design with no pipeline hazards or forwarding logic.
- **Completeness:** Implements Base Integer (I), Multiply/Divide (M), Atomics (A), Single-Precision FP (F), Double-Precision FP (D), and Privileged Architecture.
- **Power Efficiency:** Integrated auto-clock gating (ICG) to reduce dynamic power consumption.
- **Testability:** Modular design enabling unit-level and integration-level verification.

### Target ISA

Key characteristics:
- Fixed 32-bit instruction length (IALIGN=32).
- 32 integer registers (32-bit) and 32 floating-point registers (64-bit for D extension).
- Program counter (pc) register.
- Control and Status Registers (CSRs) for exception handling and machine state.
- IEEE 754 compliant FPU.
- Little-endian byte addressing.

---

## 2. Instruction Set Summary

### 2.1 Instruction Formats

RV32IMAFD uses the standard base formats (R, I, S, B, U, J) plus the R4-type format for fused multiply-add floating-point instructions.

```text
  31        25 24    20 19    15 14  12 11     7 6      0
 +----------+--------+--------+------+---------+--------+
 |  funct7  |  rs2   |  rs1   |funct3|   rd    | opcode | R-Type
 +----------+--------+--------+------+---------+--------+

  31               27 26 25 24 20 19 15 14 12 11 7 6    0
 +-------------------+--+--------+-----+-----+----+-----+
 |       rs3         |fm|  rs2   | rs1 | rm  | rd |opcode| R4-Type
 +-------------------+--+--------+-----+-----+----+-----+
```
*(Other standard formats omitted for brevity, identical to base RV32I)*

### 2.2 Instruction List by Category

#### Base Integer Instructions (RV32I)
- **Arithmetic:** ADD, SUB, ADDI, LUI, AUIPC
- **Logical:** AND, OR, XOR, ANDI, ORI, XORI
- **Shift:** SLL, SRL, SRA, SLLI, SRLI, SRAI
- **Compare:** SLT, SLTU, SLTI, SLTIU
- **Branch:** BEQ, BNE, BLT, BGE, BLTU, BGEU
- **Jump:** JAL, JALR
- **Load/Store:** LB, LH, LW, LBU, LHU, SB, SH, SW
- **System:** ECALL, EBREAK, FENCE

#### Multiply/Divide Instructions (RV32M)
- **Multiply:** MUL, MULH, MULHSU, MULHU
- **Divide/Remainder:** DIV, DIVU, REM, REMU

#### Atomic Instructions (RV32A)
- **Memory:** LR.W, SC.W
- **Atomic ALU:** AMOSWAP.W, AMOADD.W, AMOXOR.W, AMOAND.W, AMOOR.W, AMOMIN.W, AMOMAX.W, AMOMINU.W, AMOMAXU.W

#### Floating-Point Instructions (RV32F / RV32D)
- **Loads/Stores:** FLW, FLD, FSW, FSD
- **Arithmetic:** FADD.S/D, FSUB.S/D, FMUL.S/D, FDIV.S/D, FSQRT.S/D, FMADD.S/D, FMSUB.S/D, FNMSUB.S/D, FNMADD.S/D
- **Sign Injection:** FSGNJ.S/D, FSGNJN.S/D, FSGNJX.S/D
- **Min/Max:** FMIN.S/D, FMAX.S/D
- **Conversion:** FCVT.S.D, FCVT.D.S, FCVT.W.S/D, FCVT.WU.S/D, FCVT.S/D.W, FCVT.S/D.WU
- **Move:** FMV.X.W, FMV.W.X, FMV.X.D, FMV.D.X
- **Compare:** FEQ.S/D, FLT.S/D, FLE.S/D
- **Classify:** FCLASS.S/D

#### Privileged & CSR Instructions (Zicsr)
- **CSR Access:** CSRRW, CSRRS, CSRRC, CSRRWI, CSRRSI, CSRRCI
- **Trap Return:** MRET
- **Wait for Interrupt:** WFI

---

## 3. Top-Level Block Diagram

```text
                    +------------------+
                    |   Instruction    |
         +--------->|     Memory       |----------+
         |          |     (IMEM)       |          |
         |          +------------------+          |
         |                                        | instr[31:0]
    +----+----+                                   |
    |         |                              +----v----+
    |   PC    |                              | Control |
    |         |                              |  Unit   |
    +----+----+                              +----+----+
         ^                                        | control signals
         |          +------------------+          |
         |          |                  |          v
         +----------+   PC Source      |    +-----------+
                    |     MUX          |    | Immediate |
                    +------------------+    | Generator |
                                            +-----------+
                                                  |
              +-----------------------------------+
              |                                   |
         +----v----+                         +----v----+
         | Register|    rs1_data             |  ALU    |
         |  File   +---------+-------------->| Source  |
         | (32x32) |         |               |  MUX   |
         |         | rs2_data|               +----+----+
         +----+----+---------+                    |
              ^              |               +----v----+
              |              |               |         |
              |              +-------------->|   ALU   |
              |              |               | (w/ M)  |
              |              |               +----+----+
              |              |                    |
              |              v                    v
         +----+----+   +----------+         +---------+
         | WB MUX  |   |   Data   |<--------|  ALU    |
         |         |<--|  Memory  |         | Result  |
         +---------+   |  (DMEM)  |         +---------+
                       +----------+

         +------------------------------------------------+
         |               Floating-Point Unit              |
         |  +---------+    +---------+    +------------+  |
         |  |   FPR   |--->| FP ALU  |--->| FP WB MUX  |  |
         |  +---------+    +---------+    +------------+  |
         +------------------------------------------------+

         +------------------------------------------------+
         |            Privileged Architecture             |
         |  +---------+    +---------+                    |
         |  | CSR File|    |   ICG   |                    |
         |  +---------+    +---------+                    |
         +------------------------------------------------+
```

---

## 4. Module Descriptions

### 4.1 Clock Gating (ICG)
**Purpose:** Reduces dynamic power by gating the global clock when the processor is idle or stalled.
- **Inputs:** `clk`, `en`
- **Outputs:** `gated_clk`

### 4.2 Program Counter (PC)
**Purpose:** Holds the address of the current instruction. Updated to handle exceptions and `MRET`.
- **Inputs:** `clk`, `rst_n`, `pc_sel`, `pc_target`, `exception`, `mtvec`, `mret_exec`, `mepc`
- **Outputs:** `pc_out`

### 4.3 Instruction Memory (IMEM)
**Purpose:** Read-only memory storing the program instructions.
- **Size:** 512 KB

### 4.4 Register File
**Purpose:** 32 general-purpose 32-bit registers with x0 hardwired to zero.

### 4.5 Immediate Generator
**Purpose:** Extracts and sign-extends immediate values from all instruction formats.

### 4.6 ALU
**Purpose:** Performs all arithmetic, logic, and M-extension operations (Multiply/Divide).
- **Parameters:** `EXTENSION_M`

### 4.7 Data Memory (DMEM)
**Purpose:** Read/write memory for load/store and atomic operations.
- **Size:** 512 KB
- **Features:** Supports 64-bit data width for D-extension, and handles A-extension atomic operations (`amo_en`, `amo_op`).

### 4.8 Control Unit
**Purpose:** Decodes instructions and generates control signals for all extensions.
- **Parameters:** `PRIVILEGED`, `EXTENSION_M`, `EXTENSION_A`, `EXTENSION_F`, `EXTENSION_D`
- **Outputs:** Integer control, FP control, CSR control, AMO control, Exception control.

### 4.9 CSR File
**Purpose:** Manages Control and Status Registers for exceptions, interrupts, and machine state.
- **Features:** Handles `mepc`, `mtvec`, `mstatus`, `fcsr` (for FP rounding mode and flags).

### 4.10 Floating-Point Register File (FPR)
**Purpose:** 32 floating-point registers, 64 bits wide (for D extension).

### 4.11 Floating-Point ALU (FP ALU)
**Purpose:** IEEE 754 compliant floating-point arithmetic unit.
- **Features:** Supports single (F) and double (D) precision operations, rounding modes, and exception flags.

---

## 5. Datapath Description

### Single-Cycle Datapath Flow

All stages complete within a single clock cycle:

#### Stage 1: Instruction Fetch
1. PC provides address to IMEM.
2. IMEM returns 32-bit instruction.

#### Stage 2: Instruction Decode
1. Instruction decoded by Control Unit.
2. Integer RF, FPR, and CSR File read operands.
3. Immediate Generator extracts immediate.

#### Stage 3: Execute
1. Integer ALU performs arithmetic, logic, or M-extension operations.
2. FP ALU performs floating-point operations.
3. Branch/Jump targets and conditions evaluated.

#### Stage 4: Memory Access
1. DMEM accessed for loads, stores, or atomic operations.
2. 64-bit data path utilized for D-extension memory accesses.

#### Stage 5: Write-Back
1. Results written back to Integer RF, FPR, or CSR File.
2. PC updated with PC+4, branch/jump target, or exception/trap vector.

---

## 6. Control Signals Table (Extended)

| Instruction Category | reg_write | mem_write | alu_src | branch | jump | fp_we | csr_write | amo_en |
|----------------------|-----------|-----------|---------|--------|------|-------|-----------|--------|
| Integer ALU          | 1         | 0         | 0/1     | 0      | 0    | 0     | 0         | 0      |
| Load                 | 1         | 0         | 1       | 0      | 0    | 0     | 0         | 0      |
| Store                | 0         | 1         | 1       | 0      | 0    | 0     | 0         | 0      |
| Branch               | 0         | 0         | 0       | 1      | 0    | 0     | 0         | 0      |
| Jump (JAL/JALR)      | 1         | 0         | 1       | 0      | 1    | 0     | 0         | 0      |
| FP Load              | 0         | 0         | 1       | 0      | 0    | 1     | 0         | 0      |
| FP Store             | 0         | 1         | 1       | 0      | 0    | 0     | 0         | 0      |
| FP ALU               | 0/1       | 0         | X       | 0      | 0    | 1/0   | 0         | 0      |
| CSR Access           | 1         | 0         | X       | 0      | 0    | 0     | 1         | 0      |
| Atomic (AMO)         | 1         | 1         | 0       | 0      | 0    | 0     | 0         | 1      |

---

## 7. Memory Interface

### Address Space
- 32-bit byte-addressable address space.
- Separate Instruction and Data memories (Harvard architecture).

### Instruction Memory
- **Size:** 512 KB (131,072 words)
- **Access:** Word-aligned only.

### Data Memory
- **Size:** 512 KB
- **Access:** Byte, halfword, word, and doubleword (for D-extension).
- **Features:** Supports atomic read-modify-write operations.

---

## 8. Design Constraints

### Clock & Reset
- **Clock:** Single clock domain with auto-clock gating (ICG) for power savings.
- **Reset:** Synchronous active-low reset (`rst_n`).

### Simplifications
- Single-cycle design (no pipelining).
- No cache (direct memory access).
- Natural alignment assumed for memory accesses.

---

## 9. Module Hierarchy

```text
riscv_top
├── u_global_icg        (Integrated Clock Gating)
├── u_pc                (Program Counter)
├── u_imem              (Instruction Memory)
├── u_register_file     (Integer Register File)
├── u_imm_gen           (Immediate Generator)
├── u_alu               (Arithmetic Logic Unit with M-ext)
├── u_control_unit      (Main Control Unit)
├── u_dmem              (Data Memory with A-ext)
├── gen_csr.u_csr_file  (Control and Status Registers)
├── gen_fp.u_fpr        (Floating-Point Register File)
└── gen_fp.u_fp_alu     (Floating-Point ALU)
```

---

## 10. Future Extensions

| Extension | Description | Impact |
|-----------|-------------|--------|
| C Extension | Compressed Instructions | Add instruction decompressor in fetch stage |
| V Extension | Vector Operations | Major addition of vector registers and ALUs |
| Pipelining | 5-stage pipeline | Major restructure, add hazard detection/forwarding |
| Cache | Instruction and data caches | Add cache controllers, handle stalls |
| MMU | Virtual Memory Support | Add TLB and page table walker |
| Privilege | Supervisor/User Modes | Expand CSRs, add memory protection |

---

*End of Architecture Specification*