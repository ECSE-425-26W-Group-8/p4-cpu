# Compile the design files (VHDL-2008 for std.env.stop)
vcom -2008 -work work cache_package.vhd
vcom -2008 -work work memory.vhd
vcom -2008 -work work cache_fsm.vhd
vcom -2008 -work work cache.vhd
vcom -2008 -work work cache_tb.vhd

# Initialize simulation
vsim -voptargs="+acc" work.cache_tb

# Sys signals
add wave -divider "System"
add wave -label reset /cache_fsm_tb/reset
add wave -label clk /cache_fsm_tb/clk

# Wave setup: cache interface
add wave -divider "Cache Interface"
add wave -label s_read /cache_tb/s_read
add wave -label s_readdata /cache_tb/s_readdata
add wave -label s_addr /cache_tb/s_addr
add wave -label s_write /cache_tb/s_write
add wave -label s_writedata /cache_tb/s_writedata
add wave -label s_waitrequest /cache_tb/s_waitrequest

# Wave setup: Internal signals (FSM status and control)


# Wave setup: Memory-side interface
add wave -divider "Memory Interface"
add wave -label m_addr /cache_tb/m_addr
add wave -label m_read /cache_tb/m_read
add wave -label m_readdata /cache_tb/m_readdata
add wave -label m_write /cache_tb/m_write
add wave -label m_writedata /cache_tb/m_writedata
add wave -label m_waitrequest /cache_tb/m_waitrequest

# Configure wave window
wave zoom full

# Run simulation
run -all
