################ CSC258H1F Winter 2024 Assembly Final Project ##################
# This file contains our implementation of Tetris.
#
# Student 1: Leo Kaixuan Cheng, 1008752146
# Student 2: Zihan Jin, 1007676409
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       16
# - Unit height in pixels:      16
# - Display width in pixels:    256
# - Display height in pixels:   512
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
    
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

COLOR:
	.word 0x808080     # Grey
	.word 0x17161A     # Dark Grey
	.word 0x1b1b1b     # Another Dark Grey
	#.word 0xff0000
	#.word 0x00ff00
	.word 0xffff33     # Yellow

COLOR_I:     .word 0x00FFFF  # Cyan for 'I'
COLOR_T:     .word 0x800080  # Purple for 'T'
COLOR_S:     .word 0x00FF00  # Green for 'S'
COLOR_Z:     .word 0xFF0000  # Red for 'Z'
COLOR_J:     .word 0x0000FF  # Blue for 'J'
COLOR_L:     .word 0xFFA500  # Orange for 'L'

.eqv ROW_UNIT 128
.eqv COL_UNIT 256

RETRY_CHAR:
.word 3, 4, 5, 7, 8, 9, 11, 12, 13, 19, 21, 23, 28, 35, 36, 37, 39, 40, 41,
44, 51, 52, 55, 60, 67, 69, 71, 72, 73, 76, 99, 100, 101, 103, 105, 107, 108,
115, 117, 119, 121, 125, 131, 132, 133, 136, 140, 147, 148, 152, 163, 165, 168, 172

PAUSE_ARRAY:
.word 84, 85, 90, 91

Background_Music_Pitches: 
.word 64,64,59,60,62,64,60,59,
57,57,57,60,64,64,62,60,
59,59,59,60,62,62,64,64,
60,60,57,57,57,57,57,57,
0,62,62,65,69,69,67,65,
0,64,64,60,64,64,62,60,
59,59,59,60,62,62,64,64,
60,60,57,57,57,57,57,57


##############################################################################
# Mutable Data
##############################################################################
grid_layout: .space 5000
block_type:  .word   0
rotation:    .word   0
block:       .space 16
new_block:   .space 16
grid_temp:   .space 2048

#sound effect
beep: .word 72
clear: .word 100
over: .word 32
duration: .word 50
volume: .word 127

##############################################################################
# Full Shapes and its rotation
##############################################################################

O:
.word 0, 4, 64, 68
.word 0, 4, 64, 68
.word 0, 4, 64, 68
.word 0, 4, 64, 68

I:
.word 64,68,72,76
.word 4, 68, 132, 196
.word 64,68,72,76
.word 4, 68, 132, 196

S:
.word 4, 8, 64, 68
.word 0, 64, 68, 132
.word 4, 8, 64, 68
.word 0, 64, 68, 132

Z:
.word 0, 4, 68, 72
.word 4, 64, 68, 128
.word 0, 4, 68, 72
.word 4, 64, 68, 128

L:
.word 64, 68, 72, 128
.word 4, 8, 72, 136
.word 72, 128, 132, 136
.word 4, 68, 132, 136

J:
.word 64, 68, 72, 136
.word 8, 72, 132, 136
.word 64, 128, 132, 136
.word 4, 8, 68, 132

T:
.word 0, 4, 8, 68
.word 8, 68, 72, 136
.word 68, 128, 132, 136
.word 0, 64, 68, 128
##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Tetris game.
main:
    # Initialize the game
    

DRAW_BOTTOM_WALL:
    li $t0, 0     # i = 0
    la $s0, COLOR
    lw $t1, ADDR_DSPL
    li $s1, 1984  # Bottom first pixel
   
    
DRAW_BOTTOM_LOOP:
    beq $t0, 16, DRAW_BOTTOM_END
    lw $t2, 0($s0) # Gray
    add $t3, $t1, $s1
    sw $t2, ($t3)
    addi $s1, $s1, 4
    addi $t0, $t0, 1
    b DRAW_BOTTOM_LOOP
    
DRAW_BOTTOM_END:
     nop

DRAW_SIDE_WALL:
    li $t0, 0     # i = 0
    la $s0, COLOR
    lw $t1, ADDR_DSPL
    li $s1, 0  # Every first pixel
   
    
DRAW_SIDE_LOOP:
    beq $t0, 32, DRAW_SIDE_END
    lw $t2, 0($s0) # Gray
    add $t3, $t1, $s1
    sw $t2, ($t3)
    
    addi $t3, $t3, 60
    sw $t2, ($t3)
    
    addi $s1, $s1, 64
    addi $t0, $t0, 1
    b DRAW_SIDE_LOOP

