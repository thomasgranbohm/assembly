.data
COUNTER:
	.word 0x0
NUMBERS:
	.byte 0x3F
	.byte 0x06
	.byte 0x5B
	.byte 0x4F
	.byte 0x66
	.byte 0x6D
	.byte 0x07
	.byte 0x7F
	.byte 0x67

.align 0x01

.section .text

.equ SSD_ADDR, 0xFF200020

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
    
    @ Configure timer 
    mov r0, #0xC600
    movt r0, #0xFFFE
    
    @ Set timer load value
    ldr r1, =2222222 @ approx 30 fps given 
    str r1, [r0]
    
    @ Enable timer, interrupt and auto-reload flags
    mov r1, #0b1100000111
    str r1, [r0, #0x8]
    
	@ Clear the IRQ mask, enabling interrupts again
	mrs r0, cpsr
	bic r0, r0, #0x80
	msr cpsr, r0

end:
    b end


irq_handler:
    push {r0-r3, lr}
	
    @ Clear GIS interrupt flag
    mov r0, #0xC100
    movt r0, #0xFFFE
    
    @ Load interrupt id
    ldr r1, [r0, #0xC]

    @ Acknowledge interrupt id
    str r1, [r0, #0x10]
    
    @ Increase counter
	ldr r2, =COUNTER @ load address of counter const
	ldr r3, [r2] @ load value of counter
	add r3, #1
	str r3, [r2]
	
	ldr r2, =NUMBERS
	ldrb r3, [r2, r3]
	ldr r2, =SSD_ADDR
	str r3, [r2]
	
	@ Clear the timer interrupt flag
    mov r0, #0xC600
    movt r0, #0xFFFE
    mov r1, #0x1
    str r1, [r0, #0xC]      @ Write 1 to timer interrupt status register
    
    pop {r0-r3, lr}
    subs pc, lr, #4


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
	