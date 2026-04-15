# Test: Load Word (LW) and Store/Load Round-Trip
#
# Part A — no hazard: SW to addr 0, 3 NOPs, LW from addr 0, 3 NOPs, compare.
# Part B — load-to-use hazard: SW to addr 4, 3 NOPs, LW from addr 4,
#           then IMMEDIATELY use the loaded register (no NOPs).
#           The hazard-detection unit must stall correctly.
#
# Status register x31: 0 = running, 1 = pass, 301/302 = fail.

addi x31, x0, 0

# ============================================================
# Part A: SW + LW round-trip, no data hazard
# ============================================================

addi t0, x0, -1            # t0 = 0xFFFFFFFF (-1)
sw   t0, 0(x0)             # M[0] = 0xFFFFFFFF

addi x0, x0, 0             # NOP 1 — let SW reach MEM stage
addi x0, x0, 0             # NOP 2
addi x0, x0, 0             # NOP 3

lw   t1, 0(x0)             # t1 = M[0]  (should be 0xFFFFFFFF)

addi x0, x0, 0             # NOP 1 — let LW complete before compare
addi x0, x0, 0             # NOP 2
addi x0, x0, 0             # NOP 3

bne  t1, t0, f301          # t1 must equal t0

# ============================================================
# Part B: LW immediately followed by dependent instruction
#         (load-to-use hazard — no NOPs between LW and use)
# ============================================================

addi t2, x0, 42            # t2 = 42
sw   t2, 4(x0)             # M[4] = 42

addi x0, x0, 0             # NOP 1 — let SW reach MEM stage
addi x0, x0, 0             # NOP 2
addi x0, x0, 0             # NOP 3

lw   t3, 4(x0)             # t3 = M[4] = 42
addi t4, t3, 1             # HAZARD: t3 used immediately; t4 should be 43

addi t5, x0, 43            # gold value
bne  t4, t5, f302          # t4 must equal 43

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
