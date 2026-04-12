// Recreate with hard code level lights
  .syntax unified
  .cpu cortex-m4
  .fpu softvfp
  .thumb
  
  .global  Main
  .global  SysTick_Handler

  @ keep hardware defs here
  #include "definitions.S"

  .equ    LED_ON_TICKS,     1800      @ how long one led stays on
  .equ    LED_GAP_TICKS,    1200      @ gap between leds
  .equ    HOLD_LIMIT,       2000      @ hold blue button to submit / next round
  .equ    GPIOA_IDR,        0x48000010

  .section .text
  .type Main, %function

@ main setup:
@ - enable GPIO for LEDs and blue button
@ - initialise game variables
@ - start SysTick interrupt

Main:
  PUSH    {R4-R7,LR}

  @ enable GPIO clocks for memory-mapped I/O
  @ GPIOE -> LEDs, GPIOA -> blue button
  LDR     R4, =RCC_AHBENR               @ RCC_AHBENR |= (1 << GPIOEEN_BIT);
  LDR     R5, [R4]                      @
  ORR     R5, R5, #(0b1 << RCC_AHBENR_GPIOEEN_BIT) @
  ORR     R5, R5, #(0b1 << 17)          @ RCC_AHBENR |= (1 << 17); // Enable GPIOA
  STR     R5, [R4]                      @

  @ configure LED pins as output using GPIO registers
  LDR     R4, =GPIOE_MODER              @

  LDR     R5, [R4]                      @ GPIOE_MODER = (GPIOE_MODER & ~(3<<LD3_PIN*2))
  BIC     R5, #(0b11<<(LD3_PIN*2))      @               | (1<<LD3_PIN*2);
  ORR     R5, #(0b01<<(LD3_PIN*2))      @
  STR     R5, [R4]                      @

  LDR     R5, [R4]                      @ GPIOE_MODER = (GPIOE_MODER & ~(3<<LD4_PIN*2))
  BIC     R5, #(0b11<<(LD4_PIN*2))      @               | (1<<LD4_PIN*2);
  ORR     R5, #(0b01<<(LD4_PIN*2))      @
  STR     R5, [R4]                      @

  LDR     R5, [R4]                      @ GPIOE_MODER = (GPIOE_MODER & ~(3<<LD5_PIN*2))
  BIC     R5, #(0b11<<(LD5_PIN*2))      @               | (1<<LD5_PIN*2);
  ORR     R5, #(0b01<<(LD5_PIN*2))      @
  STR     R5, [R4]                      @

  LDR     R5, [R4]                      @ GPIOE_MODER = (GPIOE_MODER & ~(3<<LD6_PIN*2))
  BIC     R5, #(0b11<<(LD6_PIN*2))      @               | (1<<LD6_PIN*2);
  ORR     R5, #(0b01<<(LD6_PIN*2))      @
  STR     R5, [R4]                      @

  LDR     R5, [R4]                      @ GPIOE_MODER = (GPIOE_MODER & ~(3<<LD7_PIN*2))
  BIC     R5, #(0b11<<(LD7_PIN*2))      @               | (1<<LD7_PIN*2);
  ORR     R5, #(0b01<<(LD7_PIN*2))      @
  STR     R5, [R4]                      @

  LDR     R5, [R4]                      @ GPIOE_MODER = (GPIOE_MODER & ~(3<<LD8_PIN*2))
  BIC     R5, #(0b11<<(LD8_PIN*2))      @               | (1<<LD8_PIN*2);
  ORR     R5, #(0b01<<(LD8_PIN*2))      @
  STR     R5, [R4]                      @

  LDR     R5, [R4]                      @ GPIOE_MODER = (GPIOE_MODER & ~(3<<LD9_PIN*2))
  BIC     R5, #(0b11<<(LD9_PIN*2))      @               | (1<<LD9_PIN*2);
  ORR     R5, #(0b01<<(LD9_PIN*2))      @
  STR     R5, [R4]                      @

  LDR     R5, [R4]                      @ GPIOE_MODER = (GPIOE_MODER & ~(3<<LD10_PIN*2))
  BIC     R5, #(0b11<<(LD10_PIN*2))     @               | (1<<LD10_PIN*2);
  ORR     R5, #(0b01<<(LD10_PIN*2))     @
  STR     R5, [R4]                      @

  @ start with leds off
  BL      TurnOffAllLeds                @ TurnOffAllLeds();

  @ init seed
  LDR     R4, =seed                     @ seed = 7;
  LDR     R5, =7                        @
  STR     R5, [R4]                      @

  @ init vars
  MOV     R5, #0                        @ 
  LDR     R4, =buttonPrev               @ buttonPrev = 0;
  STR     R5, [R4]                      @
  LDR     R4, =holdCount                @ holdCount = 0;
  STR     R5, [R4]                      @
  LDR     R4, =gameResult               @ gameResult = 0;
  STR     R5, [R4]                      @
  LDR     R4, =resultArmed              @ resultArmed = 0;
  STR     R5, [R4]                      @
  LDR     R4, =tickCount                @ tickCount = 0;
  STR     R5, [R4]                      @

  @ configure SysTick interrupt
  @ game logic runs inside SysTick_Handler
  LDR     R4, =SCB_ICSR                 @ SCB_ICSR = SCB_ICSR_PENDSTCLR;
  LDR     R5, =SCB_ICSR_PENDSTCLR       @
  STR     R5, [R4]                      @

  LDR     R4, =SYSTICK_CSR              @ SYSTICK_CSR = 0;
  LDR     R5, =0                        @
  STR     R5, [R4]                      @

  LDR     R4, =SYSTICK_LOAD             @ SYSTICK_LOAD = 1400;
  LDR     R5, =1400          @ bigger = slower
  STR     R5, [R4]                      @

  LDR     R4, =SYSTICK_VAL              @ SYSTICK_VAL = 1;
  LDR     R5, =0x1                      @
  STR     R5, [R4]                      @

  LDR     R4, =SYSTICK_CSR              @ SYSTICK_CSR = 0x7;
  LDR     R5, =0x7                      @
  STR     R5, [R4]                      @

  @ make first round
  BL      StartNewRound                 @ StartNewRound();

