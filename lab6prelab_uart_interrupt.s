.equ uart_base, 0xff201000


.data
presseds: .byte 'a'
pressedr: .byte 'b'

.section .exceptions, "ax"
handler:
pro:
	addi sp, sp, -8
	stw r9, 0(sp)
	stw r8, 4(sp)

	movia r8, uart_base
	ldwio r8, 0(r8)
	andi r8, r8, 0x0ff
checks:
	movi r9, 's'
	beq r8, r9, s
	br checkr
s:
	movia r9, presseds
	ldb r9, 0(r9)
	movia r8, uart_base
	stwio r9, 0(r8)
	br epi
checkr:
	movi r9, 'r'
	beq r8, r9, r
	br epi
r:
	movia r9, pressedr
	ldb r9, 0(r9)
	movia r8, uart_base
	stwio r9, 0(r8)
epi:
	ldw r9, 0(sp)
	ldw r8, 4(sp)
	addi sp, sp, 8
	addi ea, ea, -4
	eret

.text
.global _start
_start:
	movia r9, uart_base
	movia sp, 0x00400000
	movi r8, 1
	wrctl ctl0, r8
	stwio r8, 4(r9)
	movi r8, 0x100
	wrctl ctl3, r8
loop: br loop
	