# Memory Initialization Guide (ModelSim)

This guide explains how to use the `load_mem.tcl` script to initialize the 8-bit wide memory with 32-bit instructions from your compiler output.

## Prerequisites
- **Input File:** A `.txt` file containing 32-bit Hex values (e.g., `factorial_hex.txt`).
- **Memory Structure:** An 8-bit wide `std_logic_vector` array in VHDL (e.g., `ram_block`).

## Integration Steps

### 1. Identify the Memory Path
In ModelSim, you need the hierarchical path to your memory signal. 
- If using `cache_tb.vhd`, the path is likely: `/cache_tb/MEM/ram_block`
- If using `memory_tb.vhd`, the path is likely: `/memory_tb/dut/ram_block`

### 2. Loading the Script
In the ModelSim command console, navigate to the directory containing the script and run:
```tcl
source load_mem.tcl
```

### 3. Executing the Load
Run the `load_riscv_hex` function with the file path and the memory path:
```tcl
load_riscv_hex "factorial_hex.txt" "/cache_tb/MEM/ram_block"
```

## Important Considerations

### Simulation Time & Overwriting
The current `memory.vhd` has an initialization block that runs at `now < 1 ps`. 
```vhdl
IF(now < 1 ps) THEN
    For i in 0 to ram_size-1 LOOP
        ram_block(i) <= std_logic_vector(to_unsigned(i,8));
    END LOOP;
END IF;
```
**Recommendation:** 
1. Run the simulation for at least 1ps first: `run 1ps`
2. Then execute the `load_riscv_hex` command.
3. This ensures the TCL script overwrites the hardcoded initialization values.

### Little-Endian Format
The script automatically maps the 32-bit hex values into 8-bit slots using **Little-Endian** (LSB at the lowest address), which is the standard for RISC-V.

Example: `00500513`
- Address `n+0`: `13`
- Address `n+1`: `05`
- Address `n+2`: `50`
- Address `n+3`: `00`
