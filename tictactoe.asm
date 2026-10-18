.data
board:          .word 0,0,0,0,0,0,0,0,0
currentPlayer:  .word 1
moveCount:      .word 0
welcome:        .asciiz "\nTIC TAC TOE\n"
instructions:   .asciiz "Choose a position from 1-9.\n"
promptX:        .asciiz "\nPlayer X - Choose a square (1-9): "
promptO:        .asciiz "\nPlayer O - Choose a square (1-9): "
invalid:        .asciiz "\nInvalid move. Try again.\n"
xWins:          .asciiz "\nPLAYER X WINS!\n"
oWins:          .asciiz "\nPLAYER O WINS!\n"
tie:     .asciiz "\nTIE GAME!\n"
divider:        .asciiz "\n-----------\n"
bar:            .asciiz " | "
newline:        .asciiz "\n"
X:              .asciiz "X"
O:              .asciiz "O"
empty:          .asciiz " "

.text
.globl main
main:

    #print welcome message
    li $v0, 4
    la $a0, welcome
    syscall

    #print instructions
    li $v0, 4
    la $a0, instructions
    syscall

    #print empty board
    jal print_board

game_loop:

    #load current player
    lw $t4, currentPlayer

    #check if current player is X
    li $t5, 1
    beq $t4, $t5, player1_prompt

player2_prompt:

    li $v0, 4
    la $a0, promptO
    syscall

    j read_move

player1_prompt:
    li $v0, 4
    la $a0, promptX
    syscall

read_move:
    #read integer
    li $v0, 5
    syscall
    #save input in $t0
    move $t0, $v0
    # convert into array index 0-8
    addi $t0, $t0, -1
    #check if less than 0
    bltz $t0, bad_move
    #check if greater than 8
    li $t1, 8
    bgt $t0, $t1, bad_move
    #find address of board position
    sll $t1, $t0, 2
    la $t2, board
    add $t2, $t2, $t1
    #check if square is filled
    lw $t3, 0($t2)
    bne $t3, $zero, bad_move
    #load current player
    lw $t4, currentPlayer
    #store move on board
    sw $t4, 0($t2)
    #add to move counter
    lw $t0, moveCount
    addi $t0, $t0, 1
    sw $t0, moveCount
    #print new board
    jal print_board
    #check for winner
    jal check_winner
    li $t0, 1
    beq $v0, $t0, x_winner
    li $t0, 2
    beq $v0, $t0, o_winner
    #checkw for tie
    lw $t0, moveCount
    li $t1, 9
    beq $t0, $t1, tie_game
    #switch players
    lw $t4, currentPlayer
    li $t5, 1
    #if X just played, switch to O
    beq $t4, $t5, switch_to_2
    li $t4, 1
    sw $t4, currentPlayer

    j game_loop

switch_to_2:
    li $t4, 2
    sw $t4, currentPlayer
    
    j game_loop

bad_move:
    li $v0, 4
    la $a0, invalid
    syscall

    j game_loop

x_winner:
    li $v0, 4
    la $a0, xWins
    syscall

    j end_game

o_winner:
    li $v0, 4
    la $a0, oWins
    syscall

    j end_game

tie_game:
    li $v0, 4
    la $a0, tie
    syscall

    j end_game

end_game:
    li $v0, 10
    syscall

check_winner:
    #get address of board
    la $t0, board

    #check row 1
    lw $t1, 0($t0)
    lw $t2, 4($t0)
    lw $t3, 8($t0)
    beq $t1, $zero, check_row2
    #check if all three are equal
    bne $t1, $t2, check_row2
    bne $t1, $t3, check_row2
    #winner found
    move $v0, $t1
    jr $ra

check_row2:

    lw $t1, 12($t0)
    lw $t2, 16($t0)
    lw $t3, 20($t0)
    beq $t1, $zero, check_row3
    bne $t1, $t2, check_row3
    bne $t1, $t3, check_row3
    move $v0, $t1
    jr $ra

check_row3:

    lw $t1, 24($t0)
    lw $t2, 28($t0)
    lw $t3, 32($t0)
    beq $t1, $zero, check_col1
    bne $t1, $t2, check_col1
    bne $t1, $t3, check_col1
    move $v0, $t1
    jr $ra

check_col1:
    lw $t1, 0($t0)
    lw $t2, 12($t0)
    lw $t3, 24($t0)
    beq $t1, $zero, check_col2
    bne $t1, $t2, check_col2
    bne $t1, $t3, check_col2
    move $v0, $t1
    jr $ra
    
check_col2:
    lw $t1, 4($t0)
    lw $t2, 16($t0)
    lw $t3, 28($t0)
    beq $t1, $zero, check_col3
    bne $t1, $t2, check_col3
    bne $t1, $t3, check_col3
    move $v0, $t1
    jr $ra

check_col3:

    lw $t1, 8($t0)
    lw $t2, 20($t0)
    lw $t3, 32($t0)
    beq $t1, $zero, check_diag1
    bne $t1, $t2, check_diag1
    bne $t1, $t3, check_diag1
    move $v0, $t1
    jr $ra

check_diag1:

    lw $t1, 0($t0)
    lw $t2, 16($t0)
    lw $t3, 32($t0)
    beq $t1, $zero, check_diag2
    bne $t1, $t2, check_diag2
    bne $t1, $t3, check_diag2
    move $v0, $t1
    jr $ra

check_diag2:

    lw $t1, 8($t0)
    lw $t2, 16($t0)
    lw $t3, 24($t0)
    beq $t1, $zero, no_winner
    bne $t1, $t2, no_winner
    bne $t1, $t3, no_winner
    move $v0, $t1
    jr $ra


no_winner:
    li $v0, 0
    jr $ra

print_board:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    la $t6, board
    li $t7, 0

print_loop:
    lw $t8, 0($t6)
    li $t9, 1
    beq $t8, $t9, print_x
    li $t9, 2
    beq $t8, $t9, print_o

print_empty:
    li $v0, 4
    la $a0, empty
    syscall
    j after_square

print_x:
    li $v0, 4
    la $a0, X
    syscall
    j after_square
print_o:
    li $v0, 4
    la $a0, O
    syscall
after_square:
    addi $t6, $t6, 4
    addi $t7, $t7, 1
    li $t9, 3
    beq $t7, $t9, print_divider
    li $t9, 6
    beq $t7, $t9, print_divider
    li $t9, 9
    beq $t7, $t9, board_finished
    li $v0, 4
    la $a0, bar
    syscall
    j print_loop

print_divider:
    li $v0, 4
    la $a0, divider
    syscall
    j print_loop

board_finished:
    li $v0, 4
    la $a0, newline
    syscall
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
