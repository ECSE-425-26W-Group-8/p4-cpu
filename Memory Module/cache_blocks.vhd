library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cache_package.all;

entity cache_blocks is
port (
	
	clk: IN std_logic;
	reset: IN std_logic;
	-- indexing inputs
	block_index : IN std_logic_vector(4 downto 0);
	
	-- write inputs
	new_line	: IN block_line_t;
	new_tag		: IN std_logic_vector(5 downto 0);
	data_we		: IN std_logic;
	set_dirty	: IN std_logic;

	--outputs
	cache_block	: OUT cache_block_t
  );
end cache_blocks;

architecture behavioral of cache_blocks is

-- declarations
	type cache_array_t is array (0 to 31) of cache_block_t;
	
	signal cache_array : cache_array_t := (others => empty_block);
	
	signal int_index : integer range 0 to 31 := 0;
begin
-- definition
	int_index <= to_integer(unsigned(block_index));
	
	cache_block <= cache_array(int_index);

	write_process: process(clk, reset)
	begin
		if reset = '1' then
			cache_array <= (others => empty_block);
		elsif rising_edge(clk) then
			if data_we = '1' then
				cache_array(int_index) <= (
					valid => '1',
					dirty => set_dirty,
					tag => new_tag,
					block_line => new_line
				);
			end if;
		end if;
	end process;
end behavioral;