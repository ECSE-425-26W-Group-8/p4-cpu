import sys
from convert import AssemblyConverter as AC

def main():
    # Check if the user provided at least the input file
    if len(sys.argv) < 2:
        print("Usage: python script_name.py <input_file> [output_file]")
        sys.exit(1)

    # First argument is the input file
    input_file = sys.argv[1]
    
    # Second argument is output file; defaults to 'output_bin.txt' if not provided
    output_file = sys.argv[2] if len(sys.argv) > 2 else "program.txt"

    # instantiate object
    # nibble mode means each 32 bit instruction will be divided into groups of 4 bits separated by space in output txt
    convert = AC(output_mode='f', nibble_mode=False, hex_mode=False)

    # Convert the file
    try:
        convert(input_file, output_file)
        print(f"Successfully converted '{input_file}' to '{output_file}'")
    except Exception as e:
        print(f"Error during conversion: {e}")

if __name__ == "__main__":
    main()
