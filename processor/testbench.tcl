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

# ── 0. Source helper TCL procedures ──────────────────────────────────────────
source ../memory_module/clear_mem.tcl
source ../memory_module/load_mem.tcl
source ../memory_module/dump_mem.tcl

# ── 1. Compile all VHDL files ────────────────────────────────────────────────
vlib work

vcom -work work ../memory_module/memory.vhd
vcom -work work InstructionFetch.vhd
vcom -work work ID.vhd
vcom -work work EX.vhd
vcom -work work MEM.vhd
vcom -work work WB.vhd
vcom -work work hazard_detection.vhd
vcom -work work processor.vhd
vcom -work work testbench.vhd

# ── 2. Load simulation ────────────────────────────────────────────────────────
vsim -t 1ns work.testbench

# ── 3. Clear and load instruction memory ─────────────────────────────────────
# Hierarchy path: testbench → uut (processor) → if_stage (InstructionFetch)
#                 → instruction_mem (memory component) → ram (internal array)
set IMEM /testbench/uut/if_stage/instruction_mem/ram

clear_mem $IMEM
load_riscv_bin program.txt $IMEM

# ── 4. Run 10,000 clock cycles ───────────────────────────────────────────────
run 10000 ns

# ── 5. Dump data memory ───────────────────────────────────────────────────────
# Hierarchy path: testbench → uut → mem_stage (MEM) → data_mem (memory) → ram
set DMEM /testbench/uut/mem_stage/data_mem/ram

dump_mem $DMEM memory.txt 8192

# ── 6. Dump register file ─────────────────────────────────────────────────────
# The register file lives inside the ID stage as signal 'regs'.
# ModelSim exposes it as a memory-like object addressable by register index.
set REGFILE /testbench/uut/id_stage/regs

set fp [open register_file.txt w]
for {set i 0} {$i < 32} {incr i} {
    # Each element of regs is 32 bits wide; read as a single entry.
    set val [string trim [mem display -format bin \
                          -startaddress $i -endaddress $i \
                          -noaddress $REGFILE]]
    puts $fp $val
}
close $fp

echo "--- Register file dumped to register_file.txt ---"
echo "--- Simulation complete ---"
