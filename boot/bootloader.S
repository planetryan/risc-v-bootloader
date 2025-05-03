.include "constants.inc"

.section .text.entry, "ax", @progbits
.global _start UART_BASE

_start:
    csrw mie, zero
    la sp, stack_top
    la a0, heap_start
    la a1, heap_end
    sub a1, a1, a0
    addi a2, a0, 0

    # UART_BASE is a 32-bit address; use LUI/ADDI to load it
    lui a3, %hi(UART_BASE)
    addi a3, a3, %lo(UART_BASE)
    jal uart_init
    la a0, boot_msg
    jal print_string

    lui t0, %hi(FRAMEBUFFER_ADDRESS)
    addi t0, t0, %lo(FRAMEBUFFER_ADDRESS)
    add gp, t0, zero

    li s0, 160   # cam x
    li s1, 100   # cam y
    li s2, 400   # cam z
    li s3, 0     # yaw
    li s4, 0     # pitch
    li s5, 0     # 0=cube, 1=tetra, 2=octa


main_loop:
    li a0, 0
    jal clear_screen

    addi a0, s0, 0
    addi a1, s1, 0
    addi a2, s2, 0
    addi a3, s3, 0
    addi a4, s4, 0
    addi a5, s5, 0
    jal draw_scene

    jal poll_keys

    li t6, DELAY_COUNT
delay_loop:
    addi t6, t6, -1
    bnez t6, delay_loop

    j main_loop

# Software signed multiply: a0 * a1 => a0 (result destroyed)
# Uses t0-t3 as temporaries
mul_signed:
    addi sp, sp, -32
    sd s0, 0(sp)
    sd s1, 8(sp)
    sd t0, 16(sp)
    sd t1, 24(sp)
    add t0, zero, zero   # result = 0
    add t1, zero, zero   # counter = 0
    add s0, a0, zero     # s0 = multiplicand
    add s1, a1, zero     # s1 = multiplier
    bltz s1, mul_signed_neg
    j mul_signed_loop
mul_signed_neg:
    sub s1, zero, s1
    sub s0, zero, s0
mul_signed_loop:
    beqz s1, mul_signed_end
    add t0, t0, s0
    addi s1, s1, -1
    j mul_signed_loop
mul_signed_end:
    add a0, t0, zero
    ld s0, 0(sp)
    ld s1, 8(sp)
    ld t0, 16(sp)
    ld t1, 24(sp)
    addi sp, sp, 32
    ret

# Software signed division by positive divisor: a0 / a1 => a0
# Remainder in a1, uses t0-t3 as temporaries
div_signed:
    addi sp, sp, -32
    sd s0, 0(sp)
    sd s1, 8(sp)
    sd t0, 16(sp)
    sd t1, 24(sp)
    add s0, a0, zero    # dividend
    add s1, a1, zero    # divisor
    add t0, zero, zero  # quotient
    bltz s0, div_signed_neg_dividend
    j div_signed_loop
div_signed_neg_dividend:
    sub s0, zero, s0
    call div_signed_loop
    sub t0, zero, t0
    j div_signed_end
div_signed_loop:
    blt s0, s1, div_signed_finish
    sub s0, s0, s1
    addi t0, t0, 1
    j div_signed_loop
div_signed_finish:
    ret
div_signed_end:
    add a0, t0, zero
    add a1, s0, zero
    ld s0, 0(sp)
    ld s1, 8(sp)
    ld t0, 16(sp)
    ld t1, 24(sp)
    addi sp, sp, 32
    ret

# Fixed-point shift right by 10 (divide by 1024)
shift_right_10:
    li t1, 1024
    add a1, t1, zero
    call div_signed
    ret

draw_scene:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    sd s1, 40(sp)
    sd s2, 32(sp)
    sd s3, 24(sp)
    sd s4, 16(sp)
    sd s5, 8(sp)
    sd s6, 0(sp)

    add s0, a0, zero
    add s1, a1, zero
    add s2, a2, zero
    add s3, a3, zero
    add s4, a4, zero
    add s5, a5, zero

    li t0, 0
    beq s5, t0, draw_cube_shape
    li t0, 1
    beq s5, t0, draw_tetra_shape
    li t0, 2
    beq s5, t0, draw_octa_shape
    j draw_done

draw_cube_shape:
    la a0, cube_vertices
    la a1, cube_edges
    li a2, 8
    li a3, 12
    j draw_shape

draw_tetra_shape:
    la a0, tetra_vertices
    la a1, tetra_edges
    li a2, 4
    li a3, 6
    j draw_shape

draw_octa_shape:
    la a0, octa_vertices
    la a1, octa_edges
    li a2, 6
    li a3, 12
    j draw_shape

draw_shape:
    la t0, projected_vertices
    add t1, a2, zero
