main:	# This is an overarching test to det if the cpu is working
	addi x0, x0, 0	# We are going to clear all of the callee saved regs
	add x1, x0, x0	# Set the ra to be 0
	add x2, x0, x0 	# Set the sp to be 0
	add x8, x0, x0 	# Set the frame pointer to 0
	add x9, x0, x0	# Set the saved reg to 0
	addi x18, x0, 0	# Saved registers
	addi x19, x0, 0
	addi x20, x0, 0
	addi x21, x0, 0
	addi x22, x0, 0
	addi x23, x0, 0
	addi x24, x0, 0
	addi x25, x0, 0
	addi x26, x0, 0
	addi x27, x0, 0
	jal reset		# set all caller saved reg to 0
	jal zerosTest	# Verify that all gen purp registers are zeroed out
	jal allMathOperations
	jal x0, stop

reset:	# This function resets all caller saved regs for testing
	sub x5, x0, x0	# Temporary reg
	or x6, x0, x0
	and x7, x0, x0
	mul x10, x0, x0	# Fn arg & return values
	sll x11, x0, x0
	srl x12, x0, x0	# fn args
	sra x13, x0, x0
	sra x14, x0, x0
	xori x15, x0, 0
	ori x16, x0, 0
	andi x17, x0, 0
	slti x28, x0, 0	# Temporaries
	addi x29, x0, 0
	xori x30, x0, 0
	slti x31, x0, 0
	jalr x0, ra, 0	# Branch back to the caller
	
zerosTest:	# Test that all of the values are 0
	or x5, x5, x6
	or x5, x7, x8
	or x5, x9, x10
	or x5, x11, x12
	or x5, x13, x14
	or x5, x15, x16
	or x5, x17, x18
	or x5, x19, x20
	or x5, x21, x22
	or x5, x23, x24
	or x5, x25, x26
	or x5, x27, x28
	or x5, x29, x30
	or x5, x31, x2
	
	bne x5, x0, zerosFail	# Something not 0ed out, go to zeros fail
	jalr x0, ra, 0	# We are good, go back to main
	
zerosFail:
	jal x0, zerosFail
	
	
allMathOperations:
	addi x5, x0, 10		# Set up register constants
	addi x6, x0, 5
	addi x7, x0, 2
	
	sub x10, x5, x6		# 10 should be 5
	mul x11, x6, x7		# 11 should be 10
	srl x12, x5, x7		# 12 should be 2 (10/4)
	
	sub x13, x6, x5		# 13 should be neg 5
	sra x14, x13, x7	# 14 should be neg 1 (-5/4)
	sll x15, x6, x7		# 15 should be 20 (5*4)
	
	jalr x0, ra, 0	# Branch back to the caller


branchTest:				# The x7 register will get large if it misses branches
	addi x5, x0, 10		# Set constants
	addi x6, x0, 5
	addi x7, x0, 9		# Holds the result of the test
	addi x10, x0, 0		# Holds the result of the test
	addi x11, x0, 9		# Holds the result of the test

branch1:
	beq x5, x6, branch2		# beq not taken
	subi x7, x7, 9
branch2:
	beq x5, x5, branch3		# beq taken
	addi x10, x10, 9
branch3:
	bne x5, x5, branch4		# bne not taken
	subi x11, x11, 9
branch4:
	bne x5, x6, branch5		# bne taken
	addi x7, x7, 9
branch5:
	add x12, x11, x10
	add x12, x12, x7
	
	bne x12, x0, badStop		# This won't work if branch doesn't but check anyways
	jalr x0, ra, 0			# Branch back to the caller


branchFailStop:
	jal x0, branchFailStop
	
stop:
	jal x0, stop