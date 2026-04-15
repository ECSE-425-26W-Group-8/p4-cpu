################################################################################
#
# Author:      Derrick Essou
# Date:        04/06/2026
# Description: Script to clear a memory during a modelsim simulation
#
# Arguments:
# * mem_path    - path to an initialized memory component in the modeslim simulation.
#
################################################################################
proc clear_mem {mem_path} {
    # filldata with no parameter clears the entire memory
    mem load -filltype value -filldata 0 -format bin $mem_path
    echo "--- memory cleared ---"
}
