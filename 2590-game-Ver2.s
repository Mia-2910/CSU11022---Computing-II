// Recreate with hard code level lights
  .syntax unified
  .cpu cortex-m4
  .fpu softvfp
  .thumb
  
  .global  Main
  .global  SysTick_Handler

  @ keep hardware defs here
  #include "definitions.S"

  .equ    LED_ON_TICKS,     1800      @ How long one led stays on
  .equ    LED_GAP_TICKS,    1200      @ Gap between leds
  .equ    HOLD_LIMIT,       2000      @ Hold blue button to submit / next round
  .equ    GPIOA_IDR,        0x48000010

  .section .text
  .type Main, %function

@ Main setup:
@ - Enable GPIO for LEDs and blue button
@ - Initialise game variables


Main:
  PUSH    {R4-R7,LR}

  @ Enable GPIO clocks for memory-mapped I/O
  @ GPIOE -> LEDs, GPIOA -> blue button
  LDR     R4, =RCC_AHBENR
  LDR     R5, [R4]
  ORR     R5, R5, #(0b1 << RCC_AHBENR_GPIOEEN_BIT)
  ORR     R5, R5, #(0b1 << 17)
  STR     R5, [R4]

  @ Configure LED pins as output using GPIO registers
  LDR     R4, =GPIOE_MODER

  LDR     R5, [R4]                                       @ Read 
  BIC     R5, #(0b11<<(LD3_PIN*2))                       @ Modify 
  ORR     R5, #(0b01<<(LD3_PIN*2))                       @ Write 01 to bits Led3
  STR     R5, [R4]                                       @ Write

  LDR     R5, [R4]
  BIC     R5, #(0b11<<(LD4_PIN*2))
  ORR     R5, #(0b01<<(LD4_PIN*2))                       @ Write 01 to bits Led4
  STR     R5, [R4]

  LDR     R5, [R4]
  BIC     R5, #(0b11<<(LD5_PIN*2))
  ORR     R5, #(0b01<<(LD5_PIN*2))                       @ Write 01 to bits Led5
  STR     R5, [R4]

  LDR     R5, [R4]
  BIC     R5, #(0b11<<(LD6_PIN*2))
  ORR     R5, #(0b01<<(LD6_PIN*2))                       @ Write 01 to bits Led6
  STR     R5, [R4]

  LDR     R5, [R4]
  BIC     R5, #(0b11<<(LD7_PIN*2))
  ORR     R5, #(0b01<<(LD7_PIN*2))                      @ Write 01 to bits Led7
  STR     R5, [R4]

  LDR     R5, [R4]
  BIC     R5, #(0b11<<(LD8_PIN*2))                      @ Write 01 to bits Led8
  ORR     R5, #(0b01<<(LD8_PIN*2))
  STR     R5, [R4]

  LDR     R5, [R4]
  BIC     R5, #(0b11<<(LD9_PIN*2))                      @ Write 01 to bits Led9
  ORR     R5, #(0b01<<(LD9_PIN*2))
  STR     R5, [R4]

  LDR     R5, [R4]
  BIC     R5, #(0b11<<(LD10_PIN*2))                     @ Write 01 to bits Led3
  ORR     R5, #(0b01<<(LD10_PIN*2))
  STR     R5, [R4]

  @ Start with leds off
  BL      TurnOffAllLeds

  @ Initilise seed
  LDR     R4, =seed
  LDR     R5, =7
  STR     R5, [R4]

  @ Initialise varibles
  MOV     R5, #0
  LDR     R4, =buttonPrev
  STR     R5, [R4]
  LDR     R4, =holdCount
  STR     R5, [R4]
  LDR     R4, =gameResult
  STR     R5, [R4]
  LDR     R4, =resultArmed
  STR     R5, [R4]
  LDR     R4, =tickCount
  STR     R5, [R4]

  @ Configure SysTick Timer to generate an interrupt
  LDR     R4, =SCB_ICSR                                @ Clear any pre-existing interrupts
  LDR     R5, =SCB_ICSR_PENDSTCLR
  STR     R5, [R4]

  LDR     R4, =SYSTICK_CSR                             @ Stop SysTick timer
  LDR     R5, =0                                       @   by writing 0 to CSR
  STR     R5, [R4]                                     @   CSR is the Control and Status Register

  LDR     R4, =SYSTICK_LOAD
  LDR     R5, =1400          
  STR     R5, [R4]

  LDR     R4, =SYSTICK_VAL                             @ Reset SysTick internal counter to 0
  LDR     R5, =0x1                                     @  by writing any value
  STR     R5, [R4]

  LDR     R4, =SYSTICK_CSR                             @ Start SysTick timer by setting CSR to 0x7
  LDR     R5, =0x7
  STR     R5, [R4]

  @ make first round
  BL      StartNewRound

Idle_Loop:
  B       Idle_Loop
  
