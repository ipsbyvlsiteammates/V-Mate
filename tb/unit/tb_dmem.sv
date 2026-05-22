`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////
// Testbench: tb_dmem
// Description: Unit testbench for Data Memory module
// Author: Sagi
// Date: 2026-05-14
//////////////////////////////////////////////////////////////////////////////

module tb_dmem;

    // DUT signals
    reg         clk;
    reg         mem_write;
    reg         mem_read;
    reg  [31:0] addr;
    reg  [31:0] write_data;
    reg  [2:0]  mem_size;
    wire [31:0] read_data;

    // Test tracking
    integer test_count;
    integer pass_count;

    // Instantiate DUT
    dmem dut (
        .clk(clk),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .addr(addr),
        .write_data(write_data),
        .mem_size(mem_size),
        .read_data(read_data)
    );

    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Task: write memory
    task write_mem(input [31:0] a, input [31:0] d, input [2:0] sz);
        begin
            @(posedge clk);
            addr       = a;
            write_data = d;
            mem_size   = sz;
            mem_write  = 1;
            mem_read   = 0;
            @(posedge clk);
            mem_write  = 0;
        end
    endtask

    // Task: read memory and check
    task read_and_check(input [31:0] a, input [2:0] sz, input [31:0] expected, input integer tnum, input [255:0] desc);
        begin
            addr      = a;
            mem_size  = sz;
            mem_write = 0;
            mem_read  = 1;
            #1;
            test_count = test_count + 1;
            if (read_data === expected) begin
                $display("TEST %0d PASS: %0s", tnum, desc);
                pass_count = pass_count + 1;
            end else begin
                $display("TEST %0d FAIL: %0s (expected 0x%08h, got 0x%08h)", tnum, desc, expected, read_data);
            end
            mem_read = 0;
        end
    endtask

    initial begin
        // Initialize
        mem_write  = 0;
        mem_read   = 0;
        addr       = 32'h0;
        write_data = 32'h0;
        mem_size   = 3'b010;
        test_count = 0;
        pass_count = 0;

        $display("============================================");
        $display("       Data Memory Testbench");
        $display("============================================");
        #10;

        //------------------------------------------------------------------
        // Group 1: Word Access
        //------------------------------------------------------------------
        $display("\n--- Group 1: Word Access ---");

        // TEST 1: SW then LW - write DEAD_BEEF to addr 0x00
        write_mem(32'h00, 32'hDEADBEEF, 3'b010);
        read_and_check(32'h00, 3'b010, 32'hDEADBEEF, 1, "SW then LW addr 0x00 = 0xDEADBEEF");

        // TEST 2: SW then LW - write A5A5_A5A5 to addr 0x04
        write_mem(32'h04, 32'hA5A5A5A5, 3'b010);
        read_and_check(32'h04, 3'b010, 32'hA5A5A5A5, 2, "SW then LW addr 0x04 = 0xA5A5A5A5");

        //------------------------------------------------------------------
        // Group 2: Byte Access with Sign Extension (LB)
        //------------------------------------------------------------------
        $display("\n--- Group 2: Byte Access with Sign Extension (LB) ---");

        // TEST 3: SB then LB - write 0xFF to addr 0x08, expect sign extended
        write_mem(32'h08, 32'h000000FF, 3'b000);
        read_and_check(32'h08, 3'b000, 32'hFFFFFFFF, 3, "SB 0xFF then LB = 0xFFFFFFFF (sign ext)");

        // TEST 4: SB then LB - write 0x7F to addr 0x09, positive
        write_mem(32'h09, 32'h0000007F, 3'b000);
        read_and_check(32'h09, 3'b000, 32'h0000007F, 4, "SB 0x7F then LB = 0x0000007F (positive)");

        //------------------------------------------------------------------
        // Group 3: Byte Access with Zero Extension (LBU)
        //------------------------------------------------------------------
        $display("\n--- Group 3: Byte Access with Zero Extension (LBU) ---");

        // TEST 5: SB then LBU - write 0xFF to addr 0x0A, zero extended
        write_mem(32'h0A, 32'h000000FF, 3'b000);
        read_and_check(32'h0A, 3'b100, 32'h000000FF, 5, "SB 0xFF then LBU = 0x000000FF (zero ext)");

        // TEST 6: SB then LBU - write 0x80 to addr 0x0B
        write_mem(32'h0B, 32'h00000080, 3'b000);
        read_and_check(32'h0B, 3'b100, 32'h00000080, 6, "SB 0x80 then LBU = 0x00000080 (zero ext)");

        //------------------------------------------------------------------
        // Group 4: Halfword Access with Sign Extension (LH)
        //------------------------------------------------------------------
        $display("\n--- Group 4: Halfword Access with Sign Extension (LH) ---");

        // TEST 7: SH then LH - write 0xFFFF to addr 0x0C, sign extended
        write_mem(32'h0C, 32'h0000FFFF, 3'b001);
        read_and_check(32'h0C, 3'b001, 32'hFFFFFFFF, 7, "SH 0xFFFF then LH = 0xFFFFFFFF (sign ext)");

        // TEST 8: SH then LH - write 0x7FFF to addr 0x0E, positive
        write_mem(32'h0E, 32'h00007FFF, 3'b001);
        read_and_check(32'h0E, 3'b001, 32'h00007FFF, 8, "SH 0x7FFF then LH = 0x00007FFF (positive)");

        //------------------------------------------------------------------
        // Group 5: Halfword Access with Zero Extension (LHU)
        //------------------------------------------------------------------
        $display("\n--- Group 5: Halfword Access with Zero Extension (LHU) ---");

        // TEST 9: SH then LHU - write 0x8000 to addr 0x10, zero extended
        write_mem(32'h10, 32'h00008000, 3'b001);
        read_and_check(32'h10, 3'b101, 32'h00008000, 9, "SH 0x8000 then LHU = 0x00008000 (zero ext)");

        // TEST 10: SH then LHU - write 0xABCD to addr 0x12
        write_mem(32'h12, 32'h0000ABCD, 3'b001);
        read_and_check(32'h12, 3'b101, 32'h0000ABCD, 10, "SH 0xABCD then LHU = 0x0000ABCD (zero ext)");

        //------------------------------------------------------------------
        // Group 6: Byte Within Word (Partial Write)
        //------------------------------------------------------------------
        $display("\n--- Group 6: Byte Within Word (Partial Write) ---");

        // TEST 11: Write word, overwrite byte 0, read word back
        write_mem(32'h14, 32'h12345678, 3'b010);
        write_mem(32'h14, 32'h000000AA, 3'b000);
        read_and_check(32'h14, 3'b010, 32'h123456AA, 11, "SW then SB byte0: expect 0x123456AA");

        // TEST 12: Write word, overwrite byte 3, read word back
        write_mem(32'h18, 32'h12345678, 3'b010);
        write_mem(32'h1B, 32'h000000BB, 3'b000);
        read_and_check(32'h18, 3'b010, 32'hBB345678, 12, "SW then SB byte3: expect 0xBB345678");

        //------------------------------------------------------------------
        // Group 7: Halfword Within Word (Partial Write)
        //------------------------------------------------------------------
        $display("\n--- Group 7: Halfword Within Word (Partial Write) ---");

        // TEST 13: Write word 0xFFFFFFFF, overwrite lower halfword with 0x1234
        write_mem(32'h1C, 32'hFFFFFFFF, 3'b010);
        write_mem(32'h1C, 32'h00001234, 3'b001);
        read_and_check(32'h1C, 3'b010, 32'hFFFF1234, 13, "SW then SH lower half: expect 0xFFFF1234");

        // TEST 14: Write word 0xFFFFFFFF, overwrite upper halfword with 0x5678
        write_mem(32'h20, 32'hFFFFFFFF, 3'b010);
        write_mem(32'h22, 32'h00005678, 3'b001);
        read_and_check(32'h20, 3'b010, 32'h5678FFFF, 14, "SW then SH upper half: expect 0x5678FFFF");

        //------------------------------------------------------------------
        // Group 8: Multiple Addresses
        //------------------------------------------------------------------
        $display("\n--- Group 8: Multiple Addresses ---");

        // TEST 15: Write 4 different values, read all back
        write_mem(32'h24, 32'h11111111, 3'b010);
        write_mem(32'h28, 32'h22222222, 3'b010);
        write_mem(32'h2C, 32'h33333333, 3'b010);
        write_mem(32'h30, 32'h44444444, 3'b010);
        begin
            reg [3:0] multi_pass;
            multi_pass = 4'b0000;
            // Check addr 0x24
            addr = 32'h24; mem_size = 3'b010; mem_write = 0; mem_read = 1; #1;
            if (read_data === 32'h11111111) multi_pass[0] = 1;
            // Check addr 0x28
            addr = 32'h28; #1;
            if (read_data === 32'h22222222) multi_pass[1] = 1;
            // Check addr 0x2C
            addr = 32'h2C; #1;
            if (read_data === 32'h33333333) multi_pass[2] = 1;
            // Check addr 0x30
            addr = 32'h30; #1;
            if (read_data === 32'h44444444) multi_pass[3] = 1;
            mem_read = 0;

            test_count = test_count + 1;
            if (multi_pass === 4'b1111) begin
                $display("TEST 15 PASS: Multiple addresses all correct");
                pass_count = pass_count + 1;
            end else begin
                $display("TEST 15 FAIL: Multiple addresses - some mismatch (pass_bits=%b)", multi_pass);
            end
        end

        //------------------------------------------------------------------
        // Group 9: Write Enable Gating
        //------------------------------------------------------------------
        $display("\n--- Group 9: Write Enable Gating ---");

        // TEST 16: Write word, attempt write with mem_write=0, verify unchanged
        write_mem(32'h34, 32'hCAFECAFE, 3'b010);
        // Attempt write with mem_write=0
        @(posedge clk);
        addr = 32'h34;
        write_data = 32'h00000000;
        mem_size = 3'b010;
        mem_write = 0;
        mem_read = 0;
        @(posedge clk);
        // Read back
        read_and_check(32'h34, 3'b010, 32'hCAFECAFE, 16, "Write with mem_write=0 does not modify memory");

        //------------------------------------------------------------------
        // Group 10: Read Enable Gating
        //------------------------------------------------------------------
        $display("\n--- Group 10: Read Enable Gating ---");

        // TEST 17: Write word, read with mem_read=0, expect 0
        write_mem(32'h38, 32'hBEEFBEEF, 3'b010);
        addr = 32'h38;
        mem_size = 3'b010;
        mem_write = 0;
        mem_read = 0;
        #1;
        test_count = test_count + 1;
        if (read_data === 32'h00000000) begin
            $display("TEST 17 PASS: Read with mem_read=0 returns 0x00000000");
            pass_count = pass_count + 1;
        end else begin
            $display("TEST 17 FAIL: Read with mem_read=0 (expected 0x00000000, got 0x%08h)", read_data);
        end

        // TEST 18: Read same addr with mem_read=1, expect correct value
        read_and_check(32'h38, 3'b010, 32'hBEEFBEEF, 18, "Read with mem_read=1 returns stored value");

        //------------------------------------------------------------------
        // Group 11: Sign Extension Boundary
        //------------------------------------------------------------------
        $display("\n--- Group 11: Sign Extension Boundary ---");

        // TEST 19: SB 0x80 then LB, expect sign extended to 0xFFFFFF80
        write_mem(32'h3C, 32'h00000080, 3'b000);
        read_and_check(32'h3C, 3'b000, 32'hFFFFFF80, 19, "SB 0x80 then LB = 0xFFFFFF80 (sign ext boundary)");

        // TEST 20: SH 0x8000 then LH, expect sign extended to 0xFFFF8000
        write_mem(32'h40, 32'h00008000, 3'b001);
        read_and_check(32'h40, 3'b001, 32'hFFFF8000, 20, "SH 0x8000 then LH = 0xFFFF8000 (sign ext boundary)");

        //------------------------------------------------------------------
        // Summary
        //------------------------------------------------------------------
        $display("\n============================================");
        $display("TEST RESULTS: %0d/%0d tests passed", pass_count, test_count);
        if (pass_count === test_count)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");
        $display("============================================");

        $finish;
    end

endmodule
