library ieee;
use ieee.std_logic_1164.all;

entity WB is
port(
	data_MEM_WB_REGLN 	: in std_logic_vector(downto);
	result_MEM_WB_REGLN : in std_logic_vector(downto);
	data_WB_ID_LN 		: out std_logic_vector(downto)
); 
end WB;

architecture Behavioral of WB is
begin

end Behavioral;