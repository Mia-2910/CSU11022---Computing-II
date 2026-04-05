// Recreate with hard code level lights
  .syntax unified
  .cpu cortex-m4
  .fpu softvfp
  .thumb
  
  .global  Main
  .global  SysTick_Handler

  @ Definitions are in definitions.s to keep blinky.s "clean"
  #include "definitions.S"

  .equ    BLINK_PERIOD, 10000
  .equ    HOLD_LIMIT,   2000
  .equ    GPIOA_IDR,    0x48000010

  .section .text
  .type Main, %function
Main:
  PUSH    {R4-R6,LR}

  @ Enable GPIO port E by enabling its clock
  @ STM32F303 Reference Manual 9.4.6 (pg. 148)
  LDR     R4, =RCC_AHBENR
  LDR     R5, [R4]
  ORR     R5, R5, #(0b1 << RCC_AHBENR_GPIOEEN_BIT)

  @ also enable GPIOA for blue user button
  ORR     R5, R5, #(0b1 << 17)
  STR     R5, [R4]

  @ Configure leds for output
  @ STM32F303 Reference Manual 11.4.1 (pg. 237)
  LDR     R4, =GPIOE_MODER

  LDR     R5, [R4]
  BIC     R5, #(0b11<<(LD3_PIN*2))
  ORR     R5, #(0b01<<(LD3_PIN*2))
  STR     R5, [R4]

  LDR     R5, [R4]
  BIC     R5, #(0b11<<(LD4_PIN*2))
  ORR     R5, #(0b01<<(LD4_PIN*2))
  STR     R5, [R4]

  LDR     R5, [R4]
  BIC     R5, #(0b11<<(LD5_PIN*2))
  ORR     R5, #(0b01<<(LD5_PIN*2))
  STR     R5, [R4]

  LDR     R5, [R4]
  BIC     R5, #(0b11<<(LD6_PIN*2))
  ORR     R5, #(0b01<<(LD6_PIN*2))
  STR     R5, [R4]

  LDR     R5, [R4]
  BIC     R5, #(0b11<<(LD7_PIN*2))
  ORR     R5, #(0b01<<(LD7_PIN*2))
  STR     R5, [R4]

  LDR     R5, [R4]
  BIC     R5, #(0b11<<(LD8_PIN*2))
  ORR     R5, #(0b01<<(LD8_PIN*2))
  STR     R5, [R4]

  LDR     R5, [R4]
  BIC     R5, #(0b11<<(LD9_PIN*2))
  ORR     R5, #(0b01<<(LD9_PIN*2))
  STR     R5, [R4]

  LDR     R5, [R4]
  BIC     R5, #(0b11<<(LD10_PIN*2))
  ORR     R5, #(0b01<<(LD10_PIN*2))
  STR     R5, [R4]

  @ start with leds off
  BL      TurnOffAllLeds

  @ init variables
  LDR     R4, =countdown
  LDR     R5, =BLINK_PERIOD
  STR     R5, [R4]

  MOV     R5, #0
  LDR     R4, =targetCount
  STR     R5, [R4]
  LDR     R4, =pressCount
  STR     R5, [R4]
  LDR     R4, =waitingInput
  STR     R5, [R4]
  LDR     R4, =buttonPrev
  STR     R5, [R4]
  LDR     R4, =holdCount
  STR     R5, [R4]
  LDR     R4, =gameResult
  STR     R5, [R4]

  @ Configure SysTick Timer
  @ STM32 Cortex-M4 Programming Manual 4.4.3 (pg. 225)
  LDR     R4, =SCB_ICSR
  LDR     R5, =SCB_ICSR_PENDSTCLR
  STR     R5, [R4]

  @ STM32 Cortex-M4 Programming Manual 4.5.1 (pg. 247)
  LDR   R4, =SYSTICK_CSR
  LDR   R5, =0
  STR   R5, [R4]
  
  @ STM32 Cortex-M4 Programming Manual 4.5.2 (pg. 248)
  LDR   R4, =SYSTICK_LOAD
  LDR   R5, =3000          @ bigger = slower
  STR   R5, [R4]

  @ STM32 Cortex-M4 Programming Manual 4.5.3 (pg. 249)
  LDR   R4, =SYSTICK_VAL
  LDR   R5, =0x1
  STR   R5, [R4]

  @ STM32 Cortex-M4 Programming Manual 4.4.3 (pg. 225)
  LDR   R4, =SYSTICK_CSR
  LDR   R5, =0x7
  STR   R5, [R4]

  @ Nothing else to do in Main
  @ Idle loop forever
Idle_Loop:
  B     Idle_Loop
  
End_Main:
  POP   {R4-R6,PC}




@
@ SysTick interrupt handler
@
  .type  SysTick_Handler, %function

