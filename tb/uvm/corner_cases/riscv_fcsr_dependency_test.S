.section .text
.globl _start
_start:
    li t0, 0x00006000
    csrs mstatus, t0
    li t0, 1
    csrw 0x7C0, t0
    li t0, 0
    fscsr t0
    li t1, 1
    beq t1, x0, speculate
    li t0, 1
    la t1, tohost
    sw t0, 0(t1)
loop:
    j loop
speculate:
    frcsr t2
    li t0, 3
    la t1, tohost
    sw t0, 0(t1)
    j loop

.section .data
.align 6
.globl tohost
tohost: .dword 0
.globl fromhost
fromhost: .dword 0
