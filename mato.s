.data

.align 4
space: .asciz "   "
empty: .asciz "\033[38;5;130m.\033[0m"	// brown .
snake: .asciz "\033[32m@\033[0m"	// green @
tail: .asciz "\033[32mo\033[0m"		// green 0
border: .asciz "\033[33m#\033[0m"	// yellow #
bug1: .asciz "\033[38;5;199m\244\033[0m"// pink currency sing
bug2: .asciz "\033[38;5;207m~\033[0m"	// pink ~
bug3: .asciz "\033[38;5;165m\272\033[0m"// pink circle
clear_screen: .asciz "\033[2J\n"
move_up: .asciz "\033[1A"
hide_cursor: .asciz "\033[?25l"
show_cursor: .asciz "\033[?25h"
endl: .asciz "\n"
game_over: .asciz "\033[1A Game Over. Score: "
.align 4
map: .skip 600  		// mapxlen*mapylen*4
dx: .word 1			// snake directions
dy: .word 0
headx: .word 3			// snake head coords
heady: .word 3
max_len: .word 0		// snake length
random_seed: .word 0x1234	// updated from gettimeofday
rw_buffer: .skip 100
termios: .skip 100		// terminal input configs
saved_termios: .skip 100
delay_ticks: .word 230000000	// game speed
.equ MAPXLEN, 14
.equ MAPYLEN, 8

.text
.global main

///////////////////////////////////////////////
///////////////////  MAIN  ////////////////////
///////////////////////////////////////////////
main:
	push {r4, lr}

	bl save_termios
	bl init_random_seed
	bl initialize_map

        ldr r0, =hide_cursor
        bl output

game_loop:

	bl move_and_check_collision	// update snake position
	cmp r0, #1			// did collision occur?
	beq the_end

	bl update_and_print_map

	bl check_keypress		// check if key was pressed
					// update dx and dy if needed
	b game_loop			// loop until collision

the_end:
	ldr r0, =game_over
	bl output
	ldr r0, =max_len
	ldr r0, [r0]
	bl output_int
	ldr r0, =endl
	bl output

	bl kbhit		// wait for any key
	bl cooked_mode		// just to be sure, restore termios

        ldr r0, =endl
        bl output
	ldr r0, =show_cursor
	bl output
	pop {r4, lr}
	bx lr

///////////////////////////////////////////////////
/////////////// END MAIN //////////////////////////
///////////////////////////////////////////////////




/////// MOVE AND CHECK SNAKE COLLISION ///////////
// Input: none
// Output: r0, =1 fatal collision, =0 no fatal collision
// Updates headx, heady. If collides with bug, increase max_len
// and go add a new bug
move_and_check_collision:
	push {r4, r5, r6, r7, r8, lr}
	ldr r4, =map

        ldr r1, =headx
        ldr r1, [r1]
        ldr r0, =dx
        ldr r0, [r0]
        add r5, r1, r0		// r5 = headx + dx
        ldr r2, =heady
        ldr r2, [r2]
        ldr r0, =dy
        ldr r0, [r0]
        add r6, r2, r0		// r6 = heady + dy
        mov r0, #MAPXLEN	// get map address for head (r3)
        mul r3, r6, r0
        add r3, r3, r5
        mov r0, #4
        mul r7, r3, r0		// (head) r7 = y*mapxlen + x

        ldr r0, [r4, r7]	// r0 = map point for next step
        cmp r0, #0              // collision to points >0 --> end
        bgt collision
        cmp r0, #-1             // -"- ==-1 --> end
        beq collision
        ldrlt r1, =max_len      // collision to bug --> maxlen++
        ldrlt r0, [r1]
        addlt r0, r0, #1
        strlt r0, [r1]
        bllt add_new_bug	// ...and go add a new bug

        mov r0, #1		// store new head point to map
        str r0, [r4, r7]
        ldr r0, =headx
        str r5, [r0] 		// store new headx
        ldr r0, =heady
        str r6, [r0]    	// store new heady

	mov r0, #0
	b end_move_and_coll
collision:
	mov r0, #1
end_move_and_coll:
	pop {r4, r5, r6, r7, r8, lr}
	bx lr
///////////////////////////////////////////////


