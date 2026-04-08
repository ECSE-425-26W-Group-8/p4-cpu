# =============================================================================
# MEM_sim.tcl
# Compiles and runs the MEM stage testbench in ModelSim.
#
# Run from the project root (p4-cpu/) via the ModelSim console:
#   source MEM_sim.tcl
#
# Note: all test data is written through the DUT's own port during simulation.
# No external memory pre-loading is needed (unlike the instruction memory).
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Paths
# -----------------------------------------------------------------------------
set MEM_DIR   "memory_module"
set PROC_DIR  "processor"
set TB_ENTITY "MEM_tb"

# Path to the data memory array inside the DUT hierarchy.
# Hierarchy: MEM_tb / dut (MEM) / data_mem (memory) / ram_block
set MEM_PATH  "/$TB_ENTITY/dut/data_mem/ram_block"

# -----------------------------------------------------------------------------
# 2. Compile (order matters: memory must be compiled before MEM)
# -----------------------------------------------------------------------------
echo "--- Compiling: memory module ---"
vcom -2008 "$MEM_DIR/memory.vhd"

echo "--- Compiling: MEM stage ---"
vcom -2008 "$PROC_DIR/MEM.vhd"

echo "--- Compiling: MEM testbench ---"
vcom -2008 "$PROC_DIR/MEM_tb.vhd"

# -----------------------------------------------------------------------------
# 3. Start simulation (time frozen at 0 ns)
# +acc exposes internal signals (ram_block) for wave viewing.
# -----------------------------------------------------------------------------
echo "--- Starting simulation ---"
vsim -voptargs="+acc" $TB_ENTITY 

# -----------------------------------------------------------------------------
# 4. Clear data memory
# Ensures ram_block starts at all-zeros before any testbench writes.
# -----------------------------------------------------------------------------
source "$MEM_DIR/clear_mem.tcl"
clear_mem $MEM_PATH

# -----------------------------------------------------------------------------
# 5. Wave window setup
# -----------------------------------------------------------------------------
add wave -divider "Clock"
add wave -label clk                 -noupdate                   /$TB_ENTITY/clk

add wave -divider "Inputs: EX_MEM register to MEM stage"
add wave -label "address"           -noupdate -radix hex        /$TB_ENTITY/result_EX_MEM_REGLN
add wave -label "write_data"        -noupdate -radix hex        /$TB_ENTITY/op2Addr_EX_MEM_REGLN
add wave -label "mem_read"          -noupdate                   /$TB_ENTITY/mem_read_EX_MEM_REGLN
add wave -label "mem_write"         -noupdate                   /$TB_ENTITY/mem_write_EX_MEM_REGLN

add wave -divider "Outputs: MEM to MEM_WB register"
add wave -label "read_data"         -noupdate -radix hex        /$TB_ENTITY/data_MEM_WB_LNREG
add wave -label "result (pass-thru)" -noupdate -radix hex       /$TB_ENTITY/result_MEM_WB_LNREG
# add wave -label "mem_read_out"      -noupdate                   /$TB_ENTITY/mem_read_MEM_WB_LNREG
# add wave -label "mem_write_out"     -noupdate                   /$TB_ENTITY/mem_write_MEM_WB_LNREG
add wave -label "reg_write_out"     -noupdate                   /$TB_ENTITY/reg_write_MEM_WB_LNREG
add wave -label "branch_out"        -noupdate                   /$TB_ENTITY/branch_MEM_WB_LNREG
add wave -label "jump_out"          -noupdate                   /$TB_ENTITY/jump_MEM_WB_LNREG

# -----------------------------------------------------------------------------
# 6. Run
# Tests 1 and 2: ~6 write-read pairs × 2 clock edges each = ~12 ns + margin.
# Test 3 halts simulation via severity FAILURE when both R/W are asserted.
# 30 ns is sufficient; simulation will stop early on Test 3.
# -----------------------------------------------------------------------------
echo "--- Running simulation ---"
run -all

wave zoom full
echo "--- Simulation complete. Check transcript for PASS/FAIL reports. ---"
