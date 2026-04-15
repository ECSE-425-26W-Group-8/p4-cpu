addi x31, x0, 0

addi t0, x0, 3             # t0 = 3
addi t1, x0, 5             # t1 = 5
addi t2, x0, -1            # t2 = -1 (0xFFFFFFFF signed)

beq  x0, x0, beq1ok       # 401: BEQ taken (x0 == x0), must branch
    addi x31, x0, 401      # NOT taken: ERROR
    j done
beq1ok:

beq  t0, t1, f402          # 402: BEQ not-taken (3 != 5), must NOT branch
j beq2ok
f402:
    addi x31, x0, 402
    j done
beq2ok:

blt  t0, t1, blt1ok        # 403: BLT taken (3 < 5), must branch
    addi x31, x0, 403
    j done
blt1ok:

blt  t1, t0, f404          # 404: BLT not-taken (5 < 3 is false), must NOT branch
j blt2ok
f404:
    addi x31, x0, 404
    j done
blt2ok:

blt  t2, x0, blt3ok        # 405: BLT signed taken (-1 < 0), must branch
    addi x31, x0, 405
    j done
blt3ok:

blt  x0, t2, f406          # 406: BLT signed not-taken (0 < -1 signed is false; unsigned TRUE - tests signed)
j blt4ok
f406:
    addi x31, x0, 406
    j done
blt4ok:

addi x10, x0, 1
addi x11, x0, 31
sll  x12, x10, x11         # x12 = 0x80000000 = INT_MIN
addi x13, x12, -1          # x13 = 0x7FFFFFFF = INT_MAX
blt  x13, x12, f407        # 407: BLT signed not-taken (INT_MAX < INT_MIN signed is false; unsigned TRUE)
j blt5ok
f407:
    addi x31, x0, 407
    j done
blt5ok:

bge  t1, t0, bge1ok        # 408: BGE taken (5 >= 3), must branch
    addi x31, x0, 408
    j done
bge1ok:

bge  t0, t0, bge2ok        # 409: BGE equal (3 >= 3), must branch
    addi x31, x0, 409
    j done
bge2ok:

bge  t0, t1, f410          # 410: BGE not-taken (3 >= 5 is false), must NOT branch
j bge3ok
f410:
    addi x31, x0, 410
    j done
bge3ok:

bge  x0, t2, bge4ok        # 411: BGE signed taken (0 >= -1), must branch
    addi x31, x0, 411
    j done
bge4ok:

jal  x14, jalF1            # 412: JAL stores PC+4; x14 = addr of next instr
jal  x15, jalF2            # x15 = addr of next instr; jalF1 returns here
sub  x16, x15, x14         # x16 = addr(sub) - addr(second jal) = 4; jalF2 returns here
addi x17, x0, 4
bne  x16, x17, f412

addi x31, x0, 1            # SUCCESS
j done

f412:
    addi x31, x0, 412
    j done
jalF1:
    jalr x0, x14, 0        # return to x14 (addr of second jal)
jalF2:
    jalr x0, x15, 0        # return to x15 (addr of sub)
done:
    j done
