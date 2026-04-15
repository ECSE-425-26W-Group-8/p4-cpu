# Test: Arithmetic boundary / overflow edge cases
#
# All checks use signed 32-bit semantics (RISC-V standard).
# INT_MIN = 0x80000000 = -2147483648
# INT_MAX = 0x7FFFFFFF =  2147483647
#
# INT_MIN is built with SLL (avoids a LUI dependency):
#   addi t_one, x0, 1
#   addi t_sh,  x0, 31
#   sll  intMin, t_one, t_sh   ->  0x80000000
#
# Checks:
#   601  ADD overflow:  INT_MAX + 1  wraps to INT_MIN (negative)
#   602  SUB underflow: INT_MIN - 1  wraps to INT_MAX (positive)
#   603  MUL overflow:  65536 * 65536 = 2^32; lower 32 bits = 0
#   604  SLTI negative: (-1 < 0) == 1
#   605  SLTI zero:     (0  < 0) == 0
#
# Status: x31 = 0 (run), 1 (pass), 6xx (fail).

addi x31, x0, 0

# --- Build INT_MIN and INT_MAX without LUI ---
addi x10, x0, 1
addi x11, x0, 31
sll  x12, x10, x11         # x12 = 0x80000000 = INT_MIN
addi x13, x12, -1          # x13 = 0x7FFFFFFF = INT_MAX

# ============================================================
# 601: ADD overflow — INT_MAX + 1 must wrap to INT_MIN
#      Verify: result is negative (slti result < 0 == 1)
# ============================================================
add  x14, x13, x10         # INT_MAX + 1 = 0x7FFFFFFF + 1 = 0x80000000
slti x15, x14, 0           # x15 = 1 if x14 < 0  (it should be INT_MIN = negative)
beq  x15, x0, f601         # if x15 == 0, overflow did NOT produce a negative: error

# ============================================================
# 602: SUB underflow — INT_MIN - 1 must wrap to INT_MAX
#      Verify: result is positive (slti result < 0 == 0)
#      Also verify result != INT_MIN (would mean no wraparound at all)
# ============================================================
sub  x14, x12, x10         # INT_MIN - 1 = 0x80000000 - 1 = 0x7FFFFFFF
slti x15, x14, 0           # x15 = 0 if x14 >= 0  (it should be INT_MAX = positive)
bne  x15, x0, f602         # if x15 != 0, result is still negative: error

# ============================================================
# 603: MUL overflow — lower 32 bits only
#      65536 * 65536 = 2^32; lower 32 bits = 0
#      Build 65536 = 2^16:  addi t, x0, 1; addi s, x0, 16; sll val, t, s
# ============================================================
addi x16, x0, 16
sll  x17, x10, x16         # x17 = 1 << 16 = 0x10000 = 65536
mul  x18, x17, x17         # 65536 * 65536 = 2^32; lower 32 bits = 0
bne  x18, x0, f603         # if x18 != 0, lower-32-bits truncation failed

# ============================================================
# 604: SLTI with negative immediate source: -1 < 0 must be 1
# ============================================================
addi x19, x0, -1           # x19 = -1 (0xFFFFFFFF)
slti x20, x19, 0           # x20 = (-1 < 0) ? 1 : 0 = 1
addi x21, x0, 1
bne  x20, x21, f604        # if x20 != 1, SLTI sign handling is wrong

# ============================================================
# 605: SLTI: 0 < 0 must be 0
# ============================================================
slti x20, x0, 0            # x20 = (0 < 0) ? 1 : 0 = 0
bne  x20, x0, f605         # if x20 != 0, SLTI boundary is wrong

addi x31, x0, 1            # SUCCESS
j done

f601:
    addi x31, x0, 601
    j done
f602:
    addi x31, x0, 602
    j done
f603:
    addi x31, x0, 603
    j done
f604:
    addi x31, x0, 604
    j done
f605:
    addi x31, x0, 605
    j done
done:
    j done
