# UVM Test Plan

This document outlines the UVM test plan for the V-mate RISC-V Core. It includes both the existing regression tests and newly proposed complex corner case scenarios designed to thoroughly verify the core's out-of-order execution, floating-point unit, and exception handling capabilities.

## Existing UVM Tests

The following 18 tests are currently part of the regression suite:

1. `riscv_floating_point_arithmetic_test`
2. `riscv_floating_point_rand_test`
3. `riscv_amo_test`
4. `riscv_machine_mode_rand_test`
5. `riscv_arithmetic_basic_test`
6. `riscv_jump_stress_test`
7. `riscv_illegal_instr_test`
8. `riscv_ebreak_test`
9. `riscv_unaligned_load_store_test`
10. `riscv_rand_instr_test`
11. `riscv_loop_test`
12. `riscv_rand_jump_test`
13. `riscv_mmu_stress_test`
14. `riscv_no_fence_test`
15. `riscv_csr_test`
16. `riscv_instr_cov_test`
17. `riscv_floating_point_mmu_stress_test`
18. `riscv_privileged_mode_rand_test`

## Complex Corner Case Tests

The following 11 complex corner case scenarios have been identified for future implementation to enhance verification coverage:

### 1. Precise Exceptions & Long-Latency FP Operations (M-mode + F/D + OoO)
* **Scenario:** A long-latency floating-point instruction (e.g., `fdiv.d` or `fsqrt.d`) is issued and begins execution. Immediately following it, a younger integer instruction triggers a synchronous exception (e.g., `ecall`, `ebreak`, or a misaligned load/store).
* **Expected Behavior:** The ROB must maintain precise exceptions. The exception from the younger instruction must not be handled until it becomes the oldest instruction in the ROB. If the older FP instruction completes successfully, it must commit. If an older instruction faults, the younger instruction's exception must be flushed along with its RAT renamings.

### 2. Dynamic OoO Mode Toggling (CSR 0x7C0 + Pipeline)
* **Scenario:** An instruction writes to CSR 0x7C0 to toggle OoO execution (enable to disable, or vice versa) while the ROB, Issue Queue, and pipeline stages are heavily populated with in-flight instructions.
* **Expected Behavior:** The control unit must safely handle the transition. This typically requires draining the ROB and stalling fetch/issue until the pipeline is empty before applying the new OoO state, preventing architectural state corruption.

### 3. NaN-Boxing Forwarding Hazards (F/D + OoO + Pipeline)
* **Scenario:** A single-precision floating-point load (`flw`) is executed, followed immediately by a dependent double-precision operation (e.g., `fadd.d`) that uses the loaded register as a source operand.
* **Expected Behavior:** The `flw` instruction applies NaN-boxing in the MEM stage. The OoO forwarding logic must correctly forward the fully 64-bit NaN-boxed value from the MEM stage directly to the FP ALU in the EX stage for the `fadd.d` instruction, bypassing the FPR write-back stage.

### 4. M-mode Serialization and Context Switching (M-mode + OoO)
* **Scenario:** An `mret` (Machine Return) or `wfi` (Wait for Interrupt) instruction is dispatched while the ROB contains several uncommitted, out-of-order FP and integer instructions.
* **Expected Behavior:** `mret` and `wfi` must act as serialization points. The Issue Queue/ROB must not commit the `mret` (and thus not restore the PC and privilege mode) until all older instructions have safely committed. Younger instructions fetched speculatively must be flushed.

### 5. FCSR Dependency and Speculative Execution (F/D + M-mode + OoO)
* **Scenario:** A floating-point instruction that generates an FP exception flag (e.g., overflow or inexact) is executed. A closely following integer instruction reads the `fcsr` via a `csrr` instruction.
* **Expected Behavior:** The OoO engine must respect the Read-After-Write (RAW) hazard on the `fcsr` register. The `csrr` instruction must either stall until the FP instruction commits its flags to the architectural `fcsr`, or the speculative `fcsr` state must be correctly forwarded.

### 6. Clock Gating During Pipeline Stalls (ICG + OoO + F/D)
* **Scenario:** A sequence of long-latency FP operations is issued. Subsequently, the instruction fetch stage stalls indefinitely (e.g., due to an instruction cache miss or bus delay), emptying the front-end pipeline.
* **Expected Behavior:** Fine-grained clock gating must not prematurely disable the clocks to the FP ALU, ROB, or RAT. The in-flight FP instructions must continue execution, complete, and commit successfully despite the rest of the pipeline being stalled and potentially gated.

