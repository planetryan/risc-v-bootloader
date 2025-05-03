.global rust_main  # Make sure rust_main is visible to the linker
.global _start
.text
.section .text

_start:
  la   sp, _stack_top
  jal  ra, rust_main  # EXACT CASE MATCH HERE

hang:
  j hang

.bss
_stack_top:
  .skip 4096