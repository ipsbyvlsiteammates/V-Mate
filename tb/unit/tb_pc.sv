`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////
// Testbench: tb_pc
// Description: Unit testbench for the Program Counter (pc) module.
//              Covers reset, sequential increment, branch loading,
//              and edge cases.
// Author: RISC-V Processor Project
// Date: 2024
//////////////////////////////////////////////////////////////////////////////

module tb_pc;

    //--------------------------------------------------------------------------
    // Signal declarations
    //--------------------------------------------------------------------------
    reg         clk;
    reg         rst_n;
    reg         pc_sel;
    reg  [31:0] pc_target;
    reg         exception;
    reg  [31:0] mtvec;
    reg         mret_exec;
    reg  [31:0] mepc;
    wire [31:0] pc_out;

    // Test tracking
    integer pass_count;
    integer fail_count;
    integer test_num;

    //--------------------------------------------------------------------------
    // DUT instantiation
    //--------------------------------------------------------------------------
    pc dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .pc_sel    (pc_sel),
        .pc_target (pc_target),
        .exception (exception),
        .mtvec     (mtvec),
        .mret_exec (mret_exec),
        .mepc      (mepc),
        .pc_out    (pc_out)
    );

    //--------------------------------------------------------------------------
    // Clock generation: 10ns period (5ns high, 5ns low)
    //--------------------------------------------------------------------------
    initial begin
        clk = 1'b0;
    end
    always #5 clk = ~clk;

    //--------------------------------------------------------------------------
    // Test helper tasks
    //--------------------------------------------------------------------------
    task check_pc(input [31:0] expected, input string test_name);
        begin
            test_num = test_num + 1;
            if (pc_out === expected) begin
                $display("[PASS] Test %0d: %s | pc_out = 0x%08H (expected 0x%08H)", test_num, test_name, pc_out, expected);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: %s | pc_out = 0x%08H (expected 0x%08H)", test_num, test_name, pc_out, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task wait_clock_edge;
        begin
            @(posedge clk);
            #1; // Small delay for output to settle
        end
    endtask

    //--------------------------------------------------------------------------
    // Main test sequence
    //--------------------------------------------------------------------------
    initial begin
        // Initialize
        pass_count = 0;
        fail_count = 0;
        test_num   = 0;
        rst_n      = 1'b1;
        pc_sel     = 1'b0;
        pc_target  = 32'h0000_0000;
        exception  = 1'b0;
        mtvec      = 32'h0000_0000;
        mret_exec  = 1'b0;
        mepc       = 32'h0000_0000;

        $display("============================================================");
        $display("  Program Counter (pc) Unit Test");
        $display("============================================================");

        //----------------------------------------------------------------------
        // Test 1: Reset - Assert rst_n=0, verify pc_out==0 after clock edge
        //----------------------------------------------------------------------
        rst_n = 1'b0;
        pc_sel = 1'b0;
        wait_clock_edge;
        check_pc(32'h0000_0000, "Reset asserted - pc_out should be 0");

        //----------------------------------------------------------------------
        // Test 2: Release reset - Deassert rst_n=1, verify PC starts incrementing
        //----------------------------------------------------------------------
        rst_n = 1'b1;
        pc_sel = 1'b0;
        wait_clock_edge;
        check_pc(32'h0000_0004, "Release reset - PC increments to 4");

        //----------------------------------------------------------------------
        // Test 3: Sequential increment (1 cycle) - verify pc_out goes from 4 to 8
        //----------------------------------------------------------------------
        pc_sel = 1'b0;
        wait_clock_edge;
        check_pc(32'h0000_0008, "Sequential increment - PC goes from 4 to 8");

        //----------------------------------------------------------------------
        // Test 4: Sequential increment (multiple cycles) - verify 8->12->16->20
        //----------------------------------------------------------------------
        pc_sel = 1'b0;
        wait_clock_edge;
        check_pc(32'h0000_000C, "Sequential multi-cycle - PC = 0x0C");
        wait_clock_edge;
        check_pc(32'h0000_0010, "Sequential multi-cycle - PC = 0x10");
        wait_clock_edge;
        check_pc(32'h0000_0014, "Sequential multi-cycle - PC = 0x14");

        //----------------------------------------------------------------------
        // Test 5: Branch target load - pc_sel=1, pc_target=0x100
        //----------------------------------------------------------------------
        pc_sel = 1'b1;
        pc_target = 32'h0000_0100;
        wait_clock_edge;
        check_pc(32'h0000_0100, "Branch target load - PC = 0x100");

        //----------------------------------------------------------------------
        // Test 6: Return to sequential after branch - pc_sel=0, verify PC+4 from 0x100
        //----------------------------------------------------------------------
        pc_sel = 1'b0;
        wait_clock_edge;
        check_pc(32'h0000_0104, "Return to sequential after branch - PC = 0x104");

        //----------------------------------------------------------------------
        // Test 7: Multiple consecutive branches
        //----------------------------------------------------------------------
        pc_sel = 1'b1;
        pc_target = 32'h0000_0200;
        wait_clock_edge;
        check_pc(32'h0000_0200, "Consecutive branch 1 - PC = 0x200");

        pc_target = 32'h0000_0400;
        wait_clock_edge;
        check_pc(32'h0000_0400, "Consecutive branch 2 - PC = 0x400");

        pc_target = 32'h0000_0800;
        wait_clock_edge;
        check_pc(32'h0000_0800, "Consecutive branch 3 - PC = 0x800");

        //----------------------------------------------------------------------
        // Test 8: Reset during operation - Assert reset mid-operation
        //----------------------------------------------------------------------
        pc_sel = 1'b0;
        wait_clock_edge; // PC should be 0x804
        rst_n = 1'b0;
        wait_clock_edge;
        check_pc(32'h0000_0000, "Reset during operation - PC returns to 0");

        //----------------------------------------------------------------------
        // Test 9: Branch to address 0
        //----------------------------------------------------------------------
        rst_n = 1'b1;
        pc_sel = 1'b0;
        wait_clock_edge; // PC = 4
        wait_clock_edge; // PC = 8
        pc_sel = 1'b1;
        pc_target = 32'h0000_0000;
        wait_clock_edge;
        check_pc(32'h0000_0000, "Branch to address 0 - PC = 0x00");

        //----------------------------------------------------------------------
        // Test 10: Large target address
        //----------------------------------------------------------------------
        pc_sel = 1'b1;
        pc_target = 32'hFFFF_FFFC;
        wait_clock_edge;
        check_pc(32'hFFFF_FFFC, "Large target address - PC = 0xFFFFFFFC");

        //----------------------------------------------------------------------
        // Test 11: Exception jump
        //----------------------------------------------------------------------
        pc_sel = 1'b0;
        exception = 1'b1;
        mtvec = 32'h0000_1000;
        wait_clock_edge;
        check_pc(32'h0000_1000, "Exception jump - PC = mtvec (0x1000)");
        exception = 1'b0;
        wait_clock_edge;
        check_pc(32'h0000_1004, "Sequential after exception - PC = 0x1004");

        //----------------------------------------------------------------------
        // Test 12: MRET jump
        //----------------------------------------------------------------------
        mret_exec = 1'b1;
        mepc = 32'h0000_2000;
        wait_clock_edge;
        check_pc(32'h0000_2000, "MRET jump - PC = mepc (0x2000)");
        mret_exec = 1'b0;
        wait_clock_edge;
        check_pc(32'h0000_2004, "Sequential after MRET - PC = 0x2004");

        //----------------------------------------------------------------------
        // Test Summary
        //----------------------------------------------------------------------
        $display("============================================================");
        $display("  Test Summary: %0d PASSED, %0d FAILED out of %0d tests", pass_count, fail_count, test_num);
        $display("============================================================");

        if (fail_count == 0)
            $display("  >>> ALL TESTS PASSED <<<");
        else
            $display("  >>> SOME TESTS FAILED <<<");

        $finish;
    end

    //--------------------------------------------------------------------------
    // Timeout watchdog
    //--------------------------------------------------------------------------
    initial begin
        #10000;
        $display("[ERROR] Simulation timeout!");
        $finish;
    end

endmodule
