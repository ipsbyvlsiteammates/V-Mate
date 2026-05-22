`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////
// File:        tb_register_file.sv
// Description: Testbench for RISC-V 32x32 Register File
//              Tests: reset, read/write, x0 hardwired, simultaneous reads,
//              no-forwarding, all registers, write-enable gating
//////////////////////////////////////////////////////////////////////////////

module tb_register_file;

    //--------------------------------------------------------------------------
    // Signals
    //--------------------------------------------------------------------------
    reg         clk;
    reg         rst_n;
    reg         we;
    reg  [4:0]  rs1_addr;
    reg  [4:0]  rs2_addr;
    reg  [4:0]  rd_addr;
    reg  [31:0] rd_data;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    //--------------------------------------------------------------------------
    // DUT Instantiation
    //--------------------------------------------------------------------------
    register_file dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .we       (we),
        .rs1_addr (rs1_addr),
        .rs2_addr (rs2_addr),
        .rd_addr  (rd_addr),
        .rd_data  (rd_data),
        .rs1_data (rs1_data),
        .rs2_data (rs2_data)
    );

    //--------------------------------------------------------------------------
    // Clock Generation: 10ns period (5ns high, 5ns low)
    //--------------------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    //--------------------------------------------------------------------------
    // Test Counters
    //--------------------------------------------------------------------------
    integer pass_count;
    integer fail_count;
    integer test_num;

    //--------------------------------------------------------------------------
    // Check Task
    //--------------------------------------------------------------------------
    task check(input string test_name, input [31:0] expected, input [31:0] actual);
        begin
            test_num = test_num + 1;
            if (actual === expected) begin
                $display("[PASS] %s", test_name);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %s: expected=0x%08h, got=0x%08h", test_name, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask

    //--------------------------------------------------------------------------
    // Write Task: sets up write signals before posedge clk
    //--------------------------------------------------------------------------
    task write_reg(input [4:0] addr, input [31:0] data);
        begin
            we      = 1'b1;
            rd_addr = addr;
            rd_data = data;
            @(posedge clk);
            #1;
            we      = 1'b0;
        end
    endtask

    //--------------------------------------------------------------------------
    // Read Task: sets read addresses and waits for combinational output
    //--------------------------------------------------------------------------
    task read_regs(input [4:0] addr1, input [4:0] addr2);
        begin
            rs1_addr = addr1;
            rs2_addr = addr2;
            #1; // Allow combinational logic to settle
        end
    endtask

    //--------------------------------------------------------------------------
    // Local Parameters
    //--------------------------------------------------------------------------
    localparam logic [31:0] DEADBEEF  = 32'hDEAD_BEEF;
    localparam logic [31:0] CAFEBABE  = 32'hCAFE_BABE;
    localparam logic [31:0] A5A5A5A5  = 32'hA5A5_A5A5;
    localparam logic [31:0] VALUE_X1  = 32'h0000_0001;
    localparam logic [31:0] VALUE_X2  = 32'h0000_0002;
    localparam logic [31:0] VALUE_X5  = 32'h0000_0055;
    localparam logic [31:0] VALUE_X10 = 32'h0000_00AA;
    localparam logic [31:0] VALUE_X31 = 32'h7FFF_FFFF;
    localparam logic [31:0] NEW_VAL   = 32'h1234_5678;
    localparam logic [31:0] OLD_VAL   = 32'hAAAA_BBBB;
    localparam logic [4:0]  ADDR_X0   = 5'd0;
    localparam logic [4:0]  ADDR_X1   = 5'd1;
    localparam logic [4:0]  ADDR_X2   = 5'd2;
    localparam logic [4:0]  ADDR_X3   = 5'd3;
    localparam logic [4:0]  ADDR_X5   = 5'd5;
    localparam logic [4:0]  ADDR_X10  = 5'd10;
    localparam logic [4:0]  ADDR_X15  = 5'd15;
    localparam logic [4:0]  ADDR_X31  = 5'd31;

    //--------------------------------------------------------------------------
    // Main Test Sequence
    //--------------------------------------------------------------------------
    integer j;

    initial begin
        // Initialize
        pass_count = 0;
        fail_count = 0;
        test_num   = 0;
        rst_n      = 1'b1;
        we         = 1'b0;
        rs1_addr   = 5'b0;
        rs2_addr   = 5'b0;
        rd_addr    = 5'b0;
        rd_data    = 32'b0;

        //======================================================================
        // TEST GROUP A: Reset Behavior
        //======================================================================
        $display("\n--- Test Group A: Reset Behavior ---");

        // Assert reset (active-low: rst_n = 0)
        rst_n = 1'b0;
        @(posedge clk);
        #1;

        // Test 1: After reset, x1 reads as 0
        read_regs(ADDR_X1, ADDR_X15);
        check("A1: After reset, x1 == 0", 32'h0, rs1_data);

        // Test 2: After reset, x15 reads as 0
        check("A2: After reset, x15 == 0", 32'h0, rs2_data);

        // Test 3: After reset, x31 reads as 0
        read_regs(ADDR_X31, ADDR_X0);
        check("A3: After reset, x31 == 0", 32'h0, rs1_data);

        // Deassert reset
        rst_n = 1'b1;
        @(posedge clk);
        #1;

        //======================================================================
        // TEST GROUP B: Basic Write and Read Back
        //======================================================================
        $display("\n--- Test Group B: Basic Write and Read Back ---");

        // Write to x1
        write_reg(ADDR_X1, VALUE_X1);
        read_regs(ADDR_X1, ADDR_X0);
        check("B1: Write x1, read back", VALUE_X1, rs1_data);

        // Write to x2
        write_reg(ADDR_X2, VALUE_X2);
        read_regs(ADDR_X2, ADDR_X0);
        check("B2: Write x2, read back", VALUE_X2, rs1_data);

        // Write to x5
        write_reg(ADDR_X5, VALUE_X5);
        read_regs(ADDR_X5, ADDR_X0);
        check("B3: Write x5, read back", VALUE_X5, rs1_data);

        // Write to x10
        write_reg(ADDR_X10, VALUE_X10);
        read_regs(ADDR_X10, ADDR_X0);
        check("B4: Write x10, read back", VALUE_X10, rs1_data);

        // Write to x31
        write_reg(ADDR_X31, VALUE_X31);
        read_regs(ADDR_X31, ADDR_X0);
        check("B5: Write x31, read back", VALUE_X31, rs1_data);

        //======================================================================
        // TEST GROUP C: x0 Hardwired to Zero
        //======================================================================
        $display("\n--- Test Group C: x0 Hardwired to Zero ---");

        // Attempt to write to x0
        write_reg(ADDR_X0, DEADBEEF);
        read_regs(ADDR_X0, ADDR_X0);
        check("C1: Write DEADBEEF to x0, rs1 reads 0", 32'h0, rs1_data);
        check("C2: Write DEADBEEF to x0, rs2 reads 0", 32'h0, rs2_data);

        //======================================================================
        // TEST GROUP D: Simultaneous Read of Two Different Registers
        //======================================================================
        $display("\n--- Test Group D: Simultaneous Read ---");

        // x1 and x5 should still have their written values
        read_regs(ADDR_X1, ADDR_X5);
        check("D1: Simultaneous read rs1=x1", VALUE_X1, rs1_data);
        check("D2: Simultaneous read rs2=x5", VALUE_X5, rs2_data);

        // x10 and x31
        read_regs(ADDR_X10, ADDR_X31);
        check("D3: Simultaneous read rs1=x10", VALUE_X10, rs1_data);
        check("D4: Simultaneous read rs2=x31", VALUE_X31, rs2_data);

        //======================================================================
        // TEST GROUP E: Write-then-Read Same Cycle (No Forwarding)
        //======================================================================
        $display("\n--- Test Group E: No Forwarding (Read Returns Old Value) ---");

        // First write a known value to x3
        write_reg(ADDR_X3, OLD_VAL);
        read_regs(ADDR_X3, ADDR_X0);
        check("E1: Pre-condition x3 == OLD_VAL", OLD_VAL, rs1_data);

        // Now write NEW_VAL to x3 and simultaneously read x3 in the same cycle
        // Set up write and read at the same time
        we       = 1'b1;
        rd_addr  = ADDR_X3;
        rd_data  = NEW_VAL;
        rs1_addr = ADDR_X3;
        rs2_addr = ADDR_X3;
        // Before posedge: read should still show OLD_VAL (combinational from regs)
        #1;
        check("E2: Read x3 during write cycle returns OLD value", OLD_VAL, rs1_data);

        // Now clock the write in
        @(posedge clk);
        #1;
        we = 1'b0;

        // After clock edge, read should show NEW_VAL
        read_regs(ADDR_X3, ADDR_X0);
        check("E3: After write clocked in, x3 == NEW_VAL", NEW_VAL, rs1_data);

        //======================================================================
        // TEST GROUP F: All 32 Registers
        //======================================================================
        $display("\n--- Test Group F: All 32 Registers ---");

        // Write unique values to x1-x31
        for (j = 1; j < 32; j = j + 1) begin
            write_reg(j[4:0], (32'hBA5E_0000 + j));
        end

        // Read all back and verify
        // Check x0 is still 0
        read_regs(ADDR_X0, ADDR_X1);
        check("F1: x0 still 0 after writing all regs", 32'h0, rs1_data);

        // Check a sampling of registers (x1, x16, x31)
        read_regs(ADDR_X1, 5'd16);
        check("F2: x1 == BASE+1", (32'hBA5E_0000 + 32'd1), rs1_data);
        check("F3: x16 == BASE+16", (32'hBA5E_0000 + 32'd16), rs2_data);

        read_regs(ADDR_X31, 5'd20);
        check("F4: x31 == BASE+31", (32'hBA5E_0000 + 32'd31), rs1_data);
        check("F5: x20 == BASE+20", (32'hBA5E_0000 + 32'd20), rs2_data);

        //======================================================================
        // TEST GROUP G: Write Enable Gating
        //======================================================================
        $display("\n--- Test Group G: Write Enable Gating ---");

        // x1 currently has BA5E+1. Try to write CAFEBABE with we=0
        we      = 1'b0;
        rd_addr = ADDR_X1;
        rd_data = CAFEBABE;
        @(posedge clk);
        #1;

        read_regs(ADDR_X1, ADDR_X0);
        check("G1: we=0, x1 retains old value", (32'hBA5E_0000 + 32'd1), rs1_data);

        //======================================================================
        // TEST GROUP H: Write to x0 Ignored (additional)
        //======================================================================
        $display("\n--- Test Group H: x0 Write Ignored (additional) ---");

        write_reg(ADDR_X0, A5A5A5A5);
        read_regs(ADDR_X0, ADDR_X0);
        check("H1: x0 still 0 after writing A5A5A5A5", 32'h0, rs1_data);

        //======================================================================
        // Final Summary
        //======================================================================
        $display("\n============================================");
        if (fail_count == 0) begin
            $display("TEST PASSED: %0d/%0d tests passed", pass_count, test_num);
        end else begin
            $display("TEST FAILED: %0d/%0d tests failed", fail_count, test_num);
        end
        $display("============================================\n");
        $finish;
    end

endmodule
