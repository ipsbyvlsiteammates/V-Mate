.section .text
.globl _start
_start:
    li t0, 0x00006000
    csrs mstatus, t0
    li t0, 1
    csrw 0x7C0, t0
    addi t1, x0, 10
    addi t2, x0, 20
    add t3, t1, t2
    li t0, 0
    csrw 0x7C0, t0
    addi t1, x0, 30
    addi t2, x0, 40
    add t3, t1, t2
    li t0, 1
    la t1, tohost
    sw t0, 0(t1)
loop:
    j loop

.section .data
.align 6
.globl tohost
tohost: .dword 0
.globl fromhost
fromhost: .dword 0
