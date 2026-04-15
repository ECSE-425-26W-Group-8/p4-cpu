addi x31, x0, 0

lui  t0, 1                 # 501: lui 1 -> t0 = 0x1000; verify t0 >> 12 == 1
addi t1, x0, 12
srl  t2, t0, t1            # t2 = 0x1000 >> 12 = 1
addi t3, x0, 1
bne  t2, t3, f501

lui  t0, 524288            # 502: lui 0x80000 -> t0 = 0x80000000 (INT_MIN, negative)
slti t1, t0, 0             # t1 = 1 if t0 < 0
beq  t1, x0, f502          # if t1 == 0 (not negative): error

lui  t0, 1048575           # 503: lui 0xFFFFF -> t0 = 0xFFFFF000 (-4096, negative)
slti t1, t0, 0             # t1 = 1 if t0 < 0
beq  t1, x0, f503          # if t1 == 0 (not negative): error

auipc t0, 0               # 504: t0 = PC of this instruction
auipc t1, 0               # t1 = PC of next instruction = t0 + 4
sub   t2, t1, t0          # t2 = t1 - t0 should be 4
addi  t3, x0, 4
bne   t2, t3, f504

addi x31, x0, 1            # SUCCESS
j done

f501:
    addi x31, x0, 501
    j done
f502:
    addi x31, x0, 502
    j done
f503:
    addi x31, x0, 503
    j done
f504:
    addi x31, x0, 504
    j done
done:
    j done
