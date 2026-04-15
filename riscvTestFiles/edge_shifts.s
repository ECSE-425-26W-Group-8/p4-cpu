# Test: Shift instruction edge cases (SLL, SRL, SRA)
#
# Checks 701-704 are expected to PASS on a correct RISC-V implementation.
# Check 705 EXPOSES A KNOWN BUG:
#   EX.vhd:74 uses op2[5:0] (6 bits) for shift amount instead of
#   the RISC-V-mandated op2[4:0] (5 bits).
#   Shift amount = 32 (binary 100000):
#     RISC-V spec: use bits[4:0] = 00000 -> shift by 0 -> result unchanged
#     This CPU:    use bits[5:0] = 100000 -> shift by 32 -> result = 0
#   x31 = 705 is the expected outcome on this hardware.
#
# Checks:
#   701  SLL by 0  — identity: 0xFFFFFFFF << 0 == 0xFFFFFFFF
#   702  SRL by 31 — single bit: 0xFFFFFFFF >> 31 == 1
#   703  SRA by 1  — sign-fill: 0xFFFFFFFF >> 1 (arith) == 0xFFFFFFFF
#   704  SRA by 31 — full sign-fill: INT_MIN >> 31 (arith) == 0xFFFFFFFF
#   705  SRL by 32 — spec violation: per RISC-V, result = 0xFFFFFFFF
#                    but this CPU produces 0 (THIS TEST WILL FAIL ON THIS CPU)
#
# Status: x31 = 0 (run), 1 (pass only if CPU is spec-compliant for shift-by-32),
#         7xx (fail at that check).

addi x31, x0, 0

addi t0, x0, -1            # t0 = 0xFFFFFFFF (all ones)

# ============================================================
# 701: SLL by 0 — shifting by zero must be an identity
# ============================================================
addi t1, x0, 0
sll  t2, t0, t1            # t2 = 0xFFFFFFFF << 0 = 0xFFFFFFFF
bne  t2, t0, f701

# ============================================================
# 702: SRL by 31 — only the MSB survives as bit 0
#      0xFFFFFFFF (logical) >> 31 = 0x00000001
# ============================================================
addi t1, x0, 31
srl  t2, t0, t1            # t2 = 0xFFFFFFFF >> 31 = 1
addi t3, x0, 1
bne  t2, t3, f702

# ============================================================
# 703: SRA of -1 by 1 — arithmetic right shift sign-fills
#      0xFFFFFFFF >> 1 (arithmetic) = 0xFFFFFFFF  (still -1)
# ============================================================
addi t1, x0, 1
sra  t2, t0, t1            # t2 = 0xFFFFFFFF >> 1 (arith) = 0xFFFFFFFF
bne  t2, t0, f703

# ============================================================
# 704: SRA of INT_MIN (0x80000000) by 31
#      All bits become the sign bit: result = 0xFFFFFFFF = -1
# ============================================================
addi t4, x0, 1
addi t5, x0, 31
sll  t4, t4, t5            # t4 = 1 << 31 = 0x80000000 = INT_MIN
sra  t2, t4, t5            # t2 = 0x80000000 >> 31 (arith) = 0xFFFFFFFF
bne  t2, t0, f704          # t2 must equal t0 = 0xFFFFFFFF

# ============================================================
# 705: SRL by 32 — SPEC VIOLATION TEST
#
# RISC-V spec: shift amount = rs2[4:0]; 32 dec = 0b100000 -> [4:0] = 0 -> shift by 0
#   Expected (spec): t2 = t0 = 0xFFFFFFFF  (no shift)
#
# This CPU uses rs2[5:0]; 32 dec = 0b100000 -> [5:0] = 32 -> shift by 32
#   Actual (CPU):   t2 = 0x00000000  (all bits gone)
#
# bne t2, t0 will be TAKEN because t2 = 0 != 0xFFFFFFFF -> f705 -> x31 = 705
# This is the expected failure that documents the non-compliance.
# ============================================================
addi t1, x0, 32            # shift amount = 32 (one more than the 5-bit max)
srl  t2, t0, t1            # per spec: t2 = t0; per this CPU: t2 = 0
bne  t2, t0, f705          # will branch on this CPU -> exposes the bug

addi x31, x0, 1            # SUCCESS (only if CPU is spec-compliant for shift-by-32)
j done

f701:
    addi x31, x0, 701
    j done
f702:
    addi x31, x0, 702
    j done
f703:
    addi x31, x0, 703
    j done
f704:
    addi x31, x0, 704
    j done
f705:
    addi x31, x0, 705
    j done
done:
    j done
