################################################################################
#
# Author:      Derrick
# Date:        04/06/2026
# Description: Allows to dump the entire content of a memory byte addresseable 
#               memory block into a text file in in chuncks of 32 bit words per lines
#
# Arguments:
# * mem_path    - path to an initialized memory component in the modeslim simulation.
# * file_path   - path to text file in which to dump the memory content
# * num_words   - number of 32 bit words to dump
# * start_addr  - DEFAULT:0 start address from which to dump memory
#
################################################################################

proc dump_mem {mem_path file_path num_words {start_addr 0}} {
    if {[catch {set fp [open $file_path w]} msg]} {
        echo "Error: Could not open file $file_path for writing: $msg"
        return
    }

    set addr $start_addr
    echo "--- Dumping $num_words words from $mem_path into $file_path ---"

    for {set i 0} {$i < [expr $num_words]} {incr i} {
        set b0 [string trim [mem display -format bin -startaddress $addr             -endaddress $addr           -noaddress $mem_path]]
        set b1 [string trim [mem display -format bin -startaddress [expr $addr+1]    -endaddress [expr $addr+1]  -noaddress $mem_path]]
        set b2 [string trim [mem display -format bin -startaddress [expr $addr+2]    -endaddress [expr $addr+2]  -noaddress $mem_path]]
        set b3 [string trim [mem display -format bin -startaddress [expr $addr+3]    -endaddress [expr $addr+3]  -noaddress $mem_path]]

        # reconstruct with lsb b0 to the left to ensure the 32 bit word is little endian
        puts $fp "${b3}${b2}${b1}${b0}"

        set addr [expr $addr + 4]
    }

    close $fp
    echo "--- Dumped $num_words instructions ([expr $num_words * 4] bytes) to $file_path ---"
}
