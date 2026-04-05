# CSU11022 — Computing II

## LED Counting Game — Functionality and Implementation

## 1. Overview

This program is a simple LED counting game made for the STM32F3 Discovery board.

In each round, the board shows a random sequence of LEDs. The player must count how many times LEDs appear in that sequence.

After the sequence finishes:

- a **short press** on the blue button counts as **+1**
- a **long hold** on the blue button means **submit answer**

If the number entered by the player matches the number of LEDs shown, the player wins. If it does not match, the player loses.

After the result is shown, the player can hold the blue button again to start a new random round.

## 2. Main Features

### 2.1 Random LED sequence

At the start of each round, the program creates a new random LED pattern.

- The sequence length is random
- It is always between **5 and 10 steps**
- Each step chooses one LED from a small set of LEDs used in the game

This makes each round different and prevents the game from always showing the same pattern.

### 2.2 LED display

The board shows the sequence one step at a time.

For each step:

- one LED turns on
- it stays on for a short time
- then it turns off
- then the next step is shown

This is how the player sees the pattern and counts the total number of flashes.

### 2.3 Player input

After the LED sequence is finished, the program waits for the player’s answer.

The blue button is used in two ways:

- **Short press** → add 1 to the player’s answer
- **Long hold** → submit the answer

Example:

If the player thinks the sequence had 7 flashes, they press the blue button 7 times, then hold it to submit.

### 2.4 Result checking

When the player submits the answer, the program compares:

- the real number of LED flashes
- the number entered by the player

If both numbers are the same:

- the player wins

If they are different:

- the player loses

### 2.5 Result display

The board uses LEDs to show whether the answer was correct or wrong.

- **Correct answer** → green/blue LEDs are shown
- **Wrong answer** → red/orange LEDs are shown

This gives clear visual feedback to the player.

### 2.6 Start next round

After showing the result, the program waits for the player to start a new round.

To avoid skipping the result too quickly:

- the player must first **release** the blue button
- then **hold it again** to start the next round

This makes sure the result stays visible long enough.

## 3. How Memory-Mapped I/O is used

This project uses **memory-mapped I/O** to control the hardware directly.

That means the program reads and writes to special memory addresses that are connected to hardware registers.

In this project, memory-mapped I/O is used for:

- **reading the blue button**
- **turning LEDs on and off**

For example:

- GPIO input registers are used to read the current state of the button
- GPIO output registers are used to control LED states

So instead of calling a high-level function, the program directly accesses the hardware through register addresses.

This is one of the key ideas in embedded systems programming.

## 4. How Interrupts are used

This project uses the **SysTick interrupt** to control the whole game.

Instead of writing one big loop that constantly checks everything, the program lets the SysTick timer interrupt run repeatedly.

Every time the interrupt happens, the program updates the game state.

Inside `SysTick_Handler`, the program can:

- update timers
- show the next LED in the pattern
- read the button
- detect short press or long hold
- check the answer
- move to the next round

This means the game is **interrupt-based**, not just a simple polling loop in `main`.

That makes the program more organised and closer to how real embedded systems are usually structured.

## 5. Main variables used in the program

Some important variables in the program are:

- `countdown`  
  Used as a timer during the LED show phase

- `targetCount`  
  Stores how many LED flashes were shown in the current round

- `pressCount`  
  Stores how many short presses the player has made

- `waitingInput`  
  Tells whether the program is still showing LEDs or already waiting for player input

- `holdCount`  
  Counts how long the blue button is being held

- `gameResult`  
  Stores the result of the round  
  - `0` = game still running  
  - `1` = win  
  - `2` = lose

- `seed`  
  Used to help generate the next random pattern

- `stepCount`  
  Stores how many LED steps are in the current round

- `stepIndex`  
  Tracks which step is currently being shown

- `pattern`  
  Stores the generated LED pattern for the round

## 6. Subroutines used

The program also uses small subroutines to make the code cleaner.

Examples include:

- `StartNewRound`  
  Clears old state and creates a new random round

- `GeneratePattern`  
  Generates the random sequence of LEDs

- `ShowLedFromCode`  
  Turns on the correct LED based on the pattern value

- `TurnOffAllLeds`  
  Turns all LEDs off

These subroutines make the program easier to organise and easier to read.

## 7. Summary

In summary, this project implements a simple embedded game using the STM32F3 Discovery board.

The program includes:

- random LED sequence generation
- LED output control
- blue button input handling
- short press and long hold logic
- answer checking
- win/lose result display
- starting new random rounds

The project is implemented using:

- **Memory-Mapped I/O** for hardware access
- **Interrupts** (`SysTick_Handler`) for timing and game control

This shows how embedded systems can combine direct hardware control and interrupt-based logic to create an interactive program.




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


