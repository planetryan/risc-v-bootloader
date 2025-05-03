.section .srodata
.global __global_pointer$
__global_pointer$:
    .word 0

.global _start

_start:
    la gp, __global_pointer$
    la sp, stack_top

    call main  # Call main, not rust_start

    # If main returns (it shouldn't), halt the system
    halt:
        j halt

.section .bss
.align 12
stack_bottom:
    .space 4096 * 4 # 16KB stack
stack_top: