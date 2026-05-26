# V-mate RISC-V Processor — Implementation Plan

**Project:** V-mate RISC-V RV32IMAFD Processor
**Team:** Hu-mind VLSI Team
**Author:** Sagi
**Date:** 2026-05-20

---

## Overview

This document describes the implementation plan for the V-mate RISC-V processor in Verilog. The processor implements the RV32IMAFD ISA, 5-stage pipeline, Out-of-Order execution, and M-mode privileged architecture.

**Status: All phases completed.**

---

## Phases 1-16: Base ISA, Extensions, and Integration
*(Completed)*
- Phase 1-10: RV32I Base Integer Instruction Set.
- Phase 11: Auto-Clock Gating (ICG).
- Phase 12: Privileged Architecture (M-mode).
- Phase 13: M Extension.
- Phase 14: A Extension.
- Phase 15: F and D Extensions (IEEE 754 FPU).
- Phase 16: Full Advanced System Integration.

## Phase 17: Pipelining and Out-of-Order Execution
*(Completed)*
### Objective
Implement a 5-stage pipeline and Out-of-Order (OoO) execution components (ROB, RAT, Issue Queue).

### Tasks
1. Divide datapath into IF, ID, EX, MEM, WB stages.
2. Implement ROB, RAT, and Issue Queue in the Control Unit.
3. Add CSR 0x7C0 to control OoO execution (default disabled).
4. Move NaN-boxing logic to execution units and memory load stage.
5. Implement fine-grained clock gating.

### Status
**Completed and Verified.**