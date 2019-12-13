# Dave Dorzback

.data
	inputNumberArray: .space 100
	str1: .asciiz "\nPlease enter your input hex in all caps: "
	str2: .asciiz "Your decimal number is: "
.text

.globl mainH2D	# Main global function

mainH2D:
	la $a0, str1
	li $v0, 4
	syscall

	li $v0, 8
	la $a0, inputNumberArray
	li $a1, 100
	syscall

	j fromHexaStringToDecimal

convertFinish: 

	add $a1, $a0, $zero
	la $a0, str2
	li $v0, 4
	syscall

	add $a0, $a1, $zero
	li $v0, 1
	syscall

	b baseReturn	# Removed exit syscall to be used in scientific_calc.asm

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
    blt  $t7, $zero, convertFinish  # print int if t7 < 0
    li   $t6, 16                    # load 16 to t6
    mul  $a0, $a0, $t6              # t8 = t8 * t6
    add  $a0, $a0, $t7              # add t7 to a0
    addi $t2, $t2, 1                # increment array position
    j    hexaStringToDecimalLoop

inputSub48:
    addi $t7, $t7, -48              # convert from string (ABCDEF) to int
    j    inputHexaNormalized
