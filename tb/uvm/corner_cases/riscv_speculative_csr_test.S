.globl _start
_start:
    la t0, trap_handler
    csrw mtvec, t0
    li t0, 0x6000
    csrs mstatus, t0
    li t0, 1
    csrw 0x7C0, t0
    li t1, 1
    li t2, 0
    beq t1, t2, mispredict_path
    j pass
mispredict_path:
    csrw mscratch, t1
    j fail
trap_handler:
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