SysTick_Handler:
  PUSH    {R3, R4, R5, R6, LR}

  @ if game already ended, keep result on
  LDR   R4, =gameResult
  LDR   R5, [R4]
  CMP   R5, #0
  BNE   .Lbranch

  @ if waiting for user input, go check blue button
  LDR   R4, =waitingInput
  LDR   R5, [R4]
  CMP   R5, #1
  BEQ   .LHandleInput

.LStart:
  LDR   R4, =countdown
  LDR   R5, [R4]

  LDR   R6, =9000
  CMP   R5, R6
  BEQ   .LelseFireLD6
 
  LDR   R6, =8000
  CMP   R5, R6
  BEQ   .LelseFireLD10
  
  LDR   R6, =7000
  CMP   R5, R6
  BEQ   .LelseFireLD7

  LDR   R6, =6000
  CMP   R5, R6
  BEQ   .LelseFireLD5
 
  LDR   R6, =5000
  CMP   R5, R6
  BEQ   .LelseFireLD8

  LDR   R6, =4000
  CMP   R5, R6
  BEQ   .LelseFireLD9

  LDR   R6, =2000
  CMP   R5, R6
  BEQ   .LwaitUserInput

  SUB   R5, R5, #1
  STR   R5, [R4]
  B     .Lbranch

.LelseFireLD6:
  BL      TurnOffAllLeds
  LDR     R4, =GPIOE_ODR
  LDR     R5, [R4]
  ORR     R5, #(0b1<<(LD6_PIN))
  STR     R5, [R4]

  LDR     R4, =targetCount
  LDR     R5, [R4]
  ADD     R5, R5, #1
  STR     R5, [R4]

  LDR     R4, =countdown
  LDR     R5, =8999
  STR     R5, [R4]
  B       .Lbranch

.LelseFireLD10:
  BL      TurnOffAllLeds
  LDR     R4, =GPIOE_ODR
  LDR     R5, [R4]
  ORR     R5, #(0b1<<(LD10_PIN))
  STR     R5, [R4]

  LDR     R4, =targetCount
  LDR     R5, [R4]
  ADD     R5, R5, #1
  STR     R5, [R4]

  LDR     R4, =countdown
  LDR     R5, =7999
  STR     R5, [R4]
  B       .Lbranch

.LelseFireLD7:
  BL      TurnOffAllLeds
  LDR     R4, =GPIOE_ODR
  LDR     R5, [R4]
  ORR     R5, #(0b1<<(LD7_PIN))
  STR     R5, [R4]

  LDR     R4, =targetCount
  LDR     R5, [R4]
  ADD     R5, R5, #1
  STR     R5, [R4]

  LDR     R4, =countdown
  LDR     R5, =6999
  STR     R5, [R4]
  B       .Lbranch

.LelseFireLD5:
  BL      TurnOffAllLeds
  LDR     R4, =GPIOE_ODR
  LDR     R5, [R4]
  ORR     R5, #(0b1<<(LD5_PIN))
  STR     R5, [R4]

  LDR     R4, =targetCount
  LDR     R5, [R4]
  ADD     R5, R5, #1
  STR     R5, [R4]

  LDR     R4, =countdown
  LDR     R5, =5999
  STR     R5, [R4]
  B       .Lbranch

.LelseFireLD8:
  BL      TurnOffAllLeds
  LDR     R4, =GPIOE_ODR
  LDR     R5, [R4]
  ORR     R5, #(0b1<<(LD8_PIN))
  STR     R5, [R4]

  LDR     R4, =targetCount
  LDR     R5, [R4]
  ADD     R5, R5, #1
  STR     R5, [R4]

  LDR     R4, =countdown
  LDR     R5, =4999
  STR     R5, [R4]
  B       .Lbranch

.LelseFireLD9:
  BL      TurnOffAllLeds
  LDR     R4, =GPIOE_ODR
  LDR     R5, [R4]
  ORR     R5, #(0b1<<(LD9_PIN))
  STR     R5, [R4]

  LDR     R4, =targetCount
  LDR     R5, [R4]
  ADD     R5, R5, #1
  STR     R5, [R4]

  LDR     R4, =countdown
  LDR     R5, =3999
  STR     R5, [R4]
  B       .Lbranch
 
.LwaitUserInput:
  @ player now presses blue button
  @ short press = +1
  @ hold = submit answer
  LDR     R4, =waitingInput
  MOV     R5, #1
  STR     R5, [R4]

  LDR     R4, =pressCount
  MOV     R5, #0
  STR     R5, [R4]

  LDR     R4, =buttonPrev
  MOV     R5, #0
  STR     R5, [R4]

  LDR     R4, =holdCount
  MOV     R5, #0
  STR     R5, [R4]

  BL      TurnOffAllLeds
  B       .Lbranch

