`timescale 1ns/1ps
module tb_fpu_debug;
    import fp_pkg::*;

    logic [63:0] rs1_raw = 64'h0000000000800000;
    logic [63:0] rs2_raw = 64'h00000000a3a7488e;
    logic [63:0] rs3_raw = 64'h0000000000800000;
    
    fp_unpacked_t rs1_unpacked, rs2_unpacked, rs3_unpacked;
    
    fp_unpack u_unpack1 (.in(rs1_raw), .fmt(2'b00), .out(rs1_unpacked));
    fp_unpack u_unpack2 (.in(rs2_raw), .fmt(2'b00), .out(rs2_unpacked));
    fp_unpack u_unpack3 (.in(rs3_raw), .fmt(2'b00), .out(rs3_unpacked));
    
    logic [63:0] out;
    logic [4:0] fflags;
    
    fp_fma u_fma (
        .rs1_unpacked(rs1_unpacked),
        .rs2_unpacked(rs2_unpacked),
        .rs3_unpacked(rs3_unpacked),
        .fmt(2'b00),
        .rm(RNE),
        .op(3'b000),
        .out(out),
        .fflags(fflags)
    );
    
    initial begin
        #10;
        $display("rs1: %h", rs1_raw);
        $display("rs2: %h", rs2_raw);
        $display("rs3: %h", rs3_raw);
        $display("out: %h", out);
        $display("fflags: %b", fflags);
        $finish;
    end
endmodule
