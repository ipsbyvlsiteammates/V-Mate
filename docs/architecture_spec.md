# RISC-V RV32IMAFD Pipelined Out-of-Order Processor Architecture Specification

| Field | Value |
|-------|-------|
| **Project** | V-mate RISC-V RV32IMAFD Processor |
| **Version** | 3.0 |
| **Date** | 2026-05-20 |
| **Author** | Sagi |
| **ISA Version** | RV32IMAFD Base + Extensions, Machine-Level Privileged Architecture |
| **Toolchain** | Synopsys VCS (simulation), Verdi (waveform viewing) |

---

## 1. Overview

This document specifies the architecture of a 5-stage pipelined, Out-of-Order (OoO) implementation of the RISC-V RV32IMAFD Instruction Set Architecture. The processor represents a comprehensive implementation of the RV32 ISA with advanced extensions and privileged architecture.

### Design Philosophy

- **Correctness first:** Every instruction must produce architecturally correct results.
- **Performance:** 5-stage pipeline with Out-of-Order (OoO) execution (ROB, RAT, Issue Queue) to maximize throughput. OoO is controlled via CSR 0x7C0 (default disabled).
- **Completeness:** Implements Base Integer (I), Multiply/Divide (M), Atomics (A), Single-Precision FP (F), Double-Precision FP (D), and Privileged Architecture (M-mode).
- **Power Efficiency:** Integrated auto-clock gating (ICG) and fine-grained clock gating to reduce dynamic power consumption.
- **Robust FPU:** IEEE 754 compliant FPU with NaN-boxing handled in the execution units and memory load stage, not in the register file.

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
*(Omitted for brevity, identical to base RV32IMAFD)*

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
    |   PC    |                              | Fetch/  |
    |         |                              | Decode  |
    +----+----+                              +----+----+
         ^                                        |
         |                                        v
         |                               +-----------------+
         |                               |  Issue Queue /  |
         |                               |  RAT / ROB      |
         |                               +--------+--------+
         |                                        |
         |          +------------------+          |
         +----------+   PC Source      |          v
                    |     MUX          |    +-----------+
                    +------------------+    | Immediate |
                                            | Generator |
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
**Purpose:** Reduces dynamic power by gating the global clock when the processor is idle or stalled. Fine-grained clock gating is also implemented.

### 4.2 Program Counter (PC)
**Purpose:** Holds the address of the current instruction. Updated to handle exceptions, branches, and `MRET`.

### 4.3 Instruction Memory (IMEM)
**Purpose:** Read-only memory storing the program instructions.

### 4.4 Register File
**Purpose:** 32 general-purpose 32-bit registers with x0 hardwired to zero.

### 4.5 Immediate Generator
**Purpose:** Extracts and sign-extends immediate values from all instruction formats.

### 4.6 ALU
**Purpose:** Performs all arithmetic, logic, and M-extension operations (Multiply/Divide).

### 4.7 Data Memory (DMEM)
**Purpose:** Read/write memory for load/store and atomic operations.

### 4.8 Control Unit & OoO Logic
**Purpose:** Decodes instructions and manages the 5-stage pipeline. Includes Reorder Buffer (ROB), Register Alias Table (RAT), and Issue Queue for Out-of-Order execution. OoO is controlled via CSR 0x7C0.

### 4.9 CSR File
**Purpose:** Manages Control and Status Registers for exceptions, interrupts, and machine state (M-mode).

### 4.10 Floating-Point Register File (FPR)
**Purpose:** 32 floating-point registers, 64 bits wide (for D extension). NaN-boxing is handled in the execution units and memory load stage, not here.

### 4.11 Floating-Point ALU (FP ALU)
**Purpose:** IEEE 754 compliant floating-point arithmetic unit.

---

## 5. Datapath Description

### 5-Stage Pipelined Datapath Flow

#### Stage 1: Instruction Fetch (IF)
1. PC provides address to IMEM.
2. IMEM returns 32-bit instruction.

#### Stage 2: Instruction Decode (ID) / Issue
1. Instruction decoded by Control Unit.
2. Integer RF, FPR, and CSR File read operands.
3. Instructions are dispatched to the Issue Queue, RAT renames registers, and ROB allocates entries for OoO execution.

#### Stage 3: Execute (EX)
1. Integer ALU performs arithmetic, logic, or M-extension operations.
2. FP ALU performs floating-point operations. NaN-boxing is applied here.
3. Branch/Jump targets and conditions evaluated.

#### Stage 4: Memory Access (MEM)
1. DMEM accessed for loads, stores, or atomic operations.
2. NaN-boxing is applied to FP loads.

#### Stage 5: Write-Back (WB) / Commit
1. Results written back to Integer RF, FPR, or CSR File in program order via the ROB.
2. PC updated with PC+4, branch/jump target, or exception/trap vector.

---

## 6. Memory Interface
*(Omitted for brevity, identical to base RV32IMAFD)*

---

## 7. Design Constraints
- **Clock:** Single clock domain with auto-clock gating (ICG) and fine-grained gating.
- **Reset:** Synchronous active-low reset (`rst_n`).

---

## 8. Module Hierarchy
```text
riscv_top
├── u_global_icg        (Integrated Clock Gating)
├── u_pc                (Program Counter)
├── u_imem              (Instruction Memory)
├── u_register_file     (Integer Register File)
├── u_imm_gen           (Immediate Generator)
├── u_alu               (Arithmetic Logic Unit with M-ext)
├── u_control_unit      (Main Control Unit with ROB, RAT, Issue Queue)
├── u_dmem              (Data Memory with A-ext)
├── gen_csr.u_csr_file  (Control and Status Registers)
├── gen_fp.u_fpr        (Floating-Point Register File)
└── gen_fp.u_fp_alu     (Floating-Point ALU)
```