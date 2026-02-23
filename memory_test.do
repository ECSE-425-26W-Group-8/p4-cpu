# 1. Clear previous simulation and suppress warnings
quit -sim
set NumericStdNoWarnings 1

# 2. Setup the work library (fixes vcom-66 error)
vlib work
vmap work work

# 3. Compile the memory and its testbench
# Note: Ensure the file paths are correct relative to this script
vcom -2008 -work work memory.vhd
vcom -2008 -work work memory_tb.vhd

# 4. Start the simulation
vsim -voptargs="+acc" work.memory_tb

# 5. Setup waves
add wave -divider "System"
add wave /memory_tb/clk
add wave /memory_tb/waitrequest
add wave -divider "Memory Signals"
add wave /memory_tb/address
add wave /memory_tb/memread
add wave /memory_tb/readdata
add wave /memory_tb/memwrite
add wave /memory_tb/writedata

# 6. Run for a specific time to avoid infinite loops
run 1000 ns
wave zoom full