DRAW_SIDE_END:
	nop
	
DRAW_GRID:
    li $t0, 0  # i = 0
    la $s0, COLOR
    lw $t1, ADDR_DSPL
    lw $s1, 4($s0)  # Dark Grey 1
    lw $s2, 8($s0)  # Dark Grey 2
    li $t3, 0  # Position
    li $t7, 0 # Control Alternating 
    
DRAW_GRID_LOOP:

    beq $t0, 434, DRAW_GRID_END
    la $s4, grid_layout
    add $t3, $t3, 4
    add $t5, $t3, $t1  # Address of display
    add $s3, $t7, $t0
    andi $s3, $s3, 1
    mul $t4, $t0, 4  # i * 4
    add $s4, $s4, $t3  # Address of array
    beq $s3, 1, NOT_EVEN
    sw $s1 ($t5)  # Draw grey
    sw $s1 ($s4)  # Store array
    j EVEN_END
    NOT_EVEN:
    sw $s2 ($t5)  # Draw grey
    sw $s2 ($s4)  # Store array
    EVEN_END:
    li $t4, 14
    div $t0, $t4  # i % 14
    mfhi $t6
    bne $t6, 13, CHANGE_END
    add $t3, $t3, 8
    addi $t7, $t7, 1
    CHANGE_END:
    addi $t0, $t0, 1  # i += 1
    b DRAW_GRID_LOOP
    
DRAW_GRID_END:
    nop

NEW_BLOCK:
jal DRAW_RANDOM_BLOCK

