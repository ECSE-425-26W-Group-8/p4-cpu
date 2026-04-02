library ieee;
use ieee.std_logic_1164.all;

entity ID is
port(
	addr_IF_ID_REGLN 	: in std_logic_vector(downto);
	inst_IF_ID_REGLN 	: in std_logic_vector(downto);
	addr_ID_EX_LNREG 	: out std_logic_vector(downto);
	op1_ID_EX_LNREG		: out std_logic_vector(downto);
	op2_ID_EX_LNREG 	: out std_logic_vector(downto);
	imm_ID_EX_LNREG 	: out std_logic_vector(downto);
	inst_ID_EX_LNREG 	: out std_logic_vector(downto);
	inst_MEM_ID_REGLN	: out std_logic_vector(downto);
	data_WB_ID_LN		: out std_logic_vector(downto)
); 
end ID;

architecture Behavioral of ID is
begin

end Behavioral;