# Compile the design files (VHDL-2008 for std.env.stop)
vcom -2008 -work work cache_package.vhd
vcom -2008 -work work memory.vhd
vcom -2008 -work work cache_fsm.vhd
vcom -2008 -work work cache_fsm_tb.vhd

# Initialize simulation
vsim -voptargs="+acc" work.cache_fsm_tb

# Wave setup: System signals
add wave -divider "System"
add wave -label clk /cache_fsm_tb/clk
add wave -label reset /cache_fsm_tb/reset

# Wave setup: CPU-side interface
add wave -divider "CPU Interface"
add wave -label s_read /cache_fsm_tb/s_read
add wave -label s_write /cache_fsm_tb/s_write
add wave -label s_waitrequest /cache_fsm_tb/s_waitrequest

# Wave setup: Internal signals (FSM status and control)
add wave -divider "FSM Status/Control"
add wave -label fsm_state /cache_fsm_tb/uut/state
add wave -label internal/next_state /cache_fsm_tb/uut/next_state
add wave -label hit /cache_fsm_tb/hit
add wave -label clean_miss /cache_fsm_tb/clean_miss
add wave -label dirty_miss /cache_fsm_tb/dirty_miss
add wave -label writeback /cache_fsm_tb/writeback
add wave -label data_we /cache_fsm_tb/data_we
add wave -label set_dirty /cache_fsm_tb/set_dirty

# Wave setup: Memory-side interface (Burst control)
add wave -divider "Memory Interface (Burst)"
add wave -label m_read /cache_fsm_tb/m_read
add wave -label m_write /cache_fsm_tb/m_write
add wave -label m_waitrequest /cache_fsm_tb/m_waitrequest
add wave -radix decimal -label m_index /cache_fsm_tb/m_index

# Configure wave window
wave zoom full

# Run simulation
run -all