game_loop:
    li $s0, 63
    la $t8, Background_Music_Pitches
	# !!! $t0: Y pos, $t1: X pos, $t7: color, $t9: time
	#background_music, note counter

	# 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
	# 4. Sleep

    #5. Go back to 1
    bne $t9, 300, no_drop # Gravity
    li $t9, 0
    bne $s0, $v1, play_note#reset if note_counter = 63
    li $v1,0#reset note counter
    
    play_note:
    li $v0, 31       # async play note syscall
    mul $t4, $v1, 4#multiply note counter by 4 to get the next element in the pitch array
    add $t4, $t4, $t8#add to the address of the pitch
    lw $a0, 0($t4)  # Load pitch into $a0
    li $a1, 1000  # duration 
    li $a2, 2        # instrument
    li $a3, 100      # volume
    addi $v1, $v1, 1#increament note counter
    syscall

    b press_s
    no_drop:
    li $v0, 32
    li $a0, 10
    syscall
    addi $t9, $t9, 10
    lw $t3, ADDR_KBRD
    lw $t8, 0($t3)
    beq $t8, 1, press
    b game_loop
    press:
        lw $t2, 4($t3) 
        beq $t2, 0x61, press_a
        beq $t2, 0x64, press_d
        beq $t2, 0x71, press_q
        beq $t2, 0x73, press_s
        beq $t2, 0x77, rotate_sound
        beq $t2, 0x70, pause_sound
        b game_loop
    rotate_sound:
        li $v0,31
        la $a0,beep
        lw $a0 0($a0)
        addi $a2,$a0,12
        la $a1,duration
        lw $a1, 0($a1)
        la $a3, 50

        move $a2,$a0
        move $s1,$a1
        syscall
        j press_w
        
    pause_sound:
        li $v0, 31    # async play note syscall
        li $a0, 60    # midi pitch
        li $a1, 1000  # duration
        li $a2, 0     # instrument
        li $a3, 100   # volume
        syscall
        j press_p
    
    press_w:
        jal ERASE_BLOCK
        la $t3, new_block
        la $t2, block
        lw $t4, rotation
        lw $t5, block_type
        
        #update rotation
        beq $t4, 3, reset_rotation
        addi $t4, $t4, 1#to the next rotation
        j save_rotation
        reset_rotation:
        addi $t4, $t4, -3
        save_rotation:
        la $t6, rotation
        sw $t4, 0($t6)#$s4 is rotation
        
        #for i in 0:rotation:
        li $t8, 0#outerloop counter
        mult $s7, $t0, 64#real xy position
        mul $t8, $t1, 4
        add $s7, $s7, $t8
        addi $s7, $s7, 0x10008000
        
        #$t5 is a nested array shape
        # find_rotation:
        # beq $t8, $t4, column_loop#loop until index position
        # sll $s0, $t8, 2 #row offset
        # mul $s0, $s0, 4 #multiply row and column
        # add $a0, $t5, $s0 #a0 current row address
        # addi $t8, $t8, 1
        # j find_rotation
        mul $t4, $t4, 16
        add $t4, $t5, $t4
        
        column_loop:
        lw $s4, ($t4)#first element
        add $s4, $s7, $s4#block wts
        sw $s4, ($t3)#save back
        addi $t3, $t3, 4
        
        lw $s4, 4($t4)#second
        add $s4, $s7, $s4#block
        sw $s4, ($t3)#save back
        addi $t3, $t3, 4
        
        lw $s4, 8($t4)#third
        add $s4, $s7, $s4#block
        sw $s4, ($t3)#save back
        addi $t3, $t3, 4
        
        lw $s4, 12($t4)#fourth
        add $s4, $s7, $s4#block
        sw $s4, ($t3)#save back
        
        update_array:
        lw $t6, ($t3)

        #store the updated block in t6
        jal IS_COLLISION
        lw $t6, ($sp) # Result
        addi $sp, $sp, 4
        beq $t6, 1, COLL
        jal TRANSFER_NEW_TO_ARRAY
    	COLL:
    	jal DRAW_CURRENT_BLOCK
    	b game_loop
    
    press_a:

        jal ERASE_BLOCK
        la $t3, new_block
        la $t2, block
        li $t4, 0  # Counter i

        UPDATE_LOOP:
            beq $t4, 16, UPDATE_END
            add $t5, $t4, $t2 # block
            lw $t6, ($t5)
            addi $t6, $t6, -4
            add $t5, $t4, $t3 # new block
            sw $t6, ($t5)
            addi $t4, $t4, 4
            b UPDATE_LOOP
        UPDATE_END:
        jal IS_COLLISION
        lw $t6, ($sp) # Result
        addi $sp, $sp, 4
        beq $t6, 1, COLL
        addi $t1, $t1, -1
        jal TRANSFER_NEW_TO_ARRAY
    	COLL:
    	jal DRAW_CURRENT_BLOCK
    	b game_loop
    press_d:
        
        jal ERASE_BLOCK
        la $t3, new_block
        la $t2, block
        li $t4, 0  # Counter i

        UPDATE_LOOP_2:
            beq $t4, 16, UPDATE_END_2
            add $t5, $t4, $t2 # block
            lw $t6, ($t5)
            addi $t6, $t6, 4
            add $t5, $t4, $t3 # new block
            sw $t6, ($t5)
            addi $t4, $t4, 4
            b UPDATE_LOOP_2
        UPDATE_END_2:
        jal IS_COLLISION
        lw $t6, ($sp) # Result
        addi $sp, $sp, 4
        beq $t6, 1, COLL_2
        addi $t1, $t1, 1
        jal TRANSFER_NEW_TO_ARRAY
    	COLL_2:
    	jal DRAW_CURRENT_BLOCK
    	b game_loop
        
    press_s:
        
        jal ERASE_BLOCK
        la $t3, new_block
        la $t2, block
        li $t4, 0  # Counter i

        UPDATE_LOOP_3:
            beq $t4, 16, UPDATE_END_3
            add $t5, $t4, $t2 # block
            lw $t6, ($t5)
            addi $t6, $t6, 64
            add $t5, $t4, $t3 # new block
            sw $t6, ($t5)
            addi $t4, $t4, 4
            b UPDATE_LOOP_3
        UPDATE_END_3:
        jal IS_COLLISION
        lw $t6, ($sp) # Result
        addi $sp, $sp, 4
        beq $t6, 1, COLL_3
        addi $t0, $t0, 1
        jal TRANSFER_NEW_TO_ARRAY
        jal DRAW_CURRENT_BLOCK
        b game_loop
    	COLL_3:
    	jal DRAW_CURRENT_BLOCK
    	jal CLEAR_LINE
    	jal IS_GAME_OVER
    	b NEW_BLOCK
    
    press_p:
        jal SAVE_GRID
        jal DRAW_PAUSE
        press_p_detect:
        lw $t3, ADDR_KBRD
        lw $t8, 0($t3)
        beq $t8, 1, press_p_p
        b press_p_detect
        press_p_p:
            lw $t2, 4($t3) 
            beq $t2, 0x70, press_p_restart
            b press_p_p
        press_p_restart:
        jal DRAW_GRID_ARRAY
        b game_loop
        
    press_q:
        li $v0, 10  # Terminate
        syscall
    	
    b game_loop