Idle_Loop:
  B       Idle_Loop                     @ while(1) {}
  
End_Main:
  POP     {R4-R7,PC}


@ game loop (runs in SysTick)
@ - show LED pattern
@ - read button input
@ - check result
@ - start next round

  .type  SysTick_Handler, %function

SysTick_Handler:
  PUSH    {R3, R4, R5, R6, R7, LR}

  @ free running counter for better random seed
  LDR     R4, =tickCount                @ tickCount = tickCount + 1;
  LDR     R5, [R4]                      @
  ADD     R5, R5, #1                    @
  STR     R5, [R4]                      @

  @ if already win/lose, wait for next-round input
  LDR   R4, =gameResult                 @ if (gameResult != 0) {
  LDR   R5, [R4]                        @
  CMP   R5, #0                          @
  BNE   .LResultState                   @     goto .LResultState; }

  @ if waiting for user answer, handle input
  LDR   R4, =waitingInput               @ else if (waitingInput == 1) {
  LDR   R5, [R4]                        @
  CMP   R5, #1                          @
  BEQ   .LHandleInput                   @     goto .LHandleInput; }

  @ otherwise still showing pattern
  B     .LShowPattern                   @ else { goto .LShowPattern; }


@ show pattern step by step
.LShowPattern:
  @ countdown for show phase
  LDR   R4, =countdown                  @ countdown = countdown - 1;
  LDR   R5, [R4]                        @
  SUB   R5, R5, #1                      @
  STR   R5, [R4]                        @
  CMP   R5, #0                          @ if (countdown > 0) {
  BGT   .Lbranch                        @     goto .Lbranch; }

  @ check if led is currently on or off
  LDR   R4, =showState                  @ if (showState == 0) {
  LDR   R5, [R4]                        @
  CMP   R5, #0                          @
  BEQ   .LShowNextStep                  @     goto .LShowNextStep; }

  @ led was on, now turn off and move to next step
  BL      TurnOffAllLeds                @ TurnOffAllLeds();

  LDR     R4, =stepIndex                @ stepIndex = stepIndex + 1;
  LDR     R5, [R4]                      @
  ADD     R5, R5, #1                    @
  STR     R5, [R4]                      @

  LDR     R4, =showState                @ showState = 0;
  MOV     R5, #0                        @
  STR     R5, [R4]                      @

  LDR     R4, =countdown                @ countdown = LED_GAP_TICKS;
  LDR     R5, =LED_GAP_TICKS            @
  STR     R5, [R4]                      @
  B       .Lbranch                      @ goto .Lbranch;


