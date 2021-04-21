# Snake game
A simple snake game in pure ARM Assembly for Raspberry Pi. No C functions called, I/O is done using direct system calls.
Confirmed to run also on some Android devices (Samsung S10). Note that you should change the delay_ticks variable depending on the
speed of the device you are running it on (e.g., 230 000 000 for Raspberry Pi 3, and 800 000 000 for S10).

![Snake game](https://github.com/haperofi/asm_snake/blob/main/giffed_snake.gif)

The snake is always moving forward, but you can change the
direction with wasd keys to aim for different bugs, which you can eat. With each bug, your snake grows
in length, until you are too long and collide with a wall or yourself.

Compile with:
```
as mato.s -o temp.o
ld temp.o -o mato
```
and run:
```
./mato
```
Some interesting features:
* Using ANSI ASCII colors!
* Producing random number seeds with system call to Linux gettimeofday
* Pseudo random number generator
* SVC system calls to read and write data
* Getting immediate, input from keyboard in Linux using ioctl syscalls and termios configuration structures (this was by far the hardest part in the game)
  * kbhit (wait for any key)
  * "getch"-type check the keyboard buffer for possible input


## Running on Android
To run the assembly program on Android devices, you need the NDK library. Follow instructions here: https://urish.medium.com/writing-your-first-android-app-in-assembly-30e8e0f8c3fe
You can then run the program on the phone with a terminal app, e.g., Termux. After pushing the file into /data/local/tmp/ (see link above), you must copy the program to the Termux home directory (in Termux), so Termux has the permission to run it:

```
cp /data/local/tmp/mato .
```
and run:
```
./mato
```

