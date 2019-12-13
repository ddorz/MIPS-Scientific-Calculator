# Dave Dorzback

.data 
	binToHexPrompt: .asciiz "\nChoose binary to hexadecimal ('b'), hexadecimal to binary ('h'), or exit ('e'): "
	choice: .space 3
	choiceError: .asciiz  "That isn't an available choice...\n"
	str_bin2dec:	.asciiz		"\nEnter binary value: "
	str_dec2bin:	.asciiz		"\nEnter decimal value: "
	inputNumberArray: .space 100
	str1: .asciiz "\nPlease enter your input hex in all caps: "
	ansHexa: .asciiz "Hexadecimal Equivalent: " 
	ansBin: .asciiz "\nBinary Equivalent: "
	result: .space 8 
	buffer:	.space 32

.text 

.globl mainB2H

mainB2H:
	# Print prompt
 	la $a0, binToHexPrompt
  	li $v0, 4
   	syscall
   	
   	# Get choice and branch appropriately
   	la $a0, choice
   	li $v0, 8
	la $a1, 3
	syscall
   	
  	lb $t0, 0($a0)
	beq $t0, 'b', binToHex	
	beq $t0, 'B', binToHex
	beq $t0, 'h', hexToBin	
	beq $t0, 'H', hexToBin
	beq $t0, 'e', baseReturn
	beq $t0, 'E', baseReturn
	
	la $a0, choiceError	# When user doesn't select b, h, or e
	la $v0, 4
	syscall
	
	b mainB2H
	
binToHex:	# Perform Binary-to-Hexadeciaml Conversion

# Author: Brian Guenzatti
bin2dec:
	#print input string
	li $v0, 4		
	la $a0, str_bin2dec         
	syscall
	#take input string:
	la $a0, buffer		#load buffer address
	li $a1, 32              #max input length = 32
	li $v0, 8               
	syscall
	li $t4, 0               #sum = 0
	la $t1, buffer		#load buffer address
	li $t9, 32		#count = 32
loop_b2d:
	lb $a0, ($t1)      	#load input[0]
	blt $a0, 48, result_b2d #if input[0] < 0, return null
	addi $t1, $t1, 1        #offset++
	subi $a0, $a0, 48       #input[0] to integer notation
	subi $t9, $t9, 1        #count--
	beq $a0, 0, zeroBit	#if input[0] == 0, process as 0
	beq $a0, 1, oneBit	#if input[0] == 1, process as 0
	j result_b2d     	#if input[0] !=0 && != 1, return null
	#no processing required for 0
	zeroBit:
	j loop_b2d
	#processing 1 returns 2^count		
	oneBit:                 
	li $t8, 1               #base for exponent = 1
	sllv $t5, $t8, $t9    	#temp = 2^count
	add $t4, $t4, $t5       #sum += temp 
	j loop_b2d
result_b2d:
	srlv $t4, $t4, $t9	#shift right to remove byte offset
	
	move $t2, $t4      # Move binary-to-decimal conversion to decimal-to-hex conversion
	
# Author: Sean Cruikshank

	li $t0, 8 # counter 
	la $t3, result # where answer will be stored 
Loop: 
    	beqz $t0, Exit # branch to exit if counter is equal to zero 
     	rol $t2, $t2, 4 # rotate 4 bits to the left 
     	and $t4, $t2, 0xf # mask with 1111 
     	ble $t4, 9, Sum # if less than or equal to nine, branch to sum
     	addi $t4, $t4, 55 # if greater than nine, add 55
     	b End 

Sum: 
       	addi $t4, $t4, 48 # add 48 to result 

End: 
       	sb $t4, 0($t3) # store hex digit into result 
       	addi $t3, $t3, 1 # increment address counter 
       	addi $t0, $t0, -1 # decrement loop counter 
       	
       	j Loop 

Exit: 	
	li $t4, 0
	sb $t4, 0($t3) #null terminate string
       	la $a0, ansHexa 
	li $v0, 4 
   	syscall 
   	
        la $a0, result
	li $v0, 4 
       	syscall
       	
       	b mainB2H

hexToBin:	# Perform Hexadecimal-to-Binary Conversion

# Author: Sean Cruikshank
	la $a0, str1
	li $v0, 4
	syscall

	li $v0, 8
	la $a0, inputNumberArray
	li $a1, 100
	syscall
	
	j fromHexaStringToDecimal

	b dec2bin	# Move hex-to-decimal conversion to decimal-to-binary conversion

fromHexaStringToDecimal:
    # start counter
    la   $t2, inputNumberArray       # load inputNumber address to t2
    li   $t8, 1                      # start our counter
    li   $a0, 0                      # output number
    j    hexaStringToDecimalLoop

hexaStringToDecimalLoop:
    lb   $t7, 0($t2)
    ble  $t7, '9', inputSub48       # if t7 less than or equal to char '9' inputSub48
    addi $t7, $t7, -55              # convert from string (ABCDEF) to int
    j    inputHexaNormalized

inputHexaNormalized:
    blt  $t7, $zero, dec2bin  	# print int if t7 < 0
    li   $t6, 16                    # load 16 to t6
    mul  $a0, $a0, $t6              # t8 = t8 * t6
    add  $a0, $a0, $t7              # add t7 to a0
    addi $t2, $t2, 1                # increment array position
    j    hexaStringToDecimalLoop

inputSub48:
    addi $t7, $t7, -48              # convert from string (ABCDEF) to int
    j    inputHexaNormalized

# Author Brian Guenzatti
dec2bin:			
	#bit-shifting
	add $t0, $0, $a0 	#input(address) = ($a0)
	add $t1, $0, $0 	#$t1 = 0
	addi $t3, $0, 1 	#mask = 1
	sll $t3, $t3, 31 	#left shift mask by 31 bits
	addi $t4, $0, 32 	#count = 32
	#print result prefix string
	li $v0, 4		
	la $a0, ansBin 
	syscall
	li $t5, 0		#leading zero flag
loop_d2b:
	and $t1, $t0, $t3 	#$t1 = AND(input, mask)
	beq $t1, $0, result_d2b	#break if '\0' reached
	add $t1, $0, $0 	#input(address) = 0
	addi $t1, $0, 1 	#input(address)++

result_d2b:
	#print binary bit 
	bge $t5, 1, print	#if one printed previously, jumpt to print
	beq $t1, 0, skip_print	#else if t1 == 0
	addiu $t5, $t5, 1	#increment leading zero flag
	print:
	li $v0, 1
	move $a0, $t1
	syscall
	skip_print:
	srl $t3, $t3, 1		#right shift mask by 1 bit 
	addi $t4, $t4, -1	#count--
	bne $t4, $0, loop_d2b	#if count != 0, repeat
	b mainB2H
