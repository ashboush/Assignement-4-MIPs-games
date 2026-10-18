.data

mazeFilename:    .asciiz "/Users/ashleyboushehri/MIPS Code/input_1.txt"

.align 2
buffer:          .space 4096
victoryMessage:  .asciiz "\nYou escaped the maze!"
startMessage:	  .asciiz "Move to the exit fast!!!! Don't step on a bomb.(w,a,s,d)\n"
exitMessage: 	.asciiz "\nYou quit? Okay..."
loseMessage:    .asciiz "\nBOOOOOOOOOOM! You stepped a big bomb. You died!\n"

amountOfRows:    .word 16  #pixel rows
amountOfColumns: .word 32  #pixel columns

wallColor:      .word 0x004286F4    #blue
passageColor:   .word 0x00000000    #black
playerColor:    .word 0x00FFFF00    #yellow
exitColor:      .word 0x0000FF00    #green
bombColor:      .word 0x00FF0000    #red

.text
.globl main

main:
#reading the maze
	addi $sp, $sp, -8
	jal readfile
	lw $s3, 4($sp)
#color bitmap
	jal color_bitmap
	
map_done: 
#print start 
    	li $v0, 4
    	la $a0, startMessage
    	syscall
	j mainLoop

mainLoop:
#check if player found exit
	bne $s1, $s4, no_exit
	beq $s2, $s5, victory
	j no_exit
no_exit:
#wait 60 ms
    	li $v0, 32
    	li $a0, 60 #wait time in $a0
    	syscall
    	
#keyboard move input
	li $v0, 12
	syscall
	li $t1, 'w'
	li $t2, 's'
	li $t3, 'a'
	li $t4, 'd'
	li $t5, 'x'
#call right move for each letter
	beq $v0, $t1, moveUp
	beq $v0, $t2, moveDown
	beq $v0, $t3, moveLeft
	beq $v0, $t4, moveRight
	beq $v0, $t5, exitGame

	j mainLoop 

moveUp:
	move $t0 $s1 
    	addi $t0, $t0, -1 #row -1
    	move $a0, $s1 
	move $a1, $s2	
	move $a2, $t0 
	move $a3, $s2 
	jal move_player
    	j mainLoop

moveDown:
	move $t0 $s1 
    	addi $t0, $t0, 1 # row + 1
    	move $a0, $s1 
	move $a1, $s2	
	move $a2, $t0 
	move $a3, $s2 
	jal move_player
    	j mainLoop

moveLeft:
	move $t0 $s2 #move column position to a temp register
    	addi $t0, $t0, -1 # column -1
    	move $a0, $s1 #load old pos in $a reg
	move $a1, $s2	
	move $a2, $s1 #load row
	move $a3, $t0 #load new column
	jal move_player
    	j mainLoop

moveRight:
	move $t0 $s2 #move column position to a temp register
    	addi $t0, $t0, 1 # column +1
    	move $a0, $s1 #load old pos in $a reg
	move $a1, $s2	
	move $a2, $s1 #load row
	move $a3, $t0 #load new column
	jal move_player
    	j mainLoop

exitGame:
    	#print game exit message
    	li $v0, 4
    	la $a0, exitMessage
    	syscall
    	#end game
    	li $v0, 10 #syscall 10 = exit
    	syscall
    
victory:
    	#print winner message
    	li $v0, 4 #syscall 4 = print string
    	la $a0, victoryMessage
    	syscall
    	#end game
    	li $v0, 10
    	syscall

gameOver:
    li $v0, 4
    la $a0, loseMessage
    syscall

    li $v0, 10
    syscall

move_player:
	addi $sp, $sp, -8 #reserve space for fp and ra
	sw $fp, 0($sp) #store fp
	sw $ra, 4($sp) #store ra
	move $fp, $sp #set new fp

#check if new position is valid
	#is it within screen boarders?
	blt $a2, 0, invalid_pos
	bgt $a2, 15, invalid_pos
	blt $a3, 0, invalid_pos
	bgt $a3, 31, invalid_pos
	#is it a wall?
	lw $t0, wallColor
	addi $sp, $sp, -20 #reserve space for args
	#leave some slots open for the function to work
	sw $a2, 16($sp)	#push arg (row)
	sw $a3, 12($sp)	#push arg (column)
	
	jal calculate_memory_address
	
	lw $ra, 4($fp)
	lw $t1, 4($sp) 
	move $sp, $fp 
	lw $t3, 0($t1) 
	lw $t0, wallColor #load blue 
	beq $t0, $t3, invalid_pos #check if wall by the color blue
