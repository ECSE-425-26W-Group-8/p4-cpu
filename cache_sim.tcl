vlib work
vmap work work

# Compile the design files (VHDL-2008 for std.env.stop)
vcom -2008 -work work cache_package.vhd
vcom -2008 -work work cache_blocks.vhd
vcom -2008 -work work memory.vhd
vcom -2008 -work work cache_fsm.vhd
vcom -2008 -work work cache.vhd
vcom -2008 -work work cache_tb.vhd

# Initialize simulation
vsim -voptargs="+acc" work.cache_tb

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

# Sys signals
add wave -divider "System"
add wave -label reset /cache_tb/reset
add wave -label clk /cache_tb/clk

# Wave setup: cache interface
add wave -divider "Cache Interface"
add wave -label s_read /cache_tb/s_read
add wave -label s_readdata -radix unsigned /cache_tb/s_readdata
add wave -label s_addr -radix unsigned /cache_tb/s_addr
add wave -label s_write /cache_tb/s_write
add wave -label s_writedata -radix unsigned /cache_tb/s_writedata
add wave -label s_waitrequest /cache_tb/s_waitrequest

# Wave setup: Internal signals (FSM status and control)


# Wave setup: Memory-side interface
add wave -divider "Memory Interface"
add wave -label m_addr -radix unsigned /cache_tb/m_addr
add wave -label m_read /cache_tb/m_read
add wave -label m_readdata -radix unsigned /cache_tb/m_readdata
add wave -label m_write /cache_tb/m_write
add wave -label m_writedata -radix unsigned /cache_tb/m_writedata
add wave -label m_waitrequest /cache_tb/m_waitrequest

# Configure wave window
wave zoom full

# Run simulation
run 1 ns
set NumericStdNoWarnings 0
run 500 ns
