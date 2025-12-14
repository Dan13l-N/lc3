; ---------------------------------------------------------------------------
; a small demo for the LC3 virtual machine
; print some numbers, multiply and print the result
; by Daniel N. 2025. Copyleft :) but please attribute me
; ---------------------------------------------------------------------------

; test routines
.orig x3000

    ld  r0, arg1
	jsr printnum ; print arg1
	jsr newline
    ld  r0, arg2
	jsr printnum ; print arg2
	jsr newline
	ld  r0, arg1
	ld  r1, arg2
	jsr div_mod
	jsr printnum ; print arg1 % arg2
	jsr newline
	add r0, r1, #0 
	jsr printnum ; print arg1 / arg2
	jsr newline
    ld  r0, arg3
    ld  r1, arg4
	jsr shr
	jsr printnum ; print arg2
    halt

arg1: .fill 3025
arg2: .fill 30
arg3: .fill 800
arg4: .fill 4

; ---------------------------------------------------------------------------

newline: ; prints new line
    st  r7, printnum_save
	lea r0, newline_str
	puts
	ld r7, printnum_save
	ret
newline_str: 
.fill 10 ; newline
.fill 0

; ---------------------------------------------------------------------------

printnum: ; prints number in r0 on the console
    st  r7, printnum_save
	st  r1, lib_save_r1
	lea r1, printnum_buff
    jsr itoa
	lea r0, printnum_buff
	puts
	ld  r1, lib_save_r1
	ld  r7, printnum_save
	ret
printnum_save: .fill 0
printnum_buff: .blkw 8

; ---------------------------------------------------------------------------

; converts the number in r0 into a string, using a buffer pointed by r1
; the buffer should have at least 7 characters, (5 digits, '-', 0 terminator)
; r0, r1 and r5 are not conserved; r0 will be the value of the last digit
; and r1 will point to the character in the buffer before the 0 terminator
; the whole routine is optimized and has 38 instructions

itoa: 
    add r0, r0, #0  ; check for negative r0
		brp itoa_notneg ; not negative, so skip
		brz itoa_last ; zero - bypass and add a single digit

	not r0, r0      ; convert to positive
	add r0, r0, #1  ; (it takes two instructions!)
	ld  r5, char_minus 
    str r5, r1, #0 ; store '-' to loc r1
	add r1, r1, #1 ; one char written

	itoa_notneg:

    add r5, r0, #-10 ; first check if a0 is less than 10
		brn itoa_last ; if so, bypass and write the (only) digit   

    st  r2, lib_save_r2 ; we will need these registers...
    st  r3, lib_save_r3
    st  r4, lib_save_r4 
	lea r4, itoa_table ; load the address of the table

    ; we skip digits until we find one which is not zero
	; we do it by checking if r0 is bigger than or equal to 10000,
	; then 1000, then 100, then 10 (the "constants" in the table)
	itoa_first:
    	ldr r3, r4, #0 ; load e.g. -1000 from the table into r3
		add r4, r4, #1 ; go to the next constant (in advance!)
		add r5, r0, r3 ; subtract e.g. -1000 from r0
		brn itoa_first ; still too big...
	
	; pay attention: now r4 points to one entry "too far"!

    itoa_loop:
    	ld r2, char_zero ; r2 starts with ASCII '0'
		
		itoa_sub: ; repeatedly subtract the constant
			add r5, r0, r3 ; from r0
				brn itoa_digit ; if less, we did one digit
			add r0, r5, #0 ; number back to r0
			add r2, r2, #1 ; increase char (e.g. '0' -> '1')
		br itoa_sub ; subtract again...
		
		itoa_digit: ; one digit is done, store the char
		str r2, r1, #0  ; store char in r2 to loc r1
		add r1, r1, #1  ; go to the next loc
		add r4, r4, #1  ; go to the next table entry
		; but remember r4 is "one address to far", so load from -1
    	ldr r3, r4, #-1 ; load its constant, e.g. -1000 into r3
		; this sets the n flag unless we reached the end
		; because all constants in the table are negative
		; but the end of the table is just 0
    	brn itoa_loop  ; if not done, do the next digit

    ld  r2, lib_save_r2
    ld  r3, lib_save_r3
    ld  r4, lib_save_r4

    itoa_last:     ; the last digit is always written
    ld  r5, char_zero ; it's in r0, so...
    add r5, r0, r5 ; now ASCII char is in r5
    str r5, r1, #0 ; store to loc r1
    and r5, r5, #0 ; r5 = 0
    str r5, r1, #1 ; store char 0 to loc r1+1
	ret

itoa_table: ; subtraction constants for each digit
.fill -10000
.fill -1000
.fill -100
.fill -10
.fill 0 ; end of the table

char_minus: .fill 45 ; ASCII char '-'
char_zero:  .fill 48 ; ASCII char '0'

; ---------------------------------------------------------------------------

; fast: r0 / r1 -> r1, r0 % r1 -> r0
; all other registers except for r5 are conserved

