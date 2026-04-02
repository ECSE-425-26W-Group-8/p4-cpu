library ieee;
use ieee.std_logic_1164.all;

entity MEM is
port(
	result_EX_MEM_REGLN : in std_logic_vector(downto);
	op2Addr_EX_MEM_REGLN : in std_logic_vector(downto);
	inst_EX_MEM_REGLN : in std_logic_vector(downto);
	data_MEM_WB_LNREG : out std_logic_vector(downto);
	result_MEM_WB_LNREG : out std_logic_vector(downto);
	inst_MEM_WB_LNREG : out std_logic_vector(downto);
	result_EX_IF_LN : out std_logic_vector(downto)
); 
end MEM;

architecture Behavioral of MEM is
begin

end Behavioral;