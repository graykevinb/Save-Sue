####################################################################################################################################
# Copyright 2022 Kevin Gray
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software 																	 #
# and associated documentation files (the "Software"), to deal in the Software without restriction, 															 #
# including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,													   #
#  and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,													 #
# subject to the following conditions:																																														 #
																																																																	 #
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.	 #
																																																																	 #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 																						 #
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 					 #
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 												 #
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR 								 #
# THE USE OR OTHER DEALINGS IN THE SOFTWARE.																																											 #
####################################################################################################################################
.data
prompt: .asciiz "Hello World! My name is Sue. What is yours?\n"
name_resp: .asciiz "What a lovely name!\n My files are held hostage. Will help me free them?\n"
bool_prompt: .asciiz "Y/N: "

level_one_intro: .asciiz "These hackers came and put a password locking most of my system down.\n You'll need to crack it.\n"

linux_prompt: .asciiz "Linus Linux (Blanket Edition)\nKernel 5.19.9-200.fc36.aarch64 on an aarch_64 (tty1)\n\n"
username_prompt: .asciiz "Sue login: "
password_prompt: .asciiz "Password: "
username: .asciiz "Sue"
password: .asciiz "password"
login_incorrect: .asciiz "Login incorrect\n"


final_level_prompt: .asciiz "There is a red wire and a green wire. One will free the robot. The other will blow the robot up.\n"
final_level_choices: .asciiz "Red wire (1)\nGreen wire (2): "	
win_text: .asciiz "You won the game!"
lose_text: .asciiz "Try again!"
newline: .asciiz "\n"
buffer: .space 20
.text

main:
	jal get_name	
	la $t1, ($v0)
	beq $v1, 0, leave
	beq $v1, 1, game
	game:
		jal level_one
		jal final_level
	
	leave:
		jal exit
	
	
get_name:
	addi, $sp, $sp, -4
	sw $ra, ($sp)
	
	#Ask for the user's name
	li $v0, 4
	la $a0, prompt
	syscall
	
	#Read name
	li $v0, 8
	li $a1, 20
	la $a0, buffer
	syscall
	la $t1, ($a0)
	
	#Ask if the user wants to help
	li $v0, 4
	la $a0, name_resp
	syscall 
	
	#Store response
	jal get_bool_resp
	la $v1, ($v0)
	
	la $v0, ($t1)
	
	lw $ra, ($sp)
	addi $sp, $sp, 4
	jr $ra


get_bool_resp:
	addi, $sp, $sp, -4
	sw $ra, ($sp)
	
	#Print pront of "Y/N"
	li $v0, 4
	la $a0, bool_prompt
	syscall
	
	#Read response
	li $v0, 8
	la $s0, bool_prompt
	syscall
	
	#Get first character of response
	lb $a0, 0($a0)
	
	# Remember kids 0x59 is Y and 0x4e is N
	beq $a0, 0x59, yes
	beq $a0, 0x4e, no
	yes:
		la $v0, 1
		jal end
	no:
		la $v0, 0
		jal end
	end:
	
	la $v0, ($a0)
	
	lw $ra, ($sp)
	addi $sp, $sp, 4
	jr $ra
	

level_one:
	addi $sp, $sp, -4
	sw $ra, ($sp)
	
	li $v0, 4
	la $a0, linux_prompt
	syscall
	
	#Loop will repeat until the correct credentials are entered.
	login:
		li $v0, 4
		la $a0, username_prompt
		syscall
		
		#Read username
		li $v0, 8
		li $a1, 20
		la $a0, buffer
		syscall
		
		#Check if the entered username is correct
		la $a1, username
		jal is_string_equiv
		
		#Save the validity.
		la $s1, ($v0)

		#Ask for the password
		li $v0, 4
		la $a0, password_prompt
		syscall
		
		#Read the password		
		li $v0, 8
		li $a1, 20
		la $a0, buffer
		syscall
		
		#Check if the password is valid
		la $a1, password
		jal is_string_equiv
		
		and $s2, $v0, $s1 # $s2 = Username AND Password
		beqz $s2, invalid
		jal valid
		invalid:
			li $v0, 4
			la $a0, login_incorrect
			syscall
			
			jal login
		valid:
			lw $ra, ($sp)
			addi $sp, $sp, 4
			jr $ra
	
final_level:
	addi $sp, $sp, -4
	sw $ra, ($sp)
	
	li $v0, 4
	la $a0, final_level_prompt
	syscall
	
	final_loop:
		li $v0, 4
		la $a0, final_level_choices
		syscall
		
		li $v0, 5
		syscall
		
		beq, $v0, 1, win
		beq, $v0, 2, lose
		jal final_loop
		win:
			li $v0, 4
			la $a0, win_text
			syscall
		lose:
			li $v0, 4
			la $a0, lose_text
			syscall
	end_game:
		lw $ra, ($sp)
		addi $sp, $sp, 4
		jr $ra
		
			
	
#A fun function		
is_string_equiv:
	addi $sp, $sp, -4
	sw $ra, ($sp)

	loop:
		#Compare the first characters.
		lb $t0, ($a0)
		lb $t1, ($a1)
		bne $t0, $t1, not_eq
		
		#Increment the character position.
		addi $a0, $a0, 1
		addi $a1, $a1, 1
		bnez $t1, loop
		jal end_loop
	not_eq:
		# Checks if the null terminator and null value has been reached.
		# If the loop has made it this far and the both characters have reached their terminator hex the strings are equivalent.
		beq $t0, 0x0a, newline_hex
		jal incorrect
		newline_hex:
			beqz $t1, correct
			jal incorrect
		correct:
			li $v0, 1
			jal end_loop
		incorrect:
			li $v0, 0
			jal end_loop
	end_loop:
		lw $ra, ($sp)
		addi $sp, $sp, 4
		jr $ra
	
	
exit:
	li $v0, 10
	syscall
