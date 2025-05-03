.section .text._start
.global _start
.type _start, @function

_start:
    la sp, _stack_top
    addi sp, sp, -0x1000  # Reserve 4 KiB

    csrw mstatus, zero   # Disable interrupts
    csrw mie, zero
    csrw mtvec, zero

    call rust_start

1:  j 1b