@ show next LED in pattern
.LShowNextStep:
  @ if all steps shown, wait for input
  LDR     R4, =stepIndex                @ if (stepIndex >= stepCount) {
  LDR     R5, [R4]                      @

  LDR     R4, =stepCount                @
  LDR     R6, [R4]                      @

  CMP     R5, R6                        @
  BGE     .LwaitUserInput               @     goto .LwaitUserInput; }

  @ load pattern[stepIndex]
  LDR     R4, =pattern                  @ R0 = pattern[stepIndex];
  LDR     R6, =stepIndex                @
  LDR     R7, [R6]                      @
  LDR     R0, [R4, R7, LSL #2]          @

  BL      TurnOffAllLeds                @ TurnOffAllLeds();
  BL      ShowLedFromCode               @ ShowLedFromCode(R0);

  LDR     R4, =showState                @ showState = 1;
  MOV     R5, #1                        @
  STR     R5, [R4]                      @

  LDR     R4, =countdown                @ countdown = LED_ON_TICKS;
  LDR     R5, =LED_ON_TICKS             @
  STR     R5, [R4]                      @
  B       .Lbranch                      @ goto .Lbranch;


.LwaitUserInput:
  @ wait for player input
  @ short press = +1, long hold = submit
  LDR     R4, =waitingInput             @ waitingInput = 1;
  MOV     R5, #1                        @
  STR     R5, [R4]                      @

  LDR     R4, =pressCount               @ pressCount = 0;
  MOV     R5, #0                        @
  STR     R5, [R4]                      @

  LDR     R4, =buttonPrev               @ buttonPrev = 0;
  MOV     R5, #0                        @
  STR     R5, [R4]                      @

  LDR     R4, =holdCount                @ holdCount = 0;
  MOV     R5, #0                        @
  STR     R5, [R4]                      @

  BL      TurnOffAllLeds                @ TurnOffAllLeds();
  B       .Lbranch                      @ goto .Lbranch;


.LHandleInput:
  @ read button
  @ detect press or hold
  LDR     R4, =GPIOA_IDR                @ R5 = GPIOA_IDR & 1; // Read button
  LDR     R5, [R4]                      @
  AND     R5, R5, #1                    @

  LDR     R4, =buttonPrev               @ R6 = buttonPrev;
  LDR     R6, [R4]                      @

  CMP     R5, #0                        @ if (button == 0) {
  BEQ     .LReleased                    @     goto .LReleased; }

  @ if button is being held
  CMP     R6, #1                        @ if (buttonPrev == 1) {
  BEQ     .LStillHeld                   @     goto .LStillHeld; }

  @ new press starts here
  LDR     R4, =buttonPrev               @ buttonPrev = 1;
  MOV     R6, #1                        @
  STR     R6, [R4]                      @

  LDR     R4, =holdCount                @ holdCount = 0;
  MOV     R6, #0                        @
  STR     R6, [R4]                      @
  B       .Lbranch                      @ goto .Lbranch;

.LStillHeld:
  LDR     R4, =holdCount                @ holdCount = holdCount + 1;
  LDR     R6, [R4]                      @
  ADD     R6, R6, #1                    @
  STR     R6, [R4]                      @

  LDR     R3, =HOLD_LIMIT               @ if (holdCount >= HOLD_LIMIT) {
  CMP     R6, R3                        @
  BGE     .LJudgeResult                 @     goto .LJudgeResult; }
  B       .Lbranch                      @ goto .Lbranch;

.LReleased:
  @ no old press -> nothing to do
  CMP     R6, #1                        @ if (buttonPrev != 1) {
  BNE     .Lbranch                      @     goto .Lbranch; }

  @ if release before hold limit -> count 1 press
  LDR     R4, =holdCount                @ if (holdCount >= HOLD_LIMIT) {
  LDR     R6, [R4]                      @     goto .LCleanInput; }
  LDR     R3, =HOLD_LIMIT               @
  CMP     R6, R3                        @
  BGE     .LCleanInput                  @

  LDR     R4, =pressCount               @ pressCount = pressCount + 1;
  LDR     R6, [R4]                      @
  ADD     R6, R6, #1                    @
  STR     R6, [R4]                      @

