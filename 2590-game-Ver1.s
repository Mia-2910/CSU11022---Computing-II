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

  .section .text
  .type Main, %function
Main:
  PUSH    {R4-R5,LR}

  @ Enable GPIO port E by enabling its clock
  @ STM32F303 Reference Manual 9.4.6 (pg. 148)
  LDR     R4, =RCC_AHBENR
  LDR     R5, [R4]
  ORR     R5, R5, #(0b1 << (RCC_AHBENR_GPIOEEN_BIT))
  STR     R5, [R4]

  @ We'll blink LED LD3 (the orange LED)

  @ Configure LD3 for output
  @ by setting bits 27:26 of GPIOE_MODER to 01 (GPIO Port E Mode Register)
  @ (by BIClearing then ORRing)
  @ STM32F303 Reference Manual 11.4.1 (pg. 237)
  LDR     R4, =GPIOE_MODER
  LDR     R5, [R4]                  @ Read ...
  BIC     R5, #(0b11<<(LD3_PIN*2))  @ Modify ...
  ORR     R5, #(0b01<<(LD3_PIN*2))  @ write 01 to bits led3
  STR     R5, [R4]                  @ Write 
  LDR     R5, [R4] 
  BIC     R5, #(0b11<<(LD4_PIN*2))  @ Modify ...
  ORR     R5, #(0b01<<(LD4_PIN*2))  @ write 01 to bits led4
  STR     R5, [R4]                  @ Write 
  LDR     R5, [R4] 
  BIC     R5, #(0b11<<(LD6_PIN*2))  @ Modify ...
  ORR     R5, #(0b01<<(LD6_PIN*2))  @ write 01 to bits led6
  STR     R5, [R4]                  @ Write 
  LDR     R5, [R4] 
  BIC     R5, #(0b11<<(LD8_PIN*2))  @ Modify ...
  ORR     R5, #(0b01<<(LD8_PIN*2))  @ write 01 to bits led8
  STR     R5, [R4]                  @ Write 
  LDR     R5, [R4] 
  BIC     R5, #(0b11<<(LD10_PIN*2))  @ Modify ...
  ORR     R5, #(0b01<<(LD10_PIN*2))  @ write 01 to bits led10
  STR     R5, [R4]                  @ Write 
  LDR     R5, [R4] 
  BIC     R5, #(0b11<<(LD9_PIN*2))  @ Modify ...
  ORR     R5, #(0b01<<(LD9_PIN*2))  @ write 01 to bits led9
  STR     R5, [R4]                  @ Write 
  LDR     R5, [R4] 
  BIC     R5, #(0b11<<(LD7_PIN*2))  @ Modify ...
  ORR     R5, #(0b01<<(LD7_PIN*2))  @ write 01 to bits led7
  STR     R5, [R4]                  @ Write 
  LDR     R5, [R4] 
  BIC     R5, #(0b11<<(LD5_PIN*2))  @ Modify ...
  ORR     R5, #(0b01<<(LD5_PIN*2))  @ write 01 to bits led5
  STR     R5, [R4]                  @ Write 

  @ We'll blink LED LD3 (the orange LED) every 1s
  @ Initialise the first countdown to 1000 (1000ms)
  LDR     R4, =countdown
  LDR     R5, =BLINK_PERIOD
  STR     R5, [R4]  


  @ Configure SysTick Timer to generate an interrupt every 1ms

  @ STM32 Cortex-M4 Programming Manual 4.4.3 (pg. 225)
  LDR     R4, =SCB_ICSR             @ Clear any pre-existing interrupts
  LDR     R5, =SCB_ICSR_PENDSTCLR   @
  STR     R5, [R4]                  @

  @ STM32 Cortex-M4 Programming Manual 4.5.1 (pg. 247)
  LDR   R4, =SYSTICK_CSR            @ Stop SysTick timer
  LDR   R5, =0                      @   by writing 0 to CSR
  STR   R5, [R4]                    @   CSR is the Control and Status Register
  
  @ STM32 Cortex-M4 Programming Manual 4.5.2 (pg. 248)
  LDR   R4, =SYSTICK_LOAD           @ Set SysTick LOAD for 1ms delay
  LDR   R5, =2000                   @ Assuming 8MHz clock.  // smaller it get faster it be 
  STR   R5, [R4]                    @ 

  @ STM32 Cortex-M4 Programming Manual 4.5.3 (pg. 249)
  LDR   R4, =SYSTICK_VAL            @   Reset SysTick internal counter to 0
  LDR   R5, =0x1                    @     by writing any value
  STR   R5, [R4]

  @ STM32 Cortex-M4 Programming Manual 4.4.3 (pg. 225)
  LDR   R4, =SYSTICK_CSR            @   Start SysTick timer by setting CSR to 0x7
  LDR   R5, =0x7                    @     set CLKSOURCE (bit 2) to system clock (1)
  STR   R5, [R4]                    @     set TICKINT (bit 1) to 1 to enable interrupts
                                    @     set ENABLE (bit 0) to 1

  @ Nothing else to do in Main
  @ Idle loop forever (welcome to interrupts!!)
