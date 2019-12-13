# Dave Dorzback

# Write a MIPS code that asks the user for decimal number 
# Convert it to hex and print the result 

.data 
	prompt: .asciiz "\nEnter the decimal number to convert: " 
	ans: .asciiz "\nHexadecimal equivalent: " 
	result: .space 8 

.globl mainD2H	# Main global function

.text 

mainD2H:

 	la $a0, prompt
  	li $v0, 4
   	syscall

    	li $v0, 5 
	syscall 
	
	move $t2, $v0
	la $a0, ans
	li $v0, 4
	syscall

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
	sb $t4, 0($t3) # Null terminate string

       	la $a0, result
	li $v0, 4 
       	syscall
       	
        b baseReturn # Replaces exit syscall by returning to scientific_calc.asm
