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
