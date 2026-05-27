# V-mate RISC-V Core

## Introduction
Welcome to the **V-mate** project, an advanced, open-source RISC-V processor core. V-mate is designed to deliver high performance and reliability, implementing the RISC-V RV32IMAFD architecture. This core was designed from scratch based on the official RISC-V unprivileged and privileged specifications, with no pre-existing base design.

**This design was developed in full by a single Hu-mind.ai VLSI teammate.**

## RTL Design Overview
The V-mate core features a robust and efficient microarchitecture, including:
- **5-Stage Pipeline:** Optimized for balanced performance and frequency.
- **Out-of-Order (OoO) Execution:** Advanced components including a Reorder Buffer (ROB), Register Alias Table (RAT), and an Issue Queue (controlled via CSR `0x7C0`) to maximize instruction throughput.
- **Floating-Point Unit (FPU):** A fully IEEE 754 compliant FPU supporting both single (F) and double (D) precision operations.
- **Privilege Levels:** Full support for Machine mode (M-mode) operations.
- **Power Management:** Integrated Clock Gating (ICG) for efficient power consumption.

## Design Documentation
Comprehensive documentation is provided to understand, integrate, and extend the V-mate core:
- **Architecture Spec:** High-level overview of the core's architecture and instruction set support.
- **Detailed Design Spec:** In-depth description of the microarchitecture, pipeline stages, and internal modules.
- **Implementation Plan:** Guidelines and strategies for synthesizing and implementing the core.
- **Pipeline and Power Report:** Analysis of pipeline efficiency and power consumption metrics.

## UVM Testing Environment
The V-mate core is verified using a state-of-the-art Universal Verification Methodology (UVM) environment. The testbench ensures high reliability and achieves a 100% pass rate on the RISC-V compliance suite (229/229 tests). Key testing features include:
- **Constrained Random Generation:** Extensive randomized instruction sequences to uncover corner cases.
- **LR/SC Testing:** Rigorous verification of Load-Reserved and Store-Conditional atomic operations.
- **FP Stress Tests:** Comprehensive testing of the IEEE 754 FPU, including NaN-boxing and edge cases.
- **OoO Compliance:** Verification of the Out-of-Order execution components (ROB, RAT, Issue Queue) under complex pipeline conditions.
- **Coverage:** Achieves 96.30% Line Coverage and 88.23% Overall Coverage.

## Legal Disclaimer
This repository and its contents are published "as-is". No warranties, express or implied, are provided. The authors and Hu-mind.ai take no responsibility for any issues, damages, or liabilities arising from the use of this design. Use at your own risk.