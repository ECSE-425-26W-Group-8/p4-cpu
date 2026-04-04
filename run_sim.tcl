# run_sim.tcl
# Automates the compilation, simulation, and memory loading process.

# 1. Define paths
set MEM_DIR "memory_module"
set MACHINE_CODE "factorial_hex.txt"
set OUTFILE "output.txt"
set TB_ENTITY "textio_test_tb"

# 2. Compile VHDL files (VHDL-2008)
echo "--- Compiling Source Files ---"
vcom -2008 "$MEM_DIR/memory.vhd"
vcom -2008 "textio_test_tb.vhd"

# 3. Start Simulation
echo "--- Starting Simulation ---"
vsim -voptargs="+acc" $TB_ENTITY

# 4. Setup Wave Window (Optional but helpful)
add wave -noupdate /textio_test_tb/clk
add wave -noupdate -radix decimal /textio_test_tb/address
add wave -noupdate -format hex /textio_test_tb/readdata
add wave -noupdate /textio_test_tb/waitrequest
add wave -noupdate -format hex /textio_test_tb/dut/ram_block

echo "--- Clearing memory ---"
source "$MEM_DIR/clear_mem.tcl"
echo "--- Loading Memory via load_mem.tcl ---"
source "$MEM_DIR/load_mem.tcl"
load_riscv_bin $MACHINE_CODE "/textio_test_tb/dut/ram_block"

echo "--- Running Verification ---"
run 100 ns

# Zoom the wave window to fit
wave zoom full
echo "--- Simulation Complete. ---"

mem put 
