
        .global _start
        _start:
            li x1, 10
            li x2, 3
            mul x3, x1, x2
            div x4, x1, x2
            rem x5, x1, x2
            
            la x6, atomic_var
            lr.w x7, (x6)
            li x8, 1
            sc.w x9, x8, (x6)
            amoadd.w x10, x8, (x6)
            
            la x11, float_var
            flw f0, 0(x11)
            fadd.s f1, f0, f0
            fsw f1, 4(x11)
            
            la x12, double_var
            fld f2, 0(x12)
            fadd.d f3, f2, f2
            fsd f3, 8(x12)
            
            j _start

        .data
        .align 4
        atomic_var: .word 0
        float_var: .word 0x3f800000, 0
        .align 8
        double_var: .word 0x00000000, 0x3ff00000, 0, 0
        