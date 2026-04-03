library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

package cache_package is
	
	subtype word_t is std_logic_vector(31 downto 0);
	
	type block_line_t is array (3 downto 0) of word_t;
	
	type cache_block_t is record
		valid 	: std_logic;
		dirty 	: std_logic;
		tag 	: std_logic_vector(5 downto 0);
		block_line : block_line_t;
		
	end record;

	constant empty_block : cache_block_t := (
		valid => '0',
		dirty => '0',
		tag => (others => '0'),
		block_line => (others => ( others => '0'))
	);
	
end cache_package;