DRAW_CURRENT_BLOCK:
    la $s0, block
    lw $a0, ($s0)
    sw $t7, ($a0)
    lw $a0, 4($s0)
    sw $t7, ($a0)
    lw $a0, 8($s0)
    sw $t7, ($a0)
    lw $a0, 12($s0)
    sw $t7, ($a0)
    jr $ra

ERASE:
    lw $a0, ($sp)  # Real position
    addi $sp, $sp, 4
    addi $sp, $sp, -4
    sw $ra, ($sp)  # Store addr
    la $a1, COLOR
    lw $s2, 4($a1) # Grey
    lw $s3, 8($a1) # Grey
    
    la $s1, grid_layout
    add $s1, $s1, $a0
    addi $s1, $s1, -0x10008000
    lw $s4, ($s1)
    sw $s4, ($a0)
    beq $a0, 0x10008204, NOT_SAFE_1
    beq $a0, 0x10008208, NOT_SAFE_2
    b NOT_SAFE_END
    NOT_SAFE_1:
    sw $s2, ($a0)
    b NOT_SAFE_END
    NOT_SAFE_2:
    sw $s3, ($a0)
    NOT_SAFE_END:
    
    lw $ra, ($sp)
    addi $sp, $sp, 4
    jr $ra

DRAW_RANDOM_BLOCK:

    addi $sp, $sp, -4
    sw $ra, ($sp)  # Store addr
    li $v0, 42
    li $a0, 0
    li $a1, 7  # Random number 0-6 in $a0
    syscall
    addi $s1, $a0, 0
    
    li $v0, 42
    li $a0, 0
    li $a1, 11  # Random number 0-10
    syscall
    addi $t1, $a0, 0  # X global
    li $t0, 0  # Y  global
    beq $s1, 0, DRAW_RANDOM_O
    beq $s1, 1, DRAW_RANDOM_I
    beq $s1, 2, DRAW_RANDOM_S
    beq $s1, 3, DRAW_RANDOM_Z
    beq $s1, 4, DRAW_RANDOM_L
    beq $s1, 5, DRAW_RANDOM_J
    beq $s1, 6, DRAW_RANDOM_T
    # More blocks...
    DRAW_RANDOM_O:
        addi $sp, $sp, -4
        sw $t0, ($sp)  # Y Position
        addi $sp, $sp, -4
        sw $t1, ($sp)  # X Position
        
        jal DRAW_O
        b END_RANDOM
    DRAW_RANDOM_I:
        addi $sp, $sp, -4
        sw $t0, ($sp)  # Y Position
        addi $sp, $sp, -4
        sw $t1, ($sp)  # X Position
        
        jal DRAW_I
        b END_RANDOM
    DRAW_RANDOM_S:
        addi $sp, $sp, -4
        sw $t0, ($sp)  # Y Position
        addi $sp, $sp, -4
        sw $t1, ($sp)  # X Position
        
        jal DRAW_S
        b END_RANDOM
    DRAW_RANDOM_Z:
        addi $sp, $sp, -4
        sw $t0, ($sp)  # Y Position
        addi $sp, $sp, -4
        sw $t1, ($sp)  # X Position
        
        jal DRAW_Z
        b END_RANDOM
    DRAW_RANDOM_L:
        addi $sp, $sp, -4
        sw $t0, ($sp)  # Y Position
        addi $sp, $sp, -4
        sw $t1, ($sp)  # X Position
        
        jal DRAW_L
        b END_RANDOM
    DRAW_RANDOM_J:
        addi $sp, $sp, -4
        sw $t0, ($sp)  # Y Position
        addi $sp, $sp, -4
        sw $t1, ($sp)  # X Position
        
        jal DRAW_J
        b END_RANDOM
    DRAW_RANDOM_T:
        addi $sp, $sp, -4
        sw $t0, ($sp)  # Y Position
        addi $sp, $sp, -4
        sw $t1, ($sp)  # X Position
        
        jal DRAW_T
        b END_RANDOM
    END_RANDOM:
    lw $ra, ($sp)
    addi $sp, $sp, 4
    jr $ra
