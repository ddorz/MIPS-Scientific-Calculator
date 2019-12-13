# Dave Dorzback

.data
	infix: .space 256
	postfix: .space 256
	operator: .space 256
	choice: .space 3
	endMsg: .asciiz "\nDo you want to continue: enter 'y' to continue, and 'n' to stop\n>"
	byeMsg: .asciiz "Finish the logic function!\n"
	errorMsg: .asciiz "Input error\n"
	startMsg: .asciiz "\nEnter logic expression (1: for True, 0 for False, * for AND, + for OR, ! for NOT):\nThe expression includes 1, 0, *, +, ! and parenthesis\nFor example: (1 + 0 * 1) * 0 + (1 * 0 + 1) + 1 --> 1\n>"
	prompt_result: .asciiz "Result for the logic expression is: "
	stack: .word 256

.globl logicStart # Main global function	
			
.text

# Logic Start
logicStart:	
	li $v0,4
	la $a0, startMsg
	syscall
	
#get input
	li $v0, 8
 	la $a0, infix
 	li $a1, 100
 	syscall
 	

# Status
	li $s7,0		# Status 
				# 0 = initially receive nothing
				# 1 = receive number
				# 2 = receive operator
				# 3 = receive (
				# 4 = receive )
	li $t9,0		# Count digit
	li $t5,-1		# Postfix top offset
	li $t6,-1		# Operator top offset
	la $t1, infix		# Infix current byte address +1 each loop
	la $t2, postfix
	la $t3, operator	
	addi $t1,$t1,-1		# Set initial address of infix to -1
	
# Convert to postfix
scanInfix: 			# Loop for each character in postfix
# Check all valid input option
	addi $t1,$t1,1			# Increase infix position
	lb $t4, ($t1)			# Load current infix input
	beq $t4, ' ', scanInfix		# If scan spacebar ignore and scan again
	beq $t4, '\n', EOF		# Scan end of input --> pop all operator to postfix
	beq $t9,0,digit1		# If state is 0 digit
	beq $t9,1,digit2		# If state is 1 digit
	
	continueScan:
	beq $t4, '+', Plus
	beq $t4, '*', Multiply
	beq $t4, '!', Negate
	beq $t4, '(', openBracket
	beq $t4, ')', closeBracket
wrongInput:	# When detect wrong input situation
 	
 	li $v0, 4
 	la $a0, errorMsg
 	syscall
 	j ask
 	
finishScan:

# Calculate
	li $t9,-4		# Set top of stack offset to -4
	la $t3,stack		# Load stack address
	li $t6,-1		# Load current of Postfix offset to -1
	
calPost:
	addi $t6,$t6,1		# Increment current of Postfix offset 
	add $t8,$t2,$t6		# Load address of current Postfix
	lbu $t7,($t8)		# Load value of current Postfix
	bgt $t6,$t5,printResult	# Calculate for all postfix --> print
	beq $t7, 133,negCalc
	bgt $t7,1,calculate	# If current Postfix > 99 --> an operator --> popout 2 number to calculate
	# If not then current Postfix is a number
	addi $t9,$t9,4		# Current stack top offset
	add $t4,$t3,$t9		# Current stack top address
	
	sw $t7, ($t4)
	j calPost		# Loop
	calculate:
		# Pop 1 number
		add $t4,$t3,$t9		
		
		lw $s3, ($t4)
		# Pop next number
		addi $t9,$t9,-4
		add $t4,$t3,$t9		
		
		lw $s2, ($t4)
		# Decode operator
		beq $t7,143,plus
		beq $t7,142,multiply
		
		plus:

			add $s1, $s2, $s3  			
			bne $s1, $zero, set1
			
			sw $s1, ($t4)
			li $s2, 0
			li $s3, 0
				
			j calPost

		multiply:
			mul $s1, $s2, $s3
			bne $s1, $zero, set1
			
			sw $s1, ($t4)
			li $s2, 0
			li $s3, 0	
			j calPost
negCalc:
		# Pop 1 number
		add $t4,$t3,$t9		
		
		lw $s3, ($t4)
		beq $s3, $zero, set1
		beq $s3, 1, set0
		li $s3, 0
		j calPost
		
printResult:	
	li $v0, 4
	la $a0, prompt_result
	syscall
	
	li $v0, 1
	lw $s2,($t4)
	move $a0, $s2
	syscall
	
	li $v0, 11
	li $a0, '\n'
	syscall
	
ask: 			# Ask user to continue or not

 	li $v0, 4
 	la $a0, endMsg
 	syscall
 	
 	la $a0, choice
	li $v0, 8
	la $a1, 3
	syscall
	
	lb $t0, 0($a0)
	beq $t0, 'n', end
	beq $t0, 'N', end
	beq $t0, 'y', logicStart
	beq $t0, 'Y', logicStart
	
	
	la $a0, endMsg	# When user doesn't select y or n.
	la $v0, 4
	syscall
	b ask
	
	
# End program
end:
 	
 	li $v0, 4
 	la $a0, byeMsg
 	syscall
 	
 	b logicReturn	# Replaces exit syscall by returning to scientific_calc.asm
 
# Sub program
EOF:
	j popAll
digit1:
	beq $t4,'0',store1Digit
	beq $t4,'1',store1Digit
	jal numberToPost
	j continueScan
	
digit2: 
	beq $t4,'0',wrongInput
	beq $t4,'1',wrongInput
	# If do not receive second digit
	jal numberToPost
	j continueScan


