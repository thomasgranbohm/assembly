.global _start
_start:
	mov r0, #0x0000
	movt r0, #0xc000 @ read addr
	
	mov r1, #0x0000
	movt r1, #0xc800 @ write addr
	
	ldrh r2, [r0], #2 @ load amount of frames

	mov r12, #0b0 @ control color
	
restart:
	mov r11, r2
	mov r10, r0

loadframe:
	ldrh r3, [r10], #2 @ load height width
	mov r7, #0xFF
	and r4, r3, r7
	lsr r3, #8
	
	@ r3 - height
	@ r4 - width
	

loadpixel: 
	mov r5, r1 @ tmp write addr
	mov r6, #0x0 @ y index

stepy:
	mov r7, #0x0 @ x index
stepx:
	ldrh r8, [r10], #2 @ read r8 in r8 from r0
	strh r8, [r5], #2 @ write r8 to r1
	
	@ loop through pixel columns
	add r7, #1
	cmp r7, r4
	blt stepx
	
	@ skip to next pixel row in memory
	mov r7, #320
	sub r7, r4
	lsl r7, #1
	add r5, r7
	add r5, #0x180
	
	@ loop through pixel rows
	add r6, #1
	cmp r6, r3
	blt stepy
	
	mov r9, #0x20000

delay:
    subs r9, #1
    bne delay
	
	subs r11, #0x1
	bne loadframe


	b restart	