# Draw the O block (Initialize)
DRAW_O:
    lw $a0, ($sp)  # X Position
    addi $sp, $sp, 4
    lw $a1, ($sp)  # Y Position
    addi $sp, $sp, 4
    la $s5, COLOR
    lw $s0, ADDR_DSPL
    
    la $s2, block_type
    la $s7, O
    sw $s7, 0($s2)# Store the value from $s7 into the address contained in $s2

    mul $s1, $a0, 4  # x * 4
    mul $s2, $a1, 64  # y * 64
    add $s1, $s1, 4
    add $s3, $s1, $s2  #  Real position
    add $s3, $s3, $s0
    lw $s4, 12($s5)  # Yellow
    add $t7, $s4, $zero  # Update color
    sw $s4, ($s3)
    sw $s4, 4($s3)
    sw $s4, 64($s3)
    sw $s4, 68($s3)
    la $s6, block  # Update array
    sw $s3, ($s6)
    addi $s3, $s3, 4
    sw $s3, 4($s6)
    addi $s3, $s3, 60
    sw $s3, 8($s6)
    addi $s3, $s3, 4
    sw $s3, 12($s6)
    
    jr $ra

DRAW_I:
    lw $a0, ($sp)  # X Position
    addi $sp, $sp, 4
    lw $a1, ($sp)  # Y Position
    addi $sp, $sp, 4
    la $s5, COLOR_I
    lw $s0, ADDR_DSPL
    
    la $s2, block_type
    la $s7, I
    sw $s7, 0($s2)

    mul $s1, $a0, 4  # x * 4
    mul $s2, $a1, 64  # y * 64
    add $s1, $s1, 4
    add $s3, $s1, $s2  #  Real position
    add $s3, $s3, $s0
    lw $s4, 0($s5)  # Yellow
    add $t7, $s4, $zero  # Update color
    sw $s4, ($s3)
    sw $s4, 4($s3)
    sw $s4, 8($s3)
    sw $s4, 12($s3)
    la $s6, block  # Update array
    sw $s3, ($s6)
    addi $s3, $s3, 4
    sw $s3, 4($s6)
    addi $s3, $s3, 4
    sw $s3, 8($s6)
    addi $s3, $s3, 4
    sw $s3, 12($s6)
    
    jr $ra

DRAW_S:
    lw $a0, ($sp)  # X Position
    addi $sp, $sp, 4
    lw $a1, ($sp)  # Y Position
    addi $sp, $sp, 4
    la $s5, COLOR_S
    lw $s0, ADDR_DSPL
    
    la $s2, block_type
    la $s7, S
    sw $s7, 0($s2)

    mul $s1, $a0, 4  # x * 4
    mul $s2, $a1, 64  # y * 64
    add $s1, $s1, 4
    add $s3, $s1, $s2  #  Real position
    add $s3, $s3, $s0
    lw $s4, 0($s5)  # Yellow
    add $t7, $s4, $zero  # Update color
    sw $s4, 4($s3)
    sw $s4, 8($s3)
    sw $s4, 64($s3)
    sw $s4, 68($s3)
    la $s6, block  # Update array
    addi $s3, $s3, 4
    sw $s3, ($s6)
    addi $s3, $s3, 4
    sw $s3, 4($s6)
    addi $s3, $s3, 56
    sw $s3, 8($s6)
    addi $s3, $s3, 4
    sw $s3, 12($s6)
    
    jr $ra

DRAW_Z:
    lw $a0, ($sp)  # X Position
    addi $sp, $sp, 4
    lw $a1, ($sp)  # Y Position
    addi $sp, $sp, 4
    la $s5, COLOR_Z
    lw $s0, ADDR_DSPL
    
    la $s2, block_type
    la $s7, Z
    sw $s7, 0($s2)

    mul $s1, $a0, 4  # x * 4
    mul $s2, $a1, 64  # y * 64
    add $s1, $s1, 4
    add $s3, $s1, $s2  #  Real position
    add $s3, $s3, $s0
    lw $s4, 0($s5)  # Yellow
    add $t7, $s4, $zero  # Update color
    sw $s4, ($s3)
    sw $s4, 4($s3)
    sw $s4, 68($s3)
    sw $s4, 72($s3)
    la $s6, block  # Update array
    sw $s3, ($s6)
    addi $s3, $s3, 4
    sw $s3, 4($s6)
    addi $s3, $s3, 64
    sw $s3, 8($s6)
    addi $s3, $s3, 4
    sw $s3, 12($s6)
    
    jr $ra
    
