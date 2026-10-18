.data
welcome: .asciiz "\n BLACKJACK \nThe goal is to try to get as close to 21 as possible.\nAces count as 11 or 1.\nJ, Q, and K count as 10.\n"
dealerCardsText: .asciiz "\nDealer's cards: "
playerCardsText: .asciiz "\nYour cards: "
dealerTotalText: .asciiz "\nDealer's total: "
playerTotalText: .asciiz "\nYour total: "
choiceText: .asciiz "\n\nEnter 1 to hit or 2 to stand: "
invalidText: .asciiz "\nInvalid chocie. Please enter 1 or 2: "
hitText: .asciiz "\n\nYou hit"
standText: .asciiz "\n\nYou stand. Dealer's turn \n"
dealerHitText: .asciiz "\nDealer hits"
dealerStandText: .asciiz "\nDealer stands"
playerBustText: .asciiz "\n\nBust! You went over 21.\n"
dealerBustText: .asciiz "\n\nDealer went over 21. Dealer busts!\n"
winText: .asciiz "\n\nYOU WIN!\n"
loseText: .asciiz "\n\nDEALER WINS!\n"
tieText: .asciiz "\n\nTIE GAME!\n"
commaSpace: .asciiz ", "
newline: .asciiz "\n"

cardA: .asciiz "A"
card2: .asciiz "2"
card3: .asciiz "3"
card4: .asciiz "4"
card5: .asciiz "5"
card6: .asciiz "6"
card7: .asciiz "7"
card8: .asciiz "8"
card9: .asciiz "9"
card10: .asciiz "10"
cardJ: .asciiz "J"
cardQ: .asciiz "Q"
cardK: .asciiz "K"

#array of addresses of card names
cardNames:
    .word cardA
    .word card2
    .word card3
    .word card4
    .word card5
    .word card6
    .word card7
    .word card8
    .word card9
    .word card10
    .word cardJ
    .word cardQ
    .word cardK
    
playerCards: .space 48
dealerCards: .space 48

#num of cards in each hand
playerCount: .word 0
dealerCount: .word 0

.text
.globl main

main:
#print opening message
	li $v0, 4
	la $a0, welcome
	syscall 
#deal player's cards
	jal random_card  #$v0 has random
	la $t0, playerCards
	sw $v0, 0($t0) #stores random card in $v0 into the playerCards
	li $t1, 1
	sw $t1, playerCount #adds 1 to player's card count 
	
	jal random_card
	la $t0, playerCards 
	sw $v0, 4($t0) #each entry is a word that takes 4 bytes. storing the second card requires a 4 byte offset 
	li $t1, 2
	sw $t1, playerCount #makes player count 2 
#deal dealer's cards
	jal random_card 
	la $t0, dealerCards
	sw $v0, 0($t0)
	li $t1, 1
	sw $t1, dealerCount
	
	jal random_card
	la $t0, dealerCards
	sw $v0, 4($t0)
	li $t1, 2
	sw $t1, dealerCount
#display hands
	jal display_game 
	
#player's turn
player_turn: 
#calc total 
	la $a0, playerCards
	lw $a1, playerCount
	jal calculate_total
	move $s0, $v0 #save player's total in $s0

#check for bust 
	move $a0, $s0
	jal check_bust
	# $v0 = 1 means bust 
	li $t0, 1
	beq $v0, $t0, player_busted 
#if at 21 auto stand 
	li $t0, 21
	beq $v0, $t0, player_stand

#ask for move 
ask_choice:
	li $v0, 4 
	la $a0, choiceText
	syscall 
	#read int from user
	li $v0, 5
	syscall
	move $t0, $v0 #save choice in $t0
	
#1 = hit
	li $t1, 1
	beq $t0, $t1, player_hit
#2 = stand
	li $t1, 2
	beq $t0, $t1, player_stand
#invalid
	li $v0, 4
	la $a0, invalidText
	syscall
	j ask_choice

player_hit:
#print hit message 
	li $v0, 4
	la $a0, hitText
	syscall
#random new card
	jal random_card
	move $t7, $v0 # temp save
	lw $t0, playerCount 
	la $t1, playerCards
	sll $t2, $t0, 2 #offset
	#move to next empty array position 
	add $t1, $t1, $t2
	sw $t7, 0($t1) #store new card 
	addi $t0, $t0, 1 #increase card count 
	sw $t0, playerCount
#display updated hands
	jal display_game 
#go back to player turn 
	j player_turn 
	
#player busts
player_busted: 
	li $v0, 4
	la $a0, playerBustText
	syscall 
	
	j exit_program
	
#player stands 
player_stand: 
	li $v0, 4
	la $a0, standText 
	syscall 
	#start dealer's turn 
	jal dealer_turn 
	j compare_scores
	
#dealer's turn. must hit while below 17. must stand when total >= 17
dealer_turn: 
	#save return address 
	addi $sp, $sp, -4
	sw $ra, 0($sp)

dealer_loop:
#calc total
	la $a0, dealerCards
	lw $a1, dealerCount
	jal calculate_total
	#save total
	move $s1, $v0
#check for bust
	move $a0, $s1
	jal check_bust
	li $t0, 1
	beq $v0, $t0, dealer_turn_done 
#stand if 17 or higher
	li $t0, 17 
	bge $s1, $t0, dealer_stands
#hit
	li $v0, 4
	la $a0, dealerHitText
	syscall
