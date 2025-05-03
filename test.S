.global _start
.global rust_main

.text
.section .text

_start:
  call rust_main
  j _start