################################################################################
# Group 8: RISC-V Processor Testbench Script
# ECSE 425 W26
#
# Usage (from ModelSim, with working directory set to processor/):
#   do testbench.tcl
#
# What this script does:
#   1. Compiles all VHDL sources.
#   2. Loads the simulation.
#   3. Clears instruction memory and loads program.txt.
#   4. Runs 10,000 clock cycles.
#   5. Dumps data memory to memory.txt (8192 32-bit words).
#   6. Dumps the register file to register_file.txt (32 registers).
################################################################################

set MEM_DIR   "memory_module"
set PROC_DIR  "processor"
set TB_ENTITY "testbench"

set UUT "/$TB_ENTITY/uut"

set IMEM "$UUT/if_stage/instruction_mem/ram_block"
set DMEM "$UUT/mem_stage/data_mem/ram_block"
set REGFILE "$UUT/id_stage/regs"

# ── 0. Source helper TCL procedures ──────────────────────────────────────────
source ./memory_module/clear_mem.tcl
source ./memory_module/load_mem.tcl
source ./memory_module/dump_mem.tcl

# ── 1. Compile all VHDL files ────────────────────────────────────────────────
vlib work

vcom -2008 $MEM_DIR/memory.vhd
vcom -2008 "$PROC_DIR/InstructionFetch.vhd"
vcom -2008 "$PROC_DIR/ID.vhd"
vcom -2008 "$PROC_DIR/EX.vhd"
vcom -2008 "$PROC_DIR/MEM.vhd"
vcom -2008 "$PROC_DIR/WB.vhd"
vcom -2008 "$PROC_DIR/hazard_detection.vhd"
vcom -2008 "$PROC_DIR/processor.vhd"
vcom -2008 "$PROC_DIR/testbench.vhd"

# ── 2. Load simulation ────────────────────────────────────────────────────────
vsim -voptargs="+acc" $TB_ENTITY

# ── 3. Wave window setup ──────────────────────────────────────────────────────


add wave -divider "Test Bench"
add wave -label "clk" -noupdate /$TB_ENTITY/clk
add wave -label "reset" -noupdate /$TB_ENTITY/reset

add wave -divider "Processor level"
add wave -label "stall" -noupdate /$UUT/stall
add wave -label "PC in ID" -noupdate -radix hex /$UUT/idin_pc
add wave -label "NPC in ID" -noupdate -radix hex /$UUT/idin_npc
add wave -label "IR in ID" -noupdate -radix hex /$UUT/idin_inst

add wave -divider "Instruction Fetch"
add wave -label     "PC"    -noupdate   -radix hex  $UUT/if_stage/pc
add wave -label     "NPC"    -noupdate  -radix hex  $UUT/if_stage/next_PC
add wave -label     "s_instruction"    -noupdate  -radix hex  $UUT/if_stage/s_instruction

add wave -divider "IF/ID REG"
add wave -label     "PC"    -noupdate   -radix hex  $UUT/ifid_pc
add wave -label     "NPC"    -noupdate  -radix hex  $UUT/ifid_npc
add wave -label     "IR"    -noupdate  -radix hex  $UUT/ifid_inst

add wave -divider "Instruction Decode"
add wave -label   "opcode"    -noupdate  -radix bin  $UUT/id_stage/opcode
add wave -label   "jump"    -noupdate  -radix hex  $UUT/id_stage/jump
add wave -label     "rs1"    -noupdate  -radix unsigned  $UUT/id_stage/rs1
add wave -label     "rs2"    -noupdate  -radix unsigned  $UUT/id_stage/rs2

add wave -divider "ID/EX REG"
add wave -label     "PC"    -noupdate   -radix hex  $UUT/idex_pc
add wave -label     "NPC"    -noupdate  -radix hex  $UUT/idex_npc
add wave -label     "IR"    -noupdate  -radix hex  $UUT/idex_inst
add wave -label     "op1"    -noupdate  -radix hex  $UUT/idex_op1
add wave -label     "op2"    -noupdate  -radix hex  $UUT/idex_op2
add wave -label     "Immediate Value"    -noupdate  -radix dec  $UUT/idex_imm
add wave -label     "ALU source"    -noupdate  -radix bin  $UUT/idex_alu_src
add wave -label     "ALU Operation"    -noupdate  -radix bin  $UUT/idex_alu_op
add wave -label     "memory read"    -noupdate  -radix bin  $UUT/idex_mem_read
add wave -label     "memory write"    -noupdate  -radix bin  $UUT/idex_mem_write
add wave -label     "is branch"    -noupdate  -radix bin  $UUT/idex_branch
add wave -label     "is jump"    -noupdate  -radix bin  $UUT/idex_jump

add wave -divider "Execute"
add wave -label     "branch code" -noupdate -radix bin $UUT/ex_stage/branchCode

add wave -divider "EX/MEM REG"
add wave -label     "PC"    -noupdate   -radix hex  $UUT/exmem_pc
add wave -label     "NPC"    -noupdate  -radix hex  $UUT/exmem_npc
add wave -label     "IR"    -noupdate  -radix hex  $UUT/exmem_inst
add wave -label     "result"    -noupdate  -radix hex  $UUT/exmem_result
add wave -label     "op2"    -noupdate  -radix hex  $UUT/exmem_op2
add wave -label     "memory read"    -noupdate  -radix bin  $UUT/exmem_mem_read
add wave -label     "memory write"    -noupdate  -radix bin  $UUT/exmem_mem_write
add wave -label     "branch taken"    -noupdate  -radix hex  $UUT/exmem_branch_taken
add wave -label     "is jump"    -noupdate  -radix bin  $UUT/exmem_jump


add wave -divider "Memory"

add wave -divider "MEM/WB REG"
add wave -label     "PC"    -noupdate   -radix hex  $UUT/memwb_pc
add wave -label     "NPC"    -noupdate  -radix hex  $UUT/memwb_npc
add wave -label     "IR"    -noupdate  -radix hex  $UUT/memwb_inst
add wave -label     "Memory Data"    -noupdate  -radix hex  $UUT/memwb_data
add wave -label     "ALU result"    -noupdate  -radix hex  $UUT/memwb_result
add wave -label     "reg writeback"    -noupdate  -radix bin  $UUT/memwb_reg_write
add wave -label     "write back select"    -noupdate  -radix bin  $UUT/memwb_wb_sel

add wave -divider "Write Back"
add wave -divider "Hazard Detection"

# ── 4. Define run_simulation procedure ───────────────────────────────────────
# Usage: run_simulation
# Restarts the simulation, reloads program.txt into instruction memory, and runs.
# Can be called repeatedly after sourcing this script.

proc run_simulation {} {
    global UUT IMEM DMEM REGFILE

    restart -f
    clear_mem $DMEM
    clear_mem $IMEM
    load_riscv_bin program.txt $IMEM

    run 10005 ns

    dump_mem $DMEM memory.txt 8192

    set fp [open register_file.txt w]
    for {set i 0} {$i < 32} {incr i} {
        set val [string trim [mem display -format bin \
                              -startaddress $i -endaddress $i \
                              -noaddress $REGFILE]]
        puts $fp $val
    }
    close $fp

    echo "--- Simulation complete ---"
}

# ── 5. Initial simulation run ────────────────────────────────────────────────
run_simulation