DRAW_L:
    lw $a0, ($sp)  # X Position
    addi $sp, $sp, 4
    lw $a1, ($sp)  # Y Position
    addi $sp, $sp, 4
    la $s5, COLOR_L
    lw $s0, ADDR_DSPL
    
    la $s2, block_type
    la $s7, L
    sw $s7, 0($s2)

    mul $s1, $a0, 4  # x * 4
    mul $s2, $a1, 64  # y * 64
    add $s1, $s1, 4
    add $s3, $s1, $s2  #  Real position
    add $s3, $s3, $s0
    lw $s4, 0($s5)  # Yellow
    add $t7, $s4, $zero  # Update color
    sw $s4, ($s3)
    sw $s4, 4($s3)
    sw $s4, 8($s3)
    sw $s4, 64($s3)
    la $s6, block  # Update array
    sw $s3, ($s6)
    addi $s3, $s3, 4
    sw $s3, 4($s6)
    addi $s3, $s3, 4
    sw $s3, 8($s6)
    addi $s3, $s3, 56
    sw $s3, 12($s6)
    
    jr $ra

DRAW_J:
    lw $a0, ($sp)  # X Position
    addi $sp, $sp, 4
    lw $a1, ($sp)  # Y Position
    addi $sp, $sp, 4
    la $s5, COLOR_J
    lw $s0, ADDR_DSPL
    
    la $s2, block_type
    la $s7, J
    sw $s7, 0($s2)

    mul $s1, $a0, 4  # x * 4
    mul $s2, $a1, 64  # y * 64
    add $s1, $s1, 4
    add $s3, $s1, $s2  #  Real position
    add $s3, $s3, $s0
    lw $s4, 0($s5)  # Yellow
    add $t7, $s4, $zero  # Update color
    sw $s4, ($s3)
    sw $s4, 4($s3)
    sw $s4, 8($s3)
    sw $s4, 72($s3)
    la $s6, block  # Update array
    sw $s3, ($s6)
    addi $s3, $s3, 4
    sw $s3, 4($s6)
    addi $s3, $s3, 4
    sw $s3, 8($s6)
    addi $s3, $s3, 64
    sw $s3, 12($s6)
    
    jr $ra
DRAW_T:
    lw $a0, ($sp)  # X Position
    addi $sp, $sp, 4
    lw $a1, ($sp)  # Y Position
    addi $sp, $sp, 4
    la $s5, COLOR_T
    lw $s0, ADDR_DSPL
    
    la $s2, block_type
    la $s7, T
    sw $s7, 0($s2)

    mul $s1, $a0, 4  # x * 4
    mul $s2, $a1, 64  # y * 64
    add $s1, $s1, 4
    add $s3, $s1, $s2  #  Real position
    add $s3, $s3, $s0
    lw $s4, 0($s5)  # Yellow
    add $t7, $s4, $zero  # Update color
    sw $s4, ($s3)
    sw $s4, 4($s3)
    sw $s4, 8($s3)
    sw $s4, 68($s3)
    la $s6, block  # Update array
    sw $s3, ($s6)
    addi $s3, $s3, 4
    sw $s3, 4($s6)
    addi $s3, $s3, 4
    sw $s3, 8($s6)
    addi $s3, $s3, 60
    sw $s3, 12($s6)
    
    jr $ra

ERASE_BLOCK:
    addi $sp, $sp, -4
    sw $ra, ($sp)  # Store addr
    
    la $s0, block
    lw $a1, ($s0)
    
    addi $sp, $sp, -4
    sw $a1, ($sp)  # First position
    
    jal ERASE
    
    lw $a1, 4($s0)
    addi $sp, $sp, -4
    sw $a1, ($sp)  # Second position
    
    jal ERASE
    
    lw $a1, 8($s0)
    addi $sp, $sp, -4
    sw $a1, ($sp)  # Third position
    
    jal ERASE
    
    lw $a1, 12($s0)
    addi $sp, $sp, -4
    sw $a1, ($sp)  # Fourth position
    
    jal ERASE
    
    lw $ra, ($sp)
    addi $sp, $sp, 4
    
    jr $ra

IS_COLLISION:
    addi $sp, $sp, -4
    sw $ra, ($sp)  # Store addr
    la $a0, new_block
    lw $s0, ($a0)  # First position
    li $s2, 0 # i = 0
    la $a1, COLOR
    lw $s5, 4($a1)
    lw $s6, 8($a1)
    li $a3, 0 # Result
    COLLISION_LOOP:
    	beq $s2, 16, COLLISION_LOOP_END
    	add $s3, $a0, $s2 # Blcok array pos
    	lw $s1, ($s3)
    	lw $s1, ($s1)
    	beq $s1, $s5, COLLISION_SAFE
    	beq $s1, $s6, COLLISION_SAFE
    	b COLLISION_FOUND
    	COLLISION_SAFE:
    	addi $s2, $s2, 4
    	b COLLISION_LOOP
    COLLISION_FOUND:
    	li $a3, 1
    COLLISION_LOOP_END:
        lw $ra, ($sp)
   	 addi $sp, $sp, 4
    
        addi $sp, $sp, -4
        sw $a3, ($sp)

    jr $ra
    
