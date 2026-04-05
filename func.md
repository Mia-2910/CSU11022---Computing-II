## Summary Table of Functionality

| Functionality | How it is Implemented | Key Code / Registers |
|---|---|---|
| System Initialisation | Enables GPIO clocks, configures LED pins as outputs, and resets variables | `RCC_AHBENR`, `GPIOE_MODER`, `BL TurnOffAllLeds` |
| Start First Round | Calls a function to reset the game state and generate the first pattern | `BL StartNewRound` |
| SysTick Interrupt Setup | Configures a periodic interrupt to drive the game loop | `SYSTICK_LOAD`, `SYSTICK_CSR = 0x7` |
| Main Game Loop | Runs entirely inside the interrupt handler as a state machine | `SysTick_Handler` |
| Time Tracking | Uses an incrementing counter for timing and randomness | `tickCount` |
| LED Pattern Display | Uses a countdown timer and a state variable to control LED ON/OFF phases | `countdown`, `showState` |
| LED ON Phase | Turns on one LED and keeps it on for a fixed amount of time | `LED_ON_TICKS`, `ShowLedFromCode` |
| LED OFF Phase (Gap) | Turns off LEDs between pattern steps | `LED_GAP_TICKS`, `TurnOffAllLeds` |
| Step Progression | Moves through the pattern array one step at a time | `stepIndex` |
| Pattern Storage | Stores the LED sequence in memory | `pattern[]` |
| Random Pattern Generation | Uses a simple LCG-style update to generate pseudo-random values | `seed = seed * 5 + constant` |
| Pattern Length (5–10) | Generates a pseudo-random number of steps between 5 and 10 | `AND #0x7`, `ADD #5` |
| LED Selection (0–3) | Maps pseudo-random values to specific LEDs used in the game | `AND #0x3`, `ShowLedFromCode` |
| Switch to Input Mode | Enables player input after the pattern display finishes | `waitingInput = 1` |
| Button Input Reading | Reads the button state using memory-mapped input | `GPIOA_IDR` |
| Short Press Detection | Detects a press-and-release before the hold limit and counts it as input | `pressCount++` |
| Long Hold Detection | Counts how long the button is held down | `holdCount`, `CMP HOLD_LIMIT` |
| Answer Submission | Submits the answer when the hold duration exceeds the threshold | `BGE .LJudgeResult` |
| Answer Checking | Compares player input with the correct value | `CMP pressCount, targetCount` |
| Win Condition | Lights specific LEDs when the answer is correct | `GPIOE_ODR`, `LD4`, `LD6`, `LD7`, `LD9` |
| Lose Condition | Lights different LEDs when the answer is incorrect | `GPIOE_ODR`, `LD3`, `LD5`, `LD8`, `LD10` |
| Result State Control | Prevents immediate restart until the button has been released | `resultArmed` |
| Next Round Trigger | Requires button release, then a long hold, to start a new round | `CMP holdCount, HOLD_LIMIT` |
| Seed Update Between Rounds | Mixes timing and input into the seed to vary the next round | `seed += tickCount + pressCount` |
| Reset Game State | Clears state variables for a new round | `StartNewRound` |
| LED Control (Output) | Uses memory-mapped output registers to control LEDs | `GPIOE_ODR`, `ORR`, `BIC` |
| Turn Off All LEDs | Clears all LED bits | `TurnOffAllLeds` |
| Interrupt Clearing | Clears the SysTick interrupt flag each cycle | `SCB_ICSR_PENDSTCLR` |
