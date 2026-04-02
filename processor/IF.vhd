library ieee;
use ieee.std_logic_1164.all;

entity IF is
port(
	result_EX_IF_REGLN 		: in std_logic_vector(downto);
	branchTake_EX_IF_LN 	: in std_logic_vector(downto);
	addr_IF_ID_LNREG 		: out std_logic_vector(downto);
	inst_IF_ID_LNREG 		: out std_logic_vector(downto)
); 
end IF;

architecture Behavioral of IF is
-- signals
-- unclocked - make sure these don't become registers in implimentation

-- clocked - change value once per cc
signal pc : std_logic_vector(31 downto 0);

begin

end Behavioral;