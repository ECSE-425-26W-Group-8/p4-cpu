addi x31, x0, 0

addi x10, x0, 1            # x10 = 1 (reused as shift base and unit increment)
addi x11, x0, 31           # x11 = 31 (shift amount for INT_MIN)
sll  x12, x10, x11         # x12 = 0x80000000 = INT_MIN
addi x13, x12, -1          # x13 = 0x7FFFFFFF = INT_MAX

add  x14, x13, x10         # 601: ADD overflow: INT_MAX + 1 -> wraps to INT_MIN (negative)
slti x15, x14, 0           # x15 = 1 if x14 < 0 (correct: overflowed result is negative)
beq  x15, x0, f601         # if x15 == 0: no overflow, error

sub  x14, x12, x10         # 602: SUB underflow: INT_MIN - 1 -> wraps to INT_MAX (positive)
slti x15, x14, 0           # x15 = 0 if x14 >= 0 (correct: underflowed result is positive)
bne  x15, x0, f602         # if x15 != 0: result still negative, error

addi x16, x0, 16
sll  x17, x10, x16         # 603: MUL overflow: x17 = 1 << 16 = 65536
mul  x18, x17, x17         # 65536 * 65536 = 2^32; lower 32 bits = 0
bne  x18, x0, f603         # if x18 != 0: truncation wrong, error

addi x19, x0, -1           # 604: SLTI negative: -1 < 0 must return 1
slti x20, x19, 0           # x20 = (-1 < 0) ? 1 : 0 = 1
addi x21, x0, 1
bne  x20, x21, f604        # if x20 != 1: sign handling wrong, error

slti x20, x0, 0            # 605: SLTI zero: 0 < 0 must return 0
bne  x20, x0, f605         # if x20 != 0: boundary wrong, error

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
