    .global _start
    .text
    .section .text

_start:
    # Set up stack pointer
    la   sp, _stack_top

    # Jump to Rust entry point
    jal  ra, _start_rust

hang:
    j hang

    .bss
_stack_top:
    .skip 4096  # 4 KB stack
