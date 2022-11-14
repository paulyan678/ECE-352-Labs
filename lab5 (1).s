.equ UART_CAR, 0x10001020
.equ TIMER, 0x10002000
.equ LEFT_STEER, 64
.equ RIGHT_STEER, -64
.equ S_LEFT_STEER, 127
.equ S_RIGHT_STEER, -127
.equ STRAIGHT_SPEED_MAX, 48
.equ STRAIGHT_SPEED_MIN, 47
.equ LEFT_SPEED_MAX, 40
.equ LEFT_SPEED_MIN, 40
.equ RIGHT_SPEED_MAX, 40
.equ RIGHT_SPEED_MIN, 40
.equ S_RIGHT_SPEED_MAX, 40
.equ S_RIGHT_SPEED_MIN, 40
.equ S_LEFT_SPEED_MAX, 40
.equ S_LEFT_SPEED_MIN, 40

#.equ INITIAL_STACK, 2000
.equ INITIAL_STACK, 0x00400000

.global _start
.global main

# Read sensor value and speed value return them in r2 and r3
readSensorAndSpeed:
	# Initialize stack
	addi sp, sp, -12
	stw r16, 0(sp)
	stw r17, 4(sp)
	stw ra, 8(sp)

	# Request data
	movi r16, 2 # Packet type = 2 -> 0x02
	movia r17, UART_CAR
	call pollWrite
	stwio r16, 0(r17)

waitByte0:
	# Wait until first byte (0x00)
	call readPacket
	bne r2, r0, waitByte0

	# Read sensor value
	call readPacket
	mov r3, r2 # r3 = sensor value

	call readPacket # r2 = speed value
	# Restore stack pointer
	ldw r16, 0(sp)
	ldw r17, 4(sp)
	ldw ra, 8(sp)
	addi sp, sp, 12
	ret

# Change acceleration r4 = a (-127 ~ 128)
change_a:
	# Initialize stack
	addi sp, sp, -12
	stw r16, 0(sp)
	stw r17, 4(sp)
	stw ra, 8(sp)

	# Request data
	movi r16, 4 # packet type 4 -> 0x04
	movia r17, UART_CAR
	call pollWrite
	stwio r16, 0(r17) # send first byte
	call pollWrite
	stwio r4, 0(r17) # send second byte
	
	# Restore stack pointer
	ldw r16, 0(sp)
	ldw r17, 4(sp)
	ldw ra, 8(sp)
	addi sp, sp, 12
	ret

# Change steering r4 = steeling (-127 ~ 128)
changeSteering:
	# Initialize stack
	addi sp, sp, -12
	stw r16, 0(sp)
	stw r17, 4(sp)
	stw ra, 8(sp)

	# Request data
	movi r16, 5 # packet type 5 -> 0x05
	movia r17, UART_CAR
	call pollWrite
	stwio r16, 0(r17) # send first byte
	call pollWrite
	stwio r4, 0(r17) # send second byte

	# Restore stack pointer
	ldw r16, 0(sp)
	ldw r17, 4(sp)
	ldw ra, 8(sp)
	addi sp, sp, 12
	ret

# Request space for writing
pollWrite:
  # poll UART_CAR for writing
  movia r9, UART_CAR

waitWriteSpace:
  # Wait until there is space for writing
  ldwio r8, 4(r17)
  srli r8, r8, 16
  beq r8, r0, waitWriteSpace
  ret

# Read a packet from UART return value in r2
readPacket:
  movia r9, UART_CAR

waitReadValid:
  ldwio r2, 0(r9)
  srli r8, r2, 15
  andi r8, r8, 0x1
  beq r8, r0, waitReadValid
  andi r2, r2, 0xFF
  ret

_start:
main:
  movia sp, INITIAL_STACK

checkSensorSpeed:
  call readSensorAndSpeed
  mov r16, r2 # r16 = speed
  andi r17, r3, 0b11111 # r17 = sensors

  # Switch for different situations
  movi r18, 0b11111
  beq r17, r18, goStraight
  movi r18, 0b01111
  beq r17, r18, turnRight
  movi r18, 0b00111
  beq r17, r18, turnHardRight
  movi r18, 0b11110
  beq r17, r18, turnLeft
  movi r18, 0b11100
  beq r17, r18, turnHardLeft
  br checkSensorSpeed

goStraight:
  movi r4, 0
  call changeSteering
  mov r4, r16
  movi r5, STRAIGHT_SPEED_MIN
  movi r6, STRAIGHT_SPEED_MAX
  call setSpeed
  br checkSensorSpeed
turnLeft:
  movi r4, LEFT_STEER
  call changeSteering
  mov r4, r16
  movi r5, LEFT_SPEED_MIN
  movi r6, LEFT_SPEED_MAX
  call setSpeed
  br checkSensorSpeed
turnHardLeft:
  movi r4, S_LEFT_STEER
  call changeSteering
  mov r4, r16
  movi r5, S_LEFT_SPEED_MIN
  movi r6, S_LEFT_SPEED_MAX
  call setSpeed
  br checkSensorSpeed
turnRight:
  movi r4, RIGHT_STEER
  call changeSteering
  mov r4, r16
  movi r5, RIGHT_SPEED_MIN
  movi r6, RIGHT_SPEED_MAX
  call setSpeed
  br checkSensorSpeed
turnHardRight:
  movi r4, S_RIGHT_STEER
  call changeSteering
  mov r4, r16
  movi r5, S_RIGHT_SPEED_MIN
  movi r6, S_RIGHT_SPEED_MAX
  call setSpeed
  br checkSensorSpeed

# set_speed(current, min, max)
# acceleration would be set to get current speed in range specified by min&max
setSpeed:
  addi sp, sp, -4
  stw ra, 0(sp)

  bge r4, r6, slower
  ble r4, r5, faster

slower:
  movi r4, -127
  call change_a
  br return

faster:
  movi r4, 127
  call change_a
  br return

return:
  ldw ra, 0(sp)
  addi sp, sp, 4
  ret