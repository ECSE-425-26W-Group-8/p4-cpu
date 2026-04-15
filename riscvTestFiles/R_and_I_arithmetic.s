addi x31, x0, 0     # Status: Running (0)
addi t0, x0, 10     # Operand A = 10 (0xA)
addi t1, x0, 3      # Operand B = 3 (0x3)

add  t2, t0, t1     # Test ADD: 10 + 3 = 13
addi t3, x0, 13     # Gold Value
bne  t2, t3, f1     # Error in ADD

sub  t2, t0, t1     # Test SUB: 10 - 3 = 7
addi t3, x0, 7      # Gold Value
bne  t2, t3, f2     # Error in SUB

mul  t2, t0, t1     # Test MUL: 10 * 3 = 30
addi t3, x0, 30     # Gold Value
bne  t2, t3, f3     # Error in MUL

and  t2, t0, t1     # Test AND: 1010 & 0011 = 0010 (2)
addi t3, x0, 2      # Gold Value
bne  t2, t3, f4     # Error in AND

or   t2, t0, t1     # Test OR: 1010 | 0011 = 1011 (11)
addi t3, x0, 11     # Gold Value
bne  t2, t3, f5     # Error in OR

sll  t2, t0, t1     # Test SLL: 10 << 3 = 80
addi t3, x0, 80     # Gold Value
bne  t2, t3, f6     # Error in SLL

srl  t2, t0, t1     # Test SRL: 10 >> 3 = 1
addi t3, x0, 1      # Gold Value
bne  t2, t3, f7     # Error in SRL

addi t4, x0, -8     # Load -8 for sign-extension test
sra  t2, t4, t1     # Test SRA: -8 >> 3 = -1
addi t3, x0, -1     # Gold Value
bne  t2, t3, f8     # Error in SRA

xori t2, t0, 3      # Test XORI: 10 ^ 3 = 9
addi t3, x0, 9      # Gold Value
bne  t2, t3, f9     # Error in XORI

ori  t2, t0, 5      # Test ORI: 10 | 5 = 15
addi t3, x0, 15     # Gold Value
bne  t2, t3, f10    # Error in ORI

andi t2, t0, 2      # Test ANDI: 10 & 2 = 2
addi t3, x0, 2      # Gold Value
bne  t2, t3, f11    # Error in ANDI

slti t2, t0, 5      # Test SLTI: 10 < 5 (False)
bne  t2, x0, f12    # Error in SLTI False case

slti t2, t1, 5      # Test SLTI: 3 < 5 (True)
addi t3, x0, 1      # Gold Value
bne  t2, t3, f13    # Error in SLTI True case

addi x31, x0, 1     # Status: Success (1)
j done              # Jump to final loop

f1:
    addi x31, x0, 101
    j done # ADD failed
f2:
    addi x31, x0, 102
    j done # SUB failed
f3:
    addi x31, x0, 103
    j done # MUL failed
f4:
    addi x31, x0, 104
    j done # AND failed
f5:
    addi x31, x0, 105
    j done # OR failed
f6:
    addi x31, x0, 106
    j done # SLL failed
f7:
    addi x31, x0, 107
    j done # SRL failed
f8:
    addi x31, x0, 108
    j done # SRA failed
f9:
    addi x31, x0, 201
    j done # XORI failed
f10:
    addi x31, x0, 202
    j done # ORI failed
f11:
    addi x31, x0, 203
    j done # ANDI failed
f12:
    addi x31, x0, 204
    j done # SLTI (1) failed
f13:
    addi x31, x0, 205
    j done # SLTI (2) failed
done:
    j done              # Infinite loop
