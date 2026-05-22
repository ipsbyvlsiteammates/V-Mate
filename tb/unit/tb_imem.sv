`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////
// Testbench: tb_imem
// Description: Unit testbench for instruction memory (imem) module
// Tests combinational read behavior with known hex file values
//////////////////////////////////////////////////////////////////////////////

module tb_imem;

    // Signals
    reg  [31:0] addr;
    wire [31:0] instruction;

    // Instantiate DUT
    imem dut (
        .addr(addr),
        .instruction(instruction)
    );

    // Test tracking
    integer pass_count;
    integer fail_count;
    integer test_num;

    // Task to check expected value
    task check_result;
        input [31:0] expected;
        input [255:0] test_name;
        begin
            if (instruction === expected) begin
                $display("TEST %0d PASS: %0s | addr=0x%08h | got=0x%08h", test_num, test_name, addr, instruction);
                pass_count = pass_count + 1;
            end else begin
                $display("TEST %0d FAIL: %0s | addr=0x%08h | expected=0x%08h | got=0x%08h", test_num, test_name, addr, expected, instruction);
                fail_count = fail_count + 1;
            end
            test_num = test_num + 1;
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        test_num = 1;

        $display("==================================================");
        $display("  IMEM Unit Testbench");
        $display("==================================================");

        // -------------------------------------------------------
        // Test 1: Read address 0 (word 0)
        // -------------------------------------------------------
        addr = 32'h0000_0000;
        #10;
        check_result(32'h00000013, "Read address 0 (NOP)");

        // -------------------------------------------------------
        // Test 2: Read sequential addresses (0, 4, 8, 12)
        // -------------------------------------------------------
        addr = 32'h0000_0004;
        #10;
        check_result(32'h00100093, "Read address 4 (ADDI x1, x0, 1)");

        addr = 32'h0000_0008;
        #10;
        check_result(32'h00200113, "Read address 8 (ADDI x2, x0, 2)");

        addr = 32'h0000_000C;
        #10;
        check_result(32'h00300193, "Read address 12 (ADDI x3, x0, 3)");

        // -------------------------------------------------------
        // Test 3: Read non-sequential address (0x40 = word 16)
        // -------------------------------------------------------
        addr = 32'h0000_0040;
        #10;
        check_result(32'h01000813, "Read address 0x40 (ADDI x16, x0, 16)");

        // -------------------------------------------------------
        // Test 4: Verify known instruction values at various addresses
        // -------------------------------------------------------
        addr = 32'h0000_0010;
        #10;
        check_result(32'h00400213, "Read address 0x10 (ADDI x4, x0, 4)");

        addr = 32'h0000_0014;
        #10;
        check_result(32'h00500293, "Read address 0x14 (ADDI x5, x0, 5)");

        addr = 32'h0000_001C;
        #10;
        check_result(32'h00700393, "Read address 0x1C (ADDI x7, x0, 7)");

        // -------------------------------------------------------
        // Test 5: Boundary - last valid address (word 1023 = 0x0FFC)
        // -------------------------------------------------------
        addr = 32'h0000_0FFC;
        #10;
        check_result(32'hDEADBEEF, "Read last valid address 0x0FFC");

        // -------------------------------------------------------
        // Test 6: Multiple random reads
        // -------------------------------------------------------
        addr = 32'h0000_0020;
        #10;
        check_result(32'h00800413, "Random read addr 0x20 (ADDI x8, x0, 8)");

        addr = 32'h0000_0038;
        #10;
        check_result(32'h00E00713, "Random read addr 0x38 (ADDI x14, x0, 14)");

        // -------------------------------------------------------
        // Test 7: Read same address twice (deterministic output)
        // -------------------------------------------------------
        addr = 32'h0000_0004;
        #10;
        check_result(32'h00100093, "Re-read address 4 (first)");

        addr = 32'h0000_0004;
        #10;
        check_result(32'h00100093, "Re-read address 4 (second)");

        // -------------------------------------------------------
        // Test 8: Address with upper bits set (should be ignored)
        // addr[31:12] ignored, only addr[11:2] used
        // 0xFFFFF004 -> addr[11:2] = 10'b0000000001 = word 1
        // -------------------------------------------------------
        addr = 32'hFFFFF004;
        #10;
        check_result(32'h00100093, "Upper bits ignored (0xFFFFF004 == word 1)");

        // -------------------------------------------------------
        // Summary
        // -------------------------------------------------------
        $display("==================================================");
        $display("  Test Summary: %0d PASSED, %0d FAILED out of %0d tests", pass_count, fail_count, pass_count + fail_count);
        $display("==================================================");

        if (fail_count == 0)
            $display("  ALL TESTS PASSED");
        else
            $display("  SOME TESTS FAILED");

        $finish;
    end

endmodule
