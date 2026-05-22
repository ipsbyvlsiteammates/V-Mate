`timescale 1ns/1ps
//-----------------------------------------------------------------------------
// File    : tb_alu.sv
// Author  : Sagi
// Date    : 2026-05-11
// Project : RISC-V RV32I Processor
// Brief   : Unit testbench for ALU module
//-----------------------------------------------------------------------------

module tb_alu;

    // DUT signals
    logic [31:0] operand_a;
    logic [31:0] operand_b;
    logic [3:0]  alu_op;
    logic [31:0] alu_result;
    logic        zero_flag;

    // Test counters
    integer pass_count = 0;
    integer fail_count = 0;
    integer test_count = 0;

    // ALU operation encodings
    localparam [3:0] ALU_ADD    = 4'b0000;
    localparam [3:0] ALU_SUB    = 4'b0001;
    localparam [3:0] ALU_AND    = 4'b0010;
    localparam [3:0] ALU_OR     = 4'b0011;
    localparam [3:0] ALU_XOR    = 4'b0100;
    localparam [3:0] ALU_SLT    = 4'b0101;
    localparam [3:0] ALU_SLTU   = 4'b0110;
    localparam [3:0] ALU_SLL    = 4'b0111;
    localparam [3:0] ALU_SRL    = 4'b1000;
    localparam [3:0] ALU_SRA    = 4'b1001;
    localparam [3:0] ALU_PASS_B = 4'b1010;

    // DUT instantiation
    alu dut (
        .operand_a  (operand_a),
        .operand_b  (operand_b),
        .alu_op     (alu_op),
        .alu_result (alu_result),
        .zero_flag  (zero_flag)
    );

    // Check task
    task automatic check(
        input string       test_name,
        input logic [31:0] expected_result,
        input logic        expected_zero
    );
        test_count = test_count + 1;
        if ((alu_result === expected_result) && (zero_flag === expected_zero)) begin
            $display("[PASS] %s", test_name);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] %s: expected result=%08h zero=%b, got result=%08h zero=%b",
                     test_name, expected_result, expected_zero, alu_result, zero_flag);
            fail_count = fail_count + 1;
        end
    endtask

    initial begin
        // Initialize inputs
        operand_a = 32'h0;
        operand_b = 32'h0;
        alu_op    = 4'h0;

        // ----------------------------------------------------------------
        // ADD tests
        // ----------------------------------------------------------------
        #10;
        operand_a = 32'h00000005; operand_b = 32'h00000003; alu_op = ALU_ADD;
        #10; check("ADD: 5+3=8",          32'h00000008, 1'b0);

        operand_a = 32'hFFFFFFFF; operand_b = 32'h00000001; alu_op = ALU_ADD;
        #10; check("ADD: FFFFFFFF+1=0",   32'h00000000, 1'b1);

        operand_a = 32'h80000000; operand_b = 32'h80000000; alu_op = ALU_ADD;
        #10; check("ADD: 80000000+80000000=0", 32'h00000000, 1'b1);

        // ----------------------------------------------------------------
        // SUB tests
        // ----------------------------------------------------------------
        #10;
        operand_a = 32'h0000000A; operand_b = 32'h00000003; alu_op = ALU_SUB;
        #10; check("SUB: A-3=7",          32'h00000007, 1'b0);

        operand_a = 32'h00000005; operand_b = 32'h00000005; alu_op = ALU_SUB;
        #10; check("SUB: 5-5=0",          32'h00000000, 1'b1);

        operand_a = 32'h00000000; operand_b = 32'h00000001; alu_op = ALU_SUB;
        #10; check("SUB: 0-1=FFFFFFFF",   32'hFFFFFFFF, 1'b0);

        // ----------------------------------------------------------------
        // AND tests
        // ----------------------------------------------------------------
        #10;
        operand_a = 32'hFF00FF00; operand_b = 32'h0F0F0F0F; alu_op = ALU_AND;
        #10; check("AND: FF00FF00&0F0F0F0F=0F000F00", 32'h0F000F00, 1'b0);

        operand_a = 32'hFFFFFFFF; operand_b = 32'hFFFFFFFF; alu_op = ALU_AND;
        #10; check("AND: FFFFFFFF&FFFFFFFF=FFFFFFFF", 32'hFFFFFFFF, 1'b0);

        operand_a = 32'hAAAAAAAA; operand_b = 32'h55555555; alu_op = ALU_AND;
        #10; check("AND: AAAAAAAA&55555555=0",        32'h00000000, 1'b1);

        // ----------------------------------------------------------------
        // OR tests
        // ----------------------------------------------------------------
        #10;
        operand_a = 32'hFF000000; operand_b = 32'h00FF0000; alu_op = ALU_OR;
        #10; check("OR: FF000000|00FF0000=FFFF0000",  32'hFFFF0000, 1'b0);

        operand_a = 32'h00000000; operand_b = 32'h00000000; alu_op = ALU_OR;
        #10; check("OR: 0|0=0",                        32'h00000000, 1'b1);

        operand_a = 32'hAAAAAAAA; operand_b = 32'h55555555; alu_op = ALU_OR;
        #10; check("OR: AAAAAAAA|55555555=FFFFFFFF",   32'hFFFFFFFF, 1'b0);

        // ----------------------------------------------------------------
        // XOR tests
        // ----------------------------------------------------------------
        #10;
        operand_a = 32'hFFFFFFFF; operand_b = 32'hFFFFFFFF; alu_op = ALU_XOR;
        #10; check("XOR: FFFFFFFF^FFFFFFFF=0",         32'h00000000, 1'b1);

        operand_a = 32'hAAAAAAAA; operand_b = 32'h55555555; alu_op = ALU_XOR;
        #10; check("XOR: AAAAAAAA^55555555=FFFFFFFF",  32'hFFFFFFFF, 1'b0);

        operand_a = 32'h12345678; operand_b = 32'h00000000; alu_op = ALU_XOR;
        #10; check("XOR: 12345678^0=12345678",         32'h12345678, 1'b0);

        // ----------------------------------------------------------------
        // SLT tests (signed)
        // ----------------------------------------------------------------
        #10;
        operand_a = 32'hFFFFFFFF; operand_b = 32'h00000001; alu_op = ALU_SLT;  // -1 < 1
        #10; check("SLT: -1<1 => 1",                  32'h00000001, 1'b0);

        operand_a = 32'h00000001; operand_b = 32'hFFFFFFFF; alu_op = ALU_SLT;  // 1 < -1
        #10; check("SLT: 1<-1 => 0",                  32'h00000000, 1'b1);

        operand_a = 32'h00000005; operand_b = 32'h00000005; alu_op = ALU_SLT;  // 5 < 5
        #10; check("SLT: 5<5 => 0",                   32'h00000000, 1'b1);

        // ----------------------------------------------------------------
        // SLTU tests (unsigned)
        // ----------------------------------------------------------------
        #10;
        operand_a = 32'h00000001; operand_b = 32'hFFFFFFFF; alu_op = ALU_SLTU; // 1 < FFFFFFFF
        #10; check("SLTU: 1<FFFFFFFF => 1",           32'h00000001, 1'b0);

        operand_a = 32'hFFFFFFFF; operand_b = 32'h00000001; alu_op = ALU_SLTU; // FFFFFFFF < 1
        #10; check("SLTU: FFFFFFFF<1 => 0",           32'h00000000, 1'b1);

        operand_a = 32'h00000000; operand_b = 32'h00000000; alu_op = ALU_SLTU; // 0 < 0
        #10; check("SLTU: 0<0 => 0",                  32'h00000000, 1'b1);

        // ----------------------------------------------------------------
        // SLL tests
        // ----------------------------------------------------------------
        #10;
        operand_a = 32'h00000001; operand_b = 32'h00000000; alu_op = ALU_SLL;  // 1 << 0
        #10; check("SLL: 1<<0=1",                     32'h00000001, 1'b0);

        operand_a = 32'h00000001; operand_b = 32'h00000001; alu_op = ALU_SLL;  // 1 << 1
        #10; check("SLL: 1<<1=2",                     32'h00000002, 1'b0);

        operand_a = 32'h00000001; operand_b = 32'h0000001F; alu_op = ALU_SLL;  // 1 << 31
        #10; check("SLL: 1<<31=80000000",             32'h80000000, 1'b0);

        // ----------------------------------------------------------------
        // SRL tests
        // ----------------------------------------------------------------
        #10;
        operand_a = 32'h80000000; operand_b = 32'h00000000; alu_op = ALU_SRL;  // >>0
        #10; check("SRL: 80000000>>0=80000000",       32'h80000000, 1'b0);

        operand_a = 32'h80000000; operand_b = 32'h00000001; alu_op = ALU_SRL;  // >>1
        #10; check("SRL: 80000000>>1=40000000",       32'h40000000, 1'b0);

        operand_a = 32'h80000000; operand_b = 32'h0000001F; alu_op = ALU_SRL;  // >>31
        #10; check("SRL: 80000000>>31=1",             32'h00000001, 1'b0);

        // ----------------------------------------------------------------
        // SRA tests
        // ----------------------------------------------------------------
        #10;
        operand_a = 32'h80000000; operand_b = 32'h00000000; alu_op = ALU_SRA;  // >>>0
        #10; check("SRA: 80000000>>>0=80000000",      32'h80000000, 1'b0);

        operand_a = 32'h80000000; operand_b = 32'h00000001; alu_op = ALU_SRA;  // >>>1
        #10; check("SRA: 80000000>>>1=C0000000",      32'hC0000000, 1'b0);

        operand_a = 32'h80000000; operand_b = 32'h0000001F; alu_op = ALU_SRA;  // >>>31
        #10; check("SRA: 80000000>>>31=FFFFFFFF",     32'hFFFFFFFF, 1'b0);

        // ----------------------------------------------------------------
        // PASS_B tests
        // ----------------------------------------------------------------
        #10;
        operand_a = 32'hDEADBEEF; operand_b = 32'h12345678; alu_op = ALU_PASS_B;
        #10; check("PASS_B: b=12345678",              32'h12345678, 1'b0);

        operand_a = 32'hFFFFFFFF; operand_b = 32'h00000000; alu_op = ALU_PASS_B;
        #10; check("PASS_B: b=0",                     32'h00000000, 1'b1);

        // ----------------------------------------------------------------
        // Summary
        // ----------------------------------------------------------------
        #10;
        if (pass_count == test_count)
            $display("TEST PASSED: %0d/%0d tests passed", pass_count, test_count);
        else
            $display("TEST FAILED: %0d/%0d tests passed", pass_count, test_count);

        $finish;
    end

endmodule
