.globl _start
_start:
    la t0, trap_handler
    csrw mtvec, t0
    li t0, 0x6000
    csrs mstatus, t0
    li t0, 1
    csrw 0x7C0, t0
    li t0, 0x8
    csrs mstatus, t0
    li t0, 0x800
    csrs mie, t0
    la t1, test_data
    fld ft0, 0(t1)
    fdiv.d ft1, ft0, ft0
    fdiv.d ft2, ft1, ft0
    li t2, 100
loop:
    addi t2, t2, -1
    bnez t2, loop
    j pass
trap_handler:
    csrr t0, mcause
    bltz t0, is_interrupt
    j fail
is_interrupt:
    mret
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
test_data: .dword 0x3FF0000000000000
