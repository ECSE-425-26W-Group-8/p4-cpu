-- =============================================================================
-- Group 8: RISC-V Processor Testbench
-- ECSE 425 W26
--
-- Instantiates the processor, drives a 1 GHz clock, and runs for 10,000 cycles.
-- Memory initialisation and result dumping are handled by testbench.tcl.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity testbench is
end testbench;

architecture Behavioral of testbench is

    component processor is
    port(
        clk   : in std_logic;
        reset : in std_logic
    );
    end component;

    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';

begin

    uut : processor port map(
        clk   => clk,
        reset => reset
    );

    -- 1 GHz clock: period = 1 ns
    clk <= not clk after 0.5 ns;

    stim : process
    begin
        -- Hold reset for 5 clock cycles
        wait for 5 ns;
        reset <= '0';
        -- Run for 10,000 clock cycles
        wait for 10000 ns;
        wait;
    end process;

end Behavioral;
