# Create work library
vlib work
vmap work work

# Compile design and testbench
vcom -reportprogress 300 EX.vhd
vcom -reportprogress 300 EX_tb.vhd

# Load simulation
vsim -default_radix hex work.EX_tb

# Add signals to waveform
add wave -divider "Inputs"
add wave /EX_tb/s_op1
add wave /EX_tb/s_op2
add wave /EX_tb/s_imm
add wave /EX_tb/s_alu_op
add wave -divider "Outputs"
add wave /EX_tb/r_result
add wave /EX_tb/r_branch_tk

# Run simulation
run 100 ns
