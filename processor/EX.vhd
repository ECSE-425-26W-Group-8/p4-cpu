library ieee;
use ieee.std_logic_1164.all;

entity EX is
port(
	addr_ID_EX_REGLN 		: in std_logic_vector(downto);
	op1_ID_EX_REGLN 		: in std_logic_vector(downto);
	op2_ID_EX_REGLN 		: in std_logic_vector(downto);
	imm_ID_EX_REGLN 		: in std_logic_vector(downto);
	inst_ID_EX_REGLN 		: in std_logic_vector(downto);
	branctTake_EX_IF_LNREG 	: out std_logic_vector(downto);
	result_EX_MEM_LNREG 	: out std_logic_vector(downto);
	op2Addr_EX_MEM_LNREG 	: out std_logic_vector(downto);
	inst_EX_MEM_LNREG 		: out std_logic_vector(downto)
); 
end EX;

architecture Behavioral of EX is
begin

end Behavioral;