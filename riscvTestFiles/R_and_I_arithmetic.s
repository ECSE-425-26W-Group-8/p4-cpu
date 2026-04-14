# STATUS REGISTER: x31
# x31 = 1 (Success)
# x31 = 1xx (Failure in R-type where xx is error code)
# x31 = 2xx (Failure in I-type where xx is error code)

# SETUP
addi x31, x0, 0
addi t0, x0, 10      # 0xA
addi t1, x0, 3       # 0x3

# --- 1. R-TYPE ARITHMETIC & LOGIC ---
and  t2, t0, t1      # 1010 & 0011 = 0010 (2)
addi t3, x0, 2
bne  t2, t3, fail_1

or   t2, t0, t1      # 1010 | 0011 = 1011 (11)
addi t3, x0, 11
bne  t2, t3, fail_2

xor  t2, t0, t1      # 1010 ^ 0011 = 1001 (9)
addi t3, x0, 9
bne  t2, t3, fail_3

# --- 2. SHIFTS (Crucial for funct3/funct7 decoding) ---
sll  t2, t0, t1      # 10 << 3 = 80
addi t3, x0, 80
bne  t2, t3, fail_4

srl  t2, t0, t1      # 10 >> 3 = 1
addi t3, x0, 1
bne  t2, t3, fail_5

# --- 3. SIGN EXTENSION & SRA ---
# Load -8 (0xFFFFFFF8)
addi t4, x0, -8
sra  t2, t4, t1      # -8 >> 3 (arithmetic) = -1 (0xFFFFFFFF)
addi t3, x0, -1
bne  t2, t3, fail_6

# --- 5. IMMEDIATE TYPES (Tests ImmGen) ---
xori t2, t0, 3       # 10 ^ 3 = 9
addi t3, x0, 9
bne  t2, t3, fail_9

slti t2, t0, 15      # Is 10 < 15? Yes (1)
addi t3, x0, 1
bne  t2, t3, fail_10

# --- SUCCESS ---
addi x31, x0, 1
j done

# --- FAIL CODES ---
fail_1:
    addi x31, x0, 101
    j done
fail_2:
    addi x31, x0, 102
    j done
fail_3:
    addi x31, x0, 103
    j done
fail_4:
    addi x31, x0, 104
    j done
fail_5:
    addi x31, x0, 105
    j done
fail_6:
    addi x31, x0, 106
    j done
fail_7:
    addi x31, x0, 107
    j done
fail_9:
    addi x31, x0, 201
    j done
fail_10:
    addi x31, x0, 202
    j done

done:
j done
