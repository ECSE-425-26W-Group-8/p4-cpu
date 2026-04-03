# load_mem.tcl
# 
# This script loads a 32-bit Hex instruction file into an 8-bit wide 
# ModelSim memory array using Little-Endian mapping (Byte 0 at lowest address).
#
# Usage in ModelSim Console:
# 1. source load_mem.tcl
# 2. load_riscv_hex "factorial_hex.txt" "/cache_tb/MEM/ram_block"



proc load_riscv_bin {file_path mem_path {start_addr 0}} {
    if {[catch {set fp [open $file_path r]} msg]} {
        echo "Error: Could not open file $file_path: $msg"
        return
    }
    
    set addr $start_addr
    set count 0
    
    echo "--- Loading $file_path into $mem_path starting at address $addr ---"

    while {[gets $fp line] >= 0} {
        set b0 [string range $line 24 31]
        set b1 [string range $line 16 23]
        set b2 [string range $line 8 15]
        set b3 [string range $line 0 7]

        echo loading addresses $addr to [expr $addr+4]...

        mem load -filldata $b0 -format bin $mem_path -startaddress $addr -endaddress $addr
        mem load -filldata $b1 -format bin $mem_path -startaddress [expr $addr+1] -endaddress [expr $addr+1]
        mem load -filldata $b2 -format bin $mem_path -startaddress [expr $addr+2] -endaddress [expr $addr+2]
        mem load -filldata $b3 -format bin $mem_path -startaddress [expr $addr+3] -endaddress [expr $addr+3]
        
        set addr [expr $addr+4]
        incr count
    }
    
    close $fp
    echo "--- Loaded $count instructions (total [expr $count * 4] bytes) ---"
}
