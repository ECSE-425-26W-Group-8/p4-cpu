# Load -1 into register t0
# The 12-bit immediate -1 is sign-extended to 32-bits (0xFFFFFFFF)
addi t0, x0, -1
# Store the value in t0 to memory address 0
# 0(x0) calculates the address as 0 + 0
sw t0, 0(x0)

done:
# Infinite loop using the Jump and Link instruction
# Writing to x0 (the zero register) effectively makes it a simple jump
    j done
