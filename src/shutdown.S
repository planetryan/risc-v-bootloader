    # shutdown function for QEMU Spefically, im not sure if it works with real hardware

    .section .text
    .globl _start_rust
    .align 4

_start_rust:
    li t0, 5               # Will be expanded manually below

    # li t0, 5
    lui t0, 0
    addi t0, t0, 5

loop_outer:
    # Inner loop counter t1 = 50_000_000
    lui t1, 1220           # 1220 << 12 = 0x4A00000
    addi t1, t1, 0         # 0x4A00000 is 50_331_648 (approx 50M)

loop_inner:
    addi t1, t1, -1
    bne t1, x0, loop_inner

    addi t0, t0, -1
    bne t0, x0, loop_outer

    # Power off: store 0x5555 to 0x100000
    lui t2, 0x1            # t2 = 0x100000
    addi t2, t2, 0

    lui t3, 0              # t3 = 0x5555
    addi t3, t3, 0x55
    slli t3, t3, 8
    addi t3, t3, 0x55

    sw t3, 0(t2)

hang:
    jal x0, hang
