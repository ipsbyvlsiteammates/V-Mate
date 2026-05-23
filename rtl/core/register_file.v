`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////
// File:        register_file.v
// Author:      Sagi
// Date:        2026-05-12
// Description: RISC-V 32x32 Register File
//              - Two combinational (asynchronous) read ports
//              - One synchronous write port (rising clock edge)
//              - Register x0 is hardwired to zero
//              - Active-low synchronous reset
//              - No write forwarding (read returns old value)
//////////////////////////////////////////////////////////////////////////////

module register_file (
    input  wire        clk,       // System clock
    input  wire        rst_n,     // Active-low synchronous reset
    input  wire        we,        // Write enable
    input  wire [4:0]  rs1_addr,  // Read port 1 address
    input  wire [4:0]  rs2_addr,  // Read port 2 address
    input  wire [4:0]  rd_addr,   // Write port address
    input  wire [31:0] rd_data,   // Write data
    output wire [31:0] rs1_data,  // Read port 1 data
    output wire [31:0] rs2_data   // Read port 2 data
);

    // Internal register storage: 32 registers, each 32 bits wide
    reg [31:0] regs [32];

    // Integer for reset loop
    integer i;

    //--------------------------------------------------------------------------
    // Combinational Read Ports (asynchronous)
    // x0 is hardwired to zero: if address is 0, output is always 0
    // Otherwise, output the value stored in the register array
    //--------------------------------------------------------------------------
    assign rs1_data = (rs1_addr == 5'b0) ? 32'b0 : (we && (rd_addr == rs1_addr)) ? rd_data : regs[rs1_addr];
    assign rs2_data = (rs2_addr == 5'b0) ? 32'b0 : (we && (rd_addr == rs2_addr)) ? rd_data : regs[rs2_addr];

    //--------------------------------------------------------------------------
    // Synchronous Write Port (rising clock edge)
    // - On reset (rst_n == 0): all registers are cleared to zero
    // - On normal operation: write rd_data to regs[rd_addr] if we is asserted
    //   and rd_addr is not x0 (writes to x0 are silently ignored)
    //--------------------------------------------------------------------------
    wire cg_en = (!rst_n) | (we && (rd_addr != 5'b0));
    wire gated_clk;
    icg u_local_icg (
        .clk(clk),
        .en(cg_en),
        .gated_clk(gated_clk)
    );

    always @(posedge gated_clk) begin
        if (!rst_n) begin
            // Synchronous active-low reset: clear all registers
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'b0;
            end
        end else begin
            // Normal operation: write if enabled and not targeting x0
            if (we && (rd_addr != 5'b0)) begin
                regs[rd_addr] <= rd_data;
            end
        end
    end

endmodule
