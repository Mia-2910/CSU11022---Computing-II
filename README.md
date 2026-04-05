# CSU11022---Computing-II

LED Counting Game – Functionality and Implementation
1. Overview

This program is a simple LED counting game made for the STM32F3 Discovery board.

In each round, the board shows a random sequence of LEDs.
The player must count how many times LEDs appear in that sequence.

After the sequence finishes:

a short press on the blue button counts as +1
a long hold on the blue button means submit answer

If the number entered by the player matches the number of LEDs shown, the player wins.
If it does not match, the player loses.

After the result is shown, the player can hold the blue button again to start a new random round.

2. Main Features
2.1 Random LED sequence

At the start of each round, the program creates a new random LED pattern.

The sequence length is random
It is always between 5 and 10 steps
Each step chooses one LED from a small set of LEDs used in the game

This makes each round different and prevents the game from always showing the same pattern.

2.2 LED display

The board shows the sequence one step at a time.

For each step:

one LED turns on
it stays on for a short time
then it turns off
then the next step is shown

This is how the player sees the pattern and counts the total number of flashes.

2.3 Player input

After the LED sequence is finished, the program waits for the player’s answer.

The blue button is used in two ways:

Short press → add 1 to the player’s answer
Long hold → submit the answer

Example:
If the player thinks the sequence had 7 flashes, they press the blue button 7 times, then hold it to submit.

2.4 Result checking

When the player submits the answer, the program compares:

the real number of LED flashes
the number entered by the player

If both numbers are the same:

the player wins

If they are different:

the player loses
2.5 Result display

The board uses LEDs to show whether the answer was correct or wrong.

Correct answer → green/blue LEDs are shown
Wrong answer → red/orange LEDs are shown

This gives clear visual feedback to the player.

2.6 Start next round

After showing the result, the program waits for the player to start a new round.

To avoid skipping the result too quickly:

the player must first release the blue button
then hold it again to start the next round

This makes sure the result stays visible long enough.

3. How Memory-Mapped I/O is used

This project uses memory-mapped I/O to control the hardware directly.

That means the program reads and writes to special memory addresses that are connected to hardware registers.

In this project, memory-mapped I/O is used for:

reading the blue button
turning LEDs on and off

For example:

GPIO input registers are used to read the current state of the button
GPIO output registers are used to control LED states

So instead of calling a high-level function, the program directly accesses the hardware through register addresses.

This is one of the key ideas in embedded systems programming.

4. How Interrupts are used

This project uses the SysTick interrupt to control the whole game.

Instead of writing one big loop that constantly checks everything, the program lets the SysTick timer interrupt run repeatedly.

Every time the interrupt happens, the program updates the game state.

Inside SysTick_Handler, the program can:

update timers
show the next LED in the pattern
read the button
detect short press or long hold
check the answer
move to the next round

This means the game is interrupt-based, not just a simple polling loop in main.

That makes the program more organised and closer to how real embedded systems are usually structured.

5. Main variables used in the program

Some important variables in the program are:

countdown
Used as a timer during the LED show phase
targetCount
Stores how many LED flashes were shown in the current round
pressCount
Stores how many short presses the player has made
waitingInput
Tells whether the program is still showing LEDs or already waiting for player input
holdCount
Counts how long the blue button is being held
gameResult
Stores the result of the round
0 = game still running
1 = win
2 = lose
seed
Used to help generate the next random pattern
stepCount
Stores how many LED steps are in the current round
stepIndex
Tracks which step is currently being shown
pattern
Stores the generated LED pattern for the round
6. Subroutines used

The program also uses small subroutines to make the code cleaner.

Examples include:

StartNewRound
Clears old state and creates a new random round
GeneratePattern
Generates the random sequence of LEDs
ShowLedFromCode
Turns on the correct LED based on the pattern value
TurnOffAllLeds
Turns all LEDs off

These subroutines make the program easier to organise and easier to read.

7. Summary

In summary, this project implements a simple embedded game using the STM32F3 Discovery board.

The program includes:

random LED sequence generation
LED output control
blue button input handling
short press and long hold logic
answer checking
win/lose result display
starting new random rounds

The project is implemented using:

Memory-Mapped I/O for hardware access
Interrupts (SysTick) for timing and game control

This shows how embedded systems can combine direct hardware control and interrupt-based logic to create an interactive program.
