# load_mem.tcl
# 
# This script loads a 32-bit Hex instruction file into an 8-bit wide 
# ModelSim memory array using Little-Endian mapping (Byte 0 at lowest address).
#
# Usage in ModelSim Console:
# 1. source load_mem.tcl
# 2. load_riscv_hex "factorial_hex.txt" "/cache_tb/MEM/ram_block"

proc load_riscv_hex {file_path mem_path {start_addr 0}} {
    if {[catch {set fp [open $file_path r]} msg]} {
        echo "Error: Could not open file $file_path: $msg"
        return
    }
    
    set addr $start_addr
    set count 0
    
    echo "--- Loading $file_path into $mem_path starting at address $addr ---"

    while {[gets $fp line] >= 0} {
        # Clean the line (remove whitespace/newlines)
        set line [string trim $line]
        
        # Skip empty lines or comments
        if {$line == "" || [string match "#*" $line]} { continue }
        
        # Ensure we have a valid 8-character hex string (32 bits)
        if {[string length $line] == 8} {
            # RISC-V Little Endian Mapping:
            # Hex String: [Byte3][Byte2][Byte1][Byte0] (e.g., 00500513)
            # Memory: 
            #   addr+0: Byte0 (13)
            #   addr+1: Byte1 (05)
            #   addr+2: Byte2 (50)
            #   addr+3: Byte3 (00)
            
            set b0 [string range $line 6 7]
            set b1 [string range $line 4 5]
            set b2 [string range $line 2 3]
            set b3 [string range $line 0 1]
            
            # Apply 'change' command to the simulation memory signal
            # Note: we use 'hex' radix for the value
            # ModelSim 'change' command syntax: change <signal> <value>
            # However, for array elements, 'mem set' is often more robust.
            
            mem set -address $addr          -value $b0 -format hex $mem_path
            mem set -address [expr $addr+1] -value $b1 -format hex $mem_path
            mem set -address [expr $addr+2] -value $b2 -format hex $mem_path
            mem set -address [expr $addr+3] -value $b3 -format hex $mem_path
            
            set addr [expr $addr + 4]
            incr count
        } else {
            echo "Warning: Skipping line '$line' (incorrect length for 32-bit Hex)"
        }
    }
    
    close $fp
    echo "--- Successfully loaded $count instructions (total [expr $count * 4] bytes) ---"
}
