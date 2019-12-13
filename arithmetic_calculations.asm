# Dave Dorzback

.globl arithmeticCalc

.data #0x10010000
	calcInputPrompt: .asciiz "> "
	newline: .asciiz "\n"
	natural:	.float		2.71828
	pi:		.float		3.141592
	answer:		.space		4
	# Legal operators/symbols for arithmetic calculations: (, ), +, -, *, /
	llist_legal_chars:.word		40, 41, 42, 43, 45, 46, 47, 126, 94, 97, 101, 99, 112, 115, 116, 0, 76, 108
	maxInputSize: .space 51
	zero: .float 0
	one: .float 1
	
	syntaxError: .asciiz "SYNTAX Error!!!\n"	
	overflowError: .asciiz "OVERFLOW Error!!!\n"
	inputError: .asciiz "INPUT Error!!!\n"
	
.text #0x00400000n

### Arithmetic calculations main ###
arithmeticCalc:
	move $fp, $sp # Save stackpointer position
	#jal arithmeticLoop
arithmeticLoop:	
	move $sp, $fp
	la $s0, maxInputSize		# Set address to start position
			
	# Print prompt
	la $a0, calcInputPrompt
	li $v0, 4
	syscall
		
	# Read input
	la $a0, maxInputSize	# Where to put input
	li $a1, 51		# Set character limit
	jal getInput
		
	# If a 'q' is input, return to the main menu/eval loop
	la $t0, maxInputSize
	lb $t1, ($t0)
	beq $t1, 113, arithmeticReturn		# Branch to arithmetic return in input_parsing.asm
		
	beq $t1, 0, arithmeticLoop	# If input is empty, print new prompt
		
	# Check if input includes only legal characters
	la $a0, maxInputSize
	la $a1, llist_legal_chars
	la $a2, maxInputSize
	jal validateInput
	beq $v0, 1, symbolErrorHandler
		
	jal arithmeticCalculationMain

	# Check that we reached the end of input
	# Prevent calculations like 5+5)+1
	lb $t0, ($s0)
	bne $t0, 0, syntaxErrorHandler
		
	lw $t0, ($sp)		# Load result from stack
	mtc1 $t0, $f12		# Move result to coprocessor
		
	# Check if result was +-infinity
	li	$t0, 0x7f800000
	mtc1	$t0, $f30		# +Infinity
	c.eq.d $f12, $f30
	bc1t overflowErrorHandler
	li	$t0, 0xff800000
	mtc1	$t0, $f30		# -Infinity
	c.eq.d $f12, $f30
	bc1t overflowErrorHandler
	
	# Print the result
	mov.d $f30, $f12
	jal printArithmeticResult
	
	# Loop
	j arithmeticLoop
	jr $ra

### Print result of arithmetic calculation ###
printArithmeticResult:
	li $v0, 2
	mov.d $f12, $f30
	swc1 $f12, answer
	li $s6, 1
	syscall
	la $a0, newline
	li $v0, 4
	syscall	
	add.s $f12, $f16, $f16
	add.s $f30, $f16, $f16
	jr $ra 			
	
### Get input from user ###
### Input is written to memory at a0 and a1 holds max characters to read ###
getInput:
	li $v0, 8
	syscall
# Loop through characters until newline is reached
inputLoop:
	lb $t0, ($a0)
	addi $a0, $a0, 1
	beq $t0, 10, endOfInput # End of input if newline is reached
	j inputLoop
# Replace the newline at end of input with a null terminating character and return
endOfInput:
	li $t1, 0
	sb $t1, -1($a0)
	jr $ra

### Validate input string (must contain all valid characters) ###
### a0 hold address of input string. Set v0 = 0 for valid input string, v0 = 1 for invalid ###
validateInput:
	# Decrement stack pointer and save return address
	addi $sp, $sp, -4	
	sw $ra, ($sp)
	
	# Init t0 with a0
	move $t0, $a0		
	# t9 holds a2 start address. Input string will be copied into a2 with sin/cos/tan replaced by s/c/t
	move $t9, $a2		
	# Init v0 to 0 (valid string)
	li $v0, 0		
	# Read first character 
	lb $a0, ($t0)			
	sb $a0, ($a2)
	# If the string is empty, trigger invalid input error
	beq $a0, 0, symbolErrorHandler  
