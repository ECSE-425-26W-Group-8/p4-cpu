library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Use the package containing block_line_t, word_t, and cache_block_t
use work.cache_package.all;

entity cache_blocks_tb is
end cache_blocks_tb;

architecture sim of cache_blocks_tb is

    -- 1. Signal Declarations
    signal clk_tb          : std_logic := '0';
    signal reset_tb        : std_logic := '0';
    signal block_index_tb  : std_logic_vector(4 downto 0) := (others => '0');
    signal new_line_tb     : block_line_t := (others => (others => '0'));
    signal new_tag_tb      : std_logic_vector(5 downto 0) := (others => '0');
    signal data_we_tb      : std_logic := '0';
    signal set_dirty_tb    : std_logic := '0';

    signal cache_block_out_tb : cache_block_t;

    -- Signal to stop simulation
    signal finished : boolean := false;

    -- Clock Period Definition
    constant CLK_PERIOD : time := 10 ns;

begin

    -- 2. Instantiate the Unit Under Test (UUT)
    dut: entity work.cache_blocks
        port map (
            clk          => clk_tb,
            reset        => reset_tb,
            block_index  => block_index_tb,
            new_line     => new_line_tb,
            new_tag      => new_tag_tb,
            data_we      => data_we_tb,
            set_dirty    => set_dirty_tb,
            cache_block  => cache_block_out_tb
        );

    -- 3. Clock Generation Process
    clk_process : process
    begin
        while not finished loop
            clk_tb <= '0';
            wait for CLK_PERIOD/2;
            clk_tb <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;

    -- 4. Stimulus Process
    stim_proc: process
        -- Reusable test case procedure
        procedure run_test_case(
            constant index    : in integer;
            constant tag      : in std_logic_vector(5 downto 0);
            constant data     : in block_line_t;
            constant dirty    : in std_logic
        ) is
        begin
            -- 1. Write to cache
            wait until rising_edge(clk_tb);
            block_index_tb <= std_logic_vector(to_unsigned(index, 5));
            new_tag_tb     <= tag;
            new_line_tb    <= data;
            data_we_tb     <= '1';
            set_dirty_tb   <= dirty;
            
            wait until rising_edge(clk_tb);
            data_we_tb     <= '0';
            set_dirty_tb   <= '0';
            
            -- 2. Verify write immediately
            wait for 5 ns; -- Settle in middle of cycle
            
            assert (cache_block_out_tb.valid = '1') 
                report "Test Failed at index " & integer'image(index) & ": Valid bit not set!" severity error;
            assert (cache_block_out_tb.dirty = dirty) 
                report "Test Failed at index " & integer'image(index) & ": Dirty bit mismatch!" severity error;
            assert (cache_block_out_tb.tag = tag) 
                report "Test Failed at index " & integer'image(index) & ": Tag mismatch!" severity error;
            
            for i in 0 to 3 loop
                assert (cache_block_out_tb.block_line(i) = data(i)) 
                    report "Test Failed at index " & integer'image(index) & ", word " & integer'image(i) & ": Incorrect word read back!" severity error;
            end loop;
            
            wait for CLK_PERIOD; -- Visual gap in waveform
        end procedure;

        procedure verify_read(
            constant index    : in integer;
            constant tag      : in std_logic_vector(5 downto 0);
            constant data     : in block_line_t;
            constant dirty    : in std_logic;
            constant valid    : in std_logic
        ) is
        begin
            block_index_tb <= std_logic_vector(to_unsigned(index, 5));
            wait for 5 ns; -- Settle in middle of cycle
            
            assert (cache_block_out_tb.valid = valid) 
                report "Read Verify Failed at index " & integer'image(index) & ": Valid bit mismatch!" severity error;
            if valid = '1' then
                assert (cache_block_out_tb.dirty = dirty) 
                    report "Read Verify Failed at index " & integer'image(index) & ": Dirty bit mismatch!" severity error;
                assert (cache_block_out_tb.tag = tag) 
                    report "Read Verify Failed at index " & integer'image(index) & ": Tag mismatch!" severity error;
                for i in 0 to 3 loop
                    assert (cache_block_out_tb.block_line(i) = data(i)) 
                        report "Read Verify Failed at index " & integer'image(index) & ", word " & integer'image(i) & ": Incorrect word!" severity error;
                end loop;
            end if;
            
            wait for CLK_PERIOD; -- Visual gap in waveform
        end procedure;

        variable test_data_1 : block_line_t := (0 => x"DEADBEEF", 1 => x"CAFEBABE", 2 => x"12345678", 3 => x"87654321");
        variable test_data_2 : block_line_t := (0 => x"AAAA0000", 1 => x"BBBB1111", 2 => x"CCCC2222", 3 => x"DDDD3333");
        variable test_data_3 : block_line_t := (0 => x"0000FFFF", 1 => x"1111EEEE", 2 => x"2222DDDD", 3 => x"3333CCCC");
    begin		
        -- Initialize / Global Reset
        wait for 1 ns; 
		reset_tb <= '1';
        wait for 1 ns; 
        reset_tb <= '0'; 
        wait until rising_edge(clk_tb); 
        
        -- 1. Basic Write/Read boundary tests
        report "Test Case 1: Write to index 0 (boundary)";
        run_test_case(0, "000001", test_data_1, '0');
        
        report "Test Case 2: Write to index 31 (boundary)";
        run_test_case(31, "111111", test_data_2, '1');

        -- 2. Index Independence Test
        report "Test Case 3: Verify independence between indices 0 and 31";
        verify_read(0, "000001", test_data_1, '0', '1');
        verify_read(31, "111111", test_data_2, '1', '1');

        -- 3. Overwrite Test
        report "Test Case 4: Overwrite index 0 with new data and tag";
        run_test_case(0, "101010", test_data_3, '1');
        verify_read(0, "101010", test_data_3, '1', '1');
        
        -- 4. No-Write Enable Test
        report "Test Case 5: Verify data_we = '0' does not modify cache";
        wait until rising_edge(clk_tb);
        block_index_tb <= std_logic_vector(to_unsigned(15, 5));
        new_tag_tb     <= "111000";
        new_line_tb    <= test_data_1;
        data_we_tb     <= '0';
        set_dirty_tb   <= '1';
        wait until rising_edge(clk_tb);
        verify_read(15, "000000", (others => (others => '0')), '0', '0'); -- Should still be empty

        -- 5. Reset logic
        report "Test Case 6: Verifying reset logic clears all entries...";
        reset_tb <= '1';
        wait until rising_edge(clk_tb);
        reset_tb <= '0';
        wait for 1 ns;
        verify_read(0, "000000", (others => (others => '0')), '0', '0');
        verify_read(31, "000000", (others => (others => '0')), '0', '0');

        -- End simulation
        report "Cache blocks testbench finished successfully.";
        finished <= true;
        wait;
    end process;

end sim;