.LCleanInput:
  LDR     R4, =buttonPrev               @ buttonPrev = 0;
  MOV     R6, #0                        @
  STR     R6, [R4]                      @

  LDR     R4, =holdCount                @ holdCount = 0;
  MOV     R6, #0                        @
  STR     R6, [R4]                      @
  B       .Lbranch                      @ goto .Lbranch;


@ check result
.LJudgeResult:
  LDR     R4, =waitingInput             @ waitingInput = 0;
  MOV     R5, #0                        @
  STR     R5, [R4]                      @

  LDR     R4, =pressCount               @ R5 = pressCount;
  LDR     R5, [R4]                      @

  LDR     R4, =targetCount              @ R6 = targetCount;
  LDR     R6, [R4]                      @

  CMP     R5, R6                        @ if (pressCount == targetCount) {
  BEQ     .LPlayerWin                   @     goto .LPlayerWin; }
  B       .LPlayerLose                  @ else { goto .LPlayerLose; }


.LPlayerWin:
  @ correct answer
  LDR     R4, =gameResult               @ gameResult = 1;
  MOV     R5, #1                        @
  STR     R5, [R4]                      @

  @ force release before next round
  LDR     R4, =holdCount                @ holdCount = 0;
  MOV     R5, #0                        @
  STR     R5, [R4]                      @

  LDR     R4, =buttonPrev               @ buttonPrev = 0;
  MOV     R5, #0                        @
  STR     R5, [R4]                      @

  LDR     R4, =resultArmed              @ resultArmed = 0;
  MOV     R5, #0                        @
  STR     R5, [R4]                      @

  BL      TurnOffAllLeds                @ TurnOffAllLeds();
  LDR     R4, =GPIOE_ODR                @ GPIOE_ODR |= (1<<LD4) | (1<<LD6)
  LDR     R5, [R4]                      @              | (1<<LD7) | (1<<LD9);
  ORR     R5, R5, #(1 << LD4_PIN)       @
  ORR     R5, R5, #(1 << LD6_PIN)       @
  ORR     R5, R5, #(1 << LD7_PIN)       @
  ORR     R5, R5, #(1 << LD9_PIN)       @
  STR     R5, [R4]                      @
  B       .Lbranch                      @ goto .Lbranch;


.LPlayerLose:
  @ wrong answer
  LDR     R4, =gameResult               @ gameResult = 2;
  MOV     R5, #2                        @
  STR     R5, [R4]                      @

  @ force release before next round
  LDR     R4, =holdCount                @ holdCount = 0;
  MOV     R5, #0                        @
  STR     R5, [R4]                      @

  LDR     R4, =buttonPrev               @ buttonPrev = 0;
  MOV     R5, #0                        @
  STR     R5, [R4]                      @

  LDR     R4, =resultArmed              @ resultArmed = 0;
  MOV     R5, #0                        @
  STR     R5, [R4]                      @

  BL      TurnOffAllLeds                @ TurnOffAllLeds();
  LDR     R4, =GPIOE_ODR                @ GPIOE_ODR |= (1<<LD3) | (1<<LD5)
  LDR     R5, [R4]                      @              | (1<<LD8) | (1<<LD10);
  ORR     R5, R5, #(1 << LD3_PIN)       @
  ORR     R5, R5, #(1 << LD5_PIN)       @
  ORR     R5, R5, #(1 << LD8_PIN)       @
  ORR     R5, R5, #(1 << LD10_PIN)      @
  STR     R5, [R4]                      @
  B       .Lbranch                      @ goto .Lbranch;

@ wait for next round input
.LResultState:
  LDR     R4, =GPIOA_IDR                @ R5 = GPIOA_IDR & 1; // Read button
  LDR     R5, [R4]                      @
  AND     R5, R5, #1                    @

  CMP     R5, #0                        @ if (button == 0) {
  BEQ     .LResultReleased              @     goto .LResultReleased; }

  @ if not armed yet, ignore while still holding
  LDR     R4, =resultArmed              @ if (resultArmed != 1) {
  LDR     R6, [R4]                      @     goto .Lbranch; }
  CMP     R6, #1                        @
  BNE     .Lbranch                      @

  @ now count hold for next round
  LDR     R4, =holdCount                @ holdCount = holdCount + 1;
  LDR     R6, [R4]                      @
  ADD     R6, R6, #1                    @
  STR     R6, [R4]                      @

  LDR     R3, =HOLD_LIMIT               @ if (holdCount >= HOLD_LIMIT) {
  CMP     R6, R3                        @     goto .LNextRound; }
  BGE     .LNextRound                   @
  B       .Lbranch                      @ goto .Lbranch;