inputValidationLoop:	

	# Check for potential trig symbol; 'c', 's', or 't' ascii value
	# Branch to trigSymbol subroutine if found
	seq $t5, $a0, 99
	seq $t6, $a0, 115
	seq $t7, $a0, 116
	or $t5, $t5, $t6
	or $t5, $t5, $t7
	beq $t5, 1, trigSymbol
	
	# Check for potential trig symbol; 'l', or 'L' ascii value
	# Branch to endOfTrigSymbol subroutine if found
	seq $t5, $a0, 76
	seq $t6, $a0, 108
	or $t5, $t5, $t6
	beq $t5, 1, endOfTrigSymbol
	
	jal validateSymbols			# Validate current symbol
	bne $v0, 0, endOfInputValidation  	# If v0 != 0, string is invalid, return
	addi $t0, $t0, 1			# Increment t0 and read next character
	addi $a2, $a2, 1
	lb $a0, ($t0)
	sb $a0, ($a2)
	bne $a0, 0, inputValidationLoop  	# Loop as long as not at end of string
	j endOfInputValidation
trigSymbol:
	# Branch depending on which trig symbol
	beq $a0, 99, cosSymbol
	beq $a0, 115, sinSymbol
	beq $a0, 116, tanSymbol
tanSymbol:
	# Verify the 't' character is followed by 'an'
	# Don't copy 'an' into a2 string, only 't' since we want only 1 character to represent the operation
	addi $t0, $t0, 1			# Increment t0 and read next character
	lb $a0, ($t0)
	bne $a0, 97, symbolErrorHandler		# 't' char must be followed by an 'a'
	addi $t0, $t0, 1			# Increment t0 and read next character
	lb $a0, ($t0)				# 
	bne $a0, 110, symbolErrorHandler	# 'a' char must be followed by an 'n'
	j endOfTrigSymbol
cosSymbol:
	# Verify the 'c' character is followed by 'os'
	# Don't copy 'os' into a2 string, only 'c' since we want only 1 character to represent the operation
	addi $t0, $t0, 1			# Increment t0 and read next character
	lb $a0, ($t0)
	bne $a0, 111, symbolErrorHandler		# 'c' char must be followed by an 'o'
	addi $t0, $t0, 1			# Increment t0 and read next character
	lb $a0, ($t0)				# 
	bne $a0, 115, symbolErrorHandler	# 'o' char must be followed by an 's'
	j endOfTrigSymbol
sinSymbol:
	# Verify the 's' character is followed by 'in'
	# Don't copy 'in' into a2 string, only 's' since we want only 1 character to represent the operation
	addi $t0, $t0, 1			# Increment t0 and read next character
	lb $a0, ($t0)
	bne $a0, 105, symbolErrorHandler		# 's' char must be followed by an 'i'
	addi $t0, $t0, 1			# Increment t0 and read next character
	lb $a0, ($t0)				# 
	bne $a0, 110, symbolErrorHandler	# 'i' char must be followed by an 'n'
endOfTrigSymbol:
	# Copy the next symbol into a2
	bne $v0, 0, endOfInputValidation  	# If v0 != 0, string is invalid, return
	addi $t0, $t0, 1			# Increment t0 and read next character
	addi $a2, $a2, 1			# Increment t0 and read next character
	lb $a0, ($t0)
	sb $a0, ($a2)
	bne $a0, 0, inputValidationLoop  	# Loop as long as not at end of string
endOfInputValidation:
	move $a0, $t9		# Set contents of $a0 to $t9 ($a2 start address)
	lw $ra, ($sp)		
	addi $sp, $sp, 4	# Update stack pointer
	jr $ra

### Check for a valid ASCII symbol. ###
### a0 holds the value of ASCII char and v0 is set 0 for valid or 1 for invalid ###
validateSymbols:
	move $t1, $a1		# Save legal symbol address to t1
	li $v0, 0		# Set v0 = 0 (symbol is valid)
		
	sge $t2, $a0, 48	
	sle $t3, $a0, 57	# Check if symbol is integer as 0-9 are valid
	and $t4, $t2, $t3	# Return valid if 0-9
	beq $t4, 1, endOfValidateSymbols
validationLoop:	
	lw $t2, ($t1)			     # Load legal symbol
	beq $a0, 46, endOfValidateSymbols
	addi $t1, $t1, 4		     # Increment address by 4 bytes (elements are words)
	beq $t2, $a0, endOfValidateSymbols   # Return valid if symbol matches one in valid symbol list
	bne $t2, 0, validationLoop	     # Continue looping unless end of list is reached
	li $v0, 1			     # Return invalid symbol
