# Snake game
A simple snake game in ARM Assembly for Raspberry Pi.

![Snake game](https://github.com/haperofi/asm_snake/blob/main/giffed_snake.gif)

You move with wasd as directions and eat different bugs. As you progress, your snake grows
in length, until you collide with a wall or yourself.

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
* Producing random number seeds with system call to Linux gettimeofday
* Pseudo random number generator
* SVC system calls to read and write data
* Getting immediate, nonblocking input from keyboard in Linux using ioctl syscalls and termios configuration structures (this was by far the hardest part in the game)
  * kbhit (wait for any key)
  * "getch"-type check the keyboard buffer for possible input
* Using ANSI ASCII colors!
