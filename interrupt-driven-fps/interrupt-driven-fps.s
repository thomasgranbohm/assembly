.data
ANIMATION_INFORMATION:
    .word 0x0 @ NUMBER OF FRAMES
    .hword 0x0 @ HEIGHT
    .hword 0x0 @ WIDTH

FRAME_INDEX:
    .byte 0x0 @ FRAME INDEX

.align 0x1

.section .text

.equ SSD_ADDR, 0xFF200020
.equ BIN_ADDR, 0x20000000
.equ FRAME_BUFFER_PRIMARY, 0xC8000000
.equ FRAME_BUFFER_SECONDARY, 0xC0000000
.equ PIXEL_BUFFER_CONTROL, 0xFF203020

.global _start
_start:
    b reset_handler
    b .
    b .
    b .
    b .
    b .
    b irq_handler
    b .

reset_handler:
    @ "Enable" IRQ mode
    mov r0, #0b11010010
    msr cpsr, r0
    @ set stack pointer for IRQ mode
    mov sp, #(0xFFFF - 3) @ minus 3 for alignment
    movt sp, #0xFFFF
    
    @ "Enable" supervisor mode
    mov r0, #0b11010011
    msr cpsr, r0
    @ set stack pointer 
    mov sp, #(0xFFFF - 3) @ minus 3 for alignment
    movt sp, #0xFFFF

    bl config_gic
    

configure_animation:
    ldr r9, =FRAME_BUFFER_SECONDARY
    ldr r10, =PIXEL_BUFFER_CONTROL

    mov r12, #0x4
    str r12, [r10, #0xC]
    str r9, [r10, #0x4]

load_info:
    ldr r0, =BIN_ADDR
    ldr r1, [r0], #0x4 @ number of frames
    ldr r2, [r0], #0x4
	mov r12, #0x1FF
	and r3, r2, r12 @ r3 = width
	lsr r2, #9 @ r2 = height

    ldr r0, =ANIMATION_INFORMATION
    str r1, [r0], #0x4
    strh r2, [r0], #0x2
    strh r3, [r0], #0x2

configure_timer:
    @ Configure timer 
    mov r0, #0xC600
    movt r0, #0xFFFE
    
    @ Set timer load value
    ldr r1, =2222222 @ approx 30 fps given 
    str r1, [r0]
    
    @ Enable timer, interrupt and auto-reload flags
    mov r1, #0b110000000111
    str r1, [r0, #0x8]
    
	@ Clear the IRQ mask, enabling interrupts again
	mrs r0, cpsr
	bic r0, r0, #0x80
	msr cpsr, r0

loop:
    b loop

irq_handler:
    push {r0-r3, lr}
	
    @ Clear GIS interrupt flag
    mov r0, #0xC100
    movt r0, #0xFFFE
    
    @ Load interrupt id
    ldr r1, [r0, #0xC]

    @ Acknowledge interrupt id
    str r1, [r0, #0x10]
    
    @ CHANGE FRAME HERE
    bl change_frame
	
	@ Clear the timer interrupt flag
    mov r0, #0xC600
    movt r0, #0xFFFE
    mov r1, #0x1
    str r1, [r0, #0xC] @ Write 1 to timer interrupt status register
    
    pop {r0-r3, lr}
    subs pc, lr, #4

change_frame:
    push {r4, r5, r6, r7, r10, r11, r12, lr}

    @ Get base read address
    ldr r0, =BIN_ADDR
    add r0, #8

    @ Get write address
    ldr r1, =PIXEL_BUFFER_CONTROL
    ldr r1, [r1, #0x4]

    ldr r12, =FRAME_INDEX
    ldr r12, [r12]

    @ Get height and width
    ldr r4, =ANIMATION_INFORMATION
    ldr r2, [r4], #0x4      @ r2 = Number of frames
    ldrh r3, [r4], #0x2     @ r3 = Height
    ldrh r4, [r4]           @ r4 = Width
	
    @ Calculate read offset by frame index
    @ offset = frame_index * (2 * height * width)
    @ times two because each pixel is two bytes
	mul r11, r3, r4
	lsl r11, #1
	mul r11, r12
	add r0, r11

    mov r5, #0 @ y index

step_y:
    mov r6, #0 @ x index

step_x:
    @ Load pixel pair
    ldr r7, [r0], #4

    @ Calculate write address offset
    lsl r10, r5, #0xA @ y offset
    lsl r11, r6, #0x1 @ x offset
    add r11, r10

    @ Write pixel pair to frame buffer
    str r7, [r1, r11]

    add r6, #2
    cmp r4, r6
    bgt step_x

    add r5, #1
    cmp r3, r5
    bgt step_y

    @ Switch frame buffer
    ldr r10, =PIXEL_BUFFER_CONTROL
    mov r11, #1
    str r11, [r10]

wait:
    ldr r11, [r10, #0xC]
    tst r11, #1
    bne wait

    add r12, #1
    cmp r2, r12
    bne no_reset
    mov r12, #0

no_reset:
    ldr r11, =FRAME_INDEX
    str r12, [r11]
    pop {r4, r5, r6, r7, r10, r11, r12, pc}

config_gic:
    push {lr}
    
    @ Enable interrupt #29, the private timer
    mov r0, #29
    mov r1, #1

    bl config_interrupt
    
    @ Set priority threshold to the lowest
    mov r0, #0xC100
    movt r0, #0xFFFE
    mov r1, #0xFF
    str r1, [r0, #0x04]
    
    @ Enable forwarding of interrupts from the CPU to the cores
    mov r1, #1
    str r1, [r0]
    
    @ Enable forwarding of interrupts from the Distributor to the CPU
    mov r0, #0xD000
    movt r0, #0xFFFE
    str r1, [r0]
    
    pop {pc}


config_interrupt:
    push {r4, r5, lr}

    @ Calculate interrupt address offset
    @ r0 = 0b11101
    lsr r4, r0, #3 @ r0 >> #3 = 0b11
    bic r4, r4, #3 @ bic 0b11 0b11 = 0b00
    
    mov r2, #0xD100
    movt r2, #0xFFFE

    @ Sum to Set-Enable bit address
    add r4, r2, r4
    
    @ Calculate enable bit position
    mov r2, #0x1F
    and r2, r0, r2
    mov r5, #1
    lsl r2, r5, r2
    
    @ Enable interrupt bit without changing others
    ldr r3, [r4]
    orr r3, r3, r2
    str r3, [r4]
    
    mov r2, #0xD800
    movt r2, #0xFFFE

    @ Forward interrupt to specific core
    @ i dont understand this part, even ai couldnt explain it :(
    bic r4, r0, #3
    add r4, r2, r4
    mov r2, #0x3
    and r2, r0, r2
    add r4, r2, r4
    
    strb r1, [r4]
    
    pop {r4, r5, pc}
	