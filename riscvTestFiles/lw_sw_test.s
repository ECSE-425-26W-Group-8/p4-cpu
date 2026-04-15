addi x31, x0, 0

addi t0, x0, -1            # t0 = 0xFFFFFFFF; Part A: store -1 to M[0], load back
sw   t0, 0(x0)             # M[0] = 0xFFFFFFFF
addi x0, x0, 0             # NOP 1 - let SW reach MEM stage
addi x0, x0, 0             # NOP 2
addi x0, x0, 0             # NOP 3
lw   t1, 0(x0)             # t1 = M[0] (should be 0xFFFFFFFF)
addi x0, x0, 0             # NOP 1 - let LW complete before compare
addi x0, x0, 0             # NOP 2
addi x0, x0, 0             # NOP 3
bne  t1, t0, f301          # 301: t1 must equal t0

addi t2, x0, 42            # t2 = 42; Part B: store 42 to M[4], LW + immediate use (hazard)
sw   t2, 4(x0)             # M[4] = 42
addi x0, x0, 0             # NOP 1 - let SW reach MEM stage
addi x0, x0, 0             # NOP 2
addi x0, x0, 0             # NOP 3
lw   t3, 4(x0)             # t3 = M[4] = 42
addi t4, t3, 1             # HAZARD: t3 used immediately; t4 should be 43
addi t5, x0, 43            # gold value
bne  t4, t5, f302          # 302: t4 must equal 43

addi x31, x0, 1            # SUCCESS
j done

f301:
    addi x31, x0, 301
    j done
f302:
    addi x31, x0, 302
    j done
done:
    j done