Idle_Loop:
  B     Idle_Loop
  
End_Main:
  POP   {R4-R5,PC}




@
@ SysTick interrupt handler
@
  .type  SysTick_Handler, %function
  @ intialize level

SysTick_Handler:
  PUSH    {R3, R4, R5, R6, LR}

  LDR   R2, =level
  LDR   R3, [R2]        @ load current level into R3
  CMP   R3, #0
  BEQ   .LStart
  /* This part create infinate loop if do 2 level
  CMP   R3, #1
  BEQ   .LLevel2Speed
 
 
//.LLevel2Speed:
STM32 Cortex-M4 Programming Manual 4.5.2 (pg. 248)
  LDR   R4, =SYSTICK_LOAD           @ Set SysTick
  LDR   R5, =4000                   @ Assuming 8MHz clock.  // smaller it get faster it be 
  STR   R5, [R4] 
@Reset the clock 
  LDR     R4, = countdown           @ Update countDown when moving to level 2 + finish checking userInput
  LDR     R5, =BLINK_PERIOD         @ countdown = BLINK_PERIOD;
  STR     R5, [R4] 
*/                 @
.LStart:

  LDR   R4, =countdown              
  LDR   R5, [R4]                   
                                  
  LDR   R6, =9000
  CMP   R5, R6
  BEQ    .LelseFireLD6
 
  LDR   R6, =8000
  CMP   R5, R6
  BEQ    .LelseFireLD10
  
  LDR   R6, =7000
  CMP   R5, R6
  BEQ    .LelseFireLD7

  LDR   R6, =6000
  CMP   R5, R6
  BEQ    .LelseFireLD5
 
  LDR   R6, =5000
  CMP   R5, R6
  BEQ    .LelseFireLD8

  LDR   R6, =4000
  CMP   R5, R6
  BEQ    .LelseFireLD9

  LDR   R6, =2000
  CMP   R5, R6
  BEQ    .LwaitUserInput

  SUB   R5, R5, #1                  
  STR   R5, [R4]                    

  B     .LendIfDelay                

.LelseFireLD6:                      
  @ STM32F303 Reference Manual 11.4.
  LDR     R4, =GPIOE_ODR            
  LDR     R5, [R4]                  
  BIC     R5, R5, #(1 << LD9_PIN)           @ clear bit for LED9 (turn off previous)
  EOR     R5, #(0b1<<(LD6_PIN))             @ set bit for LED6  (turn on new led)
  STR     R5, [R4]

  LDR     R4, =countdown            
  LDR     R5, =8999  @
  STR     R5, [R4]                  
  B       .LendIfDelay