End_Main:
  POP     {R4-R7,PC}




@ Game loop (runs in SysTick)
@ - show LED pattern
@ - read button input
@ - check result
@ - start next round

  .type  SysTick_Handler, %function

SysTick_Handler:
  PUSH    {R3, R4, R5, R6, R7, LR}

  @ Free running counter for better random seed
  LDR     R4, =tickCount
  LDR     R5, [R4]
  ADD     R5, R5, #1
  STR     R5, [R4]

  @ If already win/lose, wait for next-round input
  LDR   R4, =gameResult
  LDR   R5, [R4]
  CMP   R5, #0
  BNE   .LResultState

  @ If waiting for user answer, handle input
  LDR   R4, =waitingInput
  LDR   R5, [R4]
  CMP   R5, #1
  BEQ   .LHandleInput

  @ Otherwise still showing pattern
  B     .LShowPattern


@ Show pattern step by step
.LShowPattern:
  @ Countdown for show phase
  LDR   R4, =countdown
  LDR   R5, [R4]
  SUB   R5, R5, #1
  STR   R5, [R4]
  CMP   R5, #0
  BGT   .Lbranch

  @ Check if led is currently on or off
  LDR   R4, =showState
  LDR   R5, [R4]
  CMP   R5, #0
  BEQ   .LShowNextStep

  @ Led was on, now turn off and move to next step
  BL      TurnOffAllLeds

  LDR     R4, =stepIndex
  LDR     R5, [R4]
  ADD     R5, R5, #1
  STR     R5, [R4]

  LDR     R4, =showState
  MOV     R5, #0
  STR     R5, [R4]

  LDR     R4, =countdown
  LDR     R5, =LED_GAP_TICKS
  STR     R5, [R4]
  B       .Lbranch


