.section .text
.globl _start
_start:
    li t0, 0x00006000
    csrs mstatus, t0
    li t0, 1
    csrw 0x7C0, t0
    la t0, float_data
    flw f0, 0(t0)
    fadd.d f2, f0, f0
    li t0, 1
    la t1, tohost
    sw t0, 0(t1)
loop:
    j loop

.section .data
.align 6
float_data: .word 0x3f800000
.align 6
.globl tohost
tohost: .dword 0
.globl fromhost
fromhost: .dword 0
