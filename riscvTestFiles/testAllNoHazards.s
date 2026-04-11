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
	xori x15, x0, x0
	ori x16, x0, 0
	andi x17, x0, 0
	slti x28, x0, 0	# Temporaries
	addi x29, x0, 0
	xori x30, x0, 0
	slti x31, x0, 0
	jalr x0, ra, 0	# Branch back to the caller
	
zerosTest:	# Start with callee saved reg
8, 
	or x5, x8, 
zerosCallerTest:
	or x5, x5, x6
	
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
	
	
addFiveToStack:

clearFiveFromStack:

incrimentalValueRF:

stop:
	jal x0, stop
	



	


	
	
all conditional branches taken and not taken
load and store work repeatedly
jump&link work well
all math operations work well