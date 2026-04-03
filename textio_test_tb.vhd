library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all; -- Required for hwrite and reading binary strings

entity textio_test_tb is
end entity textio_test_tb;

architecture sim of textio_test_tb is
    -- Component Declaration
    component memory is
        generic(
            ram_size : INTEGER := 32768;
            mem_delay : time := 10 ns;
            clock_period : time := 1 ns
        );
        port (
            clock: IN STD_LOGIC;
            writedata: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
            address: IN INTEGER RANGE 0 TO ram_size-1;
            memwrite: IN STD_LOGIC;
            memread: IN STD_LOGIC;
            readdata: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
            waitrequest: OUT STD_LOGIC
        );
    end component;

    -- Signals
    signal clk : std_logic := '0';
    signal writedata : std_logic_vector(7 downto 0) := (others => '0');
    signal address : integer := 0;
    signal memwrite : std_logic := '0';
    signal memread : std_logic := '0';
    signal readdata : std_logic_vector(7 downto 0);
    signal waitrequest : std_logic;
    
    constant clk_period : time := 1 ns;

begin

    -- Clock Generation
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Instantiate Memory
    dut: memory
        generic map (ram_size => 32768)
        port map (
            clock => clk,
            writedata => writedata,
            address => address,
            memwrite => memwrite,
            memread => memread,
            readdata => readdata,
            waitrequest => waitrequest
        );

    -- Verification Process
    process
    begin
        -- Wait for user to perform the load (we wait for some simulation time)
        wait for 10 ns;
        
        report "--- VERIFYING FIRST INSTRUCTION (00500513) ---";
        
        -- Read Byte 0 (Expected 0x13)
        address <= 0; memread <= '1';
        wait until rising_edge(waitrequest);
        assert readdata = x"13" report "Byte 0 mismatch! Expected 13, got " & to_hstring(readdata) severity error;
        wait until falling_edge(waitrequest);
        memread <= '0';
        wait for clk_period;

        -- Read Byte 1 (Expected 0x05)
        address <= 1; memread <= '1';
        wait until rising_edge(waitrequest);
        assert readdata = x"05" report "Byte 1 mismatch! Expected 05, got " & to_hstring(readdata) severity error;
        wait until falling_edge(waitrequest);
        memread <= '0';
        wait for clk_period;

        -- Read Byte 2 (Expected 0x50)
        address <= 2; memread <= '1';
        wait until rising_edge(waitrequest);
        assert readdata = x"50" report "Byte 2 mismatch! Expected 50, got " & to_hstring(readdata) severity error;
        wait until falling_edge(waitrequest);
        memread <= '0';
        wait for clk_period;

        -- Read Byte 3 (Expected 0x00)
        address <= 3; memread <= '1';
        wait until rising_edge(waitrequest);
        assert readdata = x"00" report "Byte 3 mismatch! Expected 00, got " & to_hstring(readdata) severity error;
        wait until falling_edge(waitrequest);
        memread <= '0';

        report "--- MEMORY VERIFICATION FINISHED ---";
        wait;
    end process;

end architecture sim;