#new card
	jal random_card
	move $t7, $v0 #save card
	#get card count
	lw $t0, dealerCount
	la $t1, dealerCards
	sll $t2, $t0, 2
	add $t1, $t1, $t2
	sw $t7, 0($t1) #store new card
	 #increase dealer count 
	addi $t0, $t0, 1
	sw $t0, dealerCount
#display new hands 
	jal display_game 
#checl total again
	j dealer_loop
	
dealer_stands:
	li $v0, 4
	la $a0, dealerStandText 
	syscall
dealer_turn_done:
#restore return address
	lw $ra, 0($sp)
	addi $sp, $sp, 4 
	jr $ra 
	
compare_scores:
#calc player total
	la $a0, playerCards 
	lw $a1, playerCount 
	jal calculate_total 
	move $s0, $v0 
#calc dealer total
	la $a0, dealerCards 
	lw $a1, dealerCount 
	jal calculate_total 
	move $s1, $v0 
#check if dealer busted
	move $a0, $s1
	jal check_bust
	li $t0, 1
	beq $v0, $t0, dealer_busted
#player total > dealer total ?
	bgt $s0, $s1, player_wins
#player total < dealer total?
	blt $s0, $s1, dealer_wins
#equal totals = tie  
	j tie_game

player_wins:
	li $v0, 4
	la $a0, winText
	syscall
	j exit_program

dealer_wins:
	li $v0, 4
	la $a0, loseText
	syscall
	j exit_program

dealer_busted:
	li $v0, 4
	la $a0, dealerBustText
	syscall
	j exit_program

tie_game:
	li $v0, 4
	la $a0, tieText
	syscall
	j exit_program

#random card created from 1 to 13. 1 = ace. 11 = jack, 12 = queen, 13 = king
random_card:
	#random in w upper bound 
	li $v0, 42
	#random number generator ID
	li $a0, 0
	#upper bound is 13
	li $a1, 13
	syscall
	addi $v0, $a0, 1 #adds one to make cards start at 1 and not 0
	jr $ra

calculate_total:
	li $t0, 0 # $t0 = array index
	li $t1, 0 # total
	li $t2, 0 #number of aces

calculate_loop:
	#stop when index == card count
	beq $t0, $a1, adjust_aces
#find card in arrray
	sll $t3, $t0, 2
    	# array address + offset
    	add $t4, $a0, $t3
    	lw $t5, 0($t4) #load card
	#check for ace
    	li $t6, 1
    	beq $t5, $t6, total_ace
	#check for face card
    	li $t6, 10
    	bgt $t5, $t6, total_face_card
	#normal cards
    	add $t1, $t1, $t5
    	j total_next_card

total_ace:
	#initially count aces as 11
   	addi $t1, $t1, 11
    	addi $t2, $t2, 1 
    	j total_next_card

total_face_card:
	#worth 10
    	addi $t1, $t1, 10

total_next_card:
    	addi $t0, $t0, 1
    	j calculate_loop

adjust_aces:
#if total if over 21, done
    	ble $t1, 21, total_done
#if no aces left to change, done
   	beq $t2, $zero, total_done
#chnage ace from 11 to 1. (subtract 10)
    	addi $t1, $t1, -10
    	addi $t2, $t2, -1
    	j adjust_aces

total_done:
    	move $v0, $t1
	jr $ra

check_bust:
    	li $t0, 21
	#check if total is over 21
    	bgt $a0, $t0, is_bust
	#no bust
    	li $v0, 0
    	jr $ra
    	
is_bust:
    	li $v0, 1
    	jr $ra

display_game:
 #save return address
    	addi $sp, $sp, -4
	sw $ra, 0($sp)
#display dealer cards
    	li $v0, 4
    	la $a0, dealerCardsText
    	syscall
    	la $a0, dealerCards
    	lw $a1, dealerCount
    	jal print_hand
#dealer total
    	li $v0, 4
    	la $a0, dealerTotalText
    	syscall
    	la $a0, dealerCards
    	lw $a1, dealerCount
    	jal calculate_total
#print total number 
    	move $a0, $v0
    	li $v0, 1
    	syscall
#display player cards
    	li $v0, 4
    	la $a0, playerCardsText
    	syscall
    	la $a0, playerCards
    	lw $a1, playerCount
    	jal print_hand
#player total
    	li $v0, 4
    	la $a0, playerTotalText
    	syscall
    	la $a0, playerCards
    	lw $a1, playerCount
    	jal calculate_total
#print int
    	move $a0, $v0
    	li $v0, 1
    	syscall
#new line
    	li $v0, 4
    	la $a0, newline
    	syscall
#restore return address
	lw $ra, 0($sp)
    	addi $sp, $sp, 4
    	jr $ra

print_hand:
#save array address
    	move $t8, $a0
#save number of cards
    	move $t9, $a1
    	li $t0, 0
    	
print_hand_loop:
    	beq $t0, $t9, print_hand_done

    	sll $t1, $t0, 2
    	add $t2, $t8, $t1
#load card num
    	lw $t3, 0($t2)
#find card name
    	addi $t3, $t3, -1
    	sll $t3, $t3, 2
    	la $t4, cardNames
	add $t4, $t4, $t3
	lw $a0, 0($t4)
#print card name
	li $v0, 4
    	syscall
#print comma unless last card
    	addi $t5, $t0, 1
	beq $t5, $t9, no_comma
    	li $v0, 4
    	la $a0, commaSpace
    	syscall

no_comma:
    	addi $t0, $t0, 1
    	j print_hand_loop

print_hand_done:
    	jr $ra

exit_program:
    li $v0, 10
    syscall

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
