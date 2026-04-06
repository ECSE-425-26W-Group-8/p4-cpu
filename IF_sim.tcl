# =============================================================================
# IF_sim.tcl
# Compiles, loads memory, and runs the InstructionFetch testbench in ModelSim.
#
# Run from the project root (p4-cpu/) via the ModelSim console:
#   source IF_sim.tcl
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Paths
# -----------------------------------------------------------------------------
set MEM_DIR   "memory_module"
set PROC_DIR  "processor"
set MEM_CODE  "factorial_bin.txt"
set TB_ENTITY "InstructionFetch_tb"

# Internal path to the memory array inside the DUT hierarchy.
# Used by `mem load` to pre-populate RAM before simulation time advances.
set MEM_PATH  "/$TB_ENTITY/dut/instruction_mem/ram_block"

# -----------------------------------------------------------------------------
# 2. Compile
# -----------------------------------------------------------------------------
echo "--- Compiling: memory ---"
vcom -2008 "$MEM_DIR/memory.vhd"

echo "--- Compiling: InstructionFetch ---"
vcom -2008 "$PROC_DIR/InstructionFetch.vhd"

echo "--- Compiling: InstructionFetch_tb ---"
vcom -2008 "$PROC_DIR/InstructionFetch_tb.vhd"

# -----------------------------------------------------------------------------
# 3. Start simulation (time frozen at 0 ns)
# -----------------------------------------------------------------------------
echo "--- Starting simulation ---"
vsim -voptargs="+acc" $TB_ENTITY

# -----------------------------------------------------------------------------
# 4. Wave window setup
# All signals are visible; internal DUT signals exposed via +acc.
# -----------------------------------------------------------------------------
add wave -divider "Testbench Inputs"
add wave -label clk             -noupdate                   /$TB_ENTITY/clk
add wave -label "b taken"       -noupdate                   /$TB_ENTITY/branchTake_EX_IF_LN
add wave -label "b target"      -noupdate -radix hex        /$TB_ENTITY/result_EX_IF_REGLN

add wave -divider "Pipeline Outputs"
add wave -label "pc addr"       -noupdate -radix hex        /$TB_ENTITY/addr_IF_ID_LNREG
add wave -label "instruction"   -noupdate -radix hex        /$TB_ENTITY/inst_IF_ID_LNREG

add wave -divider "DUT Internals"
add wave -label pc              -noupdate -radix hex        /$TB_ENTITY/dut/pc
add wave -label "next pc"       -noupdate -radix hex        /$TB_ENTITY/dut/next_pc
add wave -label "int pc"        -noupdate -radix unsigned   /$TB_ENTITY/dut/int_pc
add wave -label "wait request"  -noupdate                   /$TB_ENTITY/dut/s_waitrequest
add wave -label "instruction"   -noupdate -radix hex        /$TB_ENTITY/dut/s_instruction

# -----------------------------------------------------------------------------
# 5. Load instructions into memory
#
# factorial_bin.txt is the direct compiler output: one 32-character binary
# string per instruction, stored little-endian into the 8-bit memory array
# by load_riscv_bin (defined in memory_module/load_mem.tcl).
# -----------------------------------------------------------------------------
source "$MEM_DIR/clear_mem.tcl"
clear_mem $MEM_PATH

source "$MEM_DIR/load_mem.tcl"
load_riscv_bin $MEM_CODE $MEM_PATH

# -----------------------------------------------------------------------------
# 6. Run
# Memory is fully loaded; simulation time now starts advancing.
# 3 test cases × ~3 cycles each + margin = 20 ns is more than sufficient.
# -----------------------------------------------------------------------------
echo "--- Running simulation ---"
run 20 ns

wave zoom full
echo "--- Simulation complete. Check transcript for PASS/FAIL reports. ---"