Plus:			# Input is + 
	beq $s7,2,wrongInput		# Receive operator after operator or open bracket
	beq $s7,3,wrongInput
	beq $s7,0,wrongInput		# Receive operator before any number
	li $s7,2			# Change input status to 1
	continuePlusMinus:
	beq $t6,-1,inputToOp		# There is nothing in Operator stack --> push into
	add $t8,$t6,$t3			# Load address of top Operator
	lb $t7,($t8)			# Load byte value of top Operator
	beq $t7,'(',inputToOp		# If top is ( --> push into
	beq $t7,'+',equalPrecedence	# If top is + 
	beq $t7,'*',lowerPrecedence1	# If top is * || !
	beq $t7,'!',lowerPrecedence1
	
Multiply:			# Input is * 
	beq $s7,2,wrongInput		# Receive operator after operator or open bracket
	beq $s7,3,wrongInput
	beq $s7,0,wrongInput		# Receive operator before any number
	li $s7,2
				# Change input status to 1
	continueMult:
	beq $t6,-1,inputToOp		# There is nothing in Operator stack --> push into
	add $t8,$t6,$t3			# Load address of top Operator
	lb $t7,($t8)			# Load byte value of top Operator
	beq $t7,'(',inputToOp		# If top is ( --> push into
	beq $t7,'+',inputToOp		# If top is +  --> push into
	beq $t7,'*',equalPrecedence	# If top is * 
	beq $t7, '!',lowerPrecedence2
	
Negate:			# Input is !
	
	li $s7,2
				# Change input status to 1
	beq $t6,-1,inputToOp		# There is nothing in Operator stack --> push into
	add $t8,$t6,$t3			# Load address of top Operator
	lb $t7,($t8)			# Load byte value of top Operator
	beq $t7,'(',inputToOp		# If top is ( --> push into
	beq $t7,'+',inputToOp		# If top is +  --> push into
	beq $t7,'*',inputToOp		# If top is * --> push into
	beq $t7, '!', equalPrecedence	# If top is ! 
	
openBracket:			# Input is (
	beq $s7,1,wrongInput		# Receive open bracket after a number or close bracket
	beq $s7,4,wrongInput
	li $s7,3			# Change input status to 1
	j inputToOp
closeBracket:			# Input is )
	beq $s7,2,wrongInput		# Receive close bracket after an operator or operator
	beq $s7,3,wrongInput	
	li $s7,4
	add $t8,$t6,$t3			# Load address of top Operator 
	lb $t7,($t8)			# Load byte value of top Operator
	beq $t7,'(',wrongInput		# Input contain () without anything between --> error
	continueCloseBracket:
	beq $t6,-1,wrongInput		# Can't find an open bracket --> error
	add $t8,$t6,$t3			# Load address of top Operator
	lb $t7,($t8)			# Load byte value of top Operator
	beq $t7,'(',matchBracket	# Find matched bracket
	jal opToPostfix			# Pop the top of Operator to Postfix
	j continueCloseBracket		# Then loop again till find a matched bracket or error			
equalPrecedence:	# Mean receive +  and top is +  || receive *  and top is *  || receive ! and top is !
	jal opToPostfix			# Pop the top of Operator to Postfix
	j inputToOp			# Push the new operator in
lowerPrecedence1:	# Mean receive +  and top is * || ! /
	jal opToPostfix			# Pop the top of Operator to Postfix
	j continuePlusMinus		# Loop again
lowerPrecedence2:	# Mean receive * and top is ! /
	jal opToPostfix			# Pop the top of Operator to Postfix
	j continueMult		# Loop again
inputToOp:			# Push input to Operator
	add $t6,$t6,1			# Increment top of Operator offset
	add $t8,$t6,$t3			# Load address of top Operator 
	sb $t4,($t8)			# Store input in Operator
	j scanInfix
opToPostfix:			# Pop top of Operator in push into Postfix
	addi $t5,$t5,1			# Increment top of Postfix offset
	add $t8,$t5,$t2			# Load address of top Postfix 
	addi $t7,$t7,100		# Encode operator + 100
	sb $t7,($t8)			# Store operator into Postfix
	addi $t6,$t6,-1			# Decrement top of Operator offset
	jr $ra
matchBracket:			# Discard a pair of matched brackets
	addi $t6,$t6,-1			# Decrement top of Operator offset
	j scanInfix
popAll:				# Pop all Operator to Postfix
	jal numberToPost
	beq $t6,-1,finishScan		# Operator empty --> finish
	add $t8,$t6,$t3			# Load address of top Operator 
	lb $t7,($t8)			# Load byte value of top Operator
	beq $t7,'(',wrongInput		# Unmatched bracket --> error
	beq $t7,')',wrongInput
	jal opToPostfix
	j popAll			# Loop till Operator empty
store1Digit:
	beq $s7,4,wrongInput		# Receive number after )
	addi $s4,$t4,-48		# Store first digit as number
	add $t9,$zero,1			# Change status to 1 digit
	li $s7,1
	j scanInfix

numberToPost:
	beq $t9,0,endnumberToPost
	addi $t5,$t5,1
	add $t8,$t5,$t2			
	sb $s4,($t8)			# Store number in Postfix
	add $t9,$zero,$zero		# Change status to 0 digit
	endnumberToPost:
	jr $ra
	
set1:
	li $s1, 1
	sw $s1, ($t4)
	li $s2, 0
	li $s3, 0
				
	j calPost
set0:
	li $s1, 0
	sw $s1, ($t4)
	li $s2, 0
	li $s3, 0
				
	j calPost