TRANSFER_NEW_TO_ARRAY:
    addi $sp, $sp, -4
    sw $ra, ($sp)  # Store addr
    la $a0, block
    la $a1, new_block
    li $s0, 0 # i = 0
    TRANSFER_LOOP:
    	beq $s0, 16, TRANSFER_END
    	add $s1, $a0, $s0 # block
    	add $s2, $a1, $s0 # new block
    	lw $s3, ($s2)
    	sw $s3, ($s1)
    	
    	addi $s0, $s0, 4
    	b TRANSFER_LOOP
    TRANSFER_END:
    lw $ra, ($sp)
    addi $sp, $sp, 4
    jr $ra
    
CLEAR_LINE:
    li $v0,31
    la $a0,clear
    lw $a0 0($a0)
    addi $a2,$a0,12
    la $a1,duration
    lw $a1, 0($a1)
    la $a3, volume

    move $a2,$a0
    move $s1,$a1

    syscall
    addi $sp, $sp, -4
    sw $ra, ($sp)  # Store addr
    la $s0, block
    la $a0, COLOR
    lw $a1, 4($a0) # Gray
    lw $a2, 8($a0) # Gray
    
    li $s2, 0 # i = 0
    CLEAR_LOOP:
        lw $s1, ADDR_DSPL
        beq $s2, 16, CLEAR_END
        add $s3, $s0, $s2 # Real address of block array
        lw $s4, ($s3)
        addi $s4, $s4, -0x10008000
        div $s4, $s4, 64
        mul $s4, $s4, 64
        addi $s4, $s4, 4
        add $a3, $s4, $s1 # Restore addr
        li $s5, 0 # j = 0
        CHECK_CLEAR_LOOP:
            beq $s5, 56, CHECK_CLEAR_LOOP_END # 14 * 4
            add $s6, $s5, $a3
            lw $s7, ($s6)
            beq $s7, $a1, FOUND_NOT_BLOCK
            beq $s7, $a2, FOUND_NOT_BLOCK
            addi $s5, $s5, 4
            b CHECK_CLEAR_LOOP
    	CHECK_CLEAR_LOOP_END: # A row of blocks occupied
    	li $s5, 0 # j = 0
    	CLEAR_LINE_BLOCK_LOOP:
    	    beq $s5, 56, CLEAR_LINE_BLOCK_LOOP_END # 14 * 4
    	    add $s6, $s5, $a3
    	    addi $sp, $sp, -4
    	    sw $s2, ($sp) # Push $s2 to stack
    	    addi $sp, $sp, -4
            sw $s6, ($sp) 
            jal ERASE
            lw $s2, ($sp) # Pop $s2 from stack
            addi $sp, $sp, 4
    	    addi $s5, $s5, 4
    	    b CLEAR_LINE_BLOCK_LOOP
    	CLEAR_LINE_BLOCK_LOOP_END:
    	addi $a3, $a3, 52 # End of this row
        DROP_DOWN_LOOP:
        beq $a3, 0x10008068, DROP_DOWN_LOOP_END
        addi $s1, $a3, -64
        lw $s3, ($s1)
        beq $s3, 0x17161a, DROP_DOWN_NO_CHANGE
        beq $s3, 0x1b1b1b, DROP_DOWN_NO_CHANGE
        beq $s3, 0x808080, DROP_DOWN_NO_CHANGE
        sw $s3, ($a3)
        addi $sp, $sp, -4
        sw $s2, ($sp) # Push $s2 to stack
        addi $sp, $sp, -4
        sw $s1, ($sp)
        jal ERASE
        lw $s2, ($sp) # Pop $s2 from stack
        addi $sp, $sp, 4
        DROP_DOWN_NO_CHANGE:
        addi $a3, $a3, -4
        b DROP_DOWN_LOOP
    	FOUND_NOT_BLOCK: # Not a row of blocks occupied
    	DROP_DOWN_LOOP_END:
        addi $s2, $s2, 4 # i += 4
        b CLEAR_LOOP
    CLEAR_END:
    lw $ra, ($sp)
    addi $sp, $sp, 4
    jr $ra
    