endOfValidateSymbols:
	jr $ra

### Top subroutine for calculation - Handles addition (+) and subtraction (-) operations ###
arithmeticCalculationMain:		
	# Store return address to stack and call subroutine handling 
	#  operations w/ next precedence (multiplication/division)	
	addi $sp, $sp, -4	
	sw $ra, ($sp)		
	jal multiplicationDivisionMain
additionSubtractionLoop:
	# Read character from input string 
	lb $t2, ($s0)
	
	# Check if character ASCII value matches '+' or '-'.
	# Loop iterates while '+' or '-' character, jump to end of operation otherwise
	seq $t3, $t2, 43	
	seq $t4, $t2, 45
	or $t4, $t4, $t3 	
	bne $t4, 1, endOfArithmeticCalculation

	# Save t3 'addition indicator' to stack (will be set 1 if addition operation)
	addi $sp, $sp, -4
	sw $t3, ($sp)		

	# Move to next character in input then call suhroutine to handle
	#  operations w/ next highest precedence (multiplication/division)
	addi $s0, $s0, 1	
	jal multiplicationDivisionMain
	
	# Load operands (f2, f4) as single precision floats
	# and operation indicator (t5) as word
	l.s $f4, ($sp)		
	addi $sp, $sp, 4
	lw $t5, ($sp)	
	addi $sp, $sp, 4
	l.s $f2, ($sp)	

	# t5 = 1 for addition operations, so branch to subtraction subroutine if t5 = 0
	bne $t5, 1, subtractionCalculation
additionCalculation:
	# Add operands and save the sum to stack. Continue looping
	add.s $f2, $f2, $f4	
	swc1 $f2, ($sp)
	j additionSubtractionLoop
subtractionCalculation:
	# Subtract the operands and save difference to stack. Continue looping
	sub.s $f2, $f2, $f4	
	swc1 $f2, ($sp)
	j additionSubtractionLoop
endOfArithmeticCalculation:
	# Load result from stack, load return address and save to ra
	# then save result to top of stack
	lw $t0, ($sp)
	addi $sp, $sp, 4
	lw $ra, ($sp)
	sw $t0, ($sp)
	jr $ra

### Handles multiplication (*) and division (/) operations in the calculation ###
multiplicationDivisionMain:	
	# Store return address to stack and call subroutine handling 
	#  operations w/ next precedence (exponents/powers)	
	addi $sp, $sp, -4	
	sw $ra, ($sp)
	jal exponentMain
multiplicationDivisionLoop:
	# Read character from input string 
	lb $t2, ($s0)	
	
	# Check if character ASCII value matches '*' or '/'.
	# Loop iterates while '*' or '/' character, jump to end of operation otherwise
	seq $t3, $t2, 42	
	seq $t4, $t2, 47	
	or $t4, $t4, $t3	
	beq $t4, 0, endOfMultiplicationDivision
		
	# If multiplication operation (character == '*'), save indicator as 1 (true) to stack
	addi $sp, $sp, -4
	sw $t3, ($sp)		
	
	# Move to next character in input string
	# Then call subroutine for operations with next highest precedence (exponents)
	addi $s0, $s0, 1
	jal exponentMain
	
	# Load operands (f2, f4) as single precision float
	# and multiplication indicator (t5) as word
	l.s $f4, ($sp)
	addi $sp, $sp, 4
	lw $t5, ($sp)
	addi $sp, $sp, 4
	l.s $f2, ($sp)
	
	# Branch to division calculation if multiplication indicator (t5) is 0
	bne $t5, 1, divisionCalculation
multiplicationCalculation:	
	# Multiply operands and save product to stack
	mul.s $f2, $f2, $f4
	swc1 $f2, ($sp)		
	j multiplicationDivisionLoop
divisionCalculation:	
	# Divide opernads and save quotient
	div.s $f2, $f2, $f4
	swc1 $f2, ($sp)
	j multiplicationDivisionLoop
endOfMultiplicationDivision:	
	# Load result and return address. Write result to top of stack
	lw $t0, ($sp)
	addi $sp, $sp, 4
	lw $ra, ($sp)
	sw $t0, ($sp)
	jr $ra

### Handles exponents (^) operations in the calculation ###
exponentMain:	
	# Save return adress and call subroutine handling operations w/ higher precedence (parenthesis)
	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal TranscendentalMain
exponentLoop:
	lb $t1, ($s0)	# Read character, loop while exponent (^) symbol
	# Branch to end of exponent if not ^ symbol
	seq $t2, $t1, 94	
	beq $t2, $zero, endOfExponent
		
	# Mpve to next character, call subroutine for next highest precedence
	addi $s0, $s0, 1
	jal TranscendentalMain
		
	# Load operands from sp as single precision float.
	# Operand 1: base number loaded to f2
	# Operand 2: exponent/power loaded to f4
	l.s $f4, ($sp)			
	addi $sp, $sp, 4
	l.s $f2, ($sp)

	# Load 0 as single precision float to f10
	# Load 1 as single precision float to f11
	l.s $f10, zero			
	l.s $f11, one

	# Set f3 to base number operand (f2). f3 register will hold final result
	add.s $f3, $f2, $f10		
		
	# If exponent is 1, result = f3 (base number) Branch to endOfExponent 
	c.eq.s $f4, $f11
	bc1t storeExponentResult
		
	# If exponent is 0, result = 1. Branch to zeroExponentCalculation where f3 set to 1
	c.eq.s $f4, $f10		
	bc1t zeroExponentCalculation
		
	# Set f12 to 1. Used as counter to compare against exponent in exponentCalculation
	add.s $f12, $f11, $f10			
exponentCalculation:	
	# Multiply result (f3) by base number operand (f2) and increment counter (f12) by 1
	mul.s $f3, $f3, $f2		
	add.s $f12, $f12, $f11	
	# Loop until counter == exponent, then store result
	c.eq.s $f4, $f12		
	bc1t storeExponentResult	
	j exponentCalculation
zeroExponentCalculation:
	# For zero exponents, result is always 1
	add.s $f3, $f11, $f10
storeExponentResult:
	# Store the result to stack and jump back to exponent loop. 
	# This is neccessary to handle inputs with sequential exponent operations (e.g. 2^2^2)
	swc1 $f3, ($sp)
	j exponentLoop
endOfExponent:	
	# Load result from stack, load return address and save to ra
	# then save result to top of stack
	lw $t0, ($sp)	
	addi $sp, $sp, 4
	lw $ra, ($sp)
	sw $t0, ($sp)
	jr $ra
TranscendentalMain:
	# Save return adress and call subroutine handling operations w/ higher precedence (parenthesis)
	addi $sp, $sp, -4
	sw $ra, ($sp)
	
	lb $t1, ($s0)	# Read character, l while any matching transcendental symbols
	# Branch to end of transcendental if no matching symbols symbol
	seq $s2, $t1, 76
	seq $t2, $t1, 99
	or $s2, $s2, $t2
	seq $t2, $t1, 108
	or $s2, $s2, $t2
	seq $t2, $t1, 115
	or $s2, $s2, $t2
	seq $t2, $t1, 116
	or $s2, $s2, $t2
	bne $s2, 1, skip_transc
	addi $sp, $sp, -4
	sw $t1, ($sp)
	addi $s0, $s0, 1
skip_transc:	jal parenthesisMain
		bne $s2, 1, end_transc
	# Load operand f4 as single precision float
	# and transcendental indicator (t5) as word
	l.s $f4, ($sp)
	addi $sp, $sp, 4
	lw $t5, ($sp)
	addi $sp, $sp, 4
	bne $t5, 115, skipSine
	###lalalalala 
	###do sine stuff here
	###number is in $f4
#Procedure
sine:

	#Initialize registers
	li $t1, 20

	#Store x
	mov.s $f6, $f4	#x
	mov.s $f9, $f4	#t
	mov.s $f10, $f4	#sum

	#Counter
	li $t0, 1
#Loop
loop_s:
	#Check condition
	bge $t0, $t1, result_s

	#Move value
	mov.s $f6, $f4

	# convert -1 to float
	li $t5, -1
	mtc1 $t5, $f5
	cvt.s.w $f5, $f5

	#$f6 square
	mul.s $f8, $f6, $f6
	mul.s $f8, $f8, $f5

	# multiply  $t0 by 2
	sll $t2, $t0, 1
	addi $t3, $t2, 1
	mul $t4, $t2, $t3

	#convert it to float
	mtc1 $t4, $f7
	cvt.s.w $f7, $f7

	#update $f10
	mul.s $f9, $f9, $f8
	div.s $f9, $f9, $f7
	add.s $f10, $f10, $f9

	addi $t0, $t0, 1

	#Move to loop start
	j loop_s	
	###store result to stack pointer
