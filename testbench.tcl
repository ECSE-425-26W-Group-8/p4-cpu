################################################################################
# Group 8: RISC-V Processor Testbench Script
# ECSE 425 W26
#
# Usage (from ModelSim, with working directory set to processor/):
#   do testbench.tcl
#
# What this script does:
#   1. Compiles all VHDL sources.
#   2. Loads the simulation.
#   3. Clears instruction memory and loads program.txt.
#   4. Runs 10,000 clock cycles.
#   5. Dumps data memory to memory.txt (8192 32-bit words).
#   6. Dumps the register file to register_file.txt (32 registers).
################################################################################

set MEM_DIR   "memory_module"
set PROC_DIR  "processor"
set TB_ENTITY "testbench"

set UUT "/$TB_ENTITY/uut"

set IMEM "$UUT/if_stage/instruction_mem/ram_block"
set DMEM "$UUT/mem_stage/data_mem/ram_block"
set REGFILE "$UUT/id_stage/regs"

# ── 0. Source helper TCL procedures ──────────────────────────────────────────
source ./memory_module/clear_mem.tcl
source ./memory_module/load_mem.tcl
source ./memory_module/dump_mem.tcl

# ── 1. Compile all VHDL files ────────────────────────────────────────────────
vlib work

vcom -2008 $MEM_DIR/memory.vhd
vcom -2008 "$PROC_DIR/InstructionFetch.vhd"
vcom -2008 "$PROC_DIR/ID.vhd"
vcom -2008 "$PROC_DIR/EX.vhd"
vcom -2008 "$PROC_DIR/MEM.vhd"
vcom -2008 "$PROC_DIR/WB.vhd"
vcom -2008 "$PROC_DIR/hazard_detection.vhd"
vcom -2008 "$PROC_DIR/processor.vhd"
vcom -2008 "$PROC_DIR/testbench.vhd"

# ── 2. Load simulation ────────────────────────────────────────────────────────
vsim -voptargs="+acc" $TB_ENTITY

# Load waves here_____________________
view wave
#radix -hex

add wave -noupdate -divider "Processor Signals"
add wave -label "Clock"   $UUT/clk
add wave -label "Opcode"   $UUT/clk

add wave -noupdate -divider "Fetch Control Units"
add wave -label "Inst_out"   $UUT/if_stage/npc_IF_ID_LNREG
add wave -label "Inst_Mem_out"   $UUT/if_stage/inst_IF_ID_LNREG

add wave -noupdate -divider "ID"
add wave -label "Clock"   $UUT/id_stage/clk
add wave -label "Opcode"   $UUT/id_stage/opcode
add wave -label "ALU_Op"   $UUT/id_stage/alu_op
add wave -label "ALU_Src"  $UUT/id_stage/alu_src
add wave -label "RegWrite" $UUT/id_stage/reg_write

add wave -radix hex -label "op1_out"  $UUT/id_stage/op1_ID_EX_LNREG
add wave -radix hex -label "op2_out" $UUT/id_stage/op2_ID_EX_LNREG
add wave -radix hex -label "imm_out" $UUT/id_stage/imm_ID_EX_LNREG

add wave -radix hex -label "inst_in" $UUT/id_stage/inst_IF_ID_REGLN

add wave -noupdate -divider "EX Control Units"
add wave -radix hex -label "ALU_out"   $UUT/ex_stage/result_EX_MEM_LNREG
add wave -radix hex -label "imm_in" $UUT/ex_stage/imm_ID_EX_REGLN


add wave -noupdate -divider "MEM Control Units"

add wave -noupdate -divider "WB Control Units"

# ── 3. Clear and load instruction memory ─────────────────────────────────────

clear_mem $DMEM
clear_mem $IMEM
load_riscv_bin program.txt $IMEM

# ── 4. Run 10,000 clock cycles + reset ───────────────────────────────────────────────
run 10005 ns

# ── 5. Dump data memory ───────────────────────────────────────────────────────
# Hierarchy path: testbench → uut → mem_stage (MEM) → data_mem (memory) → ram

# TODO rename to right output
#dump_mem $DMEM memory.txt 8192
# dump_mem $IMEM inst_mem.txt 8192

# ── 6. Dump register file ─────────────────────────────────────────────────────
# The register file lives inside the ID stage as signal 'regs'.
# ModelSim exposes it as a memory-like object addressable by register index.

# TODO rename to right output
#set fp [open register_file.txt w]
#for {set i 0} {$i < 32} {incr i} {
#    # Each element of regs is 32 bits wide; read as a single entry.
#    set val [string trim [mem display -format bin \
#                          -startaddress $i -endaddress $i \
#                          -noaddress $REGFILE]]
#    puts $fp $val
#}
#close $fp

echo "--- Simulation complete ---"