.LResultReleased:
  @ after result, player must release first
  LDR     R4, =holdCount                @ holdCount = 0;
  MOV     R6, #0                        @
  STR     R6, [R4]                      @

  LDR     R4, =resultArmed              @ resultArmed = 1;
  MOV     R6, #1                        @
  STR     R6, [R4]                      @

  B       .Lbranch                      @ goto .Lbranch;

.LNextRound:
  @ start next round
  LDR     R4, =seed                     @ R5 = seed;
  LDR     R5, [R4]                      @

  LDR     R6, =tickCount                @ R5 = R5 + tickCount;
  LDR     R6, [R6]                      @
  ADD     R5, R5, R6                    @

  LDR     R6, =pressCount               @ R5 = R5 + pressCount;
  LDR     R6, [R6]                      @
  ADD     R5, R5, R6                    @

  STR     R5, [R4]                      @ seed = R5;

  BL      StartNewRound                 @ StartNewRound();
  B       .Lbranch                      @ goto .Lbranch;


.Lbranch:
  @ clear SysTick interrupt
  LDR     R4, =SCB_ICSR                 @ SCB_ICSR = SCB_ICSR_PENDSTCLR;
  LDR     R5, =SCB_ICSR_PENDSTCLR       @
  STR     R5, [R4]                      @

  POP  {R3, R4, R5, R6, R7, PC}



@ new round
@ reset and generate pattern
StartNewRound:
  PUSH    {R4-R7, LR}

  BL      TurnOffAllLeds                @ TurnOffAllLeds();

  @ clear state
  MOV     R5, #0                        @
  LDR     R4, =pressCount               @ pressCount = 0;
  STR     R5, [R4]                      @
  LDR     R4, =waitingInput             @ waitingInput = 0;
  STR     R5, [R4]                      @
  LDR     R4, =buttonPrev               @ buttonPrev = 0;
  STR     R5, [R4]                      @
  LDR     R4, =holdCount                @ holdCount = 0;
  STR     R5, [R4]                      @
  LDR     R4, =gameResult               @ gameResult = 0;
  STR     R5, [R4]                      @
  LDR     R4, =showState                @ showState = 0;
  STR     R5, [R4]                      @
  LDR     R4, =stepIndex                @ stepIndex = 0;
  STR     R5, [R4]                      @
  LDR     R4, =resultArmed              @ resultArmed = 0;
  STR     R5, [R4]                      @

  @ make random pattern
  BL      GeneratePattern               @ GeneratePattern();

  @ targetCount = stepCount
  LDR     R4, =stepCount                @ targetCount = stepCount;
  LDR     R5, [R4]                      @
  LDR     R4, =targetCount              @
  STR     R5, [R4]                      @

  @ start first gap before first led
  LDR     R4, =countdown                @ countdown = LED_GAP_TICKS;
  LDR     R5, =LED_GAP_TICKS            @
  STR     R5, [R4]                      @

  POP     {R4-R7, PC}


@ generate random pattern
GeneratePattern:
  PUSH    {R4-R7, LR}

  @ seed = seed*5 + 3
  LDR     R4, =seed                     @ seed = (seed * 5) + 3;
  LDR     R5, [R4]                      @
  ADD     R5, R5, R5, LSL #2            @
  ADD     R5, R5, #3                    @
  STR     R5, [R4]                      @

  @ stepCount = 5..10
  AND     R6, R5, #0x7                  @ R6 = seed & 0x7;
  CMP     R6, #5                        @ if (R6 <= 5) { goto .LstepOk; }
  BLE     .LstepOk                      @
  SUB     R6, R6, #2                    @ R6 = R6 - 2;
.LstepOk:
  ADD     R6, R6, #5                    @ stepCount = R6 + 5; // Result: 5 to 10
  LDR     R4, =stepCount                @
  STR     R6, [R4]                      @

  @ fill pattern array
  MOV     R7, #0                        @ R7 = 0; // i = 0
