.global _start
_start:
    li x1, 0x6000
    csrs mstatus, x1
    la x11, float_var
    flw f0, 0(x11)
    flw f1, 4(x11)
    flw f2, 8(x11)
    fadd.s f3, f0, f1
    fmadd.s f4, f0, f1, f2
    li x1, 3
    fsrm x0, x1
    li x2, -5
    fcvt.s.w f5, x2
    fsw f5, 12(x11)
    la x12, double_var
    fld f6, 0(x12)
    fld f7, 8(x12)
    fadd.d f8, f6, f7
    fsd f8, 16(x12)
    fdiv.s f9, f0, f2
end:
    j end

.text
.align 4
float_var:
    .word 0x3f800000, 0x40000000, 0x00000000, 0x00000000
.align 8
double_var:
    .word 0x00000000, 0x3ff00000, 0x00000000, 0x40000000, 0x00000000, 0x00000000
