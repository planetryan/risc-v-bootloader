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

# kernel directory, might or might not change
kernel_image_addr:
    .incbin "/mnt/c/Users/vboxuser/Documents/risc-v/kernel/vmlinux"