project_loop:
    lw t2, 0(a0)      # x
    lw t3, 4(a0)      # y
    lw t4, 8(a0)      # z
    sub t2, t2, s0    # x -= cam_x
    sub t3, t3, s1    # y -= cam_y
    sub t4, t4, s2    # z -= cam_z

    # Yaw rotation
    add a5, s3, zero
    call cos_deg
    add t5, a0, zero       # t5 = cos(yaw)
    add a5, s3, zero
    call sin_deg
    add t6, a0, zero       # t6 = sin(yaw)

    add a0, t2, zero
    add a1, t5, zero
    call mul_signed
    add t3, a0, zero       # t3 = x * cos(yaw)
    add a0, t4, zero
    add a1, t6, zero
    call mul_signed
    add t4, a0, zero       # t4 = z * sin(yaw)
    sub t0, t3, t4         # t0 = x*cos - z*sin
    add a0, t0, zero
    call shift_right_10
    add t1, a0, zero       # t1 = (x*cos-z*sin)>>10

    add a0, t2, zero
    add a1, t6, zero
    call mul_signed
    add t3, a0, zero       # t3 = x * sin(yaw)
    add a0, t4, zero
    add a1, t5, zero
    call mul_signed
    add t4, a0, zero       # t4 = z * cos(yaw)
    add t0, t3, t4         # t0 = x*sin + z*cos
    add a0, t0, zero
    call shift_right_10
    add t2, a0, zero       # t2 = (x*sin+z*cos)>>10

    # Pitch rotation
    add a5, s4, zero
    call cos_deg
    add t5, a0, zero       # t5 = cos(pitch)
    add a5, s4, zero
    call sin_deg
    add t6, a0, zero       # t6 = sin(pitch)

    add a0, t3, zero
    add a1, t5, zero
    call mul_signed
    add t4, a0, zero       # t4 = y * cos(pitch)
    add a0, t2, zero
    add a1, t6, zero
    call mul_signed
    add t5, a0, zero       # t5 = z * sin(pitch)
    sub t0, t4, t5         # t0 = y*cos - z*sin
    add a0, t0, zero
    call shift_right_10
    add t1, a0, zero       # t1 = (y*cos-z*sin)>>10

    add a0, t3, zero
    add a1, t6, zero
    call mul_signed
    add t4, a0, zero       # t4 = y * sin(pitch)
    add a0, t2, zero
    add a1, t5, zero
    call mul_signed
    add t5, a0, zero       # t5 = z * cos(pitch)
    add t0, t4, t5         # t0 = y*sin + z*cos
    add a0, t0, zero
    call shift_right_10
    add t2, a0, zero       # t2 = (y*sin+z*cos)>>10

    # Project vertex
    add a0, t1, zero
    add a1, t2, zero
    add a2, t5, zero
    call project_vertex
    sw a0, 0(t0)
    sw a1, 4(t0)
    addi t0, t0, 8
    addi a0, a0, 12
    addi t1, t1, -1
    bnez t1, project_loop

    # Draw edges
    add t1, a3, zero
    la t0, projected_vertices
    add t2, a1, zero
edge_loop:
    lw t3, 0(t2)
    lw t4, 4(t2)
    slli t5, t3, 3
    add t6, t0, t5
    lw a0, 0(t6)
    lw a1, 4(t6)
    slli t5, t4, 3
    add t6, t0, t5
    lw a2, 0(t6)
    lw a3, 4(t6)
    call draw_line
    addi t2, t2, 8
    addi t1, t1, -1
    bnez t1, edge_loop

draw_done:
    ld ra, 56(sp)
    ld s0, 48(sp)
    ld s1, 40(sp)
    ld s2, 32(sp)
    ld s3, 24(sp)
    ld s4, 16(sp)
    ld s5, 8(sp)
    ld s6, 0(sp)
    addi sp, sp, 64
    ret

poll_keys:
    # Use LUI/ADDI to load UART_BASE
    lui t0, %hi(UART_BASE)
    addi t0, t0, %lo(UART_BASE)
    lw t1, UART_LSR(t0)
    andi t1, t1, 0x01
    beqz t1, poll_done
    lb t2, UART_RX(t0)
    li t3, 'w'
    beq t2, t3, move_forward
    li t3, 's'
    beq t2, t3, move_backward
    li t3, 'a'
    beq t2, t3, move_left
    li t3, 'd'
    beq t2, t3, move_right
    li t3, 'q'
    beq t2, t3, yaw_left
    li t3, 'e'
    beq t2, t3, yaw_right
    li t3, 'r'
    beq t2, t3, shape_prev
    li t3, 'f'
    beq t2, t3, shape_next
    j poll_done
move_forward:
    addi s2, s2, -CAMERA_STEP
    j poll_done
move_backward:
    addi s2, s2, CAMERA_STEP
    j poll_done
move_left:
    addi s0, s0, -CAMERA_STEP
    j poll_done
move_right:
    addi s0, s0, CAMERA_STEP
    j poll_done
yaw_left:
    addi s3, s3, -CAMERA_ROT_STEP
    j poll_done
yaw_right:
    addi s3, s3, CAMERA_ROT_STEP
    j poll_done
shape_prev:
    addi s5, s5, -1
    bltz s5, shape_prev_wrap
    j poll_done
shape_prev_wrap:
    li s5, 2
    j poll_done
shape_next:
    addi s5, s5, 1
    li t3, 2
    bgt s5, t3, shape_next_wrap
    j poll_done
