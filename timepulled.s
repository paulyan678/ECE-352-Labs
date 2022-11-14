
.equ timer0_base, 0xff202000
.equ timer0_status, 0
.equ timer0_control, 4
.equ timer0_periodl, 8
.equ timer0_periodh, 12
.equ timer0_snapl, 16
.equ timer0_snaph, 20
.equ tickspersec, 10000
.equ led, 0xff200000
.text
.global _start
_start:
flipled:
movia r8, led
ldwio r10, 0(r8)
nor r10, r10, r10
stwio r10, 0(r8)
movi r4, 1
call waitasec
br flipled

waitasec:
	movia r8, timer0_base
	movi r9, 0x8
	stwio r9, timer0_control(r8)
	
	movi r9, %lo(tickspersec)
	stwio r9, timer0_periodl(r8)
	movi r9, %hi(tickspersec)
	stwio r9, timer0_periodh(r8)
	
	movi r9, 0x6
	stwio r9, timer0_control(r8)

onesec:
	ldwio r9, timer0_status(r8)
	andi r9, r9, 0x1
	beq r9, r0, onesec
	
	stwio r0, timer0_status(r8)
	subi r4, r4, 1
	bne r4, r0, onesec
	movi r9, 0x8
	stwio r9, timer0_control(r8)
	
	ret
