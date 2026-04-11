main:	# This is an overarching test to det if the cpu is working
	addi x0, x0, 0	# We are going to clear all of the callee saved regs
	add x1, x0, x0	# Set the ra to be 0
	add x2, x0, x0 	# Set the sp to be 0
	add x8, x0, x0 	# Set the frame pointer to 0
	add x9, x0, x0	# Set the saved reg to 0

	addi x18, x0, 0
	addi x19, x0, 0
	addi x20, x0, 0
	addi x21, x0, 0
	addi x22, x0, 0
	addi x23, x0, 0
	addi x24, x0, 0
	addi x25, x0, 0
	addi x26, x0, 0
	addi x27, x0, 0

	jal reset
	
	do some more stuff
	


reset:	# This function resets all caller saved regs for testing
	sub x5, x0, x0
	or x6, x0, x0
	and x7, x0, x0

	mul x10, x0, x0
	sll x11, x0, x0

	srl x12, x0, x0
	sra x13, x0, x0
	sra x14, x0, x0
	xori x15, x0, x0
	ori x16, x0, 0
	andi x17, x0, 0

	slti x28, x0, 0
	addi x29, x0, 0
	xori x30, x0, 0
	slti x31, x0, 0

	jalr x0, ra, 0	# Branch back to the caller
	
stop:
	jal x0, stop