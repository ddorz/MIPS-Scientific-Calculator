# Dave Dorzback

.data	
	str_mode:	.asciiz		"\n\n(D = decimal to binary, B = binary to decimal, E = exit)\nEnter mode: "
	input_error:	.asciiz		"\nInvalid response... "
	str_dec2bin:	.asciiz		"\nEnter decimal value: "
	str_bin2dec:	.asciiz		"\nEnter binary value: "
	str_result:	.asciiz		"\tResult: " 
	buffer:		.space		32
	
        #######  all conversions limited to 2^30  ####### 

.globl	mainD2B, bin2dec	# Global functions

.text

mainD2B:
	#print mode string
	la $a0, str_mode	
	li $v0, 4		
	syscall		
	#take input char:	
	li $v0, 12		
	syscall		
	beq $v0, 'b', bin2dec 	#case: 'd'/'D'
	beq $v0, 'B', bin2dec	
	beq $v0, 'd', dec2bin	#case: 'b'/'B'
	beq $v0, 'D', dec2bin 	
	beq $v0, 'e', baseReturn	#case: 'e'/'E'
	beq $v0, 'E', baseReturn	# Replaces exit syscall by returning to scientific_calc.asm
	error:
	#print error string
	la $a0, input_error	#default:
	li $v0, 4		
	syscall			
	j mainD2B
	
dec2bin:
	#print input string
	la $a0, str_dec2bin	
	li $v0, 4		
	syscall			
	#take input
	li $v0, 5
	syscall
	move $a0, $v0
	#bit-shifting
	add $t0, $0, $a0 	#input(address) = ($a0)
	add $t1, $0, $0 	#$t1 = 0
	addi $t3, $0, 1 	#mask = 1
	sll $t3, $t3, 31 	#left shift mask by 31 bits
	addi $t4, $0, 32 	#count = 32
	#print result prefix string
	li $v0, 4		
	la $a0, str_result 
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
	b mainD2B
		
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
	la $a0, str_result
	li $v0, 4
	syscall
	#print decimal conversion
	move $a0, $t4      	
	li $v0, 1      		
	syscall
	b mainD2B
