`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////
// Module: imem
// Description: Instruction Memory (Read-Only) for RISC-V single-cycle processor
//              1024 words x 32 bits (4 KB) combinational read ROM
//              Initialized from program.hex via $readmemh
// Author: RISC-V Processor Project
// Date: 2024
//////////////////////////////////////////////////////////////////////////////

module imem (
    input  wire [31:0] addr,        // Byte address (from PC)
    output wire [31:0] instruction  // 32-bit instruction at given address
);

    // Memory: 1024 words x 32 bits
    reg [31:0] mem [131072];

    // Combinational read: word index = addr[11:2]
    assign instruction = mem[addr[18:2]];

    // Initialize memory from hex file
    // initial block removed to prevent race condition

endmodule
