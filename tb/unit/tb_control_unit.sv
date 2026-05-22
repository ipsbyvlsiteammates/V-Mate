`timescale 1ns/1ps

module tb_control_unit;

    // Inputs
    reg [6:0] opcode;
    reg [2:0] funct3;
    reg [6:0] funct7;
    reg [4:0] rs1_addr;
    reg [4:0] rs2_addr;
    reg [4:0] rd_addr;

    // Outputs
    wire        reg_write;
    wire  [1:0] result_sel;
    wire        mem_write;
    wire        mem_read;
    wire        alu_src;
    wire        pc_src_auipc;
    wire  [2:0] imm_sel;
    wire        branch;
    wire        jump;
    wire  [3:0] alu_op;
    wire  [2:0] mem_size;
    wire        csr_write;
    wire  [1:0] csr_op;
    wire        csr_imm_sel;
    wire        exception;
    wire  [3:0] exception_cause;
    wire        mret_exec;

    // Instantiate the Unit Under Test (UUT)
    control_unit #(
        .PRIVILEGED(1)
    ) uut (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .reg_write(reg_write),
        .result_sel(result_sel),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .alu_src(alu_src),
        .pc_src_auipc(pc_src_auipc),
        .imm_sel(imm_sel),
        .branch(branch),
        .jump(jump),
        .alu_op(alu_op),
        .mem_size(mem_size),
        .csr_write(csr_write),
        .csr_op(csr_op),
        .csr_imm_sel(csr_imm_sel),
        .exception(exception),
        .exception_cause(exception_cause),
        .mret_exec(mret_exec)
    );

    integer tests_passed = 0;
    integer tests_failed = 0;

    task check;
        input string name;
        input [6:0] exp_opcode;
        input [2:0] exp_funct3;
        input [6:0] exp_funct7;
        input [4:0] exp_rs1_addr;
        input [4:0] exp_rs2_addr;
        input [4:0] exp_rd_addr;
        
        input exp_reg_write;
        input [1:0] exp_result_sel;
        input exp_mem_write;
        input exp_mem_read;
        input exp_alu_src;
        input exp_pc_src_auipc;
        input [2:0] exp_imm_sel;
        input exp_branch;
        input exp_jump;
        input [3:0] exp_alu_op;
        input [2:0] exp_mem_size;
        input exp_csr_write;
        input [1:0] exp_csr_op;
        input exp_csr_imm_sel;
        input exp_exception;
        input [3:0] exp_exception_cause;
        input exp_mret_exec;
        begin
            opcode = exp_opcode;
            funct3 = exp_funct3;
            funct7 = exp_funct7;
            rs1_addr = exp_rs1_addr;
            rs2_addr = exp_rs2_addr;
            rd_addr = exp_rd_addr;
            #1;
            
            if (reg_write !== exp_reg_write ||
                result_sel !== exp_result_sel ||
                mem_write !== exp_mem_write ||
                mem_read !== exp_mem_read ||
                alu_src !== exp_alu_src ||
                pc_src_auipc !== exp_pc_src_auipc ||
                imm_sel !== exp_imm_sel ||
                branch !== exp_branch ||
                jump !== exp_jump ||
                alu_op !== exp_alu_op ||
                mem_size !== exp_mem_size ||
                csr_write !== exp_csr_write ||
                csr_op !== exp_csr_op ||
                csr_imm_sel !== exp_csr_imm_sel ||
                exception !== exp_exception ||
                exception_cause !== exp_exception_cause ||
                mret_exec !== exp_mret_exec) begin
                $display("FAIL: %s", name);
                $display("  Expected: reg_write=%b, result_sel=%b, mem_write=%b, mem_read=%b, alu_src=%b, pc_src_auipc=%b, imm_sel=%b, branch=%b, jump=%b, alu_op=%b, mem_size=%b, csr_write=%b, csr_op=%b, csr_imm_sel=%b, exception=%b, exception_cause=%b, mret_exec=%b", 
                    exp_reg_write, exp_result_sel, exp_mem_write, exp_mem_read, exp_alu_src, exp_pc_src_auipc, exp_imm_sel, exp_branch, exp_jump, exp_alu_op, exp_mem_size, exp_csr_write, exp_csr_op, exp_csr_imm_sel, exp_exception, exp_exception_cause, exp_mret_exec);
                $display("  Actual  : reg_write=%b, result_sel=%b, mem_write=%b, mem_read=%b, alu_src=%b, pc_src_auipc=%b, imm_sel=%b, branch=%b, jump=%b, alu_op=%b, mem_size=%b, csr_write=%b, csr_op=%b, csr_imm_sel=%b, exception=%b, exception_cause=%b, mret_exec=%b", 
                    reg_write, result_sel, mem_write, mem_read, alu_src, pc_src_auipc, imm_sel, branch, jump, alu_op, mem_size, csr_write, csr_op, csr_imm_sel, exception, exception_cause, mret_exec);
                tests_failed = tests_failed + 1;
            end else begin
                $display("PASS: %s", name);
                tests_passed = tests_passed + 1;
            end
        end
    endtask

    initial begin
        $display("Starting Control Unit Tests...");
        
        // Base RV32I Instructions
        // ADD: opcode=0110011, funct3=000, funct7=0000000
        check("ADD", 7'b0110011, 3'b000, 7'b0000000, 5'd1, 5'd2, 5'd3,
              1'b1, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0, 1'b0, 4'b0000, 3'b000, 1'b0, 2'b00, 1'b0, 1'b0, 4'b0000, 1'b0);
              
        // ADDI: opcode=0010011, funct3=000, funct7=0000000
        check("ADDI", 7'b0010011, 3'b000, 7'b0000000, 5'd1, 5'd2, 5'd3,
              1'b1, 2'b00, 1'b0, 1'b0, 1'b1, 1'b0, 3'b000, 1'b0, 1'b0, 4'b0000, 3'b000, 1'b0, 2'b00, 1'b0, 1'b0, 4'b0000, 1'b0);

        // LW: opcode=0000011, funct3=010, funct7=0000000
        check("LW", 7'b0000011, 3'b010, 7'b0000000, 5'd1, 5'd2, 5'd3,
              1'b1, 2'b01, 1'b0, 1'b1, 1'b1, 1'b0, 3'b000, 1'b0, 1'b0, 4'b0000, 3'b010, 1'b0, 2'b00, 1'b0, 1'b0, 4'b0000, 1'b0);

        // SW: opcode=0100011, funct3=010, funct7=0000000
        check("SW", 7'b0100011, 3'b010, 7'b0000000, 5'd1, 5'd2, 5'd3,
              1'b0, 2'b00, 1'b1, 1'b0, 1'b1, 1'b0, 3'b001, 1'b0, 1'b0, 4'b0000, 3'b010, 1'b0, 2'b00, 1'b0, 1'b0, 4'b0000, 1'b0);

        // BEQ: opcode=1100011, funct3=000, funct7=0000000
        check("BEQ", 7'b1100011, 3'b000, 7'b0000000, 5'd1, 5'd2, 5'd3,
              1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 3'b010, 1'b1, 1'b0, 4'b0001, 3'b000, 1'b0, 2'b00, 1'b0, 1'b0, 4'b0000, 1'b0);

        // JAL: opcode=1101111, funct3=000, funct7=0000000
        check("JAL", 7'b1101111, 3'b000, 7'b0000000, 5'd1, 5'd2, 5'd3,
              1'b1, 2'b10, 1'b0, 1'b0, 1'b0, 1'b0, 3'b100, 1'b0, 1'b1, 4'b0000, 3'b000, 1'b0, 2'b00, 1'b0, 1'b0, 4'b0000, 1'b0);

        // JALR: opcode=1100111, funct3=000, funct7=0000000
        check("JALR", 7'b1100111, 3'b000, 7'b0000000, 5'd1, 5'd2, 5'd3,
              1'b1, 2'b10, 1'b0, 1'b0, 1'b1, 1'b0, 3'b000, 1'b0, 1'b1, 4'b0000, 3'b000, 1'b0, 2'b00, 1'b0, 1'b0, 4'b0000, 1'b0);

        // LUI: opcode=0110111, funct3=000, funct7=0000000
        check("LUI", 7'b0110111, 3'b000, 7'b0000000, 5'd1, 5'd2, 5'd3,
              1'b1, 2'b00, 1'b0, 1'b0, 1'b1, 1'b0, 3'b011, 1'b0, 1'b0, 4'b1010, 3'b000, 1'b0, 2'b00, 1'b0, 1'b0, 4'b0000, 1'b0);

        // AUIPC: opcode=0010111, funct3=000, funct7=0000000
        check("AUIPC", 7'b0010111, 3'b000, 7'b0000000, 5'd1, 5'd2, 5'd3,
              1'b1, 2'b00, 1'b0, 1'b0, 1'b1, 1'b1, 3'b011, 1'b0, 1'b0, 4'b0000, 3'b000, 1'b0, 2'b00, 1'b0, 1'b0, 4'b0000, 1'b0);

        // Privileged Instructions
        // ECALL: opcode=1110011, funct3=000, funct7=0000000, rs2=00000
        check("ECALL", 7'b1110011, 3'b000, 7'b0000000, 5'd0, 5'b00000, 5'd0,
              1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0, 1'b0, 4'b0000, 3'b000, 1'b0, 2'b00, 1'b0, 1'b1, 4'd11, 1'b0);

        // EBREAK: opcode=1110011, funct3=000, funct7=0000000, rs2=00001
        check("EBREAK", 7'b1110011, 3'b000, 7'b0000000, 5'd0, 5'b00001, 5'd0,
              1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0, 1'b0, 4'b0000, 3'b000, 1'b0, 2'b00, 1'b0, 1'b1, 4'd3, 1'b0);

        // MRET: opcode=1110011, funct3=000, funct7=0011000, rs2=00010
        check("MRET", 7'b1110011, 3'b000, 7'b0011000, 5'd0, 5'b00010, 5'd0,
              1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0, 1'b0, 4'b0000, 3'b000, 1'b0, 2'b00, 1'b0, 1'b0, 4'b0000, 1'b1);

        // CSRRW: opcode=1110011, funct3=001
        check("CSRRW", 7'b1110011, 3'b001, 7'b0000000, 5'd1, 5'd0, 5'd2,
              1'b1, 2'b11, 1'b0, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0, 1'b0, 4'b0000, 3'b000, 1'b1, 2'b01, 1'b0, 1'b0, 4'b0000, 1'b0);

        // CSRRS: opcode=1110011, funct3=010, rs1!=0
        check("CSRRS", 7'b1110011, 3'b010, 7'b0000000, 5'd1, 5'd0, 5'd2,
              1'b1, 2'b11, 1'b0, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0, 1'b0, 4'b0000, 3'b000, 1'b1, 2'b10, 1'b0, 1'b0, 4'b0000, 1'b0);

        // CSRRS: opcode=1110011, funct3=010, rs1==0
        check("CSRRS_RO", 7'b1110011, 3'b010, 7'b0000000, 5'd0, 5'd0, 5'd2,
              1'b1, 2'b11, 1'b0, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0, 1'b0, 4'b0000, 3'b000, 1'b0, 2'b10, 1'b0, 1'b0, 4'b0000, 1'b0);

        // CSRRC: opcode=1110011, funct3=011, rs1!=0
        check("CSRRC", 7'b1110011, 3'b011, 7'b0000000, 5'd1, 5'd0, 5'd2,
              1'b1, 2'b11, 1'b0, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0, 1'b0, 4'b0000, 3'b000, 1'b1, 2'b11, 1'b0, 1'b0, 4'b0000, 1'b0);

        // CSRRWI: opcode=1110011, funct3=101
        check("CSRRWI", 7'b1110011, 3'b101, 7'b0000000, 5'd1, 5'd0, 5'd2,
              1'b1, 2'b11, 1'b0, 1'b0, 1'b0, 1'b0, 3'b101, 1'b0, 1'b0, 4'b0000, 3'b000, 1'b1, 2'b01, 1'b1, 1'b0, 4'b0000, 1'b0);

        // CSRRSI: opcode=1110011, funct3=110, rs1!=0
        check("CSRRSI", 7'b1110011, 3'b110, 7'b0000000, 5'd1, 5'd0, 5'd2,
              1'b1, 2'b11, 1'b0, 1'b0, 1'b0, 1'b0, 3'b101, 1'b0, 1'b0, 4'b0000, 3'b000, 1'b1, 2'b10, 1'b1, 1'b0, 4'b0000, 1'b0);

        // CSRRCI: opcode=1110011, funct3=111, rs1!=0
        check("CSRRCI", 7'b1110011, 3'b111, 7'b0000000, 5'd1, 5'd0, 5'd2,
              1'b1, 2'b11, 1'b0, 1'b0, 1'b0, 1'b0, 3'b101, 1'b0, 1'b0, 4'b0000, 3'b000, 1'b1, 2'b11, 1'b1, 1'b0, 4'b0000, 1'b0);

        $display("---------------------------------------------------------");
        $display("Test Summary: %0d Passed, %0d Failed", tests_passed, tests_failed);
        $display("---------------------------------------------------------");
        if (tests_failed == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("SOME TESTS FAILED");
        end
        $finish;
    end

endmodule
