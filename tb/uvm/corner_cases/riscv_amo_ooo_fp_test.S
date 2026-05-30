.globl _start
_start:
    li t0, 0x6000
    csrs mstatus, t0
    li t0, 1
    csrw 0x7C0, t0
    la t1, test_data
    la t2, amo_data
    fld ft0, 0(t1)
    fadd.d ft1, ft0, ft0
    fsd ft1, 8(t1)
    li t3, 1
    amoadd.w t4, t3, 0(t2)
    j pass
pass:
    li t0, 1
    la t1, tohost
    sw t0, 0(t1)
1:  j 1b
fail:
    li t0, 3
    la t1, tohost
    sw t0, 0(t1)
1:  j 1b
.section .data
.align 6
tohost: .dword 0
fromhost: .dword 0
test_data: .dword 0x3FF0000000000000, 0
amo_data: .word 0
