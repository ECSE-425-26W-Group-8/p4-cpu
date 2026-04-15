# Test: BEQ, BLT, BGE branch instructions + JAL/JALR return-address value
#
# Checks:
#   401  BEQ taken        (x0 == x0)
#   402  BEQ not-taken    (3 != 5)
#   403  BLT taken        (3 < 5)
#   404  BLT not-taken    (5 < 3 is false)
#   405  BLT signed taken (-1 < 0)
#   406  BLT signed not   (0 < -1 is false — unsigned would be TRUE, signed is FALSE)
#   407  BLT signed not   (INT_MAX < INT_MIN is false — same unsigned/signed inversion)
#   408  BGE taken        (5 >= 3)
#   409  BGE equal        (3 >= 3)
#   410  BGE not-taken    (3 >= 5 is false)
#   411  BGE signed taken (0 >= -1)
#   412  JAL/JALR return address: consecutive JAL PCs differ by 4
#
# Status: x31 = 0 (run), 1 (pass), 4xx (fail).

addi x31, x0, 0

# --- Set up base operands ---
addi t0, x0, 3             # t0 = 3
addi t1, x0, 5             # t1 = 5
addi t2, x0, -1            # t2 = 0xFFFFFFFF (= -1 signed)

# ============================================================
# BEQ tests
# ============================================================

# 401: BEQ taken — x0 == x0, must branch
beq  x0, x0, beq1ok
    addi x31, x0, 401      # NOT taken: ERROR
    j done
beq1ok:

# 402: BEQ not-taken — 3 != 5, must NOT branch
beq  t0, t1, f402
j beq2ok
f402:
    addi x31, x0, 402
    j done
beq2ok:

# ============================================================
# BLT tests
# ============================================================

# 403: BLT taken — 3 < 5, must branch
blt  t0, t1, blt1ok
    addi x31, x0, 403
    j done
blt1ok:

# 404: BLT not-taken — 5 < 3 is false, must NOT branch
blt  t1, t0, f404
j blt2ok
f404:
    addi x31, x0, 404
    j done
blt2ok:

# 405: BLT signed taken — -1 < 0, must branch
blt  t2, x0, blt3ok
    addi x31, x0, 405
    j done
blt3ok:

# 406: BLT signed not-taken — 0 < -1 is false (signed).
#      Unsigned: 0 < 0xFFFFFFFF is TRUE — this exposes signed vs unsigned.
blt  x0, t2, f406
j blt4ok
f406:
    addi x31, x0, 406
    j done
blt4ok:

# 407: BLT signed not-taken — INT_MAX < INT_MIN is false (signed).
#      Build INT_MIN = 0x80000000 and INT_MAX = 0x7FFFFFFF using SLL.
addi x10, x0, 1
addi x11, x0, 31
sll  x12, x10, x11         # x12 = 1 << 31 = 0x80000000 = INT_MIN
addi x13, x12, -1          # x13 = INT_MIN - 1 = 0x7FFFFFFF = INT_MAX

blt  x13, x12, f407        # INT_MAX < INT_MIN must NOT branch (signed: 2^31-1 < -2^31 is false)
j blt5ok
f407:
    addi x31, x0, 407
    j done
blt5ok:

# ============================================================
# BGE tests  (t0=3, t1=5, t2=-1 still valid)
# ============================================================

# 408: BGE taken — 5 >= 3, must branch
bge  t1, t0, bge1ok
    addi x31, x0, 408
    j done
bge1ok:

# 409: BGE equal — 3 >= 3, must branch
bge  t0, t0, bge2ok
    addi x31, x0, 409
    j done
bge2ok:

# 410: BGE not-taken — 3 >= 5 is false, must NOT branch
bge  t0, t1, f410
j bge3ok
f410:
    addi x31, x0, 410
    j done
bge3ok:

# 411: BGE signed taken — 0 >= -1 (signed), must branch
bge  x0, t2, bge4ok
    addi x31, x0, 411
    j done
bge4ok:

# ============================================================
# JAL / JALR return-address verification
#
# Pattern:
#   jal x14, jalF1   -- x14 = addr of NEXT instr (= addr of second jal)
#   jal x15, jalF2   -- x15 = addr of NEXT instr (= addr of sub)
#   sub x16, x15, x14  -- x16 should be 4 (one instruction apart)
#
# jalF1 does: jalr x0, x14, 0  (returns to second jal)
# jalF2 does: jalr x0, x15, 0  (returns to sub)
# ============================================================

jal  x14, jalF1            # x14 = PC+4 = addr of "jal x15, jalF2"
jal  x15, jalF2            # x15 = PC+4 = addr of "sub x16, x15, x14"
sub  x16, x15, x14         # x16 = addr(sub) - addr(second jal) = 4
addi x17, x0, 4
bne  x16, x17, f412

addi x31, x0, 1            # ALL TESTS PASSED
j done

f412:
    addi x31, x0, 412
    j done

# --- JAL helper functions (only reachable via jal above) ---
jalF1:
    jalr x0, x14, 0        # return to x14 (= addr of second jal)
jalF2:
    jalr x0, x15, 0        # return to x15 (= addr of sub)

done:
    j done
