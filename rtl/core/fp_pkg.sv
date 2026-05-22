`timescale 1ns/1ps
package fp_pkg;
    typedef enum logic [2:0] {
        RNE = 3'b000,
        RTZ = 3'b001,
        RDN = 3'b010,
        RUP = 3'b011,
        RMM = 3'b100
    } roundmode_e;

    localparam logic [10:0] FP64_EXP_BIAS = 11'd1023;
    localparam logic [7:0]  FP32_EXP_BIAS = 8'd127;

    typedef struct packed {
        logic        sign;
        logic signed [12:0] exp;
        logic [55:0] sig;
        logic        is_zero;
        logic        is_inf;
        logic        is_nan;
        logic        is_snan;
        logic        is_qnan;
        logic        is_subnormal;
    } fp_unpacked_t;
endpackage