/////// PRINT AND UPDATE MAP ///////////////////
// Input: none
// Output: none, updates and prints map
// Map is the main data structure for the game. Snake
// head is 0 ('@'), tail is increasing numbers 1,2,3,.. ('O').
// At each update step, tail is aged, and based on max_len,
// an empty space may be drawn instead: 0 ('.'). Borders
// are -1 ('#'). Different bugs are -2, -3, -4.
update_and_print_map:
	push {r4, r5, r6, r7, r8, lr}
	ldr r6, =map
        ldr r0, =clear_screen
        bl output

        mov r5, #0
mapy_loop:
        mov r4, #0
        cmp r5, #MAPYLEN
        beq end_map_loop
        add r5, r5, #1
	ldr r0, =space
	bl output
mapx_loop:
        cmp r4, #MAPXLEN
        ldreq r0, =endl
        bleq output
        cmp r4, #MAPXLEN
        beq mapy_loop
        add r4, r4, #1

        //// Update and print map point ////
        ldr r7, [r6]            // load map point

        cmp r7, #0              //if point is:
        addgt r0, r7, #1        //>0 --> increase its value +1
        strgt r0, [r6]          //i.e. snake tail get older
        ldreq r0, =empty        //==0 --> '.' to be printed
        cmp r7, #1
        ldreq r0, =snake        //==1 --> '@' head
        ldrgt r0, =tail         //>1 --> '0' tail
        cmp r7, #-1
        ldreq r0, =border       //==-1 --> '#'
        cmp r7, #-2             //==-2 --> '*'
        ldreq r0, =bug1
	cmp r7, #-3             //==-3 --> '~'
        ldreq r0, =bug2
	cmp r7, #-4             //==-4 --> '%'
        ldreq r0, =bug3


        ldr r1, =max_len        // cut tail if its too long
        ldr r1, [r1]
        add r1, r1, #1
        cmp r7, r1
        movgt r0, #0            // >max_len --> reset point to empty
        strgt r0, [r6]
        ldrgt r0, =empty

        bl output               // print the point

        add r6, r6, #4          // next  point in map
        b mapx_loop

end_map_loop:
	ldr r0, =endl
	bl output
	pop {r4, r5, r6, r7, r8, lr}
	bx lr
///////////////////////////////////////////////



/////////// CHECK KEYPRESS and UPDATE DX DY ///
// Input: none
// Output: none, update dx and dy
check_keypress:
	push {r4, r5, r6, lr}

      	bl raw_mode		// key presses are not buffered
      	bl delay
      	bl input
	ldr r4, [r0]
      	bl cooked_mode		// return to normal mode immediately
				// this is overkill, but helps when
				// debugging

      	//bl initscr            // For A LOT easier implementation,
        //bl noecho             // one could use ncurses C-library
        //bl cbreak             //
        //mov r0, #500          // wait 500ms for keypress
        //bl timeout            //
        //bl getch              // ncurses function: get non-blocking
 	//mov r4, r0            // keypress, store in r0
	//bl endwin		//

	cmp r4, #0x73           // 'w'
        moveq r0, #1
        beq update_dxdy

        cmp r4, #0x61           // 'a'
        moveq r0, #2
        beq update_dxdy

        cmp r4, #0x77           // 's'
        moveq r0, #3
        beq update_dxdy

        cmp r4, #0x64           // 'd'
        moveq r0, #4
        beq update_dxdy

	b end_check_keypress

update_dxdy:
	ldr r1, =dx
	ldr r2, =dy

	mov r4, #0	// new dx
	mov r5, #0	// new dy

	cmp r0, #1
        moveq r5, #1

        cmp r0, #2
        moveq r4, #-1

        cmp r0, #3
        moveq r5, #-1

        cmp r0, #4
        moveq r4, #1

	str r4, [r1]
	str r5, [r2]

end_check_keypress:
	pop {r4,r5, r6, lr}
	bx lr
//////////////////////////////////////


////////// INIT MAP /////////////////
// Input: none
// Output: none
// Initialize map values, mainly draw borders.
initialize_map:
	push {r4, lr}

	//horizontal borders//
	ldr r4, =map
	mov r0, #0
	mov r1, #MAPYLEN
	sub r2, r1, #1		// compute offset for bottom row
	mov r1, #MAPXLEN
	mul r2, r2, r1
	mov r1, #4
	mul r2, r2, r1
top_loop:
        cmp r0, #MAPXLEN
        beq end_top_loop
        add r0, r0, #1

	mov r1, #-1
	str r1, [r4]
	str r1, [r4, r2]  	// r2 is the offset for bottom row
	add r4, r4, #4
	b top_loop
