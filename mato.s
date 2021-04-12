.data

.align 4
space: .asciz "   "
// Colors from: https://en.wikipedia.org/wiki/ANSI_escape_code
// Escape char for Raspberry Pi is \033
empty: .asciz "\033[38;5;130m.\033[0m"	// brown .
snake: .asciz "\033[32m@\033[0m"	// green @
tail: .asciz "\033[32mo\033[0m"		// green 0
border: .asciz "\033[33m#\033[0m"	// yellow #
bug1: .asciz "\033[38;5;199m\244\033[0m"// pink currency sing
bug2: .asciz "\033[38;5;207m~\033[0m"	// pink ~
bug3: .asciz "\033[38;5;165m\272\033[0m"// pink circle
clear_screen: .asciz "\033[2J"
move_up: .asciz "\033[1A"
hide_cursor: .asciz "\033[?25l"
show_cursor: .asciz "\033[?25h"
endl: .asciz "\n"
game_over: .asciz "\033[1A Game Over. Score: %d\n"
.align 4
map: .skip 600  // mapxlen*mapylen*4
dx: .word 1
dy: .word 0
headx: .word 3
heady: .word 3
max_len: .word 0
random_seed: .word 0x1234

.equ MAPXLEN, 14
.equ MAPYLEN, 9

.text
.global main

///////////////////////////////////////////////
///////////////////  MAIN  ////////////////////
main:
	push {r4, lr}

	bl init_random_seed

        ldr r0, =hide_cursor
        bl printf

	bl initialize_map

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
	ldr r1, =max_len
	ldr r1, [r1]
	bl printf
	bl getchar			// wait for any key
	ldr r0, =show_cursor
	bl printf
	ldr r0, =clear_screen
	bl printf
	pop {r4, lr}
	bx lr

/////////////// END MAIN //////////////////////////
///////////////////////////////////////////////////



/////// MOVE AND CHECK SNAKE COLLISION ///////////
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
update_and_print_map:
	push {r4, r5, r6, r7, r8, lr}
	ldr r6, =map
        ldr r0, =clear_screen
        bl printf

        mov r5, #0
mapy_loop:
        mov r4, #0
        cmp r5, #MAPYLEN
        beq end_map_loop
        add r5, r5, #1
	ldr r0, =space
	bl printf
mapx_loop:
        cmp r4, #MAPXLEN
        ldreq r0, =endl
        bleq printf
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

        bl printf               // print the point

        add r6, r6, #4          // next  point in map
        b mapx_loop

end_map_loop:
	ldr r0, =endl
	bl printf
	pop {r4, r5, r6, r7, r8, lr}
	bx lr
///////////////////////////////////////////////



/////////// CHECK KEYPRESS and UPDATE DX DY ///
// Input: none
// Output: none, update dx and dy
check_keypress:
	push {r4, r5, r6, lr}

        bl initscr              // ncurses init functions
        bl noecho               //
        bl cbreak               //
        mov r0, #500            // wait 500ms for keypress
        bl timeout              //
        bl getch                // ncurses function: get non-blocking
                                // keypress, store in r0

        cmp r0, #0x73           // 'w'
        moveq r0, #1
        beq update_dxdy

        cmp r0, #0x61           // 'a'
        moveq r0, #2
        beq update_dxdy

        cmp r0, #0x77           // 's'
        moveq r0, #3
        beq update_dxdy

        cmp r0, #0x64           // 'd'
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
        bl endwin               // ncurses end function
	pop {r4,r5, r6, lr}
	bx lr
//////////////////////////////////////


////////// INIT MAP /////////////////
// Input: none
// Output: none
// Initialize map values
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
// Adds a new bug to the map in a random location
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
// Note that #1 shift would be enough, but we want small numbers so
// calculating the following modulo is fast
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
        mov r7, #0x00004e
        svc #0

        pop {r7, lr}
        bx lr
/////////////////////////////////////

