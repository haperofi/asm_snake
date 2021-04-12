# Snake game
A simple snake game in ARM Assembly for Raspberry Pi.

![Snake game](https://github.com/haperofi/asm_snake/blob/main/snake_armasm_2.png)

You move with wasd as directions and eat different bugs. As you progress, your snake grows
in lenght, until you collide with a wall or yourself.

Needs Ncurses library, get it using:
```
sudo apt-get install libncurses5-dev libncursesw5-dev 
```
Compile with:
```
as mato.s -o temp.o
gcc temp.o -o mato -lncurses
```
and run:
```
./mato
```