.LHandleInput:
  @ read blue button PA0
  LDR     R4, =GPIOA_IDR
  LDR     R5, [R4]
  AND     R5, R5, #1

  LDR     R4, =buttonPrev
  LDR     R6, [R4]

  CMP     R5, #0
  BEQ     .LReleased

  @ if button is being held
  CMP     R6, #1
  BEQ     .LStillHeld

  @ new press starts here
  LDR     R4, =buttonPrev
  MOV     R6, #1
  STR     R6, [R4]

  LDR     R4, =holdCount
  MOV     R6, #0
  STR     R6, [R4]
  B       .Lbranch

.LStillHeld:
  LDR     R4, =holdCount
  LDR     R6, [R4]
  ADD     R6, R6, #1
  STR     R6, [R4]

  LDR     R4, =holdCount
  LDR     R6, [R4]
  LDR     R3, =HOLD_LIMIT
  CMP     R6, R3
  BGE     .LJudgeResult
  B       .Lbranch

.LReleased:
  @ no old press -> nothing to do
  CMP     R6, #1
  BNE     .Lbranch

  @ if release before hold limit -> count 1 press
  LDR     R4, =holdCount
  LDR     R6, [R4]
  LDR     R3, =HOLD_LIMIT
  CMP     R6, R3
  BGE     .LCleanInput

  LDR     R4, =pressCount
  LDR     R6, [R4]
  ADD     R6, R6, #1
  STR     R6, [R4]

.LCleanInput:
  LDR     R4, =buttonPrev
  MOV     R6, #0
  STR     R6, [R4]

  LDR     R4, =holdCount
  MOV     R6, #0
  STR     R6, [R4]
  B       .Lbranch

.LJudgeResult:
  LDR     R4, =waitingInput
  MOV     R5, #0
  STR     R5, [R4]

  LDR     R4, =pressCount
  LDR     R5, [R4]

  LDR     R4, =targetCount
  LDR     R6, [R4]

  CMP     R5, R6
  BEQ     .LPlayerWin
  B       .LPlayerLose

.LPlayerWin:
  @ right answer
  LDR     R4, =gameResult
  MOV     R5, #1
  STR     R5, [R4]

  BL      TurnOffAllLeds
  LDR     R4, =GPIOE_ODR
  LDR     R5, [R4]
  ORR     R5, R5, #(1 << LD4_PIN)
  ORR     R5, R5, #(1 << LD6_PIN)
  ORR     R5, R5, #(1 << LD7_PIN)
  ORR     R5, R5, #(1 << LD9_PIN)
  STR     R5, [R4]
  B       .Lbranch

.LPlayerLose:
  @ wrong answer
  LDR     R4, =gameResult
  MOV     R5, #2
  STR     R5, [R4]

  BL      TurnOffAllLeds
  LDR     R4, =GPIOE_ODR
  LDR     R5, [R4]
  ORR     R5, R5, #(1 << LD3_PIN)
  ORR     R5, R5, #(1 << LD5_PIN)
  ORR     R5, R5, #(1 << LD8_PIN)
  ORR     R5, R5, #(1 << LD10_PIN)
  STR     R5, [R4]

.Lbranch:
  @ Clear interrupt
  LDR     R4, =SCB_ICSR
  LDR     R5, =SCB_ICSR_PENDSTCLR
  STR     R5, [R4]

  @ Return from interrupt handler
  POP  {R3, R4, R5, R6, PC}

TurnOffAllLeds:
  PUSH    {R4,R5,LR}
  LDR     R4, =GPIOE_ODR
  LDR     R5, [R4]
  BIC     R5, R5, #(1 << LD3_PIN)
  BIC     R5, R5, #(1 << LD4_PIN)
  BIC     R5, R5, #(1 << LD5_PIN)
  BIC     R5, R5, #(1 << LD6_PIN)
  BIC     R5, R5, #(1 << LD7_PIN)
  BIC     R5, R5, #(1 << LD8_PIN)
  BIC     R5, R5, #(1 << LD9_PIN)
  BIC     R5, R5, #(1 << LD10_PIN)
  STR     R5, [R4]
  POP     {R4,R5,PC}

  .section .data

countdown:
  .word 0        @ round timer

targetCount:
  .word 0        @ how many leds were shown

pressCount:
  .word 0        @ how many times player pressed

waitingInput:
  .word 0        @ 0 = showing leds, 1 = checking player input

buttonPrev:
  .word 0        @ previous state of blue button

holdCount:
  .word 0        @ count how long button is held

gameResult:
  .word 0        @ 0 = playing, 1 = win, 2 = lose

  .end
