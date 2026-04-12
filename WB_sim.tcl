# =============================================================================
# WB_sim.tcl
# Compiles and runs the WB (Write-Back) stage testbench in ModelSim.
#
# Run from the project root (p4-cpu/) via the ModelSim console:
#   source WB_sim.tcl
#
# The WB stage is purely combinational — no memory module is needed.
# All inputs are driven directly by the testbench stimulus process.
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Paths
# -----------------------------------------------------------------------------
set PROC_DIR  "processor"
set TB_ENTITY "WB_tb"

# -----------------------------------------------------------------------------
# 2. Compile
# -----------------------------------------------------------------------------
vlib work

echo "--- Compiling: WB stage ---"
vcom -2008 "$PROC_DIR/WB.vhd"

echo "--- Compiling: WB testbench ---"
vcom -2008 "$PROC_DIR/WB_tb.vhd"

# -----------------------------------------------------------------------------
# 3. Start simulation
# +acc exposes internal signals for wave viewing.
# -----------------------------------------------------------------------------
echo "--- Starting simulation ---"
vsim -voptargs="+acc" $TB_ENTITY

# -----------------------------------------------------------------------------
# 4. Wave window setup
# -----------------------------------------------------------------------------
add wave -divider "Clock"
add wave -label clk                      -noupdate                   /$TB_ENTITY/clk

add wave -divider "MUX select"
add wave -label "wb_sel"                 -noupdate -radix binary     /$TB_ENTITY/wb_sel_MEM_WB_REGLN

add wave -divider "Data inputs to WB stage"
add wave -label "result (ALU)"           -noupdate -radix hex        /$TB_ENTITY/result_MEM_WB_REGLN
add wave -label "data (mem read)"        -noupdate -radix hex        /$TB_ENTITY/data_MEM_WB_REGLN
add wave -label "npc (PC+4)"             -noupdate -radix hex        /$TB_ENTITY/npc_MEM_WB_REGLN
add wave -label "pc"                     -noupdate -radix hex        /$TB_ENTITY/pc_MEM_WB_REGLN

add wave -divider "Control inputs"
add wave -label "reg_write_in"           -noupdate                   /$TB_ENTITY/reg_write_MEM_WB_REGLN
add wave -label "branch_in"              -noupdate                   /$TB_ENTITY/branch_MEM_WB_REGLN
add wave -label "jump_in"                -noupdate                   /$TB_ENTITY/jump_MEM_WB_REGLN

add wave -divider "Outputs to ID stage"
add wave -label "data_WB_ID (selected)"  -noupdate -radix hex        /$TB_ENTITY/data_WB_ID_LN
add wave -label "reg_write_out"          -noupdate                   /$TB_ENTITY/reg_write_WB_ID_LN

# -----------------------------------------------------------------------------
# 5. Run
# All 6 tests are purely combinational — simulation finishes in well under 1 us.
# -----------------------------------------------------------------------------
echo "--- Running simulation ---"
run -all

wave zoom full
echo "--- Simulation complete. Check transcript for PASS/FAIL reports. ---"
