

.equ timer0_base, 0xff202000
.equ timer0_status, 0
.equ timer0_control, 4
.equ timer0_periodl, 8
.equ timer0_periodh, 12
.equ timer0_snapl, 16
.equ timer0_snaph, 20
.equ tickspersec, 10000000
.equ led, 0xff200000
.global _start
.text
_start:
	movia sp, 0x00400000
	movia r8, timer0_base
	movi r9, 1
	#let the cpu accept the interupt
	wrctl ctl0, r9
	wrctl ctl3, r9
	#stop timer 
	movi r9, 0x8
	stwio r9, timer0_control(r8)
	# set ticks
	movi r9, %lo(tickspersec)
	stwio r9, timer0_periodl(r8)
	movi r9, %hi(tickspersec)
	stwio r9, timer0_periodh(r8)
	#turn on continue and start timer and enable interupt
	movi r9, 0x7
	stwio r9, timer0_control(r8)
	#doing nothing and wait for interrupt
loop: br loop

.section .exceptions, "ax"
handler:
pro:
	addi sp, sp, -8
	stw r8, 0(sp)
	stw r10, 4(sp)
	
	#clear timeout 
	movia r8, timer0_base
	stwio r0, timer0_status(r8)
	#invert led
	movia r8, led
	ldwio r10, 0(r8)
	nor r10, r10, r10
	stwio r10, 0(r8)
	
epi:
	ldw r8, 0(sp)
	ldw r10, 4(sp)
	addi sp, sp, 8
	subi ea, ea, 4
	eret
	
