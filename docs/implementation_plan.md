# RV32I Single-Cycle Processor — Implementation Plan

**Project:** RISC-V RV32I Single-Cycle Processor
**Team:** Hu-mind VLSI Team
**Author:** Sagi
**Date:** 2026-05-11
**Location:** `/home/guy/Sagi/riscv_processor/`
**Simulation Toolchain:** Synopsys VCS

---

## Table of Contents

1. [Overview](#overview)
2. [Directory Structure](#directory-structure)
3. [General VCS Workflow](#general-vcs-workflow)
4. [Phase 1: ALU Module](#phase-1-alu-module)
5. [Phase 2: Register File](#phase-2-register-file)
6. [Phase 3: Immediate Generator](#phase-3-immediate-generator)
7. [Phase 4: Program Counter and Instruction Memory](#phase-4-program-counter-and-instruction-memory)
8. [Phase 5: Control Unit](#phase-5-control-unit)
9. [Phase 6: Data Memory](#phase-6-data-memory)
10. [Phase 7: Single-Cycle Datapath Integration](#phase-7-single-cycle-datapath-integration)
11. [Phase 8: Load/Store Instructions](#phase-8-loadstore-instructions)
12. [Phase 9: Branch and Jump Instructions](#phase-9-branch-and-jump-instructions)
13. [Phase 10: Full ISA Verification](#phase-10-full-isa-verification)
14. [Phase Dependency Graph](#phase-dependency-graph)
15. [Summary Table](#summary-table)

---

## Overview

This document describes the incremental implementation plan for a RISC-V RV32I single-cycle processor in Verilog. The processor implements all 47 base integer instructions as defined in Chapter 2 of the RISC-V Unprivileged ISA Specification (pages 42–58).

Each phase produces one or more RTL modules along with a dedicated unit or integration testbench. **No phase may begin until all pass criteria of its prerequisite phases have been met.** This ensures a solid, verified foundation at every step.

---

## Directory Structure

```
/home/guy/Sagi/riscv_processor/
├── rtl/
│   ├── core/          # Core processor modules
│   │   ├── alu.v
│   │   ├── register_file.v
│   │   ├── imm_gen.v
│   │   ├── pc.v
│   │   ├── control_unit.v
│   │   └── riscv_top.v
│   └── mem/           # Memory modules
│       ├── imem.v
│       └── dmem.v
├── tb/
│   ├── unit/          # Unit testbenches
│   │   ├── tb_alu.sv
│   │   ├── tb_register_file.sv
│   │   ├── tb_imm_gen.sv
│   │   ├── tb_pc.sv
│   │   ├── tb_imem.sv
│   │   ├── tb_control_unit.sv
│   │   └── tb_dmem.sv
│   └── top/           # Integration testbenches
│       ├── tb_riscv_top.sv
│       └── test_programs/
│           ├── r_type_test.hex
│           ├── i_type_test.hex
│           ├── load_store_test.hex
│           ├── branch_jump_test.hex
│           └── full_isa_test.hex
├── sim/               # Simulation scripts and file lists
│   ├── filelist_alu.f
│   ├── filelist_register_file.f
│   ├── filelist_imm_gen.f
│   ├── filelist_pc.f
│   ├── filelist_imem.f
│   ├── filelist_control_unit.f
│   ├── filelist_dmem.f
│   └── filelist_riscv_top.f
├── docs/              # Documentation
│   ├── architecture_spec.md
│   └── implementation_plan.md   # ← This document
└── scripts/           # Build and utility scripts
```

---

## General VCS Workflow

Every verification step follows this exact procedure:

```bash
# 1. Navigate to simulation directory
cd /home/guy/Sagi/riscv_processor/sim/

# 2. Compile design and testbench
vcs -sverilog -debug_access+all -kdb -lca -f <filelist_name>.f

# 3. Run simulation
./simv

# 4. Check simulation output for PASS/FAIL
#    - Every testbench must print "TEST PASSED" on success
#    - Every testbench must print "TEST FAILED" and $finish on any failure
#    - Return code 0 = pass, non-zero = fail
```

**Testbench conventions:**
- All testbenches use SystemVerilog (`.sv` extension)
- Each test case prints: `[PASS] <test_name>` or `[FAIL] <test_name>: expected=<X>, got=<Y>`
- At the end of simulation, print a summary: `"TEST PASSED: <N>/<N> tests passed"` or `"TEST FAILED: <M>/<N> tests failed"`
- Use `$finish` to terminate simulation
- Use `$error` for failure reporting

---

## Phase 1: ALU Module

### Objective

Implement the Arithmetic Logic Unit supporting all RV32I computational operations. This is the core execution engine of the processor and has no dependencies on other modules.

### Files to Create

| File | Path | Description |
|------|------|-------------|
| `alu.v` | `rtl/core/alu.v` | ALU module |
| `tb_alu.sv` | `tb/unit/tb_alu.sv` | ALU unit testbench |
| `filelist_alu.f` | `sim/filelist_alu.f` | VCS file list for ALU test |

### Module Interface

```verilog
module alu (
    input  wire [31:0] operand_a,    // First operand (rs1 value)
    input  wire [31:0] operand_b,    // Second operand (rs2 value or immediate)
    input  wire [3:0]  alu_op,       // ALU operation select
    output wire [31:0] alu_result,   // ALU result
    output wire        zero_flag     // Result is zero (used for branches)
);
```

### ALU Operations

| alu_op | Operation | Description |
|--------|-----------|-------------|
| 4'b0000 | ADD | `operand_a + operand_b` |
| 4'b0001 | SUB | `operand_a - operand_b` |
| 4'b0010 | AND | `operand_a & operand_b` |
| 4'b0011 | OR  | `operand_a \| operand_b` |
| 4'b0100 | XOR | `operand_a ^ operand_b` |
| 4'b0101 | SLT | Signed less-than comparison |
| 4'b0110 | SLTU | Unsigned less-than comparison |
| 4'b0111 | SLL | Shift left logical (by operand_b[4:0]) |
| 4'b1000 | SRL | Shift right logical (by operand_b[4:0]) |
| 4'b1001 | SRA | Shift right arithmetic (by operand_b[4:0]) |

### Testbench Requirements

The testbench (`tb_alu.sv`) must verify:

1. **ADD:** Positive + positive, negative + negative, overflow cases, zero result
2. **SUB:** Basic subtraction, result = 0, negative result
3. **AND:** All-ones, all-zeros, mixed patterns
4. **OR:** All-ones, all-zeros, mixed patterns
5. **XOR:** Same operands (→ 0), complementary operands (→ all-ones)
6. **SLT:** Positive vs negative, equal values, boundary values (e.g., 0x7FFFFFFF vs 0x80000000)
7. **SLTU:** Unsigned comparison, 0 vs max, boundary cases
8. **SLL:** Shift by 0, shift by 1, shift by 31
9. **SRL:** Shift by 0, shift by 1, shift by 31, MSB = 1 (verify zero-fill)
10. **SRA:** Shift by 0, shift by 1, shift by 31, MSB = 1 (verify sign-extension)
11. **Zero flag:** Verify zero_flag asserts when result = 0, deasserts otherwise

Minimum: **3 test vectors per operation**, total ≥ 30 test cases.

### File List (`sim/filelist_alu.f`)

```
../rtl/core/alu.v
../tb/unit/tb_alu.sv
```

### Verification Procedure

```bash
cd /home/guy/Sagi/riscv_processor/sim/
vcs -sverilog -debug_access+all -kdb -lca -f filelist_alu.f
./simv
```

### Pass/Fail Criteria

- **PASS:** All ≥ 30 test cases print `[PASS]`. Final summary: `"TEST PASSED: N/N tests passed"`
- **FAIL:** Any test case prints `[FAIL]` with expected vs actual values. Final summary shows failure count.

### Dependencies

None — this is the first phase.

### Estimated Complexity

**Simple** — Combinational logic only, well-defined operations.

---

## Phase 2: Register File

### Objective

Implement the 32×32-bit register file with two asynchronous read ports and one synchronous write port, with register x0 hardwired to zero.

### Files to Create

| File | Path | Description |
|------|------|-------------|
| `register_file.v` | `rtl/core/register_file.v` | Register file module |
| `tb_register_file.sv` | `tb/unit/tb_register_file.sv` | Register file unit testbench |
| `filelist_register_file.f` | `sim/filelist_register_file.f` | VCS file list |

### Module Interface

```verilog
module register_file (
    input  wire        clk,
    input  wire        rst_n,         // Active-low reset
    input  wire        we,            // Write enable
    input  wire [4:0]  rs1_addr,      // Read port 1 address
    input  wire [4:0]  rs2_addr,      // Read port 2 address
    input  wire [4:0]  rd_addr,       // Write port address
    input  wire [31:0] rd_data,       // Write data
    output wire [31:0] rs1_data,      // Read port 1 data
    output wire [31:0] rs2_data       // Read port 2 data
);
```

### Testbench Requirements

1. **Reset behavior:** After reset, all registers read as 0
2. **Write and read back:** Write to register x1–x31, read back and verify
3. **x0 hardwired to zero:** Write non-zero value to x0, read back — must return 0
4. **Simultaneous read:** Read two different registers in the same cycle
5. **Write-then-read same cycle:** Write to a register and read it in the same cycle (verify forwarding behavior or one-cycle latency — document which is implemented)
6. **All registers:** Write unique values to all 32 registers, read all back
7. **Write enable:** Verify that data is NOT written when `we = 0`

Minimum: **15 test cases**.

### File List (`sim/filelist_register_file.f`)

```
../rtl/core/register_file.v
../tb/unit/tb_register_file.sv
```

### Verification Procedure

```bash
cd /home/guy/Sagi/riscv_processor/sim/
vcs -sverilog -debug_access+all -kdb -lca -f filelist_register_file.f
./simv
```

### Pass/Fail Criteria

- **PASS:** All ≥ 15 test cases pass. x0 always returns 0 regardless of writes. Write enable correctly gates writes.
- **FAIL:** Any register returns incorrect data, or x0 returns non-zero.

### Dependencies

None — independent of Phase 1.

### Estimated Complexity

**Simple** — Standard register file design.

---

## Phase 3: Immediate Generator

### Objective

Implement the immediate extraction and sign-extension logic for all six RV32I instruction formats (R, I, S, B, U, J).

### Files to Create

| File | Path | Description |
|------|------|-------------|
| `imm_gen.v` | `rtl/core/imm_gen.v` | Immediate generator module |
| `tb_imm_gen.sv` | `tb/unit/tb_imm_gen.sv` | Immediate generator unit testbench |
| `filelist_imm_gen.f` | `sim/filelist_imm_gen.f` | VCS file list |

### Module Interface

```verilog
module imm_gen (
    input  wire [31:0] instruction,   // Full 32-bit instruction
    input  wire [2:0]  imm_sel,       // Immediate format select
    output wire [31:0] imm_out        // Sign-extended immediate
);
```

### Immediate Formats

| imm_sel | Format | Immediate Bits |
|---------|--------|----------------|
| 3'b000 | I-type | `{inst[31], {20{inst[31]}}, inst[30:20]}` |
| 3'b001 | S-type | `{inst[31], {20{inst[31]}}, inst[30:25], inst[11:7]}` |
| 3'b010 | B-type | `{inst[31], {19{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0}` |
| 3'b011 | U-type | `{inst[31:12], 12'b0}` |
| 3'b100 | J-type | `{inst[31], {11{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0}` |

### Testbench Requirements

1. **I-type:** Positive immediate, negative immediate, zero, max positive (2047), max negative (-2048)
2. **S-type:** Positive offset, negative offset, zero
3. **B-type:** Positive offset, negative offset, verify LSB is always 0
4. **U-type:** Various upper immediate values, verify lower 12 bits are 0
5. **J-type:** Positive offset, negative offset, verify LSB is always 0, large offset
6. **Sign extension:** Verify sign bit propagation for all signed formats

Minimum: **18 test cases** (≥ 3 per format, plus sign-extension edge cases).

### File List (`sim/filelist_imm_gen.f`)

```
../rtl/core/imm_gen.v
../tb/unit/tb_imm_gen.sv
```

### Verification Procedure

```bash
cd /home/guy/Sagi/riscv_processor/sim/
vcs -sverilog -debug_access+all -kdb -lca -f filelist_imm_gen.f
./simv
```

### Pass/Fail Criteria

- **PASS:** All ≥ 18 test cases produce correct sign-extended immediate values matching hand-computed expected values.
- **FAIL:** Any immediate value is incorrect.

### Dependencies

None — independent of Phases 1 and 2.

### Estimated Complexity

**Simple** — Combinational bit manipulation and sign extension.

---

## Phase 4: Program Counter and Instruction Memory

### Objective

Implement the program counter register (with reset, sequential increment, and branch/jump target loading) and the instruction memory (read-only, initialized from a hex file).

### Files to Create

| File | Path | Description |
|------|------|-------------|
| `pc.v` | `rtl/core/pc.v` | Program counter module |
| `imem.v` | `rtl/mem/imem.v` | Instruction memory module |
| `tb_pc.sv` | `tb/unit/tb_pc.sv` | PC unit testbench |
| `tb_imem.sv` | `tb/unit/tb_imem.sv` | Instruction memory unit testbench |
| `filelist_pc.f` | `sim/filelist_pc.f` | VCS file list for PC test |
| `filelist_imem.f` | `sim/filelist_imem.f` | VCS file list for IMEM test |

### Module Interfaces

```verilog
module pc (
    input  wire        clk,
    input  wire        rst_n,         // Active-low reset
    input  wire        pc_sel,        // 0 = PC+4, 1 = branch/jump target
    input  wire [31:0] pc_target,     // Branch/jump target address
    output reg  [31:0] pc_out         // Current PC value
);
```

```verilog
module imem (
    input  wire [31:0] addr,          // Byte address
    output wire [31:0] instruction    // Instruction at addr
);
```

### Design Notes

- **PC:** Resets to `32'h0000_0000`. On each rising clock edge: if `pc_sel == 0`, `pc_out <= pc_out + 4`; if `pc_sel == 1`, `pc_out <= pc_target`.
- **IMEM:** Word-addressed internally (addr[31:2] used as index). Initialized using `$readmemh` from a `.hex` file. Size: 1024 words (4 KB) initially.

### Testbench Requirements

**tb_pc.sv:**
1. Reset: PC = 0 after reset
2. Sequential increment: PC advances by 4 each cycle when `pc_sel = 0`
3. Branch target: PC loads target when `pc_sel = 1`
4. Return to sequential: After branch, PC resumes +4 increment
5. Multiple branches: Consecutive branch targets

Minimum: **8 test cases**.

**tb_imem.sv:**
1. Read first instruction (address 0)
2. Read sequential instructions (addresses 0, 4, 8, ...)
3. Read non-sequential address
4. Verify known instruction values from preloaded hex file
5. Boundary: Read last valid address

Minimum: **6 test cases**.

### File Lists

**`sim/filelist_pc.f`:**
```
../rtl/core/pc.v
../tb/unit/tb_pc.sv
```

**`sim/filelist_imem.f`:**
```
../rtl/mem/imem.v
../tb/unit/tb_imem.sv
```

### Verification Procedure

```bash
# PC test
cd /home/guy/Sagi/riscv_processor/sim/
vcs -sverilog -debug_access+all -kdb -lca -f filelist_pc.f
./simv

# IMEM test
vcs -sverilog -debug_access+all -kdb -lca -f filelist_imem.f
./simv
```

### Pass/Fail Criteria

- **PASS (PC):** All ≥ 8 test cases pass. PC resets to 0, increments by 4, loads branch targets correctly.
- **PASS (IMEM):** All ≥ 6 test cases pass. Instructions match expected values from hex file.
- **FAIL:** Any PC value or instruction readback is incorrect.

### Dependencies

None — independent of Phases 1–3.

### Estimated Complexity

**Simple** — PC is a simple register with mux; IMEM is a ROM with `$readmemh`.

---

## Phase 5: Control Unit

### Objective

Implement the main control decoder and ALU control logic that generates all control signals based on the instruction opcode, funct3, and funct7 fields for every RV32I instruction type.

### Files to Create

| File | Path | Description |
|------|------|-------------|
| `control_unit.v` | `rtl/core/control_unit.v` | Control unit module |
| `tb_control_unit.sv` | `tb/unit/tb_control_unit.sv` | Control unit testbench |
| `filelist_control_unit.f` | `sim/filelist_control_unit.f` | VCS file list |

### Module Interface

```verilog
module control_unit (
    input  wire [6:0]  opcode,        // instruction[6:0]
    input  wire [2:0]  funct3,        // instruction[14:12]
    input  wire [6:0]  funct7,        // instruction[31:25]
    output wire        reg_write,     // Write enable for register file
    output wire [1:0]  result_sel,    // Writeback mux: 00=ALU, 01=DMEM, 10=PC+4
    output wire        mem_write,     // Data memory write enable
    output wire        mem_read,      // Data memory read enable
    output wire        alu_src,       // ALU operand B: 0=rs2, 1=immediate
    output wire [2:0]  imm_sel,       // Immediate format select
    output wire        branch,        // Branch instruction flag
    output wire        jump,          // Jump instruction flag (JAL/JALR)
    output wire [3:0]  alu_op,        // ALU operation select
    output wire [2:0]  mem_size       // Memory access size (funct3 for loads/stores)
);
```

### Control Signal Truth Table (Key Entries)

| Instruction Type | opcode | reg_write | result_sel | mem_write | alu_src | branch | jump |
|-----------------|--------|-----------|------------|-----------|---------|--------|------|
| R-type          | 0110011 | 1 | 00 | 0 | 0 | 0 | 0 |
| I-type ALU      | 0010011 | 1 | 00 | 0 | 1 | 0 | 0 |
| Load            | 0000011 | 1 | 01 | 0 | 1 | 0 | 0 |
| Store           | 0100011 | 0 | xx | 1 | 1 | 0 | 0 |
| Branch          | 1100011 | 0 | xx | 0 | 0 | 1 | 0 |
| JAL             | 1101111 | 1 | 10 | 0 | x | 0 | 1 |
| JALR            | 1100111 | 1 | 10 | 0 | 1 | 0 | 1 |
| LUI             | 0110111 | 1 | 00 | 0 | 1 | 0 | 0 |
| AUIPC           | 0010111 | 1 | 00 | 0 | 1 | 0 | 0 |

### Testbench Requirements

1. **R-type instructions:** Test all 10 R-type variants (ADD, SUB, AND, OR, XOR, SLT, SLTU, SLL, SRL, SRA) — verify correct `alu_op` for each
2. **I-type ALU:** Test ADDI, ANDI, ORI, XORI, SLTI, SLTIU, SLLI, SRLI, SRAI — verify `alu_src = 1` and correct `alu_op`
3. **Load instructions:** LB, LH, LW, LBU, LHU — verify `mem_read`, `result_sel`, `mem_size`
4. **Store instructions:** SB, SH, SW — verify `mem_write`, `reg_write = 0`
5. **Branch instructions:** BEQ, BNE, BLT, BGE, BLTU, BGEU — verify `branch = 1`, correct `alu_op` for comparison
6. **JAL:** Verify `jump = 1`, `result_sel = 10` (PC+4 writeback)
7. **JALR:** Verify `jump = 1`, `alu_src = 1`, `result_sel = 10`
8. **LUI:** Verify correct control signals
9. **AUIPC:** Verify correct control signals

Minimum: **25 test cases** (one per unique instruction encoding).

### File List (`sim/filelist_control_unit.f`)

```
../rtl/core/control_unit.v
../tb/unit/tb_control_unit.sv
```

### Verification Procedure

```bash
cd /home/guy/Sagi/riscv_processor/sim/
vcs -sverilog -debug_access+all -kdb -lca -f filelist_control_unit.f
./simv
```

### Pass/Fail Criteria

- **PASS:** All ≥ 25 test cases produce correct control signals for every RV32I instruction type. Each signal is individually verified.
- **FAIL:** Any control signal is incorrect for any instruction type.

### Dependencies

None — but the ALU operation encoding (Phase 1) must be consistent with `alu_op` values generated here. **Design coordination required with Phase 1.**

### Estimated Complexity

**Medium** — Many instruction types and control signal combinations to handle correctly.

---

## Phase 6: Data Memory

### Objective

Implement the data memory module supporting byte, halfword, and word read/write operations with proper sign extension for loads.

### Files to Create

| File | Path | Description |
|------|------|-------------|
| `dmem.v` | `rtl/mem/dmem.v` | Data memory module |
| `tb_dmem.sv` | `tb/unit/tb_dmem.sv` | Data memory unit testbench |
| `filelist_dmem.f` | `sim/filelist_dmem.f` | VCS file list |

### Module Interface

```verilog
module dmem (
    input  wire        clk,
    input  wire        mem_write,     // Write enable
    input  wire        mem_read,      // Read enable
    input  wire [31:0] addr,          // Byte address
    input  wire [31:0] write_data,    // Data to write
    input  wire [2:0]  mem_size,      // funct3: 000=byte, 001=half, 010=word, 100=byte-u, 101=half-u
    output wire [31:0] read_data      // Data read (sign/zero extended)
);
```

### Design Notes

- Memory size: 4096 bytes (1024 words) initially
- Byte-addressable
- Read data sign extension:
  - LB (funct3=000): Sign-extend byte to 32 bits
  - LH (funct3=001): Sign-extend halfword to 32 bits
  - LW (funct3=010): No extension needed
  - LBU (funct3=100): Zero-extend byte to 32 bits
  - LHU (funct3=101): Zero-extend halfword to 32 bits
- Write granularity:
  - SB (funct3=000): Write byte
  - SH (funct3=001): Write halfword
  - SW (funct3=010): Write word

### Testbench Requirements

1. **Word write/read:** Write a word, read it back
2. **Byte write/read (LB):** Write a byte with MSB=1, read back with sign extension
3. **Byte write/read (LBU):** Write a byte with MSB=1, read back with zero extension
4. **Halfword write/read (LH):** Write a halfword with MSB=1, read back with sign extension
5. **Halfword write/read (LHU):** Write a halfword with MSB=1, read back with zero extension
6. **Byte within word:** Write a word, then overwrite one byte, read back full word to verify only that byte changed
7. **Halfword within word:** Similar to above for halfword
8. **Address alignment:** Test various byte offsets within a word
9. **Multiple addresses:** Write to different addresses, read all back
10. **Read without write enable:** Verify memory is not modified when `mem_write = 0`

Minimum: **15 test cases**.

### File List (`sim/filelist_dmem.f`)

```
../rtl/mem/dmem.v
../tb/unit/tb_dmem.sv
```

### Verification Procedure

```bash
cd /home/guy/Sagi/riscv_processor/sim/
vcs -sverilog -debug_access+all -kdb -lca -f filelist_dmem.f
./simv
```

### Pass/Fail Criteria

- **PASS:** All ≥ 15 test cases pass. All access sizes work correctly. Sign/zero extension is correct for all load types. Byte/halfword writes only modify the targeted bytes.
- **FAIL:** Any read returns incorrect data, or sign/zero extension is wrong.

### Dependencies

None — independent module. However, `mem_size` encoding must be consistent with control unit (Phase 5).

### Estimated Complexity

**Medium** — Byte-addressable memory with sub-word access and sign extension requires careful implementation.

---

## Phase 7: Single-Cycle Datapath Integration

### Objective

Wire all previously verified modules together into the top-level single-cycle processor (`riscv_top.v`) and verify correct execution of R-type and I-type arithmetic instructions.

### Files to Create

| File | Path | Description |
|------|------|-------------|
| `riscv_top.v` | `rtl/core/riscv_top.v` | Top-level processor module |
| `tb_riscv_top.sv` | `tb/top/tb_riscv_top.sv` | Integration testbench |
| `r_type_test.hex` | `tb/top/test_programs/r_type_test.hex` | R-type test program (hex) |
| `i_type_test.hex` | `tb/top/test_programs/i_type_test.hex` | I-type test program (hex) |
| `filelist_riscv_top.f` | `sim/filelist_riscv_top.f` | VCS file list for integration |

### Module Interface

```verilog
module riscv_top (
    input  wire        clk,
    input  wire        rst_n
);
```

### Internal Datapath Connections

```
PC → IMEM → Instruction
                ↓
         Control Unit → control signals
                ↓
         Register File (rs1, rs2 read)
                ↓
         Immediate Generator
                ↓
         ALU (operand_a = rs1, operand_b = rs2 or imm)
                ↓
         Data Memory (for loads/stores)
                ↓
         Writeback Mux → Register File (rd write)
                ↓
         Next PC Mux → PC
```

### Test Program (R-type example)

```assembly
# R-type test program
addi x1, x0, 5       # x1 = 5
addi x2, x0, 3       # x2 = 3
add  x3, x1, x2      # x3 = 8
sub  x4, x1, x2      # x4 = 2
and  x5, x1, x2      # x5 = 1
or   x6, x1, x2      # x6 = 7
xor  x7, x1, x2      # x7 = 6
slt  x8, x2, x1      # x8 = 1 (3 < 5)
sll  x9, x1, x2      # x9 = 40 (5 << 3)
srl  x10, x1, x2     # x10 = 0 (5 >> 3)
```

### Testbench Approach

- Load test program hex file into instruction memory
- Run simulation for a fixed number of cycles
- After execution, read register file values and compare against expected results
- Use `$readmemh` to initialize IMEM
- Testbench monitors register writes and checks final register state

### File List (`sim/filelist_riscv_top.f`)

```
../rtl/core/alu.v
../rtl/core/register_file.v
../rtl/core/imm_gen.v
../rtl/core/pc.v
../rtl/core/control_unit.v
../rtl/mem/imem.v
../rtl/mem/dmem.v
../rtl/core/riscv_top.v
../tb/top/tb_riscv_top.sv
```

### Verification Procedure

```bash
cd /home/guy/Sagi/riscv_processor/sim/
vcs -sverilog -debug_access+all -kdb -lca -f filelist_riscv_top.f
./simv
```

### Pass/Fail Criteria

- **PASS:** After executing the R-type and I-type test programs, all destination registers contain the expected values. Testbench prints register dump and comparison.
- **FAIL:** Any register contains an incorrect value after program execution.

### Dependencies

**All of Phases 1–6 must pass before starting Phase 7.**

### Estimated Complexity

**Complex** — First integration of all modules. Wiring errors, signal width mismatches, and timing issues are likely. Expect debugging iterations.

---

## Phase 8: Load/Store Instructions

### Objective

Verify that load and store instructions (LB, LH, LW, LBU, LHU, SB, SH, SW) execute correctly through the integrated processor datapath.

### Files to Create

| File | Path | Description |
|------|------|-------------|
| `load_store_test.hex` | `tb/top/test_programs/load_store_test.hex` | Load/store test program |

### Test Program

```assembly
# Load/Store test program
addi x1, x0, 0x1A2   # x1 = 0x1A2 (test data)
sw   x1, 0(x0)        # MEM[0] = 0x000001A2
lw   x2, 0(x0)        # x2 = 0x000001A2
lh   x3, 0(x0)        # x3 = 0x000001A2 (sign-extended halfword)
lhu  x4, 0(x0)        # x4 = 0x000001A2 (zero-extended halfword)
lb   x5, 0(x0)        # x5 = 0xFFFFFFA2 (sign-extended byte, 0xA2 has MSB=1)
lbu  x6, 0(x0)        # x6 = 0x000000A2 (zero-extended byte)
addi x7, x0, 0xFF     # x7 = 0xFF
sb   x7, 4(x0)        # MEM[4] byte 0 = 0xFF
lb   x8, 4(x0)        # x8 = 0xFFFFFFFF (sign-extended 0xFF)
lbu  x9, 4(x0)        # x9 = 0x000000FF (zero-extended 0xFF)
sh   x1, 8(x0)        # MEM[8] halfword 0 = 0x01A2
lh   x10, 8(x0)       # x10 = 0x000001A2
# Test with offset addressing
addi x11, x0, 16      # x11 = 16 (base address)
sw   x1, 4(x11)       # MEM[20] = 0x000001A2
lw   x12, 4(x11)      # x12 = 0x000001A2
```

### Verification Procedure

```bash
cd /home/guy/Sagi/riscv_processor/sim/
vcs -sverilog -debug_access+all -kdb -lca -f filelist_riscv_top.f
./simv +PROGRAM=load_store_test.hex
```

*(The testbench should accept a plusarg or be modified to load the appropriate hex file.)*

### Pass/Fail Criteria

- **PASS:** All destination registers contain expected values after program execution:
  - Word loads return full 32-bit values
  - Signed byte/halfword loads are correctly sign-extended
  - Unsigned byte/halfword loads are correctly zero-extended
  - Store followed by load returns the stored value
  - Offset addressing works correctly
- **FAIL:** Any register or memory value is incorrect.

### Dependencies

**Phase 7 must pass** (integrated datapath working for R-type/I-type).

### Estimated Complexity

**Medium** — Memory path already exists from Phase 7; this phase validates the load/store data path including sign/zero extension through the full pipeline.

---

## Phase 9: Branch and Jump Instructions

### Objective

Verify that all branch instructions (BEQ, BNE, BLT, BGE, BLTU, BGEU) and jump instructions (JAL, JALR) execute correctly, including PC update and link register writeback.

### Files to Create

| File | Path | Description |
|------|------|-------------|
| `branch_jump_test.hex` | `tb/top/test_programs/branch_jump_test.hex` | Branch/jump test program |

### Test Program

```assembly
# Branch and Jump test program

# --- BEQ test ---
addi x1, x0, 5
addi x2, x0, 5
beq  x1, x2, beq_taken    # Should branch (5 == 5)
addi x3, x0, 0            # Should be skipped
beq_taken:
addi x3, x0, 1            # x3 = 1 (branch was taken)

# --- BNE test ---
addi x4, x0, 3
bne  x1, x4, bne_taken    # Should branch (5 != 3)
addi x5, x0, 0            # Should be skipped
bne_taken:
addi x5, x0, 1            # x5 = 1

# --- BLT test ---
addi x6, x0, -1           # x6 = -1 (signed)
blt  x6, x1, blt_taken    # Should branch (-1 < 5 signed)
addi x7, x0, 0
blt_taken:
addi x7, x0, 1            # x7 = 1

# --- BGE test ---
bge  x1, x4, bge_taken    # Should branch (5 >= 3)
addi x8, x0, 0
bge_taken:
addi x8, x0, 1            # x8 = 1

# --- BLTU test ---
bltu x4, x1, bltu_taken   # Should branch (3 < 5 unsigned)
addi x9, x0, 0
bltu_taken:
addi x9, x0, 1            # x9 = 1

# --- BGEU test ---
bgeu x1, x4, bgeu_taken   # Should branch (5 >= 3 unsigned)
addi x10, x0, 0
bgeu_taken:
addi x10, x0, 1           # x10 = 1

# --- Branch NOT taken test ---
beq  x1, x4, should_not_branch  # Should NOT branch (5 != 3)
addi x11, x0, 1           # x11 = 1 (this should execute)
should_not_branch:

# --- JAL test ---
jal  x12, jal_target       # x12 = PC+4 (return address)
addi x13, x0, 0            # Should be skipped
jal_target:
addi x13, x0, 1            # x13 = 1

# --- JALR test ---
addi x14, x0, jalr_target  # x14 = address of jalr_target (needs relocation)
jalr x15, x14, 0           # x15 = PC+4, jump to x14
addi x16, x0, 0            # Should be skipped
jalr_target:
addi x16, x0, 1            # x16 = 1
```

*(Note: The actual hex encoding will need correct address calculations for branch offsets and jump targets.)*

### Verification Procedure

```bash
cd /home/guy/Sagi/riscv_processor/sim/
vcs -sverilog -debug_access+all -kdb -lca -f filelist_riscv_top.f
./simv +PROGRAM=branch_jump_test.hex
```

### Pass/Fail Criteria

- **PASS:**
  - All taken branches skip the correct number of instructions
  - All not-taken branches fall through correctly
  - BEQ/BNE: Equality comparison correct
  - BLT/BGE: Signed comparison correct (especially negative numbers)
  - BLTU/BGEU: Unsigned comparison correct
  - JAL: PC jumps to target, rd = PC+4
  - JALR: PC jumps to (rs1 + imm) with LSB cleared, rd = PC+4
  - Link registers (x12, x15) contain correct return addresses
- **FAIL:** Any branch takes/doesn't take incorrectly, or jump target/link address is wrong.

### Dependencies

**Phase 7 must pass.** Phase 8 is recommended but not strictly required.

### Estimated Complexity

**Medium** — Branch target calculation and condition evaluation must be correct. Signed vs unsigned comparison is a common source of bugs.

---

## Phase 10: Full ISA Verification

### Objective

Run a comprehensive test program that exercises all 47 RV32I instructions, verifying complete ISA compliance of the single-cycle processor.

### Files to Create

| File | Path | Description |
|------|------|-------------|
| `full_isa_test.hex` | `tb/top/test_programs/full_isa_test.hex` | Comprehensive ISA test program |

### Test Coverage

The test program must cover:

| Category | Instructions | Count |
|----------|-------------|-------|
| R-type arithmetic | ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND | 10 |
| I-type arithmetic | ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI | 9 |
| Load | LB, LH, LW, LBU, LHU | 5 |
| Store | SB, SH, SW | 3 |
| Branch | BEQ, BNE, BLT, BGE, BLTU, BGEU | 6 |
| Jump | JAL, JALR | 2 |
| Upper immediate | LUI, AUIPC | 2 |
| System | ECALL, EBREAK | 2 |
| Memory ordering | FENCE | 1 |
| **Total** | | **40** |

*(Note: ECALL, EBREAK, and FENCE may be implemented as NOPs for this basic implementation, but must not cause errors. The remaining 7 of the 47 instructions are pseudo-instructions or variants covered by the above.)*

### Test Strategy

1. **Self-checking program:** Each instruction writes a result to a known register or memory location. At the end, a signature block in memory contains all results.
2. **Golden reference:** Expected signature values are pre-computed and compared by the testbench.
3. **Edge cases included:**
   - Arithmetic overflow
   - Signed vs unsigned boundary (0x7FFFFFFF, 0x80000000)
   - Shift by 0 and shift by 31
   - Branch forward and backward
   - Store then load same address
   - LUI followed by ADDI (standard two-instruction constant load)
   - AUIPC for PC-relative addressing

### Verification Procedure

```bash
cd /home/guy/Sagi/riscv_processor/sim/
vcs -sverilog -debug_access+all -kdb -lca -f filelist_riscv_top.f
./simv +PROGRAM=full_isa_test.hex
```

### Pass/Fail Criteria

- **PASS:** All instructions produce correct results. Memory signature matches golden reference exactly. Testbench prints: `"FULL ISA TEST PASSED: All 47 RV32I instructions verified"`
- **FAIL:** Any instruction produces an incorrect result. Testbench identifies which instruction(s) failed.

### Dependencies

**All of Phases 7–9 must pass.**

### Estimated Complexity

**Complex** — Writing and debugging a comprehensive self-checking test program is time-consuming. Hex encoding must be exact.

---

## Phase Dependency Graph

```
Phase 1 (ALU) ──────────────────────────────┐
Phase 2 (Register File) ────────────────────┤
Phase 3 (Immediate Generator) ──────────────┤
Phase 4 (PC + IMEM) ────────────────────────┼──→ Phase 7 (Integration) ──→ Phase 8 (Load/Store) ──┐
Phase 5 (Control Unit) ─────────────────────┤                        ├──→ Phase 9 (Branch/Jump) ──┼──→ Phase 10 (Full ISA)
Phase 6 (Data Memory) ─────────────────────┘                        └──────────────────────────────┘
```

**Key constraints:**
- Phases 1–6 can be developed **in parallel** (no inter-dependencies)
- Phase 7 requires **all** of Phases 1–6
- Phases 8 and 9 require Phase 7
- Phase 10 requires Phases 8 and 9

---

## Summary Table

| Phase | Module(s) | RTL Files | TB Files | Dependencies | Complexity | Min Tests |
|-------|-----------|-----------|----------|-------------|------------|----------|
| 1 | ALU | `rtl/core/alu.v` | `tb/unit/tb_alu.sv` | None | Simple | 30 |
| 2 | Register File | `rtl/core/register_file.v` | `tb/unit/tb_register_file.sv` | None | Simple | 15 |
| 3 | Immediate Gen | `rtl/core/imm_gen.v` | `tb/unit/tb_imm_gen.sv` | None | Simple | 18 |
| 4 | PC + IMEM | `rtl/core/pc.v`, `rtl/mem/imem.v` | `tb/unit/tb_pc.sv`, `tb/unit/tb_imem.sv` | None | Simple | 14 |
| 5 | Control Unit | `rtl/core/control_unit.v` | `tb/unit/tb_control_unit.sv` | None | Medium | 25 |
| 6 | Data Memory | `rtl/mem/dmem.v` | `tb/unit/tb_dmem.sv` | None | Medium | 15 |
| 7 | Integration | `rtl/core/riscv_top.v` | `tb/top/tb_riscv_top.sv` | 1–6 | Complex | 10+ |
| 8 | Load/Store | — | test program hex | 7 | Medium | 12+ |
| 9 | Branch/Jump | — | test program hex | 7 | Medium | 15+ |
| 10 | Full ISA | — | test program hex | 8, 9 | Complex | 47+ |

---

## Appendix A: File List Templates

### Unit Test File Lists

Each unit test file list follows the pattern:
```
../rtl/<subdir>/<module>.v
../tb/unit/tb_<module>.sv
```

### Integration Test File List (`sim/filelist_riscv_top.f`)

```
// RTL Core Modules
../rtl/core/alu.v
../rtl/core/register_file.v
../rtl/core/imm_gen.v
../rtl/core/pc.v
../rtl/core/control_unit.v
../rtl/core/riscv_top.v

// RTL Memory Modules
../rtl/mem/imem.v
../rtl/mem/dmem.v

// Testbench
../tb/top/tb_riscv_top.sv
```

---

## Appendix B: Testbench Template

```systemverilog
`timescale 1ns/1ps

module tb_<module_name>;

    // --- Parameters ---
    // ...

    // --- Signals ---
    // ...

    // --- DUT Instantiation ---
    <module_name> dut (
        // port connections
    );

    // --- Test Infrastructure ---
    integer pass_count = 0;
    integer fail_count = 0;
    integer test_count = 0;

    task check(
        input string test_name,
        input [31:0] expected,
        input [31:0] actual
    );
        test_count = test_count + 1;
        if (expected === actual) begin
            $display("[PASS] %s", test_name);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] %s: expected=0x%08h, got=0x%08h", test_name, expected, actual);
            fail_count = fail_count + 1;
        end
    endtask

    // --- Test Sequence ---
    initial begin
        // ... test cases ...

        // --- Summary ---
        $display("\n========================================");
        if (fail_count == 0)
            $display("TEST PASSED: %0d/%0d tests passed", pass_count, test_count);
        else
            $display("TEST FAILED: %0d/%0d tests failed", fail_count, test_count);
        $display("========================================\n");
        $finish;
    end

endmodule
```

---

## Appendix C: RISC-V Reference

- **Specification:** `/home/guy/Sagi/Downloads/riscv-unprivileged.pdf`
- **Chapter 2 (pages 42–58):** RV32I Base Integer Instruction Set — all instruction encodings, formats, and semantics
- **Instruction encoding reference:** Table 24.2 in the specification (RV32I opcode map)

---

*End of Implementation Plan*

===NEW PHASES===
## Phase 11: Auto-Clock Gating

### Objective
Implement an Integrated Clock Gating (ICG) cell to enable global clock gating for power reduction, controlled by a `clk_en` signal.

### Files to Create/Modify
| File | Path | Description |
|------|------|-------------|
| `icg.v` | `rtl/core/icg.v` | Integrated clock gating module |
| `tb_icg.sv` | `tb/unit/tb_icg.sv` | ICG unit testbench |

### Testbench Requirements
1. Verify clock passes through when `en = 1`.
2. Verify clock is gated (held low) when `en = 0`.
3. Verify no glitches occur during `en` transitions.

---

## Phase 12: Privileged Architecture (CSRs and Exceptions)

### Objective
Implement the Machine-level Privileged Architecture, including the Control and Status Register (CSR) file, exception handling, and related instructions (CSRRW, CSRRS, CSRRC, CSRRWI, CSRRSI, CSRRCI, ECALL, EBREAK, MRET).

### Files to Create/Modify
| File | Path | Description |
|------|------|-------------|
| `csr_file.v` | `rtl/core/csr_file.v` | CSR file module |
| `tb_csr_file.sv` | `tb/unit/tb_csr_file.sv` | CSR file unit testbench |
| `csr_test.hex` | `tb/top/test_programs/csr_test.hex` | CSR and exception test program |

### Testbench Requirements
1. Read and write to implemented CSRs (mstatus, mepc, mtvec, mcause).
2. Verify exception triggering and PC redirection to `mtvec`.
3. Verify `mret` restores PC from `mepc`.

---

## Phase 13: M Extension (Integer Multiplication and Division)

### Objective
Implement the RV32M standard extension for integer multiplication and division.

### Files to Create/Modify
| File | Path | Description |
|------|------|-------------|
| `alu.v` | `rtl/core/alu.v` | Update ALU to support M extension operations |
| `m_ext_test.hex` | `tb/top/test_programs/m_ext_test.hex` | M extension test program |

### Testbench Requirements
1. Verify MUL, MULH, MULHSU, MULHU.
2. Verify DIV, DIVU, REM, REMU.
3. Verify division by zero and overflow edge cases.

---

## Phase 14: A Extension (Atomic Instructions)

### Objective
Implement the RV32A standard extension for atomic memory operations (AMOs) and Load-Reserved/Store-Conditional (LR/SC).

### Files to Create/Modify
| File | Path | Description |
|------|------|-------------|
| `dmem.v` | `rtl/mem/dmem.v` | Update DMEM to support AMO logic |
| `a_ext_test.hex` | `tb/top/test_programs/a_ext_test.hex` | A extension test program |

### Testbench Requirements
1. Verify LR.W and SC.W success and failure conditions.
2. Verify AMOSWAP.W, AMOADD.W, AMOAND.W, AMOOR.W, AMOXOR.W, AMOMAX.W, AMOMIN.W.

---

## Phase 15: F and D Extensions (IEEE 754 FPU)

### Objective
Implement the RV32F and RV32D standard extensions for single- and double-precision IEEE 754 floating-point operations, including the Floating-Point Register (FPR) file and FP ALU.

### Files to Create/Modify
| File | Path | Description |
|------|------|-------------|
| `fpr.v` | `rtl/core/fpr.v` | Floating-point register file |
| `fp_alu.v` | `rtl/core/fp_alu.v` | IEEE 754 Floating-point ALU |
| `tb_fpr.sv` | `tb/unit/tb_fpr.sv` | FPR unit testbench |
| `tb_fp_alu.sv` | `tb/unit/tb_fp_alu.sv` | FP ALU unit testbench |
| `fd_ext_test.hex` | `tb/top/test_programs/fd_ext_test.hex` | F/D extension test program |

### Testbench Requirements
1. Verify FPR read/write for 32-bit and 64-bit widths.
2. Verify FP addition, subtraction, multiplication, division, and square root.
3. Verify FP to integer and integer to FP conversions.
4. Verify floating-point load/store operations.
5. Verify rounding modes and exception flags (fflags).

---

## Phase 16: Full Advanced System Integration

### Objective
Integrate all extensions (M, A, F, D), Privileged architecture, and ICG into the top-level processor and verify the complete system.

### Files to Create/Modify
| File | Path | Description |
|------|------|-------------|
| `riscv_top.v` | `rtl/core/riscv_top.v` | Update top-level with parameters and new modules |
| `full_advanced_isa_test.hex` | `tb/top/test_programs/full_advanced_isa_test.hex` | Comprehensive test program |

### Testbench Requirements
1. Execute a comprehensive test program utilizing base RV32I, M, A, F, D, and Privileged instructions.
2. Verify correct interaction between integer and floating-point pipelines.

===UPDATED SUMMARY TABLE===
| Phase | Module(s) | RTL Files | TB Files | Dependencies | Complexity | Min Tests |
|-------|-----------|-----------|----------|-------------|------------|----------|
| 1 | ALU | `rtl/core/alu.v` | `tb/unit/tb_alu.sv` | None | Simple | 30 |
| 2 | Register File | `rtl/core/register_file.v` | `tb/unit/tb_register_file.sv` | None | Simple | 15 |
| 3 | Immediate Gen | `rtl/core/imm_gen.v` | `tb/unit/tb_imm_gen.sv` | None | Simple | 18 |
| 4 | PC + IMEM | `rtl/core/pc.v`, `rtl/mem/imem.v` | `tb/unit/tb_pc.sv`, `tb/unit/tb_imem.sv` | None | Simple | 14 |
| 5 | Control Unit | `rtl/core/control_unit.v` | `tb/unit/tb_control_unit.sv` | None | Medium | 25 |
| 6 | Data Memory | `rtl/mem/dmem.v` | `tb/unit/tb_dmem.sv` | None | Medium | 15 |
| 7 | Integration | `rtl/core/riscv_top.v` | `tb/top/tb_riscv_top.sv` | 1–6 | Complex | 10+ |
| 8 | Load/Store | — | test program hex | 7 | Medium | 12+ |
| 9 | Branch/Jump | — | test program hex | 7 | Medium | 15+ |
| 10 | Full ISA | — | test program hex | 8, 9 | Complex | 47+ |
| 11 | Auto-Clock Gating | `rtl/core/icg.v` | `tb/unit/tb_icg.sv` | None | Simple | 3 |
| 12 | Privileged Arch | `rtl/core/csr_file.v` | `tb/unit/tb_csr_file.sv`, `csr_test.hex` | 10 | High | 15+ |
| 13 | M Extension | `rtl/core/alu.v` (update) | `m_ext_test.hex` | 10 | Medium | 20+ |
| 14 | A Extension | `rtl/mem/dmem.v` (update) | `a_ext_test.hex` | 10 | High | 15+ |
| 15 | F & D Extensions | `rtl/core/fpr.v`, `rtl/core/fp_alu.v` | `tb/unit/tb_fpr.sv`, `tb/unit/tb_fp_alu.sv`, `fd_ext_test.hex` | 10, 12 | Very High | 40+ |
| 16 | Advanced Integration | `rtl/core/riscv_top.v` (update) | `full_advanced_isa_test.hex` | 11–15 | Complex | 100+ |