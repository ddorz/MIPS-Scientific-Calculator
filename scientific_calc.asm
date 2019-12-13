# Dave Dorzback

.data	
	hiPrompt: .asciiz "Hi, you are currently using a MIPS scientific calculator!"
	evalPrompt: .asciiz "\nChoose your evaluation type: arithemetic ('a'), logic ('l'), base conversion ('b'), exit ('e'): "
	newEval: .asciiz "\nChange evaluation type? (y / n): "
	
	branchPrompt: .asciiz "\nChoose your conversion type (vise-versa): binary to hexidecimal ('b'), hexidecimal to decimal ('h'), decimal to binary ('d'): "
	hexToDecPrompt: .asciiz "Choose hexidecimal to decimal ('h') or decimal to hexadecimal ('d') (any other key will exit): "
	
	arithmeticPrompt: .asciiz "\nPerform arithmetic and transcendental functions as you would in a scientific calculator below. Press ('q') to quit.\n"
	
	choice: .space 3 	# Enter choice
	choiceError: .asciiz  "That isn't an available choice...\n"
	
	closeCalc: .asciiz "Closing the calculator...\n"
	
.globl logicReturn, baseReturn, arithmeticReturn
	
.text
	# Print hiPrompt
	la $a0, hiPrompt
	jal printString
		
evalLoop:	# Print and execute evaluation prompt
	la $a0, evalPrompt
	jal printString
	
	# Get evaluation choice and determine the choice.	
	la $a0, choice	# Address of userIn
	jal choiceCall

	lb $t0, 0($a0)
	beq $t0, 'a', arithmetic
	beq $t0, 'A', arithmetic
	beq $t0, 'l', logic
	beq $t0, 'L', logic
	beq $t0, 'b', baseCon
	beq $t0, 'B', baseCon
	beq $t0, 'e', exit
	beq $t0, 'E', exit
	
	la $a0, choiceError	# When user doesn't select a, l, b, or e.
	jal printString
	b evalLoop
	
	# If an input starts with an operator, the previous calculated answer is the operand.
	
	# Make sure no input ends with an operator.
	
exit:	# Exit the program
	la $a0, closeCalc
	jal printString
	
	li $v0, 10
	syscall

arithmetic: # Arithmetic Type Functions
	la $a0, arithmeticPrompt	# Print arithmetic prompt
	jal printString
	
	b arithmeticCalc	# Use arithmetic_calculations.asm

arithmeticReturn:	# After arithmetic return
	jal changeEval
	b arithmetic
	
logic: # Logic Type Functions
	b logicStart	# Use logic_function.asm

logicReturn:	# After logic function task
	jal changeEval
	b logic
	
baseCon: # Base-Conversion Type Functions
	la $a0, branchPrompt
	jal printString
	
	# Get branch choice and determine the choice.	
	la $a0, choice	
	jal choiceCall
	
	lb $t0, 0($a0)
	beq $t0, 'b', bH
	beq $t0, 'h', hD
	beq $t0, 'd', dB
	
	la $a0, choiceError	# When user doesn't select b, h, or d.
	jal printString
	b baseCon

baseReturn:	# After base conversion task
	jal changeEval
	b baseCon

bH:
	b mainB2H	# Use the bin_to_hex.asm file
	b baseReturn
hD:
	la $a0, hexToDecPrompt
	jal printString
	
	#Determine conversion choice and choose correct .asm files
	la $a0, choice	
	jal choiceCall
	
	lb $t0, 0($a0)
	beq $t0, 'h', mainH2D	# hextodec.asm
	beq $t0, 'd', mainD2H	# dectohex.asm
	
	b mainD2H
	b baseReturn
dB:
	b mainD2B	# Use the decimal_binary.asm file
	b baseReturn

changeEval:	# Change evaluation type? (Occurs in all 3 types of functions)
	la $a0, newEval # Print string
	la $v0, 4
	syscall
	
	# Get new evaluation choice and determine the choice.	
	la $a0, choice
	li $v0, 8
	la $a1, 3
	syscall

	lb $t0, 0($a0)
	beq $t0, 'n', jumpBack
	beq $t0, 'N', jumpBack
	beq $t0, 'y', evalLoop
	beq $t0, 'Y', evalLoop
	
	la $a0, choiceError	# When user doesn't select y or n.
	la $v0, 4
	syscall
	b changeEval	
jumpBack:	# Jump back to previous evaluation
	jr $ra

printString:	# This function prints strings in address $a0.
	la $v0, 4
	syscall
	jr $ra
	
printFloat:	# This function prints floats in address $a0.
	la $v0, 2
	syscall
	jr $ra
	
choiceCall:	# This function reads in a character for a choice.
	li $v0, 8
	la $a1, 3
	syscall
	jr $ra