end_top_loop:

	//vertical borders//
	ldr r4, =map
	mov r0, #0
        mov r1, #MAPXLEN
        sub r2, r1, #1          // compute offset for left row
	mov r3, #4
	mul r2, r2, r3
        mov r1, #MAPXLEN
        mul r3, r1, r3
side_loop:
	cmp r0, #MAPYLEN
	beq end_side_loop
        add r0, r0, #1

        mov r1, #-1
        str r1, [r4]
        str r1, [r4, r2]  	// r2 is offset for left row
        add r4, r4, r3   	// r3 is offset for next point
        b side_loop
end_side_loop:

	bl add_new_bug

	pop {r4, lr}
	bx lr
////////////////////////////////


////// ADD NEW BUG /////////////
// Input: none
// Output: none
// Adds a new random bug to the map in a random location
add_new_bug:
	push {r4, r5, r6, lr}
	ldr r4, =map
        mov r1, #MAPYLEN
        mov r2, #MAPXLEN
        mul r5, r1, r2          // mapylen*mapxlen
	bl get_random		// r0 = next random
	mov r1, #3
	bl divide		// r0 = r0 % 3
	cmp r0, #0
	moveq r6, #-2		// new bug '*'
	cmp r0, #1
        moveq r6, #-3	        // new bug '~'
        movgt r6, #-4         	// new bug '%'


add_bug_new_try:
	bl get_random		// r0 = next random
	mov r1, r5
	bl divide		// r0 / (mapylen*mapxlen)
				// --> r0 stores the modulo
	mov r3, #4
	mul r0, r0, r3  	// map address for new bug

	ldr r3, [r4, r0]	// load map point
	cmp r3, #0		// map point must be empty = 0 = '.'
	moveq r2, r6		// new bug: -2, -3, or -4
	streq r2, [r4, r0]	// store bug to map
	bne add_bug_new_try	// if not empty, try again

	pop {r4, r5, r6, lr}
	bx lr
/////////////////////////////////////


////// DIVISION (integer) ///////////
// Input: r0 (dividend), r1 (divisor), both integers
// Output: r0 (remainder, modulo), r1 (integer result of r0/r1)
divide:
	mov r2, #0
divide_loop:		// how many times r1 can be substr from r0?
	cmp r0, r1
	movlt r1, r2
	blt end_divide

	sub r0, r0, r1
	add r2, r2, #1  // increase counter
	b divide_loop

end_divide:
	bx lr
/////////////////////////////////////


//// NEXT RANDOM (positive) INT  ////
// Input: none
// Output: r0, next random number (positive)
// Takes random_seed from memory, updates the seed and returns it.
// Numbers are 2's complement, so lsr should make every number positive.
// Note that #1 shift would be enough for this purpose, but we want 
// small random numbers so calculating the following modulo is fast
get_random:
	ldr r1, =random_seed
	ldr r0, [r1]
	add r0, r0, #137
	eor r0, r0, r0, ror #13
	lsr r0, r0, #5	//shift right to ensure positiveness
	str r0, [r1]

	bx lr
/////////////////////////////////////


///////// INIT RANDOM SEED //////////
// Input: none
// Output: none, updates random_seed
// Makes a software interrupt by supervisor call to gettimeofday
// Interrupt numbers from: https://syscalls.w3challs.com/?arch=arm_strong
// For Raspberry Pi, replace 9 in 0x900.. with 0
init_random_seed:
        push {r7, lr}
        ldr r0, =random_seed
        mov r7, #0x00004e	// syscall for gettimeofday
        svc #0

        pop {r7, lr}
        bx lr
/////////////////////////////////////


////// OUTPUT //////////////////////
// Input: r0, address of string to print
// Output: none, prints to stdout
output:
	push {r4, r6, r7, lr}
	mov r4, r0		// store orig addr of string
	mov r3, #0
count_loop:			// count chars in the string
	ldrb r1, [r0], #1	// each char is one byte
	cmp r1, #0		// each string must be null-ended
	beq next_print
	addne r3, r3, #1
	b count_loop
next_print:
	mov r0, #1              // stdout
    	mov r1, r4	        // address of the string
    	mov r2, r3             	// string length
    	mov r7, #4              // syscall for 'write'
    	svc #0                  // software interrupt
	pop {r4, r6, r7, lr}
	bx lr
