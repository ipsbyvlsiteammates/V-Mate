`timescale 1ns/1ps

module tb_arch_test;
    logic clk;
    logic rst_n;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Reset generation
    initial begin
        rst_n = 0;
        #22 rst_n = 1;
    end

    // DUT Instantiation
    riscv_top dut (
        .clk_en(1'b1),
        .clk(clk),
        .rst_n(rst_n)
    );

    // Load memories
    initial begin
        $readmemh("imem.hex", dut.u_imem.mem);
        $readmemh("dmem.hex", dut.u_dmem.mem);
    end

    // Monitor tohost
    logic [31:0] tohost_addr;
    initial begin
        if (!$value$plusargs("TOHOST_ADDR=%x", tohost_addr)) begin
            $display("ERROR: +TOHOST_ADDR not provided");
            $finish;
        end
    end

    logic [31:0] tohost_payload;
    always @(posedge clk) begin
        if (dut.mem_write_w) begin
            if (dut.alu_result_w == tohost_addr) begin
                tohost_payload <= dut.rs2_data_w;
            end else if (dut.alu_result_w == tohost_addr + 4) begin
                if (dut.rs2_data_w == 32'd0) begin
                    if (tohost_payload[0] == 1'b1) begin
                        if (tohost_payload == 32'd1) begin
                            $display("TEST PASSED");
                            $finish;
                        end else begin
                            $display("TEST FAILED with code %0d", tohost_payload >> 1);
                            $finish;
                        end
                    end
                end else if (dut.rs2_data_w == 32'h01010000) begin
                    $write("%c", tohost_payload[7:0]);
                end
            end
        end
    end

    
    integer trace_file;
    initial begin
        trace_file = $fopen("trace.log", "w");
    end
    always @(posedge clk) begin
        if (rst_n) begin
            $fdisplay(trace_file, "PC: %h | Instr: %h | rs1_d: %h | rs2_d: %h | alu_res: %h | mem_w: %b | reg_w: %b | csr_w: %b | csr_op: %b | csr_addr: %h | csr_wdata: %h | mscratch: %h", 
                dut.pc_out_w, dut.instruction_w, dut.rs1_data_w, dut.rs2_data_w, dut.alu_result_w, dut.mem_write_w, dut.reg_write_w, dut.csr_write_w, dut.csr_op_w, dut.instruction_w[31:20], dut.csr_wdata_w, dut.gen_csr.u_csr_file.mscratch_reg);
        end
    end

    // Timeout
    initial begin
        #10000000; // 1,000,000 ns = 100,000 cycles
        $display("TEST TIMEOUT");
        $finish;
    end

    always @(posedge clk) begin
        if (rst_n && (dut.fp_we_w || dut.fp_mem_write_w || dut.instruction_w[6:0] == 7'b1010011 || dut.instruction_w[6:0] == 7'b1000011 || dut.instruction_w[6:0] == 7'b1000111 || dut.instruction_w[6:0] == 7'b1001011 || dut.instruction_w[6:0] == 7'b1001111)) begin
            $display("FP_TRACE PC: %h | Instr: %h | rs1: %h | rs2: %h | rs3: %h | alu_res: %h | fflags: %b", 
                dut.pc_out_w, dut.instruction_w, dut.fp_rs1_data_w, dut.fp_rs2_data_w, dut.fp_rs3_data_w, dut.fp_alu_result_w, dut.fp_fflags_w);
        end
    end

endmodule