#check for bomb
	lw $t0, bombColor
	beq $t0, $t3, gameOver
#if all pass then its a valid position
	j valid_pos
	
invalid_pos:
#invalid position (wall) dont move player
	move $v0, $a0 # return old pos
	move $v1, $a1
	move $s1, $v0 # save pos at $s regs
	move $s2, $v1
	jr $ra

valid_pos:
    	move $v0, $a2      #new roq
    	move $v1, $a3      #new column
    	move $s1, $v0      #save new row
    	move $s2, $v1      #save new column
	j change_pos

change_pos:
#clear old player pixel
	move $t0, $a0
	move $t1, $a1
	lw $t6, passageColor
	
	addi $sp, $sp, -20 #reserve space for args
	sw $t0, 16($sp) #store row number
	sw $t1, 12($sp) #store column number
	sw $t6, 8($sp) #store color
	#leave the other 2 slots open for the function to work
	
	jal color_pixel
	
#draw new player pixel
	move $t0, $a2 #put new pos in temp register
	move $t1, $a3
	lw $t6, playerColor #load color to temp register
	addi $sp, $sp, -20 #reserve space for args
	sw $t0, 16($sp) #store row number
	sw $t1, 12($sp) #store column number
	sw $t6, 8($sp) #store color
	#leave the other 2 slots open for the function to work.
	
	jal color_pixel
	
	lw $ra, 4($fp)
	jr $ra

color_bitmap:
	li $t0, 0 #initialize row number
	li $t1, 0 #initialize column number

	addi $sp, $sp, -12 #reserve space
	sw $t0, 8($sp) # row number
	sw $t1, 4($sp) # column number
	sw $s3, 0($sp) 

	j readbuffer
	
readbuffer:
    	addi $sp, $sp, -8 #make space for $fp and $ra
    	sw $fp, 0($sp) #store old fp
    	sw $ra, 4($sp) #store ra
    	move $fp, $sp #set new fp
    	
 # retrieve args
    	lw $t0, 16($fp)
    	lw $t1, 12($fp) 
    	lw $t2, 8($fp) 
    	
    	li $t3, 0 # number of chars read
    	
 #open the file
        li $v0, 13  # syscall code for opening a file
        la $a0, mazeFilename   # address of the filename
        li $a1, 0 
        li $a2, 0 
        syscall
        move $s0, $v0

#read the file into the buffer
        li $v0, 14  #syscall code for reading a file
        move $a0, $s0
        la $a1, buffer 
        li $a2, 4096 #number of bytes to read
        syscall

#loop through each character in the buffer
        la $t4, buffer  #load the address of the beginning of the buffer into $t4
	li $t3, 0 #initialise # chars read
	
loop:
        lb $t5, 0($t4) #load the character from memory into $t5
        beq $t3, $t2, map_done #go to loop end when all characters have been read
        
	beq $t5, 'w', wall
	beq $t5, 'p', passage
	beq $t5, 's', player
	beq $t5, 'u', exit_point
	beq $t5, 'b', bomb
	j newline # 'default'

wall:
  	lw $t6, wallColor
#pass args to color_pixel()
	addi $sp, $sp, -20 
	sw $t0, 16($sp) #row number
	sw $t1, 12($sp) #column number
	sw $t6, 8($sp) #color
	sw $t2, 4($sp) # # chars to read
	sw $t3, 0($sp) # chars read
	
	jal color_pixel
	j next_char
		
newline:

	addi $t3, $t3, 1 #increment number of chars read
        addi $t4, $t4, 1  #increment buffer address
        j loop
        
passage:
  	lw $t6, passageColor
	# pass args to color_pixel()
	addi $sp, $sp, -20 
	sw $t0, 16($sp)
	sw $t1, 12($sp) 
	sw $t6, 8($sp)
	sw $t2, 4($sp) 
	sw $t3, 0($sp)
	jal color_pixel
	j next_char
		
player:
  	lw $t6, playerColor
	# pass args to color_pixel()
	addi $sp, $sp, -20 
	sw $t0, 16($sp)
	sw $t1, 12($sp) 
	sw $t6, 8($sp) 
	sw $t2, 4($sp) 
	sw $t3, 0($sp)
	move $s1, $t0 
	move $s2, $t1 
	jal color_pixel

	j next_char
		
exit_point:
  	lw $t6, exitColor

	addi $sp, $sp, -20 
	sw $t0, 16($sp) 
	sw $t1, 12($sp)
	sw $t6, 8($sp)
	sw $t2, 4($sp)
	sw $t3, 0($sp)
	
	move $s4, $t0 # save exit position
	move $s5, $t1
	jal color_pixel
	j next_char

