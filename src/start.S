    .global _start
    .text
    .section .text

_start:

    la   sp, _stack_top

    jal  ra, _start_rust

hang:
    j hang

    .bss
_stack_top:
    .skip 4096 
