# Create the library
vlib work

# Compile the files in the correct dependency order
vcom cache_package.vhd
vcom cache_blocks.vhd
vcom cache_blocks_tb.vhd

# Start the simulation
vsim cache_blocks_tb

# Add signals to the wave window
add wave -divider "Stimulus Inputs"
add wave -hex /clk_tb
add wave -hex /reset_tb
add wave -hex /block_index_tb
add wave -hex /data_we_tb
add wave -hex /set_dirty_tb
add wave -hex /new_tag_tb
add wave -hex /new_line_tb

add wave -divider "Record Output Fields"
# Use dot notation for record fields in ModelSim
add wave -hex /cache_block_out_tb
# Internal State
add wave -divider "Internal State"
add wave -hex /dut/int_index

# Run the simulation
run -all