bomb:
    lw $t6, bombColor

    addi $sp, $sp, -20
    sw $t0, 16($sp) #row
    sw $t1, 12($sp) #column
    sw $t6, 8($sp)   #red color
    sw $t2, 4($sp) #chars to read
    sw $t3, 0($sp) #chars read

    jal color_pixel

    j next_char

next_char:
    	addi $t3, $t3, 1 #increment number of chars read
        addi $t4, $t4, 1 #increment buffer address
        
        # increment row and col
       	bgt $t1, 31, endl #check if column number is out of range
       	j not_endl 
       	
endl:
        addi $t0, $t0, 1 #increment row number
        li $t1, 0 #reset column number
        
not_endl:
	addi $t1, $t1, 1 #increment column num        
        j loop

end_loop:
    	#close the file
    	li $v0, 16
    	move $a0, $s0
    	syscall
    	#restore saved registers
    	move $sp, $fp
    	lw $ra, 4($sp)
    	lw $fp, 0($sp)
    	#remove stack frame
    	addi $sp, $sp, 8

    	jr $ra
    	
color_pixel:
	addi $sp, $sp, -8   # reserve space on stack for $ra, and fp
	sw $fp, 0($sp)
	sw $ra, 4($sp)	
	move $fp, $sp	

#pass args calculate_memory_address
	addi $sp, $sp, -20
	lw $t0, 24($fp)	# retrieve row num
	sw $t0, 16($sp)	
	lw $t0, 20($fp)	#retrieve column num
	sw $t0, 12($sp)
	lw $t0, 16($fp)	#retrieve color
	sw $t0, 8($sp) 
	lw $t0, 12($fp) #retrieve num chars to read
	sw $t0, 4($sp) 
	lw $t0, 8($fp) #retrieve num chars read (restore purposes)
	sw $t0, 0($sp) 

    	jal calculate_memory_address
    
    	lw $t5, 4($sp) 
    	sw $t6, 0($t5) #write color 
    	move $sp, $fp	  

       	lw $ra, 4($fp)
       	lw $fp, 0($sp)	
	jr $ra

calculate_memory_address:

	addi $sp, $sp, -12 #reserve place for $fp, returnval, $ra
	sw $ra, 8($sp)
	# returnval will be put at 4($fp)
	sw $fp, 0($sp)	#save old fp 

	move $fp, $sp	#set fp to current sp
   
    	lw $t0, 28($fp) #row number
    	lw $t1, 24($fp) #column number
    
    	#compute offset from $gp
    	mul $t2, $t0, 32      
    	mul $t2, $t2, 4     #4 bytes per pixel
    	mul $t1, $t1, 4     #4 bytes per pixel
    	add $t3, $t2, $t1       # $t3 = row_offset + column_offset
    	move $s0, $gp    #load the val of $gp into $s0 (the starting address of the pixel data)
    	add $v0, $s0, $t3       # $v0 = $gp + row_offset + column_offset
    
    	andi $t2, $v0, 3  
    	subu $v0, $v0, $t2  
    
    	sw $v0, 4($fp) 
    
    	#restore temps
    	lw $t0, 28($fp) #row
    	lw $t1, 24($fp) #column
    	lw $t6, 20($fp) #color
    	lw $t2, 16($fp) #chars to read
    	lw $t3, 12($fp) #chars read
    	move $sp, $fp  #pop frame
        lw $fp, 0($fp) #old framepointer

    	jr $ra 

readfile:

	sw $fp, 0($sp)	#store old fp
	move $fp, $sp	#set fp to current sp
	
	#open file to read
	li $v0, 13 #system call for open file
	la $a0, mazeFilename #output file name
	li $a1, 0 #Open for writing --flags are 0: read 1: write
	li $a2, 0 
	syscall
	move $s6, $v0 #save the file descriptor

	#read from file to buffer
	li $v0, 14 # system call for read from file
	move $a0, $s6 
	la $a1, buffer 
	li $a2, 2048 #hardcode max number of characters to size of buffer)
	syscall 
	move $s3, $v0 # save num chars to read in $s3

	sw $v0, 4($fp)	#store returnval above fp

	#close the file
	li $v0, 16 # system call for close file
	move $a0, $s6 
	syscall

	move $sp, $fp #pop frame
	lw $fp, 0($fp)	#restore old fp

	jr $ra		# return