### 7. Atomic Memory Operations vs. OoO FP Stores (A + F/D + OoO)
* **Scenario:** An `lr.w` (Load Reserved) and `sc.w` (Store Conditional) sequence is interleaved with out-of-order floating-point stores (`fsw`/`fsd`) targeting the same or adjacent memory cache lines.
* **Expected Behavior:** The Load/Store Queue (LSQ) or memory controller must ensure that OoO FP stores do not silently invalidate the reservation of the `lr.w`/`sc.w` sequence incorrectly, and memory ordering rules must be strictly preserved.

### 8. Asynchronous Interrupts vs. OoO FP Execution
* **Scenario:** An asynchronous interrupt (e.g., machine timer interrupt) is asserted while multiple long-latency FP instructions are executing out-of-order, and the OoO mode is dynamically being toggled via CSR 0x7C0.
* **Expected Behavior:** The core must take the interrupt precisely at the instruction boundary of the oldest uncommitted instruction. In-flight FP instructions older than the interrupt point must complete and commit. Younger instructions must be flushed. The OoO toggle must either complete before the trap or be safely aborted/deferred until after the trap handler returns, without corrupting architectural state.

### 9. Branch Misprediction Overlaps
* **Scenario:** A branch is mispredicted. In the speculative path, a misaligned load triggers an M-mode exception, and an FP load (`flw`) attempts to forward a NaN-boxed value to a dependent FP instruction.
* **Expected Behavior:** The branch misprediction must be resolved, and the speculative path must be flushed entirely. The M-mode exception from the misaligned load must NOT be taken (as it is on a mispredicted path). The NaN-boxing forwarding must not corrupt the architectural FPRs.

### 10. LSQ Forwarding and Traps
* **Scenario:** An out-of-order FP store (`fsd`) writes to an address, and a subsequent FP load (`fld`) forwards this value from the LSQ. Immediately following this, an older integer instruction triggers an M-mode trap (e.g., illegal instruction).
* **Expected Behavior:** The LSQ must correctly forward the 64-bit value to the dependent `fld` speculatively. However, since the older integer instruction traps, the speculative `fsd` and `fld` must be flushed from the ROB and LSQ before they commit to the data cache or architectural FPRs.

### 11. Speculative CSR Accesses
* **Scenario:** An M-mode CSR write (e.g., modifying `mtvec` or `mstatus`) is executed speculatively behind an unresolved branch or an older instruction that eventually faults.
* **Expected Behavior:** The CSR write must not update the architectural CSR state until it becomes the oldest instruction and commits. If the preceding instruction faults or the branch is mispredicted, the speculative CSR write must be flushed, ensuring the trap vector and status registers remain intact.

## Phase 2 Complex Corner Case Tests

### Proposed Complex Corner Case Tests

1. **CSR Hazard: Dynamic FCSR Rounding Mode Change during OoO FP Execution**
   * **Scenario:** Multiple long-latency FP instructions (e.g., `fdiv.d`, `fsqrt.s`) are issued and executing out-of-order. An integer instruction writes to the `fcsr` (via `csrrw`) to change the rounding mode (FRM), followed immediately by more FP instructions.
   * **Expected Behavior:** The core must ensure that FP instructions issued *before* the `fcsr` write use the old rounding mode, and those issued *after* use the new rounding mode. The OoO engine must correctly handle this RAW hazard on the CSR, potentially by serializing the `fcsr` write or stalling issue until older FP instructions commit.

2. **Memory Subsystem Hazard: Load-to-Use Stall with Branch Misprediction and LSQ Forwarding**
   * **Scenario:** A store instruction writes to address X. A subsequent load reads from address X (triggering LSQ forwarding). A dependent integer instruction uses the loaded value to resolve a conditional branch. The branch is mispredicted.
   * **Expected Behavior:** The LSQ must forward the data correctly for the speculative load. When the branch misprediction is detected in the EX stage, the speculative path must be flushed. The original store must still commit correctly to the data cache once it reaches the head of the ROB.

3. **Resource Exhaustion: ROB/Issue Queue Full during Asynchronous Interrupt**
   * **Scenario:** The pipeline is flooded with independent, long-latency instructions (e.g., mixed FP and integer divides) until the Reorder Buffer (ROB) and Issue Queue are completely full. At the exact cycle the ROB becomes full, a Machine Timer Interrupt (MTI) is asserted.
   * **Expected Behavior:** The core must not deadlock. It must stop fetching/issuing, take the trap on the oldest uncommitted instruction boundary, flush the younger instructions from the full ROB, and jump to the trap handler without corrupting the architectural state.

