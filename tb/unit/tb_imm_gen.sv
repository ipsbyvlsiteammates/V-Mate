`timescale 1ns/1ps

module tb_imm_gen;

    // Inputs
    reg [31:0] instruction;
    reg [2:0]  imm_sel;

    // Outputs
    wire [31:0] imm_out;

    // Instantiate the Unit Under Test (UUT)
    imm_gen uut (
        .instruction(instruction),
        .imm_sel(imm_sel),
        .imm_out(imm_out)
    );

    // Test variables
    integer tests_passed = 0;
    integer tests_failed = 0;

    // Task to check results
    task check_result;
        input [31:0] expected;
        input string test_name;
        begin
            #1; // Wait for combinational logic
            if (imm_out === expected) begin
                $display("PASS: %s", test_name);
                tests_passed = tests_passed + 1;
            end else begin
                $display("FAIL: %s | Expected: %h, Got: %h", test_name, expected, imm_out);
                tests_failed = tests_failed + 1;
            end
        end
    endtask

    initial begin
        // Initialize Inputs
        instruction = 0;
        imm_sel = 0;

        $display("Starting imm_gen tests...");

        // Test IMM_I
        instruction = 32'h80010093; // ADDI x1, x2, -2048
        imm_sel = 3'b000;
        check_result(32'hfffff800, "IMM_I: Negative value (-2048)");

        instruction = 32'h7ff10093; // ADDI x1, x2, 2047
        imm_sel = 3'b000;
        check_result(32'h000007ff, "IMM_I: Positive value (2047)");

        // Test IMM_S
        instruction = 32'hfe112fa3; // SW x1, -1(x2)
        imm_sel = 3'b001;
        check_result(32'hffffffff, "IMM_S: Negative value (-1)");

        instruction = 32'h00112fa3; // SW x1, 31(x2)
        imm_sel = 3'b001;
        check_result(32'h0000001f, "IMM_S: Positive value (31)");

        // Test IMM_B
        instruction = 32'hfe208fe3; // BEQ x1, x2, -2
        imm_sel = 3'b010;
        check_result(32'hfffffffe, "IMM_B: Negative value (-2)");

        instruction = 32'h00208063; // BEQ x1, x2, 0
        imm_sel = 3'b010;
        check_result(32'h00000000, "IMM_B: Zero value (0)");

        // Test IMM_U
        instruction = 32'h123450b7; // LUI x1, 0x12345
        imm_sel = 3'b011;
        check_result(32'h12345000, "IMM_U: Positive value (0x12345000)");

        instruction = 32'hfffff0b7; // LUI x1, 0xfffff
        imm_sel = 3'b011;
        check_result(32'hfffff000, "IMM_U: Negative value (0xfffff000)");

        // Test IMM_J
        instruction = 32'hffffffef; // JAL x1, -2
        imm_sel = 3'b100;
        check_result(32'hfffffffe, "IMM_J: Negative value (-2)");

        instruction = 32'h000000ef; // JAL x1, 0
        imm_sel = 3'b100;
        check_result(32'h00000000, "IMM_J: Zero value (0)");

        // Test IMM_Z
        instruction = 32'h000f9073; // CSRRW x0, csr, 31
        imm_sel = 3'b101;
        check_result(32'h0000001f, "IMM_Z: Max value (31)");

        instruction = 32'h00001073; // CSRRW x0, csr, 0
        imm_sel = 3'b101;
        check_result(32'h00000000, "IMM_Z: Min value (0)");

        // Default case
        instruction = 32'hffffffff;
        imm_sel = 3'b111;
        check_result(32'h00000000, "Default: Unknown imm_sel");

        // Print summary
        $display("-------------------------------------------------");
        $display("Test Summary:");
        $display("Passed: %0d", tests_passed);
        $display("Failed: %0d", tests_failed);
        $display("-------------------------------------------------");
        if (tests_failed == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("SOME TESTS FAILED");
        end

        $finish;
    end

endmodule
