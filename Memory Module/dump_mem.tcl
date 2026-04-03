# dump_mem.tcl
#
# Reads from an 8-bit wide ModelSim memory array and writes contents
# to a text file as 32-bit binary values per line (one instruction per line).
# Uses Little-Endian mapping to reconstruct words (Byte 0 at lowest address = LSB).
#
# Usage in ModelSim Console:
# 1. source dump_mem.tcl
# 2. dump_mem "/textio_test_tb/dut/ram_block" "output_bin.txt" <num_words> {start_addr 0}

proc dump_mem {mem_path file_path num_words {start_addr 0}} {
    if {[catch {set fp [open $file_path w]} msg]} {
        echo "Error: Could not open file $file_path for writing: $msg"
        return
    }

    set addr $start_addr
    echo "--- Dumping $num_words words from $mem_path into $file_path ---"

    for {set i 0} {$i < [expr $num_words]} {incr i} {
        # Read 4 consecutive bytes (little-endian: b0 is LSB, b3 is MSB)
        set b0 [string trim [mem display -format bin -startaddress $addr             -endaddress $addr           -noaddress $mem_path]]
        set b1 [string trim [mem display -format bin -startaddress [expr $addr+1]    -endaddress [expr $addr+1]  -noaddress $mem_path]]
        set b2 [string trim [mem display -format bin -startaddress [expr $addr+2]    -endaddress [expr $addr+2]  -noaddress $mem_path]]
        set b3 [string trim [mem display -format bin -startaddress [expr $addr+3]    -endaddress [expr $addr+3]  -noaddress $mem_path]]

        # Reconstruct 32-bit word: MSB (b3) first, matching the input file format
        puts $fp "${b3}${b2}${b1}${b0}"

        set addr [expr $addr + 4]
    }

    close $fp
    echo "--- Dumped $num_words instructions ([expr $num_words * 4] bytes) to $file_path ---"
}