result_s:	
	swc1 $f10, ($sp)
	#j end_transc
skipSine: bne $t5, 99, skipCosine
	###lalalalala 
	###do cosine stuff here
	###number is in $f4
#Procedure
cosine:
	#Initialize registers
	li $t1, 20

	#Store x
	mov.s $f6, $f4	#x
	li $t2, 1
	mtc1 $t2, $f9
	cvt.s.w $f9, $f9 #t
	mtc1 $t2, $f10
	cvt.s.w $f10, $f10 #sum

	#Counter
	li $t0, 1

	#Loop
loop_c:

	#Check condition
	bge $t0, $t1, result_c

	#Move value
	mov.s $f6, $f4

	# convert -1 to float
	li $t5, -1
	mtc1 $t5, $f5
	cvt.s.w $f5, $f5

	#$f4 square
	mul.s $f8, $f6, $f6
	mul.s $f8, $f8, $f5

	# multiply  $t0 by 2
	sll $t2, $t0, 1
	addi $t3, $t2, -1
	mul $t4, $t2, $t3

	#convert it to float
	mtc1 $t4, $f7
	cvt.s.w $f7, $f7

	#update $f4
	mul.s $f9, $f9, $f8
	div.s $f9, $f9, $f7
	add.s $f10, $f10, $f9

	addi $t0, $t0, 1

	#Move to loop start
	j loop_c
	###store result to stack pointer 
result_c:	
	swc1 $f10, ($sp)
skipCosine: bne $t5, 116, skipTan
	###lalalalala 
	###do tangent stuff here
	###number is in $f4
tan:
	#Initialize registers
	li $t1, 20

	#Store x
	mov.s $f6, $f4	#x
	mov.s $f9, $f4	#t
	mov.s $f10, $f4	#sum

	#Counter
	li $t0, 1
#Loop
loop_s_t:
	#Check condition
	bge $t0, $t1, result_s_t

	#Move value
	mov.s $f6, $f4

	# convert -1 to float
	li $t5, -1
	mtc1 $t5, $f5
	cvt.s.w $f5, $f5

	#$f6 square
	mul.s $f8, $f6, $f6
	mul.s $f8, $f8, $f5

	# multiply  $t0 by 2
	sll $t2, $t0, 1
	addi $t3, $t2, 1
	mul $t4, $t2, $t3

	#convert it to float
	mtc1 $t4, $f7
	cvt.s.w $f7, $f7

	#update $f10
	mul.s $f9, $f9, $f8
	div.s $f9, $f9, $f7
	add.s $f10, $f10, $f9

	addi $t0, $t0, 1

	#Move to loop start
	j loop_s_t	
	###store result to stack pointer
result_s_t:	
	mov.s $f1, $f10
	
	#Initialize registers
	li $t1, 20

	#Store x
	mov.s $f6, $f4	#x
	li $t2, 1
	mtc1 $t2, $f9
	cvt.s.w $f9, $f9 #t
	mtc1 $t2, $f10
	cvt.s.w $f10, $f10 #sum

	#Counter
	li $t0, 1

	#Loop
loop_c_t:

	#Check condition
	bge $t0, $t1, result_c_t

	#Move value
	mov.s $f6, $f4

	# convert -1 to float
	li $t5, -1
	mtc1 $t5, $f5
	cvt.s.w $f5, $f5

	#$f4 square
	mul.s $f8, $f6, $f6
	mul.s $f8, $f8, $f5

	# multiply  $t0 by 2
	sll $t2, $t0, 1
	addi $t3, $t2, -1
	mul $t4, $t2, $t3

	#convert it to float
	mtc1 $t4, $f7
	cvt.s.w $f7, $f7

	#update $f4
	mul.s $f9, $f9, $f8
	div.s $f9, $f9, $f7
	add.s $f10, $f10, $f9

	addi $t0, $t0, 1

	#Move to loop start
	j loop_c_t
	###store result to stack pointer 
result_c_t:	
	mov.s $f2, $f10
	
	div.s $f10, $f1, $f2	#tan = sin/cos
	###store result to stack pointer	
	swc1 $f10, ($sp)
skipTan: bne $t5, 108, skipLog2
	###lalalalala 
	###do log base 2 stuff here
	###number is in $f4
