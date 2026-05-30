.section .text
.globl _start
_start:
    li t0, 0x00006000
    csrs mstatus, t0
    li t0, 1
    csrw 0x7C0, t0
    la t0, trap_handler
    csrw mtvec, t0
    ecall
    li t0, 1
    la t1, tohost
    sw t0, 0(t1)
loop:
    j loop
trap_handler:
    csrr t0, mepc
    addi t0, t0, 4
    csrw mepc, t0
    mret

.section .data
.align 6
.globl tohost
tohost: .dword 0
.globl fromhost
fromhost: .dword 0