IS_GAME_OVER:
    addi $sp, $sp, -4
    sw $ra, ($sp)
    lw $a0  ADDR_DSPL
    la $a1, COLOR
    lw $s4, 4($a1)
    lw $s5, 8($a1)
    li $s0, 4 # i = 4
    CHECK_GAME_OVER_LOOP:
        beq $s0, 56, CHECK_GAME_OVER_LOOP_END
        add $s1, $s0, $a0
        lw $s2, ($s1)
        beq $s2, $s4, GAME_SAFE
        beq $s2, $s5, GAME_SAFE
        b GAME_FOUND_NOT_BLOCK
        GAME_SAFE:
        addi $s0, $s0, 4
        b CHECK_GAME_OVER_LOOP
    GAME_FOUND_NOT_BLOCK: # Game Over
    jal GAME_OVER
    li $v0, 10  # Terminate
    syscall
    CHECK_GAME_OVER_LOOP_END:
    lw $ra, ($sp)
    addi $sp, $sp, 4
    jr $ra

GAME_OVER:
    li $s0, 0
    lw $s1, ADDR_DSPL
    la $s2, RETRY_CHAR
    
    li $v0, 31    # async play note syscall
    li $a0, 60    # midi pitch
    li $a1, 1000  # duration
    li $a2, 0    # instrument
    li $a3, 200   # volume
    syscall
    
    DRAW_GAME_OVER_LOOP:
    beq $s0, 216, DRAW_GAME_OVER_END
    add $s3, $s0, $s2
    lw $s3, ($s3)
    mul $s3, $s3, 4
    add $s3, $s3, $s1
    addi $s3, $s3, 256
    li $s4, 0xffffff
    sw $s4, ($s3)
    addi $s0, $s0, 4
    b DRAW_GAME_OVER_LOOP
    DRAW_GAME_OVER_END:
    CHECK_KBRD_LOOP:
    lw $t3, ADDR_KBRD
    lw $t8, 0($t3)
    beq $t8, 1, press_game_over
    press_game_over:
        lw $t2, 4($t3) 
        beq $t2, 0x72, press_r
    b CHECK_KBRD_LOOP
    press_r:
    b main

SAVE_GRID:
    addi $sp, $sp, -4
    sw $ra, ($sp)
    lw $a0, ADDR_DSPL
    la $a1, grid_temp
    li $s0, 0
    SAVE_GRID_LOOP:
    beq $s0, 2048, SAVE_GRID_LOOP_END
    add $s1, $a0, $s0
    add $s2, $a1, $s0
    lw $s3, ($s1)
    sw $s3, ($s2)
    addi $s0, $s0, 4
    b SAVE_GRID_LOOP
    SAVE_GRID_LOOP_END:
    
    lw $ra, ($sp)
    addi $sp, $sp, 4
    jr $ra
    
DRAW_GRID_ARRAY:
    addi $sp, $sp, -4
    sw $ra, ($sp)
    lw $a0, ADDR_DSPL
    la $a1, grid_temp
    li $s0, 0
    DRAW_GRID_ARRAY_LOOP:
    beq $s0, 2048, DRAW_GRID_ARRAY_LOOP_END
    add $s1, $a0, $s0
    add $s2, $a1, $s0
    lw $s3, ($s2)
    sw $s3, ($s1)
    addi $s0, $s0, 4
    b DRAW_GRID_ARRAY_LOOP
    DRAW_GRID_ARRAY_LOOP_END:
    lw $ra, ($sp)
    addi $sp, $sp, 4
    jr $ra
    
DRAW_PAUSE:
    la $a0, PAUSE_ARRAY
    li $s0, 0
    li $s1, 0 # offset
    lw $a2, ADDR_DSPL
    DRAW_PAUSE_LOOP_1:
    beq $s0, 9, DRAW_PAUSE_LOOP_END1
    li $s2, 0
    DRAW_PAUSE_LOOP_2:
    beq $s2, 16, DRAW_PAUSE_LOOP_END2
    add $s3, $a0, $s2
    lw $s4, ($s3)
    mul $s4, $s4, 4
    add $s4, $s4, $a2
    add $s4, $s4, $s1
    li $s5, 0xffffff
    sw $s5, ($s4)
    addi $s2, $s2, 4
    b DRAW_PAUSE_LOOP_2
    DRAW_PAUSE_LOOP_END2:
    addi $s0, $s0, 1
    addi $s1, $s1, 64
    b DRAW_PAUSE_LOOP_1
    DRAW_PAUSE_LOOP_END1:
    jr $ra