////////////////////////////////////


////// INPUT ///////////////////////
// Input: none
// Output: address of input string =rw_buffer
input:
	push {r4, r6, r7, lr}
	ldr r4, =rw_buffer
	mov r1, #0
	str r1, [r4]
	str r1, [r4, #+4]	// make sure buffer is empty

	mov r0, #0              // stdin
        mov r1, r4              // address of the string
        mov r2, #1              // string length = 1
        mov r7, #3              // syscall for 'write'
        svc #0                  // software interrupt

	mov r0, r4		//return address of string

end_input:
	nop
	pop {r4, r6, r7, lr}
        bx lr
////////////////////////////////////////////////


////// OUTPUT INTEGER TO PRINT AS STRING ///////
// Input: r0, 32 bit positive integer
// Output: none, prints r0 to stdout as decimal
output_int:
	push {r4, r5, r6, lr}
	mov r4, r0
    	mov r5, #8		// word is 8 x 4 bits
	mov r6, #0		// carry
	ldr r3, =rw_buffer	// buffer to write string
	add r3, r3, #7		// start writing from end
output_int_loop:
    	// Take least significant 4 bits from r4 into r0, loop 8 times
    	mov r0, r4, lsl #28
	mov r0, r0, lsr #28

	cmp r6, #0		// add carry if previous round >9
	addgt r0, r0, #1
	movgt r6, #0

	cmp r0, #9		// check if >9, if so mark carry
	subgt r0, r0, #10
	movgt r6, #1

    	mov r4, r4, lsl #4	// Shift r4 for next time

    	// For each nibble (now in r0) convert to ASCII
    	add r0, r0, #48
	strb r0, [r3], #-1

    	sub r5, r5, #1		// decrease loop counter
	cmp r5, #0
    	bne output_int_loop

	ldr r0, =rw_buffer	// reset to start
	mov r2, #6
output_int_loop3:		// skip leading zeroes (max 7)
	ldrb r1, [r0]
	cmp r1, #0x30		//= "0" in ascii
	addeq r0, r0, #1
	bne output_int_end
	subs r2, r2, #1
	bmi output_int_end	//if last number is also 0, print it
	b output_int_loop3
output_int_end:
	bl output

	pop {r4, r5, r6, lr}
	bx lr
////////////////////////////////////////////


////////DELAY///////////////////////////
// Input, Output: none
// Delay program for delay_ticks loop time
delay:
        ldr r0, =delay_ticks
        ldr r0, [r0]
        mov r1, #0
delay_loop:
        cmp r1, r0
        add r1, r1, #1
        blt delay_loop

        bx lr
////////////////////////////////////////


///// KBHIT ////////////////////////////
// Input, Output: none
// Wait for any key press
kbhit:
        push {r4, lr}
        bl cbreak_off
        bl input
        bl cooked_mode
        pop {r4, lr}
        bx lr
////////////////////////////////////////



///////////////////////////////////////////////////////
//        TERMIOS MANIPULATION FUNCTIONS
// Controls how data is buffered and read from keyboard
///////////////////////////////////////////////////////
//struct termios {
//    tcflag_t c_iflag;               // input mode flags
//    tcflag_t c_oflag;               // output mode flags
//    tcflag_t c_cflag;               // control mode flags
//    tcflag_t c_lflag;               // local mode flags
//    cc_t c_line;                    // line discipline
//    cc_t c_cc[NCCS];                // control characters
//};
///////////////////////////////////////////////////////
// Input, Output: none
// Saves current termios (terminal input) configs to memory.
// Needed so that they can be restored after config changes.
save_termios:
        push {r4, lr}
        bl read_termios
        ldr r0, =termios
        mov r1, #0
        ldr r2, =saved_termios
loop_save:                      // save old configurations
        cmp r1, #11
        beq end_loop_save
        ldr r3, [r0], #4
        str r3, [r2], #4
        add r1, r1, #1
        b loop_save
end_loop_save:
	pop {r4, lr}
	bx lr
//////////////////////////////////////////////
// Input, Output: none
// Change input mode to raw mode. Input is not buffered.
// Needed to immediate reading of data from keypresses.
// Following instructions in:
// https://sourceforge.net/p/hla-stdlib/mailman/hla-stdlib-talk/
//         thread/814462.63171.qm@web65510.mail.ac4.yahoo.com/
// Flag values from:
// https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/
//         linux.git/tree/include/uapi/asm-generic/termbits.h?id=HEAD
raw_mode:
	push {r4, r5, r6, r7, r8, lr}

	bl save_termios

	ldr r0, =termios
	//termattr.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);
	mov r1, #1000
	orr r1, r1, #2
	orr r1, r1, #0100000
	orr r1, r1, #01
	mvn r1, r1
	ldr r6, [r0, #+12]
	and r6, r6, r1
	str r6, [r0, #+12]
   	//termattr.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
	mov r2, #2
	orr r2, #400
	orr r2, #20
	orr r2, #2000
	mvn r2, r2
	ldr r6, [r0]
        and r6, r6, r2
        str r6, [r0]
  	//termattr.c_cflag &= ~(CSIZE | PARENB);
	mov r3, #60
	orr r3, #400
	mvn r3, r3
	ldr r6, [r0, #+8]
        and r6, r6, r3
   	//termattr.c_cflag |= CS8;
	mov r4, #60
        orr r6, r6, r4
        str r6, [r0, #+8]
   	//termattr.c_oflag &= ~(OPOST);
	mvn r5, #1
 	ldr r6, [r0, #+4]
        and r6, r6, r5
        str r6, [r0, #+4]
	//termattr.c_cc[VMIN] = 1;  // or 0 for some Unices 
   	mov r7, #0		// needs to be 0 for Raspbian
	strb r7, [r0, #+23]	// 16 + 1 + 6 (VMIN) 
	//termattr.c_cc[VTIME] = 0;
	mov r8, #0
	strb r8, [r0, #+22]	// 16 + 1 + 5 (VTIME)

	bl write_termios
	pop {r4, r5, r6, r7, r8, lr}
	bx lr
/////////////////////////////////////////
// Input, Output: none
// Set input mode to normal mode. Needs pre-saved termios
// structure saved in save_termios. Make sure to call this
// at the end of program, or your terminal input is toast.
cooked_mode:
	push {r4, lr}
	ldr r0, =termios
        mov r1, #0
        ldr r2, =saved_termios
loop_load:                      // load old configurations
        cmp r1, #11
        beq end_loop_load
        ldr r3, [r2], #4
        str r3, [r0], #4
        add r1, r1, #1
	b loop_load
end_loop_load:

	bl write_termios
	pop {r4, lr}
	bx lr
/////////////////////////////////////////
// Input, Output: none
// Don't wait for a newline in following inputs
cbreak_off:
        push {r7, lr}
        bl read_termios

        ldr r0, =termios
        ldr r1, [r0, #+12]!
	mvn r2, #0x00000002 	// NOT ICANON flag
        and r1, r1, r2		// AND local flag
	mvn r2, #1000		// NOT ECHO flag
	and r1, r1, r2		// AND local flag
        str r1, [r0]            // store back to termios+12

        bl write_termios
        pop {r7, lr}
        bx lr
//////////////////////////////////////////
// Input, Output: none
// Wait for newline to buffer input, as normal
cbreak_on:
	push {r7, lr}
        bl read_termios

	ldr r0, =termios
	ldr r1, [r0, #+12]!
	mov r2, #0x00000002	// ICANON flag
	orr r1, r1, r2		// canonical bit ON in local mode flags
        mov r2, #1000           // ECHO flag
        and r1, r1, r2
	str r1, [r0]		// store back to termios+12

        bl write_termios
	pop {r7, lr}
	bx lr
//////////////////////////////////////////
// Input, Output: none
// Make syscall to ioctl and read termios structure to memory
read_termios:
        push {r7, lr}

	mov r0,	#0		// stdin
	ldr r1, =#0x5401 	// READ termios parameters
	ldr r2, =termios	// address for termios buffer
	mov r7, #54		// syscall for ioctl 0x36
	svc #0

        pop {r7, lr}
        bx lr
/////////////////////////////////////////
// Input, Output: none
// Make syscall to ioctl and input termios structure to system
write_termios:
        push {r7, lr}

        mov r0, #0              // stdin
        ldr r1, =#0x5402        // WRITE termios parameters
        ldr r2, =termios        // address for termios buffer
        mov r7, #54             // syscall for ioctl 0x36
        svc #0

        pop {r7, lr}
        bx lr
//////////////////////////////////////////