4. **FPU Edge Case: Subnormal FMA Chain with NaN Propagation**
   * **Scenario:** A sequence of Fused Multiply-Add (`fmadd.d`) instructions is executed where the inputs are a mix of subnormal numbers and signaling NaNs (sNaN).
   * **Expected Behavior:** The FPU must correctly handle subnormal arithmetic without losing precision incorrectly (IEEE 754 compliance). The sNaN must be converted to a quiet NaN (qNaN) and propagated through the FMA chain, setting the invalid operation (NV) flag in the `fcsr` exactly once per sNaN consumed.

5. **Clock Gating (ICG) Edge Case: ICG Activation during Pipeline Flush**
   * **Scenario:** A branch misprediction or synchronous exception triggers a full pipeline flush. Simultaneously, the instruction fetch unit experiences a cache miss, causing the front-end to stall and potentially triggering fine-grained clock gating (ICG) for the fetch/decode stages.
   * **Expected Behavior:** The ICG logic must not prevent the flush control signals from propagating. The pipeline must be cleanly flushed, and the architectural state must remain consistent, even if parts of the pipeline are attempting to clock-gate due to the stall.

6. **Memory Subsystem Hazard: Back-to-Back Store-Load-Store to Same Address (OoO Memory Disambiguation)**
   * **Scenario:** `sw reg1, 0(x1)`, followed by `lw reg2, 0(x1)`, followed by `sw reg3, 0(x1)` are issued in close succession.
   * **Expected Behavior:** The OoO memory disambiguation logic (LSQ) must ensure the `lw` receives the value from the first `sw`, and the final state of memory at `0(x1)` reflects the second `sw`. If executed out of order, the LSQ must detect the RAW and WAW hazards and prevent stale data from being committed or forwarded.

XX. `icache_hazard_self_modifying_code_test`
   - **Description**: Tests I-cache coherence by executing a sequence of instructions that overwrite upcoming instructions in the pipeline, followed by a FENCE.I instruction to ensure the modified instructions are fetched and executed correctly.

XX. `fpu_advanced_exceptions_test`
   - **Description**: Triggers multiple simultaneous FPU exceptions (e.g., overflow, inexact, and invalid operation) across a sequence of out-of-order floating-point instructions to verify correct FCSR update and exception handling.

XX. `branch_predictor_thrashing_test`
   - **Description**: Floods the branch predictor with a high volume of pseudo-random branches and deep nested loops to cause capacity misses and thrashing, verifying the core's recovery from continuous branch mispredictions.

XX. `lsq_unaligned_forwarding_test`
   - **Description**: Tests the Load/Store Queue (LSQ) by performing unaligned stores followed immediately by unaligned loads from overlapping memory addresses, ensuring correct data forwarding before the store commits to memory.


### 12. OoO Execution with Multi-level Cache Eviction and Page Faults
* **Scenario:** An out-of-order load triggers a page fault while simultaneously causing a cache eviction of dirty data. An older instruction then resolves a branch misprediction, flushing the load.
* **Expected Behavior:** The page fault must not be taken, and the cache eviction must either complete safely or be rolled back without corrupting memory.

### 13. Interrupt Storm during FPU Context Switch
* **Scenario:** High frequency of asynchronous interrupts occurs while the core is saving/restoring the FPU context (modifying the FS field in mstatus).
* **Expected Behavior:** The core must precisely take interrupts without corrupting the FPU architectural state or the mstatus register.

### 14. Misaligned AMO across Page Boundary with PMP Fault
* **Scenario:** A misaligned Atomic Memory Operation (AMO) crosses a page boundary, where the first page is valid but the second page triggers a Physical Memory Protection (PMP) fault.
* **Expected Behavior:** The core must not partially execute the AMO. It must trap precisely with a store/AMO access fault before any memory state is modified.

### 15. Instruction Cache Coherence with DMA/External Master
* **Scenario:** An external agent writes to instruction memory while the core is speculatively fetching from the same cache line.
* **Expected Behavior:** The core must detect the modification (if supported by coherence protocol) or correctly execute a `fence.i` to invalidate the stale I-cache line before execution.


### csr_hazard_multicore_interrupt_test
Description: Tests CSR hazards during multicore interrupts.

### mem_hazard_dma_cache_coherence_test
Description: Tests memory hazards with DMA and cache coherence.

### resource_exhaustion_rob_lsq_full_test
Description: Tests resource exhaustion when ROB and LSQ are full.

### fpu_edge_case_denormal_pipeline_flush_test
Description: Tests FPU edge cases with denormal numbers and pipeline flushes.

### clock_gating_debug_mode_wakeup_test
Description: Tests clock gating during debug mode wakeup.
