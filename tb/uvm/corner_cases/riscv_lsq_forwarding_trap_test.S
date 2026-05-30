.globl _start
_start:
    la t0, trap_handler
    csrw mtvec, t0
    li t0, 0x6000
    csrs mstatus, t0
    li t0, 1
    csrw 0x7C0, t0
    la t1, test_data
    li t2, 0x12345678
    sw t2, 0(t1)
    lw t3, 0(t1)
    ebreak
    j fail
trap_handler:
    csrr t0, mcause
    li t1, 3
    beq t0, t1, pass
    j fail
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
test_data: .word 0