.LelseFireLD10:                     
  @ STM32F303 Reference Manual 11.4.
  LDR     R4, =GPIOE_ODR            
  LDR     R5, [R4]                  
  BIC     R5, R5, #(1 << LD6_PIN)   
  EOR     R5, #(0b1<<(LD10_PIN))     
  STR     R5, [R4]
  LDR     R4, =countdown            
  LDR     R5, =7999  @
  STR     R5, [R4]                  
  B       .LendIfDelay
.LelseFireLD7:                      
  @ STM32F303 Reference Manual 11.4.
  LDR     R4, =GPIOE_ODR            
  LDR     R5, [R4]                  
  BIC     R5, R5, #(1 << LD10_PIN)  
  EOR     R5, #(0b1<<(LD7_PIN))     
  STR     R5, [R4]
  LDR     R4, =countdown            
  LDR     R5, =6999  @
  STR     R5, [R4]                  
  B       .LendIfDelay
.LelseFireLD5:                      
  @ STM32F303 Reference Manual 11.4.
  LDR     R4, =GPIOE_ODR            
  LDR     R5, [R4]                  
  BIC     R5, R5, #(1 << LD7_PIN)   
  EOR     R5, #(0b1<<(LD5_PIN))     
  STR     R5, [R4]
  LDR     R4, =countdown            
  LDR     R5, =5999  @
  STR     R5, [R4]                  
  B       .LendIfDelay
.LelseFireLD8:                      
  @ STM32F303 Reference Manual 11.4.
  LDR     R4, =GPIOE_ODR            
  LDR     R5, [R4]                  
  BIC     R5, R5, #(1 << LD5_PIN)   
  EOR     R5, #(0b1<<(LD8_PIN))     
  STR     R5, [R4]
  LDR     R4, =countdown            
  LDR     R5, =4999  @
  STR     R5, [R4]                  
  B       .LendIfDelay

.LelseFireLD9:                      
  @ STM32F303 Reference Manual 11.4.
  LDR     R4, =GPIOE_ODR            
  LDR     R5, [R4]                  
  BIC     R5, R5, #(1 << LD8_PIN)   
  EOR     R5, #(0b1<<(LD9_PIN))  á  
  STR     R5, [R4]

  LDR     R4, =countdown 
  LDR     R5, =3999  
  STR     R5, [R4]                  
  B       .LendIfDelay
 
.LendIfDelay:                       
  LDR     R4, =countdown         @ 
  LDR     R5, [R4]                    
  CMP     R5, #0  
  BNE     .Lbranch
  LDR     R5, =BLINK_PERIOD      @
  STR     R5, [R4]               @ havent reset coundown, not really need
 
.LwaitUserInput:
  //Minh ..... (might using EXTI0_IRQHandle for button click. Or set a flag 
  //            then subroutine: wait 5 seconds for user to press, then check userPress.
  //            After that update the ;eve;)
  // If cannot figure out how to check user input of 2 level; just do 1 level
  // delete everythings related to R2

@ If you can figure out how to do 2 level,  give up with it
@ .LupdateLevel:
@   LDR   R3, [R2]                  @ if (level == 0)
@   CMP   R3, #0                    @   {level +=1 }
@   BNE   .LBacktoLevel1            @ else                              
@   ADD   R3, R3, #1                @   {levle = 0}
@   STR   R3, [R2]                 
@   B       .LendIfDelay
@ .LBacktoLevel1:                  
@   MOV    R3, #0                  
@   STR    R3, [R2]

.Lbranch:
  @ STM32 Cortex-M4 Programming Manual 4.4.3 (pg. 225)
  LDR     R4, =SCB_ICSR             @ Clear (acknowledge) the interrupt
  LDR     R5, =SCB_ICSR_PENDSTCLR   @
  STR     R5, [R4]                  @

  @ Return from interrupt handler
  POP  {R3, R4, R5, R6, PC}

EXTI0_IRQHandler:

@ check unserinput
@ blinky all red if wrong
@ blinkey all blue / all led rainbow if right





  .section .data

countdown:
  .space  4
level:
    .word 0        @ current level, initialized to 0 @ deleat this if dont do 2 level



  .end
