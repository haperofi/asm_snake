# Snake game
A simple snake game in pure ARM Assembly for Raspberry Pi. No C functions called, I/O is done using direct system calls.

![Snake game](https://github.com/haperofi/asm_snake/blob/main/giffed_snake.gif)

The snake is always moving forward, but you can change the
direction with wasd keys to aim for different bugs, which you can eat. With each bug, your snake grows
in length, until you are too long and collide with a wall or yourself.

Compile with:
```
as mato.s -o temp.o
gcc temp.o -o mato
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

