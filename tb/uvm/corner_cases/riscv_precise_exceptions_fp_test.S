.section .text
.globl _start
_start:
    li t0, 0x00006000
    csrs mstatus, t0
    li t0, 1
    csrw 0x7C0, t0
    la t0, trap_handler
    csrw mtvec, t0
    fcvt.d.w f2, x0
    fcvt.d.w f4, x0
    fdiv.d f0, f2, f4
    ecall
fail:
    li t0, 3
    la t1, tohost
    sw t0, 0(t1)
    j loop
trap_handler:
pass:
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
