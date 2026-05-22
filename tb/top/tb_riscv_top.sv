module tb_riscv_top;

  logic clk;
  logic rst_n;

  // Instantiate the DUT
  riscv_top #(
    .PRIVILEGED(0)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .clk_en(1'b1)
  );

  initial begin
    $monitor("Time=%0t rst_n=%b PC=%h instr=%h x30=%h", $time, rst_n, dut.u_pc.pc_out, dut.u_imem.instruction, dut.u_register_file.regs[30]);
  end
  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10ns period
  end

  // Expected signature array
  logic [31:0] expected_sig [0:40];
  int errors;

  initial begin
    // Initialize expected signature
    expected_sig[0]  = 32'h00000005;
    expected_sig[1]  = 32'h00000008;
    expected_sig[2]  = 32'h00000002;
    expected_sig[3]  = 32'h00000028;
    expected_sig[4]  = 32'h00000001;
    expected_sig[5]  = 32'h00000000;
    expected_sig[6]  = 32'h00000006;
    expected_sig[7]  = 32'h00000005;
    expected_sig[8]  = 32'hffffffff;
    expected_sig[9]  = 32'h00000007;
    expected_sig[10] = 32'h00000001;
    expected_sig[11] = 32'h00000001;
    expected_sig[12] = 32'h00000000;
    expected_sig[13] = 32'h0000000a;
    expected_sig[14] = 32'h0000000d;
    expected_sig[15] = 32'h00000004;
    expected_sig[16] = 32'h00000014;
    expected_sig[17] = 32'h0000000a;
    expected_sig[18] = 32'hfffffffc;
    expected_sig[19] = 32'h12345678;
    expected_sig[20] = 32'h000000b8;
    expected_sig[21] = 32'h12345678;
    expected_sig[22] = 32'hffffff80;
    expected_sig[23] = 32'h0000ff80;
    expected_sig[24] = 32'hffffff80;
    expected_sig[25] = 32'h00000080;
    expected_sig[26] = 32'h00000000;
    expected_sig[27] = 32'h00000000;
    expected_sig[28] = 32'h00000000;
    expected_sig[29] = 32'h00000000;
    expected_sig[30] = 32'h00000000;
    expected_sig[31] = 32'h00000000;
    expected_sig[32] = 32'h00000000;
    expected_sig[33] = 32'h00000174;
    expected_sig[34] = 32'h00000188;
    expected_sig[35] = 32'h00000001;
    expected_sig[36] = 32'h00000005;
    expected_sig[37] = 32'h80000000;
    expected_sig[38] = 32'h80000000;
    expected_sig[39] = 32'h00000001;
    expected_sig[40] = 32'h00000000;

    // Load instruction memory
    $readmemh("../tb/top/test_programs/full_isa_test.hex", dut.u_imem.mem);

    // Reset sequence
    rst_n = 0;
    errors = 0;
    
    // Wait 3 cycles
    repeat(3) @(posedge clk);
    rst_n = 1;

    // Run for 500 cycles
    repeat(500) @(posedge clk);

    // Check signature
    $display("--- Checking Signature ---");
    for (int i = 0; i < 41; i++) begin
      if ({dut.u_dmem.mem[2048 + i*4 + 3], dut.u_dmem.mem[2048 + i*4 + 2], dut.u_dmem.mem[2048 + i*4 + 1], dut.u_dmem.mem[2048 + i*4]} === expected_sig[i]) begin
        $display("[PASS] Signature[%0d] (Addr 0x%0x): Expected 0x%08x, Got 0x%08x", 
                 i, 32'h800 + i*4, expected_sig[i], {dut.u_dmem.mem[2048 + i*4 + 3], dut.u_dmem.mem[2048 + i*4 + 2], dut.u_dmem.mem[2048 + i*4 + 1], dut.u_dmem.mem[2048 + i*4]});
      end else begin
        $display("[FAIL] Signature[%0d] (Addr 0x%0x): Expected 0x%08x, Got 0x%08x", 
                 i, 32'h800 + i*4, expected_sig[i], {dut.u_dmem.mem[2048 + i*4 + 3], dut.u_dmem.mem[2048 + i*4 + 2], dut.u_dmem.mem[2048 + i*4 + 1], dut.u_dmem.mem[2048 + i*4]});
        errors++;
      end
    end

    if (errors == 0) begin
      $display("FULL ISA TEST PASSED: All 47 RV32I instructions verified");
    end else begin
      $display("FULL ISA TEST FAILED with %0d errors", errors);
    end

    $finish;
  end

endmodule