#Procedure

	#Initialize registers
	li $t1, 100000

	# convert 1 to float
	l.s $f5, one

	#Store x
	#f12->f4, $f4->$f8
	mov.s $f8, $f4	#x
	sub.s $f8, $f8, $f5
	add.s $f6, $f4, $f5
	div.s $f8, $f8, $f6	#t = (x-1)/(x+1)

	mul.s $f9, $f8, $f8 #n = t*t

	mov.s $f10, $f8	#sum = t
	
	#Counter
	li $t0, 3
#Loop
loop:

	#Check condition
	bge $t0, $t1, res_log2

	# t = t * n
	mul.s $f8, $f8, $f9

	# convert $t0 to float
	mtc1 $t0, $f7
	cvt.s.w $f7, $f7

	#update sum ($f10)
	div.s $f6, $f8, $f7	#t/i
	add.s $f10, $f10, $f6

	addi $t0, $t0, 2

	#Move to loop start
	j loop

#Exit loop
res_log2:
	add.s $f1, $f10, $f10
	
#Procedure
ln2:
	#Initialize registers
	li $t1, 100000

	# convert 1 to float
	l.s $f5, one

	# convert 2 to float
	li $t4, 2		
	mtc1 $t4, $f4
	cvt.s.w $f4, $f4	
	
	#Store x
	mov.s $f8, $f4	#x
	sub.s $f8, $f8, $f5
	add.s $f6, $f4, $f5
	div.s $f8, $f8, $f6	#t = (x-1)/(x+1)

	mul.s $f9, $f8, $f8 #n = t*t

	mov.s $f10, $f8	#sum = t
	
	#Counter
	li $t0, 3
#Loop
loop_2:

	#Check condition
	bge $t0, $t1, res_ln2

	# t = t * n
	mul.s $f8, $f8, $f9

	# convert $t0 to float
	mtc1 $t0, $f7
	cvt.s.w $f7, $f7

	#update sum ($f10)
	div.s $f6, $f8, $f7	#t/i
	add.s $f10, $f10, $f6

	addi $t0, $t0, 2

	#Move to loop start
	j loop_2

#Exit loop
res_ln2:
	add.s $f2, $f10, $f10	
	###store result to stack pointer
	div.s $f10, $f1, $f2
	swc1 $f10, ($sp)
skipLog2: bne $t5, 76, end_transc
	###lalalalala 
	###do log base 10 stuff here
	###number is in $f4
	#Procedure

	#Initialize registers
	li $t1, 100000

	# convert 1 to float
	l.s $f5, one

	#Store x
	#f12->f4, $f4->$f8
	mov.s $f8, $f4	#x
	sub.s $f8, $f8, $f5
	add.s $f6, $f4, $f5
	div.s $f8, $f8, $f6	#t = (x-1)/(x+1)

	mul.s $f9, $f8, $f8 #n = t*t

	mov.s $f10, $f8	#sum = t
	
	#Counter
	li $t0, 3
#Loop
loop_l:

	#Check condition
	bge $t0, $t1, res_log10

	# t = t * n
	mul.s $f8, $f8, $f9

	# convert $t0 to float
	mtc1 $t0, $f7
	cvt.s.w $f7, $f7

	#update sum ($f10)
	div.s $f6, $f8, $f7	#t/i
	add.s $f10, $f10, $f6

	addi $t0, $t0, 2

	#Move to loop start
	j loop_l

#Exit loop
res_log10:
	add.s $f1, $f10, $f10
	
#Procedure
ln10:
	#Initialize registers
	li $t1, 100000

	# convert 1 to float
	l.s $f5, one

	# convert 2 to float
	li $t4, 10	
	mtc1 $t4, $f4
	cvt.s.w $f4, $f4	
	
	#Store x
	mov.s $f8, $f4	#x
	sub.s $f8, $f8, $f5
	add.s $f6, $f4, $f5
	div.s $f8, $f8, $f6	#t = (x-1)/(x+1)

	mul.s $f9, $f8, $f8 #n = t*t

	mov.s $f10, $f8	#sum = t
	
	#Counter
	li $t0, 3
#Loop
loop_10:

	#Check condition
	bge $t0, $t1, res_ln10

	# t = t * n
	mul.s $f8, $f8, $f9

	# convert $t0 to float
	mtc1 $t0, $f7
	cvt.s.w $f7, $f7

	#update sum ($f10)
	div.s $f6, $f8, $f7	#t/i
	add.s $f10, $f10, $f6

	addi $t0, $t0, 2

	#Move to loop start
	j loop_10

#Exit loop
res_ln10:
	add.s $f2, $f10, $f10	
	###store result to stack pointer
	div.s $f10, $f1, $f2
	swc1 $f10, ($sp)
