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
	word_offset : IN std_logic_vector(1 downto 0);
	
	-- write inputs
	new_line	: IN block_line_t;
	new_tag		: IN std_logic_vector(5 downto 0);
	data_we		: IN std_logic;
	dirty_we	: IN std_logic;

	--outputs
	valid	: OUT std_logic;
	dirty 	: OUT std_logic;
	tag		: OUT std_logic_vector(5 downto 0);
	word	: OUT word_t
  );
end cache_blocks;

architecture behavioral of cache_blocks is

-- declarations
	type cache_array_t is array (0 to 31) of cache_block_t;
	
	signal cache_array : cache_array_t := (others => empty_block);
	
	signal int_index : integer range 0 to 31 := 0;
	signal int_offset : integer range 0 to 3 := 0;
begin
-- definition
	int_index <= to_integer(unsigned(block_index));
	int_offset <= to_integer(unsigned(word_offset));
	
	valid <= cache_array(int_index).valid;
	dirty <= cache_array(int_index).dirty;
	tag <= cache_array(int_index).tag;
	word <= cache_array(int_index).block_line(int_offset);

	write_process: process(clk, reset)
	begin
		if reset = '1' then
			cache_array <= (others => empty_block);
		elsif rising_edge(clk) then
			if data_we = '1' then
				cache_array(int_index) <= (
					valid => '1',
					dirty => dirty_we,
					tag => new_tag,
					block_line => new_line
				);
			end if;
		end if;
	end process;
end behavioral;