.LShowNextStep:
  @ If all steps shown, wait for input
  LDR     R4, =stepIndex
  LDR     R5, [R4]

  LDR     R4, =stepCount
  LDR     R6, [R4]

  CMP     R5, R6
  BGE     .LwaitUserInput

  @ Load pattern[stepIndex]
  LDR     R4, =pattern
  LDR     R6, =stepIndex
  LDR     R7, [R6]
  LDR     R0, [R4, R7, LSL #2]

  BL      TurnOffAllLeds
  BL      ShowLedFromCode

  LDR     R4, =showState
  MOV     R5, #1
  STR     R5, [R4]

  LDR     R4, =countdown
  LDR     R5, =LED_ON_TICKS
  STR     R5, [R4]
  B       .Lbranch


.LwaitUserInput:
  @ Wait for player input
  @ Short press = +1, long hold = submit
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
  @ read button
  @ detect press or hold
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

  LDR     R3, =HOLD_LIMIT
  CMP     R6, R3
  BGE     .LJudgeResult
  B       .Lbranch

.LReleased:
  @ No old press -> nothing to do
  CMP     R6, #1
  BNE     .Lbranch

  @ If release before hold limit -> count 1 press
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


@ check result
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
  @ correct answer
  LDR     R4, =gameResult
  MOV     R5, #1
  STR     R5, [R4]

  @ force release before next round
  LDR     R4, =holdCount
  MOV     R5, #0
  STR     R5, [R4]

  LDR     R4, =buttonPrev
  MOV     R5, #0
  STR     R5, [R4]

  LDR     R4, =resultArmed
  MOV     R5, #0
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
  @ Ưrong answer
  LDR     R4, =gameResult
  MOV     R5, #2
  STR     R5, [R4]

  @ Force release before next round
  LDR     R4, =holdCount
  MOV     R5, #0
  STR     R5, [R4]

  LDR     R4, =buttonPrev
  MOV     R5, #0
  STR     R5, [R4]

  LDR     R4, =resultArmed
  MOV     R5, #0
  STR     R5, [R4]

  BL      TurnOffAllLeds
  LDR     R4, =GPIOE_ODR
  LDR     R5, [R4]
  ORR     R5, R5, #(1 << LD3_PIN)
  ORR     R5, R5, #(1 << LD5_PIN)
  ORR     R5, R5, #(1 << LD8_PIN)
  ORR     R5, R5, #(1 << LD10_PIN)
  STR     R5, [R4]
  B       .Lbranch

@ wait for next round input
.LResultState:
  LDR     R4, =GPIOA_IDR
  LDR     R5, [R4]
  AND     R5, R5, #1

  CMP     R5, #0
  BEQ     .LResultReleased

  @ if not armed yet, ignore while still holding
  LDR     R4, =resultArmed
  LDR     R6, [R4]
  CMP     R6, #1
  BNE     .Lbranch

  @ now count hold for next round
  LDR     R4, =holdCount
  LDR     R6, [R4]
  ADD     R6, R6, #1
  STR     R6, [R4]

  LDR     R3, =HOLD_LIMIT
  CMP     R6, R3
  BGE     .LNextRound
  B       .Lbranch

.LResultReleased:
  @ after result, player must release first
  LDR     R4, =holdCount
  MOV     R6, #0
  STR     R6, [R4]

  LDR     R4, =resultArmed
  MOV     R6, #1
  STR     R6, [R4]

  B       .Lbranch

.LNextRound:
  @ start next round
  LDR     R4, =seed
  LDR     R5, [R4]

  LDR     R6, =tickCount
  LDR     R6, [R6]
  ADD     R5, R5, R6

  LDR     R6, =pressCount
  LDR     R6, [R6]
  ADD     R5, R5, R6

  STR     R5, [R4]

  BL      StartNewRound
  B       .Lbranch


.Lbranch:
  @ Clear SysTick interrupt
  LDR     R4, =SCB_ICSR
  LDR     R5, =SCB_ICSR_PENDSTCLR
  STR     R5, [R4]

  POP  {R3, R4, R5, R6, R7, PC}



@ New round
@ Reset and generate pattern
StartNewRound:
  PUSH    {R4-R7, LR}

  BL      TurnOffAllLeds

  @ Clear state
  MOV     R5, #0
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
  LDR     R4, =showState
  STR     R5, [R4]
  LDR     R4, =stepIndex
  STR     R5, [R4]
  LDR     R4, =resultArmed
  STR     R5, [R4]

  @ Make random pattern
  BL      GeneratePattern

  @ TargetCount = stepCount
  LDR     R4, =stepCount
  LDR     R5, [R4]
  LDR     R4, =targetCount
  STR     R5, [R4]

  @ Start first gap before first led
  LDR     R4, =countdown
  LDR     R5, =LED_GAP_TICKS
  STR     R5, [R4]

  POP     {R4-R7, PC}

.LgenRandom:
@ Generate random pattern
  PUSH    {R4-R7, LR}

  @ Seed = seed*5 + 3
  LDR     R4, =seed
  LDR     R5, [R4]
  ADD     R5, R5, R5, LSL #2
  ADD     R5, R5, #3
  STR     R5, [R4]

  @ StepCount = 5..10
  AND     R6, R5, #0x7
  CMP     R6, #5
  BLE     .LstepOk
  SUB     R6, R6, #2
.LstepOk:
  ADD     R6, R6, #5
  LDR     R4, =stepCount
  STR     R6, [R4]

  @ fill pattern array
  MOV     R7, #0
.LpatternLoop:
  CMP     R7, R6
  BGE     .LpatternDone

  @ Seed = seed*5 + 1
  LDR     R4, =seed
  LDR     R5, [R4]
  ADD     R5, R5, R5, LSL #2
  ADD     R5, R5, #1
  STR     R5, [R4]

  @ Led code = 0..3
  AND     R5, R5, #0x3

  LDR     R4, =pattern
  STR     R5, [R4, R7, LSL #2]

  ADD     R7, R7, #1
  B       .LpatternLoop

.LpatternDone:
  POP     {R4-R7, PC}


@ R0 = led code
@ 0 -> LD5
@ 1 -> LD6
@ 2 -> LD7
@ 3 -> LD8
ShowLedFromCode:
  PUSH    {R4, R5, LR}

  LDR     R4, =GPIOE_ODR
  LDR     R5, [R4]

  CMP     R0, #0
  BNE     .Lcheck1
  ORR     R5, R5, #(1 << LD5_PIN)
  B       .LshowDone

.Lcheck1:
  CMP     R0, #1
  BNE     .Lcheck2
  ORR     R5, R5, #(1 << LD6_PIN)
  B       .LshowDone

.Lcheck2:
  CMP     R0, #2
  BNE     .Lcheck3
  ORR     R5, R5, #(1 << LD7_PIN)
  B       .LshowDone

.Lcheck3:
  ORR     R5, R5, #(1 << LD8_PIN)

.LshowDone:
  STR     R5, [R4]
  POP     {R4, R5, PC}


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
  .word 0        @ Timer for show phase

targetCount:
  .word 0        @ How many leds player should count

pressCount:
  .word 0        @ How many times player pressed

waitingInput:
  .word 0        @ 0 = showing leds, 1 = player input

buttonPrev:
  .word 0        @ Old blue button state

holdCount:
  .word 0        @ How long blue button is held

gameResult:
  .word 0        @ 0 = playing, 1 = win, 2 = lose

seed:
  .word 0        @ Small random seed

tickCount:
  .word 0        @ Keeps increasing, used to mix random seed

stepCount:
  .word 0        @ How many leds this round (5 to 10)

stepIndex:
  .word 0        @ Current step while showing pattern

showState:
  .word 0        @ 0 = gap, 1 = led currently on

resultArmed:
  .word 0        @ Must release after result before next round

pattern:
  .space 40      @ 10 words max

  .end
