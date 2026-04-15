addi x31, x0, 0

addi t0, x0, -1            # t0 = 0xFFFFFFFF (all ones, used as base value)

addi t1, x0, 0             # 701: SLL by 0 - identity: 0xFFFFFFFF << 0 == 0xFFFFFFFF
sll  t2, t0, t1            # t2 = 0xFFFFFFFF << 0 = 0xFFFFFFFF
bne  t2, t0, f701

addi t1, x0, 31            # 702: SRL by 31 - single bit survives: 0xFFFFFFFF >> 31 == 1
srl  t2, t0, t1            # t2 = 0xFFFFFFFF >> 31 = 1
addi t3, x0, 1
bne  t2, t3, f702

addi t1, x0, 1             # 703: SRA of -1 by 1 - arithmetic sign-fill: stays 0xFFFFFFFF
sra  t2, t0, t1            # t2 = 0xFFFFFFFF >> 1 (arith) = 0xFFFFFFFF
bne  t2, t0, f703

addi t4, x0, 1             # 704: SRA of INT_MIN by 31 - full sign-fill -> 0xFFFFFFFF
addi t5, x0, 31
sll  t4, t4, t5            # t4 = 1 << 31 = 0x80000000 = INT_MIN
sra  t2, t4, t5            # t2 = 0x80000000 >> 31 (arith) = 0xFFFFFFFF
bne  t2, t0, f704

addi t1, x0, 32            # 705: SRL by 32 - SPEC VIOLATION (EX.vhd:74 uses op2[5:0] not op2[4:0])
srl  t2, t0, t1            # RISC-V spec: 32[4:0]=0 -> shift by 0 -> t2=0xFFFFFFFF; this CPU shifts by 32 -> t2=0
bne  t2, t0, f705          # branches on this CPU (t2=0 != 0xFFFFFFFF) -> x31=705 documents the bug

addi x31, x0, 1            # SUCCESS (only reachable if CPU is spec-compliant for shift-by-32)
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