end_transc:	
	lw $t0, ($sp)
	addi $sp, $sp, 4
	lw $ra, ($sp)
	sw $t0, ($sp)
	jr $ra
### Handles parenthesis symbols in the calculations by recursively starting new calculation ###
parenthesisMain:
	# Save return address
	addi $sp, $sp, -4
	sw $ra, ($sp)
		
	# Read character in input string
	lb $t0, ($s0)
		
	# If character an open parenthesis '(', branch to openParenthesis subroutine
	# Otherwise, convert number in input string to float and jump to end of parenthesis routine
	beq $t0, 40, openParenthesis  
	jal inputToFloatMain
	j endOfParenthesis
openParenthesis:
	# Read next character in input, then recursively start new calculation
	move $s3, $s2
	addi $s0, $s0, 1		
	jal arithmeticCalculationMain
	move $s2, $s3
	
	# Read character in input string
	lb $t0, ($s0)
		
	# Character should be closing parenthesis ')' or end of string '\0'
	# Call syntax error handler if not
	sne $t1, $t0, 41		
	seq $t2, $t0, 0
	or $t1, $t1, $t2
	bne $t1, 0, syntaxErrorHandler
		
	# Read last character 
	addi $s0, $s0, 1
endOfParenthesis:
	# Load result from stack, load return address and save to ra
	# then save result to top of stack
	lw $t0, ($sp)
	addi $sp, $sp, 4
	lw $ra, ($sp)
	sw $t0, ($sp)
	jr $ra

### Handles numerical values in calculation. 				###
### Reads from input string and converts to floating point numbers. 	###
### Notes: Decimal numbers currently not working as inputs. Generates 	###
### a syntax or overflow error. May be issue with convertToFloatLoop or ###
### exception handler.							###
inputToFloatMain:	
atof:		
		lb	$t1, ($s0)		# Read character
		seq	$t9, $t1, 126		# If character is tilde
		beq	$t9, 0, move1		# skip character and set negative flag
		addi	$s0,$s0, 1
		lb	$t1, ($s0)		# Read character
move1:		seq	$t8, $t1, 101		# If character is the natural number
		beq	$t8, 1, ecalc		# Do natural number calc
		beq	$t1, 112, pcalc		# If char p, do pi calc
		beq	$t1, 97, anscalc
		sle	$t2, $t1, 57		# Check that character is '0' - '9'
		sge	$t3, $t1, 48
		and	$t3, $t2, $t3
		beq	$t3, 0, syntaxErrorHandler
		
		li	$t0, 0			# Save length of number to $t0
atof_loop:	lb	$t1, ($s0)		# Read character
		sle	$t2, $t1, 57
		sge	$t3, $t1, 48
		and	$t3, $t2, $t3		# $t3 = character is '0' - '9'
		seq	$t2, $t1, 46		# If number has dot in it
		beq	$t2,1,float_input	# Start float calculation
		
		addi	$t0, $t0, 1		# Increase length
		addi	$s0, $s0, 1		# Next character
skipdot:	beq	$t3, 1, atof_loop	# Read character was a digit, read next character
		
		addi	$t0, $t0, -1		# Loop adds 1 times too much
		move	$t1, $t0		# Length of the number to $t1
		li	$t5, 1
		li	$t6, 0			# Total value of number
		li	$t7, 10
		addi	$s0, $s0, -2		# Loop adds too muchs, go back to the last digit.
		
		li	$v0, 0
convert_loop:	lb	$t4, ($s0)		# Read digit
		addi	$t4, $t4, -48		# Convert it to number '0' ascii is 48, 48 - 48 == 0
		addi	$t1, $t1, -1		#
		mul	$t4, $t4, $t5		# $t4 = $t4 * $t5, number * 10^x
		add	$t6, $t6, $t4		# Add number to total value
		beq	$v0, 1, overflowErrorHandler
		mul	$t5, $t5, $t7		# $t5 = $t5 * 10
		addi	$s0, $s0, -1		# Move to previous digi
		bne	$t1, 0, convert_loop
		
		add	$s0, $s0, $t0		# Move cursor back to last digit
		addi	$s0, $s0, 1		# Next char
		beqz	$t9, atof_return
		sub	$t6, $zero, $t6
						
