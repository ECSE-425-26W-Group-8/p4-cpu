# Memory Initialization Guide (ModelSim)

This guide explains how to use the `load_mem.tcl` script to initialize the 8-bit wide memory with 32-bit instructions from your compiler output.

## Prerequisites
- **Input File:** A `.txt` file containing 32-bit values (e.g., `factorial_bin.txt`).
- **Memory Structure:** An 8-bit wide `std_logic_vector` array in VHDL (e.g., `ram_block`).

## Integration Steps

### 1. Identify the Memory Path
In ModelSim, you need the hierarchical path to your memory signal. 
- If using `memory_tb.vhd`, the path is likely: `/memory_tb/dut/ram_block`

### 2. Loading the Script
In the ModelSim command console, navigate to the directory containing the script and run:
```tcl
source load_mem.tcl
```

### 3. Executing the Load
Run the `load_riscv_hex` function with the file path and the memory path:
```tcl
load_riscvx_bin "factorial_bin.txt" "/memory_tb/dut/ram_block"
```

## Important Considerations

### Little-Endian Format
The script automatically maps the 32-bit hex values into 8-bit slots using **Little-Endian** (LSB at the lowest address), which is the standard for RISC-V.

Example: `00500513`
- Address `n+0`: `13`
- Address `n+1`: `05`
- Address `n+2`: `50`
- Address `n+3`: `00`