div_mod:
    st  r4, lib_save_r4
	and r4, r4, #0 ; 0 by default, the result is negative

	; if r1 == 0, we can't divide, just return
	add r1, r1, #0
		brp div_not0
		brn div_r1_neg
	    ld  r4, lib_save_r4
		ret

	div_r1_neg:
	not r4, r4     ; flip it
	not r1, r1 
	add r1, r1, #1 ; now r1 is positive 

	div_not0:

	; check if r1 is one, if so, we can immediately return
	add r5, r1, #-1
		brp div_not1
		add r1, r0, #0 ; r1 = r0 (quotient)
		and r0, r0, #0 ; r0 = 0 (remainder)
	    ld  r4, lib_save_r4
		ret
	
	div_not1:
	; we have to create a table with r1, 2*r1, 4*r1, 8*r1...
    ; ...because LC3 is the only CPU without bit shifts!

    st  r2, lib_save_r2
    st  r3, lib_save_r3
	lea r2, lib_div_table ; load the address of the table

	; is r0 maybe negative?
	add r3, r0, #0
	brn div_r0_neg
		not r3, r0     ; r3 = -r0 for smaller code
		add r3, r3, #1 ; as usual, two instructions are needed
		not r4, r4     ; flip it
	div_r0_neg:

	; we calculate only constants smaller or equal than r0
	div_table_loop:
		add r5, r3, r1
			brp div_table_done ; meaning, r1 < r0
		str r1, r2, #0 ; store r1 to the table...
		add r1, r1, r1 ; r1 = r1 << 1
		add r2, r2, #2 ; go to the next table cell
	br div_table_loop

	div_table_done:
	; now the table is done :)
	; we don't need r1 anymore, it will collect the result
	; r2 points to the shift of r1 greater than r0
	and r1, r1, #0 ; r1 = 0
    ldr r5, r2, #-2 ; load 2^(N-1) * divisor

    div_loop:
      add r5, r3, r5
      brp div_next ; (-r0) + 2^N*div > 0 => 2^N*div > r0 
	    add r3, r5, #0  ; now r0 has the (negative) remainder
	    ldr r5, r2, #-1 ; load 2^N
	    add r1, r1, r5  ; update r1 (the quotient)
	  div_next:
	  add r2, r2, #-2 ; r2 goes to the PREVIOUS entry...
	  ldr r5, r2, #-2 ; load 2^N * divisor
	  brp div_loop ; if we didn't come back to 0, repeat this

    ; now r1 has the quotient, and r3 the negative remainder
	not r0, r3
	add r0, r0, #1 ; now the remainder is in r0
	add r4, r4, #0 ; should the overall result be negative?
	brnp div_positive
		not r1, r1
		add r1, r1, #1 ; r1 = -r1
	div_positive:
    ld  r2, lib_save_r2
    ld  r3, lib_save_r3
    ld  r4, lib_save_r3
	ret

.fill 0 ; this marks the start, as we move back to lower powers
.fill 0 ; 
lib_div_table: ; table of powers of 2
.fill 0  ; divisor
.fill 0x0001
.fill 0  ; 2 * divisor
.fill 0x0002
.fill 0  ; 4 * divisor
.fill 0x0004
.fill 0  ; 8 * divisor
.fill 0x0008

.fill 0  ; 16 * divisor
.fill 0x0010 
.fill 0  ; you get the system...
.fill 0x0020
.fill 0
.fill 0x0040
.fill 0
.fill 0x0080

.fill 0
.fill 0x0100   
.fill 0
.fill 0x0200
.fill 0
.fill 0x0400
.fill 0
.fill 0x0800

.fill 0
.fill 0x1000 
.fill 0
.fill 0x2000
.fill 0
.fill 0x4000
.fill 0
.fill 0x8000 

; ---------------------------------------------------------------------------

or: ; r0 or r1 -> r1; other registers are not touched
    not r0, r0
	not r1, r1
	and r0, r0, r1
	not r0, r0
	ret

; ---------------------------------------------------------------------------

mul_10: ; r0 * 10 -> r0; r5 is trashed
    add r5, r0, r0 ; now r5 = 2 * r0
    add r0, r5, r5 ; now r0 = 4 * r0
    add r0, r0, r0 ; now r0 = 8 * r0
	add r0, r0, r5 ; now r0 = 10 * r0
	ret

; ---------------------------------------------------------------------------

shr: ; r0 >> r1 -> r1; other registers are not touched except r5
    st  r2, lib_save_r2
    st  r3, lib_save_r3

	ld  r2, lib_one ; set r2 = 1 << r1
	shr_loop1:
	  add r1, r1, #-1
      brn shr_exit
	  add r2, r2, r2
	  br shr_loop1
	shr_exit:
	ld r1, lib_one

	and r3, r3, #0  ; set r3 = 0; it will hold the result

    shr_loop2:
      and r5, r0, r2 ; check if the r2 bit is set in r0
      brz lib_notset	    
		add r3, r3, r1
      lib_notset:
      ; always shift r1 and r2 by one left
	  add r1, r1, r1
	  add r2, r2, r2 ; we do it the last
	  brnp shr_loop2 ; check if r2 is still on
    br done ; the same epologue as multiply :) so we reuse it

; ---------------------------------------------------------------------------

; r0 * r1 -> r0; registers except r5 are not touched
; works for all numbers, positive, negative, whetever :)
; overflows are ignored...

multiply: 
    st  r2, lib_save_r2
    st  r3, lib_save_r3
	ld  r2, lib_one ; r2 = 1
	and r3, r3, #0  ; r3 = 0; it will hold the result

    mul_loop1:
    	and r5, r0, r2 ; check if the r2 bit is set in r0
        	brz mul_notset	    
	    	add r3, r3, r1
      	mul_notset:
      	; always shift r1 and r2 by one left
	  	add r1, r1, r1
	  	add r2, r2, r2 ; we do it the last
	  	brnp mul_loop1 ; check if r2 is still on
 
	done:
	add r0, r3, #0 ; now r0 has the result
    ld  r2, lib_save_r2
    ld  r3, lib_save_r3
	ret

lib_save_r1: .fill 0
lib_save_r2: .fill 0
lib_save_r3: .fill 0
lib_save_r4: .fill 0
lib_one:     .fill 1
    
; ---------------------------------------------------------------------------

.end
