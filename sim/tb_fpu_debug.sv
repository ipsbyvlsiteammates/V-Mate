`timescale 1ns/1ps
module tb_fpu_debug;
    reg [4:0] fp_alu_op;
    reg [1:0] fmt;
    reg [2:0] rm;
    reg [2:0] fcsr_rm;
    reg [63:0] rs1_data;
    reg [63:0] rs2_data;
    reg [63:0] rs3_data;
    reg [31:0] int_rs1_data;
    reg int_to_fp;
    reg fp_to_int;
    reg [4:0] rs2_addr;
    
    wire [63:0] result;
    wire [4:0] fflags;
    
    fp_alu #(
        .EXTENSION_F(1),
        .EXTENSION_D(1)
    ) dut (
        .fp_alu_op(fp_alu_op),
        .fmt(fmt),
        .rm(rm),
        .fcsr_rm(fcsr_rm),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .rs3_data(rs3_data),
        .int_rs1_data(int_rs1_data),
        .int_to_fp(int_to_fp),
        .fp_to_int(fp_to_int),
        .rs2_addr(rs2_addr),
        .result(result),
        .fflags(fflags)
    );
    
    initial begin
        fp_alu_op = 0; // FADD
        fmt = 0; // FP32
        rm = 3; // RDN
        fcsr_rm = 3;
        rs1_data = 64'hffffffff4dcb5323;
        rs2_data = 64'hffffffff5dc732fa;
        rs3_data = 64'hffffffff4dcb5323;
        int_rs1_data = 0;
        int_to_fp = 0;
        fp_to_int = 0;
        rs2_addr = 0;
        
        #10;
        $display("rs1_unpacked: sign=%b exp=%d sig=%h", dut.rs1_unpacked.sign, dut.rs1_unpacked.exp, dut.rs1_unpacked.sig);
        $display("rs2_unpacked: sign=%b exp=%d sig=%h", dut.rs2_unpacked.sign, dut.rs2_unpacked.exp, dut.rs2_unpacked.sig);
        $display("eff_rs1: sign=%b exp=%d sig=%h", dut.u_fp_fma.eff_rs1.sign, dut.u_fp_fma.eff_rs1.exp, dut.u_fp_fma.eff_rs1.sig);
        $display("eff_rs2: sign=%b exp=%d sig=%h", dut.u_fp_fma.eff_rs2.sign, dut.u_fp_fma.eff_rs2.exp, dut.u_fp_fma.eff_rs2.sig);
        $display("eff_rs3: sign=%b exp=%d sig=%h", dut.u_fp_fma.eff_rs3.sign, dut.u_fp_fma.eff_rs3.exp, dut.u_fp_fma.eff_rs3.sig);
        $display("P_exp_ext=%d A_exp_ext=%d exp_diff=%d", dut.u_fp_fma.P_exp_ext, dut.u_fp_fma.A_exp_ext, dut.u_fp_fma.exp_diff);
        $display("P_sig_val=%h A_sig_val=%h", dut.u_fp_fma.P_sig_val, dut.u_fp_fma.A_sig_val);
        $display("P_sig_shifted=%h A_sig_shifted=%h", dut.u_fp_fma.P_sig_shifted, dut.u_fp_fma.A_sig_shifted);
        $display("sum_ext=%h res_sign=%b", dut.u_fp_fma.sum_ext, dut.u_fp_fma.res_sign);
        $display("norm_sum=%h lzc=%d", dut.u_fp_fma.norm_sum, dut.u_fp_fma.lzc);
        $display("out_exp=%d out_sig=%h", dut.u_fp_fma.out_exp, dut.u_fp_fma.out_sig);
        $display("final_sign=%b", dut.u_fp_fma.final_sign);
        $display("rp_out=%h rp_fflags=%b", dut.u_fp_fma.rp_out, dut.u_fp_fma.rp_fflags);
        $display("result=%h fflags=%b", result, fflags);
        $finish;
    end
endmodule
