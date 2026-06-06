.global _start
_start:	
	mov r9, #0x0
	movt r9, #0xc000 @ write addr
	
	mov r10, #0x3020
	movt r10, #0xFF20
	
    mov r12, #0b100
    str r12, [r10, #0xC]
	
	ldr r12, [r10, #4]
	cmp r12, r9
	beq load_info
	str r9, [r10, #4]

load_info:
	mov r0, #0x20000000 @ bin addr
	ldr r1, [r0], #4 @ number of frames
	
load_frame:
	@ load frame info
	ldr r9, [r10, #4] @ load write addr
	
	ldr r2, [r0], #4
	mov r12, #0x1FF
	and r3, r2, r12 @ r3 = width
	lsr r2, #9 @ r2 = height
	
	mov r4, #0 @ y index
	
step_y:
	mov r5, #0 @ x index
	
step_x:
	ldr r6, [r0], #4
	
    @ calculate write addr offset
	lsl r12, r5, #0x1
	lsl r11, r4, #0xA
	add r12, r11
	
	str r6, [r9, r12]
	
	add r5, #2 @ add 2 cause 2 frames at a time
	cmp r3, r5
	bne step_x
	
	add r4, #1
	cmp r2, r4
	bne step_y
	
	mov r11, #1
	str r11, [r10]
	
	mov r11, #0x302C
	movt r11, #0xFF20
	
wait:
	ldr r12, [r11]
	tst r12, #1
	bne wait
	
	subs r1, #1
	bne load_frame
	
	b load_info
	