.LpatternLoop:
  CMP     R7, R6                        @ if (i >= stepCount) { goto .LpatternDone; }
  BGE     .LpatternDone                 @

  @ seed = seed*5 + 1
  LDR     R4, =seed                     @ seed = (seed * 5) + 1;
  LDR     R5, [R4]                      @
  ADD     R5, R5, R5, LSL #2            @
  ADD     R5, R5, #1                    @
  STR     R5, [R4]                      @

  @ led code = 0..3
  AND     R5, R5, #0x3                  @ R5 = seed & 0x3; // Map to 0..3

  LDR     R4, =pattern                  @ pattern[i] = R5;
  STR     R5, [R4, R7, LSL #2]          @

  ADD     R7, R7, #1                    @ i++;
  B       .LpatternLoop                 @ goto .LpatternLoop;

.LpatternDone:
  POP     {R4-R7, PC}


@ R0 = led code
@ 0 -> LD5
@ 1 -> LD6
@ 2 -> LD7
@ 3 -> LD8
ShowLedFromCode:
  PUSH    {R4, R5, LR}

  LDR     R4, =GPIOE_ODR                @
  LDR     R5, [R4]                      @

  CMP     R0, #0                        @ if (R0 == 0) {
  BNE     .Lcheck1                      @
  ORR     R5, R5, #(1 << LD5_PIN)       @     GPIOE_ODR |= (1 << LD5_PIN);
  B       .LshowDone                    @     goto .LshowDone; }

.Lcheck1:
  CMP     R0, #1                        @ else if (R0 == 1) {
  BNE     .Lcheck2                      @
  ORR     R5, R5, #(1 << LD6_PIN)       @     GPIOE_ODR |= (1 << LD6_PIN);
  B       .LshowDone                    @     goto .LshowDone; }

.Lcheck2:
  CMP     R0, #2                        @ else if (R0 == 2) {
  BNE     .Lcheck3                      @
  ORR     R5, R5, #(1 << LD7_PIN)       @     GPIOE_ODR |= (1 << LD7_PIN);
  B       .LshowDone                    @     goto .LshowDone; }

.Lcheck3:                               @ else {
  ORR     R5, R5, #(1 << LD8_PIN)       @     GPIOE_ODR |= (1 << LD8_PIN); }

.LshowDone:
  STR     R5, [R4]                      @ GPIOE_ODR = R5;
  POP     {R4, R5, PC}


TurnOffAllLeds:
  PUSH    {R4,R5,LR}
  LDR     R4, =GPIOE_ODR                @ GPIOE_ODR &= ~((1<<LD3) | (1<<LD4) ...);
  LDR     R5, [R4]                      @
  BIC     R5, R5, #(1 << LD3_PIN)       @
  BIC     R5, R5, #(1 << LD4_PIN)       @
  BIC     R5, R5, #(1 << LD5_PIN)       @
  BIC     R5, R5, #(1 << LD6_PIN)       @
  BIC     R5, R5, #(1 << LD7_PIN)       @
  BIC     R5, R5, #(1 << LD8_PIN)       @
  BIC     R5, R5, #(1 << LD9_PIN)       @
  BIC     R5, R5, #(1 << LD10_PIN)      @
  STR     R5, [R4]                      @
  POP     {R4,R5,PC}


  .section .data

countdown:
  .word 0        @ timer for show phase

targetCount:
  .word 0        @ how many leds player should count

pressCount:
  .word 0        @ how many times player pressed

waitingInput:
  .word 0        @ 0 = showing leds, 1 = player input

buttonPrev:
  .word 0        @ old blue button state

holdCount:
  .word 0        @ how long blue button is held

gameResult:
  .word 0        @ 0 = playing, 1 = win, 2 = lose

seed:
  .word 0        @ small random seed

tickCount:
  .word 0        @ keeps increasing, used to mix random seed

stepCount:
  .word 0        @ how many leds this round (5 to 10)

stepIndex:
  .word 0        @ current step while showing pattern

showState:
  .word 0        @ 0 = gap, 1 = led currently on

resultArmed:
  .word 0        @ must release after result before next round

pattern:
  .space 40      @ 10 words max

  .end
