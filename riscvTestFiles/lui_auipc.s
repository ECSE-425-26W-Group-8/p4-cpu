# Test: LUI and AUIPC instructions
#
# LUI  rd, imm  ->  rd = imm << 12  (20-bit immediate, lower 12 bits zeroed)
# AUIPC rd, imm ->  rd = PC + (imm << 12)
#
# Checks:
#   501  LUI 1        -> 0x00001000; verified by SRL 12 == 1
#   502  LUI 524288   -> 0x80000000 (INT_MIN); verified by SLTI < 0 == 1
#   503  LUI 1048575  -> 0xFFFFF000 (-4096);   verified by SLTI < 0 == 1
#   504  AUIPC diff   -> two consecutive AUIPC(0) addresses differ by exactly 4
#
# Status: x31 = 0 (run), 1 (pass), 5xx (fail).

addi x31, x0, 0

# ============================================================
# 501: lui t0, 1  ->  t0 = 0x00001000 = 4096
#      Verify: t0 >> 12 == 1
# ============================================================
lui  t0, 1
addi t1, x0, 12
srl  t2, t0, t1            # t2 = 0x00001000 >> 12 = 1
addi t3, x0, 1
bne  t2, t3, f501

# ============================================================
# 502: lui t0, 524288  ->  t0 = 0x80000000 = INT_MIN (most negative)
#      Verify: SLTI(t0 < 0) == 1
#      (0x80000000 as signed 32-bit = -2147483648)
# ============================================================
lui  t0, 524288
slti t1, t0, 0             # t1 = 1  if t0 < 0
beq  t1, x0, f502          # if t1 == 0 (not negative), error

# ============================================================
# 503: lui t0, 1048575  ->  t0 = 0xFFFFF000 = -4096 (max U-type immediate)
#      Verify: SLTI(t0 < 0) == 1
# ============================================================
lui  t0, 1048575
slti t1, t0, 0             # t1 = 1  if t0 < 0
beq  t1, x0, f503          # if t1 == 0 (not negative), error

# ============================================================
# 504: AUIPC(0) at two consecutive addresses differs by 4
#      auipc t0, 0  ->  t0 = PC of first auipc
#      auipc t1, 0  ->  t1 = PC of second auipc = t0 + 4
#      sub t2, t1, t0  ->  t2 should be 4
# ============================================================
auipc t0, 0                # t0 = PC of this instruction
auipc t1, 0                # t1 = PC of this instruction = t0 + 4
sub   t2, t1, t0           # t2 = t1 - t0 should be 4
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