shape_next_wrap:
    li s5, 0
poll_done:
    ret

project_vertex:
    li t0, PERSPECTIVE_FACTOR
    addi t1, a2, 1
    add a0, t0, zero
    add a1, t1, zero
    call div_signed
    add t2, a0, zero
    add a0, a0, zero
    add a1, t2, zero
    call mul_signed
    add a0, a0, zero
    add a1, t2, zero
    call mul_signed
    li t3, SCREEN_WIDTH
    srli t3, t3, 1
    add a0, a0, t3
    li t4, SCREEN_HEIGHT
    srli t4, t4, 1
    add a1, a1, t4
    ret

draw_line:
    call draw_pixel
    add a0, a2, zero
    add a1, a3, zero
    call draw_pixel
    ret

draw_pixel:
    blt a0, zero, pixel_out
    blt a1, zero, pixel_out
    li t0, SCREEN_WIDTH
    bge a0, t0, pixel_out
    li t0, SCREEN_HEIGHT
    bge a1, t0, pixel_out
    li t1, SCREEN_WIDTH
    add t2, a1, zero
    add t3, a0, zero
    call mul_signed
    add t0, t0, t3
    lui t1, %hi(FRAMEBUFFER_ADDRESS)
    addi t1, t1, %lo(FRAMEBUFFER_ADDRESS)
    add t0, t0, t1
    li t1, 0xF
    sb t1, 0(t0)
pixel_out:
    ret

clear_screen:
    li t0, 0
    li t1, 0
clear_loop:
    sb a0, 0(gp)
    addi gp, gp, 1
    addi t1, t1, 1
    li t2, SCREEN_SIZE
    blt t1, t2, clear_loop
    ret

uart_init:
    addi sp, sp, -8
    sd ra, 0(sp)
    li t0, UART_BAUD_DIVISOR
    sw t0, UART_DIV(a3)
    li t0, UART_LCR_8N1
    sw t0, UART_LCR(a3)
    ld ra, 0(sp)
    addi sp, sp, 8
    ret

print_string:
    addi sp, sp, -8
    sd ra, 0(sp)
print_loop:
    lb a1, 0(a0)
    beqz a1, print_done
    addi a2, a3, 0
    call transmit_byte
    addi a0, a0, 1
    j print_loop
print_done:
    ld ra, 0(sp)
    addi sp, sp, 8
    ret

transmit_byte:
transmit_wait:
    lw t0, UART_LSR(a2)
    andi t0, t0, LSR_TX_EMPTY
    beqz t0, transmit_wait
    sb a1, UART_TX(a2)
    ret

sin_deg:
    add a0, a5, zero
    li t6, 360
    blt a0, zero, sin_neg
    j sin_mod
sin_neg:
    add a0, a0, t6
    j sin_mod
sin_mod:
    blt a0, t6, sin_mod_end
    sub a0, a0, t6
    j sin_mod
sin_mod_end:
    li t0, 0
    beq a0, t0, sin_0
    li t0, 90
    beq a0, t0, sin_90
    li t0, 180
    beq a0, t0, sin_180
    li t0, 270
    beq a0, t0, sin_270
    li a0, 724
    ret
sin_0:
    li a0, 0
    ret
sin_90:
    li a0, 1024
    ret
sin_180:
    li a0, 0
    ret
sin_270:
    li a0, -1024
    ret

cos_deg:
    addi a5, a5, 90
    call sin_deg
    ret

.section .rodata
boot_msg:        .string "Bare-Metal 3D Shapes\n"

cube_vertices:
    .word -50, -50, -50
    .word  50, -50, -50
    .word  50,  50, -50
    .word -50,  50, -50
    .word -50, -50,  50
    .word  50, -50,  50
    .word  50,  50,  50
    .word -50,  50,  50
cube_edges:
    .word 0,1
    .word 1,2
    .word 2,3
    .word 3,0
    .word 4,5
    .word 5,6
    .word 6,7
    .word 7,4
    .word 0,4
    .word 1,5
    .word 2,6
    .word 3,7

tetra_vertices:
    .word 0,0,60
    .word 0,57,-20
    .word -49,-28,-20
    .word 49,-28,-20
tetra_edges:
    .word 0,1
    .word 0,2
    .word 0,3
    .word 1,2
    .word 1,3
    .word 2,3

octa_vertices:
    .word 0,0,60
    .word 0,57,0
    .word -49,-28,0
    .word 49,-28,0
    .word 0,0,-60
    .word 0,-57,0
octa_edges:
    .word 0,1
    .word 0,2
    .word 0,3
    .word 0,5
    .word 1,2
    .word 1,3
    .word 1,4
    .word 2,3
    .word 2,4
    .word 2,5
    .word 3,4
    .word 3,5
    .word 4,5

.section .bss
.global stack_bottom
stack_bottom:
    .space STACK_SIZE
.global stack_top
stack_top:

.global heap_start
heap_start:
    .space HEAP_SIZE
.global heap_end
heap_end:

projected_vertices:
    .space SHAPE_MAX_VERTICES*8
