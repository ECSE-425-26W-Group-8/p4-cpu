library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Use the package containing block_line_t, word_t, and cache_block_t
use work.cache_package.all;

entity cache_blocks_tb is
end cache_blocks_tb;

architecture sim of cache_blocks_tb is

    -- 1. Component Declaration for the Unit Under Test (UUT)
    component cache_blocks
        port (
            clk          : IN  std_logic;
            reset        : IN  std_logic;
            block_index  : IN  std_logic_vector(4 downto 0);
            word_offset  : IN  std_logic_vector(1 downto 0);
            new_line     : IN  block_line_t;
            new_tag      : IN  std_logic_vector(5 downto 0);
            data_we      : IN  std_logic;
            dirty_we     : IN  std_logic;
            valid        : OUT std_logic;
            dirty        : OUT std_logic;
            tag          : OUT std_logic_vector(5 downto 0);
            word         : OUT word_t
        );
    end component;

    -- 2. Signal Declarations
    signal clk_tb          : std_logic := '0';
    signal reset_tb        : std_logic := '0';
    signal block_index_tb  : std_logic_vector(4 downto 0) := (others => '0');
    signal word_offset_tb  : std_logic_vector(1 downto 0) := (others => '0');
    signal new_line_tb     : block_line_t := (others => (others => '0'));
    signal new_tag_tb      : std_logic_vector(5 downto 0) := (others => '0');
    signal data_we_tb      : std_logic := '0';
    signal dirty_we_tb     : std_logic := '0';

    signal valid_tb        : std_logic;
    signal dirty_tb        : std_logic;
    signal tag_tb          : std_logic_vector(5 downto 0);
    signal word_tb         : word_t;

    -- Clock Period Definition (e.g., 100MHz)
    constant CLK_PERIOD : time := 10 ns;


begin

    -- 3. Instantiate the Unit Under Test (UUT)
    dut: cache_blocks
        port map (
            clk          => clk_tb,
            reset        => reset_tb,
            block_index  => block_index_tb,
            word_offset  => word_offset_tb,
            new_line     => new_line_tb,
            new_tag      => new_tag_tb,
            data_we      => data_we_tb,
            dirty_we     => dirty_we_tb,
            valid        => valid_tb,
            dirty        => dirty_tb,
            tag          => tag_tb,
            word         => word_tb
        );

    -- 4. Clock Generation Process
    clk_process : process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD/2;
        clk_tb <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- 5. Stimulus Process
    stim_proc: process
		procedure write_cache_line(
			constant index    : in integer;
			constant tag      : in std_logic_vector(5 downto 0);
			constant data     : in block_line_t;
			constant dirty    : in std_logic
		) is
		begin
			wait until rising_edge(clk_tb);
			block_index_tb <= std_logic_vector(to_unsigned(index, 5));
			new_tag_tb   <= tag;
			new_line_tb  <= data;
			data_we_tb      <= '1';
			dirty_we_tb  <= dirty;
			
			wait until rising_edge(clk_tb);
			data_we_tb      <= '0';
			dirty_we_tb  <= '0';
		end procedure;
		
		variable test_data : block_line_t := (
            0 => x"DEADBEEF", 
            1 => x"CAFEBABE", 
            2 => x"12345678", 
            3 => x"87654321"
        );
    begin		
        -- Initialize / Global Reset
        reset_tb <= '1';
        wait for 2 ns; 
        reset_tb <= '0'; 
        wait until rising_edge(clk_tb); 
        
		write_cache_line(
            index     => 5, 
            tag       => "101010", 
            data      => test_data, 
            dirty     => '1'
        );
		
		block_index_tb <= std_logic_vector(to_unsigned(5, 5));
        word_offset_tb <= "01"; -- Word 1
        wait for 1 ns; -- Small delay to let combinational signals settle 
        
        assert (word_tb = x"CAFEBABE") 
            report "Test Failed: Incorrect word read back!" severity error;
        assert (valid_tb = '1') 
            report "Test Failed: Valid bit not set!" severity error;
		
		word_offset_tb <= "00"; -- Word 1
        wait for 5 ns; -- Small delay to let combinational signals settle 
		assert (word_tb = x"DEADBEEF") 
            report "Test Failed: Incorrect word read back!" severity error;
		
		word_offset_tb <= "10"; -- Word 1
        wait for 5 ns; -- Small delay to let combinational signals settle 
		assert (word_tb = x"12345678") 
            report "Test Failed: Incorrect word read back!" severity error;
			
		word_offset_tb <= "11"; -- Word 1
        wait for 5 ns; -- Small delay to let combinational signals settle 
		assert (word_tb = x"87654321") 
            report "Test Failed: Incorrect word read back!" severity error;
        -- TODO: Add test cases here
        -- 1. Write a block
        -- 2. Read back different words in the block
        -- 3. Check for Tag match

        -- End simulation
        report "Cache initialization testbench finished.";
        wait;
    end process;

end sim;