.equ jtag_uart_base, 0xff201000
.equ uart_base, 0x10001020
.equ timer0_base, 0xff202000
.equ straight_steering, 0
.equ straight_speed, 48
.equ turn_speed, 40
.equ right_steering, -64
.equ hard_right_steering, -127
.equ left_steering, 64
.equ hard_left_steering, 127
.equ tickspersec, 100000000

.data
speed: .skip 1
sensor: .skip 1
tobeprinted: .byte 'r'

.section .exceptions, "ax"
interrupt_handller:
pro:
addi sp, sp, -8
stw r2, 0(sp)
stw r3, 4(sp)


#load timer status
movia r2, timer0_base
ldwio r3, 0(r2)
andi r3, r3, 0x01
istimerbeingnaughty:
beq r3, r0, isuartbeingnaughty
timerisnaughty:
#clear timeout 
stwio r0, 0(r2)
#what to print in r3
movia r3, tobeprinted
ldb r3, 0(r3)
#print speed?
movi r2, 's'
bne r3, r2, print_sensor
print_speed:
movia r3, speed
movia r2, jtag_uart_base
#r3 has speed
ldb r3, 0(r3)
#send speed to uart
stwio r3, 0(r2)
br isuartbeingnaughty
#print sensor!
print_sensor:
movia r3, sensor
movia r2, jtag_uart_base
#r3 has sensor
ldb r3, 0(r3)
#send sensor to uart
stwio r3, 0(r2)

isuartbeingnaughty:
movia r2, jtag_uart_base
ldwio r3, 4(r2)
andi r3, r3, 0x100
beq r3, r0, epi
uartisbeingnaughty:
#input in r3
ldwio r3, 0(r2)
andi r3, r3, 0xff
isspressed:
movi r2, 's'
bne r3, r2, isrpressed
#update what to print to 's'
movia r2, tobeprinted
stb r3, 0(r2)
br epi
isrpressed:
movi r2, 'r'
bne r3, r2, epi
#update what to print to 'r'
movia r2, tobeprinted
stb r3, 0(r2)

epi:
ldw r2, 0(sp)
ldw r3, 4(sp)
addi sp, sp, 8
addi ea, ea, -4
eret

.text
.global _start
_start:
#enable interupts in cpu
movi r2, 1
wrctl ctl0, r2
movi r2, 0x101
wrctl ctl3, r2

#enable interupt in uart
movia r2, jtag_uart_base
movi r3, 1
stwio r3, 4(r2)

#initlize stack pointer
movia sp, 0x00400000

#set up timer
movia r2, timer0_base
#stop timer
movi r3, 0x8
stwio r3, 4(r2)
#set lower 16 bits ticks
movi r3, %lo(tickspersec)
stwio r3, 8(r2)
#set upper 16 bits ticks
movi r3, %hi(tickspersec)
stwio r3, 12(r2)
#turn on continue and start timer and enable interupt
movi r3, 0x7
stwio r3, 4(r2)

main:
# read the sensors and speed
call read_sensor_and_speed
# r2 has speed r3 has sensor

#store the value of speed and sensor to be printed
movia r4, speed
stb r2, 0(r4)
movia r4, sensor
stb r3, 0(r4)

checkStraight:
movi r4, 0b11111
bne r3, r4, checkRight
Straight:
#change steering and set speed
movi r4, straight_steering

#push the speed onto the stack as per calling convention
addi sp, sp, -4
stw r2, 0(sp)
call changeSteering
ldw r2, 0(sp)
addi sp, sp, 4

mov r4, r2
movi r5, straight_speed
call setSpeed

br main

checkRight:
movi r4, 0b01111
bne r3, r4, checkHardRight
Right:
#change steering and set speed
movi r4, right_steering

#push the speed onto the stack as per calling convention
addi sp, sp, -4
stw r2, 0(sp)
call changeSteering
ldw r2, 0(sp)
addi sp, sp, 4

mov r4, r2
movi r5, turn_speed
call setSpeed

br main

checkHardRight:
movi r4, 0b00111
bne r3, r4, checkLeft
HardRight:
#change steering and set speed
movi r4, hard_right_steering

#push the speed onto the stack as per calling convention
addi sp, sp, -4
stw r2, 0(sp)
call changeSteering
ldw r2, 0(sp)
addi sp, sp, 4

mov r4, r2
movi r5, turn_speed
call setSpeed

br main

checkLeft:
movi r4, 0b11110
bne r3, r4, checkHardLeft
Left:
#change steering and set speed
movi r4, left_steering

#push the speed onto the stack as per calling convention
addi sp, sp, -4
stw r2, 0(sp)
call changeSteering
ldw r2, 0(sp)
addi sp, sp, 4

mov r4, r2
movi r5, turn_speed
call setSpeed

br main

checkHardLeft:
movi r4, 0b11100
bne r3, r4, main
HardLeft:
#change steering and set speed
#change steering and set speed
movi r4, hard_left_steering

#push the speed onto the stack as per calling convention
addi sp, sp, -4
stw r2, 0(sp)
call changeSteering
ldw r2, 0(sp)
addi sp, sp, 4

mov r4, r2
movi r5, turn_speed
call setSpeed

br main


changeSteering:
# r4 contains amount to steer
changeSteering_pro:
addi sp, sp, -8
stw ra, 0(sp)

stw r4, 4(sp)
movi r4, 0x05
call sending
ldw r4, 4(sp)
call sending
changeSteering_epi:
ldw ra, 0(sp)
addi sp, sp, 8
ret

setSpeed:
# r4 contains the current speed and r5 contains the target speed
addi sp, sp, -4
stw ra, 0(sp)
check_slow_down:
ble r4, r5, check_speed_up
slow_down:
movi r4, 0x04
call sending

movi r4, -127
call sending

br epi_setSpeed

check_speed_up:
beq r4, r5, epi_setSpeed
speed_up:
movi r4, 0x04
call sending

movi r4, 127
call sending

epi_setSpeed:
ldw ra, 0(sp)
addi sp, sp, 4
ret

read_sensor_and_speed:
#sensor inforamtion return in r3
#speed return in r2
read_sensor_and_speed_pro:
addi sp, sp, -8
stw ra, 0(sp)

movi r4, 0x02
call sending

wait0:
call reading
bne r2, r0, wait0:

getsensor:
call reading

getspeed:
stw r2, 4(sp)
call reading
ldw r3, 4(sp)

read_sensor_and_speed_epi:
ldw ra, 0(sp)
addi sp, sp, 8
ret


sending: 
#send information in r4 using uart
# r4 parameter
# r2 uart_base
# r3 temp register stores uart control register 
#return nothing 
  movia r2, uart_base 
sending_poll:
  ldwio r3, 4(r2) 
  srli  r3, r3, 16 
  beq   r3, r0, sending_poll
  stwio r4, 0(r2)
ret

reading:
#reading information from uart and return in r2
# r4 uart_base
# r3 temp register stores uart recieve register 
# r2 return data recieved 
  movia r4, uart_base
reading_poll:
  ldwio r3, 0(r4) 
  andi  r2, r3, 0x8000 
  beq   r2, r0, reading_poll
  andi  r2, r3, 0x00FF
 ret