atof_return:	mtc1	$t6, $f0		# Move total number to coprocessor
		cvt.s.w	$f0, $f0
		addi	$sp, $sp, -4
		swc1	$f0, ($sp)		# Save converted number to stack
		jr	$ra			# Jump back to number
		
float_input:	li 	$t8, 0			# Decimal counter
		addi	$s0, $s0, 1		# Nect character
float_loop:	lb 	$t1, ($s0)
		sle	$t2, $t1, 57
		sge	$t3, $t1, 48
		and	$t3, $t2, $t3		# $t3 = character is '0' - '9'
		addi 	$s0, $s0, 1		# Next character
		addi	$t0, $t0, 1		# Increase length
		addi	$t8, $t8, 1		# Increase decimal length
		beq	$t3, 1, float_loop	# Read character was a number = read next character
		addi	$t0, $t0, -1		# Loop adds 1 too many
		addi	$t8, $t8, -1		
		li 	$t5, 1			# Load place value
		mtc1	$t5, $f10		# and move it to the coprocessor
		cvt.s.w	$f10, $f10		# Convert place value to float
		li	$t5, 10			# load weight value
		mtc1	$t5, $f20
		cvt.s.w	$f20,$f20
		li	$t5, 0			# load sum register
		mtc1	$t5, $f0
		cvt.s.w	$f0,$f0
		addi	$s0, $s0, -1		# loop goes to far beyond string
		li	$s7, 0			# loop counter for fractional part
fract_loop:	div.s	$f10, $f10, $f20	# get fractional part max place value
		addi	$s7, $s7, 1		# and divide 1 by ten that many times
		bne	$s7, $t8, fract_loop
		move	$t1, $t0		# move length of number
		li	$v0, 0
skip_dot2:	addi	$s0, $s0, -1		# go to previous digit
		lb	$t4, ($s0)		# load digit
		beq	$t4, 46, skip_dot2	# if digit is period, skip
		addi	$t4, $t4, -48		# convert digit from char to int
		addi	$t1, $t1, -1		# decrement size
		mtc1	$t4, $f30		# move digit to coprocessor and convert
		cvt.s.w	$f30, $f30
		mul.s	$f30, $f30, $f10	# multiply digit by place weight
		add.s	$f0, $f0, $f30		# add digit to total sum
		mul.s	$f10, $f10, $f20	# move place weight to the left
		bne	$t1, 0, skip_dot2	# loop until no digits left
		add	$s0, $s0, $t0		# get back to end of number
		addi	$s0, $s0, 1		# 1 more for next character
		beqz	$t9, float_return	# if not negative, end
		li	$t5, 0			# otherwise, make number negative
		mtc1	$t5, $f16
		cvt.s.w	$f16, $f16
		sub.s	$f0, $f16, $f0
float_return:	addi	$sp, $sp, -4
		swc1	$f0, ($sp)		# Save converted number to stack
		jr	$ra			# Jump back to number
		

ecalc:		l.s	$f0, natural
		addi	$s0, $s0, 1
		beqz 	$t9, endecalc
		sub.s 	$f0, $f30, $f0
endecalc:	addi 	$sp, $sp, -4
		swc1	$f0, ($sp)
		jr 	$ra
		
pcalc:		l.s	$f0, pi
		addi	$s0, $s0, 1
		beqz 	$t9, endpcalc
		sub.s 	$f0, $f30, $f0
endpcalc:	addi 	$sp, $sp, -4
		swc1	$f0, ($sp)
		jr 	$ra

anscalc:	beqz	$s6, syntaxErrorHandler
		l.s	$f0, answer
		addi 	$s0, $s0, 1
		beqz	$t9, endacalc
		sub.s	$f0, $f30, $f0
endacalc:	addi 	$sp, $sp, -4
		swc1	$f0, ($sp)
		jr	$ra
### Error handler for syntax errors ###
syntaxErrorHandler:	
	la $a0, syntaxError
	li $v0, 4	
	syscall
	j arithmeticLoop
	
### Error handler for overflow errors ###
overflowErrorHandler:	
	la $a0, overflowError
	li $v0, 4
	syscall
	j arithmeticLoop
	
### Error handler for illegal symbol errors ###
symbolErrorHandler:
	la $a0, inputError
	li $v0, 4
	syscall
	j arithmeticLoop

### Exception handler for convertToFloatLoop. Prints overFlowError on exception ###
 .ktext	0x80000180
 	li $v0, 1
	mfc0 $k0, $14   		
 	addi $k0, $k0, 4 	
	mtc0 $k0, $14   		
	eret
