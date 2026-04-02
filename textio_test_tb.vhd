library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all; -- Required for hwrite and reading binary strings

entity textio_test_tb is
end entity textio_test_tb;

architecture sim of textio_test_tb is
begin

    process
        file input_file  : text open read_mode is "factorial_bin.txt";
        file output_file : text open write_mode is "factorial_hex.txt";
        variable l_in     : line;
        variable l_out    : line;
        variable bin_val  : std_logic_vector(31 downto 0);
    begin
        report "--- Starting TextIO Test ---" severity note;

        while not endfile(input_file) loop
            readline(input_file, l_in);
            
            -- Skip empty lines or comments if any (simple check for content)
            if l_in'length > 0 then
                -- Read the binary string into a std_logic_vector
                read(l_in, bin_val);

                -- Report the value in Hex to the console
                -- Note: to_hstring requires VHDL-2008
                report "Binary: " & to_string(bin_val) & " | Hex: " & to_hstring(bin_val);

                -- Write the hex value to the output file
                hwrite(l_out, bin_val);
                writeline(output_file, l_out);
            end if;
        end loop;

        report "--- TextIO Test Finished. Check factorial_hex.txt for results. ---" severity note;

        file_close(input_file);
        file_close(output_file);
        
        wait; -- End simulation
    end process;

end architecture sim;
