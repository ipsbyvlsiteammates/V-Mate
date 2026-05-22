# Architectural Modification Report: Pipelining and Power Optimization for `riscv_top`

## 1. Introduction
The current `riscv_top` module implements a single-cycle RISC-V processor supporting RV32I with optional M, A, F, and D extensions. While single-cycle architectures are straightforward, they suffer from long critical paths (limiting maximum clock frequency) and inefficient power utilization. This report outlines the necessary architectural modifications to transition the design to a pipelined architecture for high clock rates, alongside advanced clock gating techniques for low power consumption.

## 2. Pipelining Strategy
To achieve high clock rates, the single-cycle datapath must be divided into a standard 5-stage pipeline:
*   **Instruction Fetch (IF):** PC generation and Instruction Memory access.
*   **Instruction Decode (ID):** Instruction decoding (Control Unit), Register File read, and Immediate Generation.
*   **Execute (EX):** ALU operations, Branch target calculation, and Branch condition evaluation.
*   **Memory (MEM):** Data Memory access (read/write) and AMO operations.
*   **Write-Back (WB):** Writing results back to the Integer or Floating-Point Register Files.

**Implementation Requirements:**
*   Insert pipeline registers (e.g., `IF/ID`, `ID/EX`, `EX/MEM`, `MEM/WB`) between stages to hold data and control signals.
*   Propagate control signals generated in the ID stage through the pipeline registers to the EX, MEM, and WB stages.

## 3. Hazard Resolution
Pipelining introduces data and control hazards that must be resolved to maintain correct execution.

### 3.1 Data Hazards
*   **Forwarding (Bypassing):** Implement a forwarding unit to route data from the `EX/MEM` and `MEM/WB` pipeline registers directly to the ALU inputs in the EX stage. This resolves Read-After-Write (RAW) hazards without stalling, except for load-use hazards.
*   **Load-Use Stalls:** Implement a hazard detection unit in the ID stage. If an instruction in the EX stage is a load (`mem_read_w` is true) and its destination register matches either source register of the instruction in the ID stage, stall the IF and ID stages for one cycle and insert a bubble (NOP) into the EX stage.

### 3.2 Control Hazards
*   **Branch Prediction:** The current design resolves branches in the EX stage, which would result in a 2-cycle penalty for taken branches. Implement a static branch predictor (e.g., "predict not taken" or "predict backward taken, forward not taken") or a dynamic branch predictor (Branch Target Buffer and Branch History Table) in the IF stage.
*   **Flush Logic:** If a branch is mispredicted or a jump is executed, flush the instructions in the IF and ID stages by clearing the `IF/ID` and `ID/EX` pipeline registers.

## 4. FPU Pipelining
Floating-Point operations (especially division and square root, if supported, or even standard addition/multiplication) typically require more than one cycle to complete.
*   **Multi-Cycle EX Stage:** Decouple the FP ALU from the integer pipeline. Allow the FP ALU to take multiple cycles.
*   **Write-Back Arbitration:** Since FP instructions may complete out-of-order relative to integer instructions, implement a scoreboard or reservation stations to track register dependencies and arbitrate access to the WB stage.
*   **Stalling:** Alternatively, for a simpler implementation, stall the entire pipeline while a multi-cycle FP operation is executing, though this sacrifices performance.

## 5. Power Optimization (Clock Gating)
The current design includes a global clock gate (`icg u_global_icg`). To further reduce dynamic power, implement fine-grained clock gating:
*   **Register File Clock Gating:** Gate the clock to individual registers within the Integer and FP Register Files. Only enable the clock for the specific register being written to (`we` & decoded `rd_addr`).
*   **Pipeline Stage Gating:** Gate the clock to pipeline registers if the stage is stalled or contains a bubble (NOP).
*   **Functional Unit Gating:** Gate the clock to the Integer ALU, FP ALU, and Multiplier/Divider (M-extension) when they are not in use. For example, if the current instruction is not an FP instruction, the FP ALU clock should be disabled.
*   **Operand Isolation:** Prevent switching activity from propagating through combinational logic (like the ALU or FPU) when the unit is not being used. This can be done by forcing the inputs to zero or holding their previous values using latches or AND gates.

## 6. Conclusion
Transitioning `riscv_top` from a single-cycle to a pipelined architecture will significantly reduce the critical path, allowing for higher clock frequencies. Coupling this with forwarding, hazard detection, and fine-grained clock gating will yield a high-performance, power-efficient RISC-V core suitable for modern embedded applications.