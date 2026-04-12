library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity EX is
port(
	addr_ID_EX_REGLN 		: in std_logic_vector(31 downto 0);
	op1_ID_EX_REGLN 		: in std_logic_vector(31 downto 0);
	op2_ID_EX_REGLN 		: in std_logic_vector(31 downto 0);
	imm_ID_EX_REGLN 		: in std_logic_vector(31 downto 0);
	inst_ID_EX_REGLN 		: in std_logic_vector(31 downto 0);	-- Holds the instruction - use for control
	
	alu_src		: in std_logic; 	-- 1 for imm, 0 for registers
	alu_op 		: in std_logic_vector(3 downto 0); -- ALU operations
	branch		: in std_logic; -- control flow
	jump		: in std_logic; -- control flow
	
/* I don't need these, should I still have them or does that just lead to clutter?
	mem_read	: out std_logic; -- mem access
	mem_write	: out std_logic; -- mem access
	reg_write	: out std_logic; -- write to reg
	wb_sel		: out std_logic_vector(1 downto 0) --what to write back
*/
	
	branctTake_EX_IF_LNREG 	: out std_logic_vector(31 downto 0);
	result_EX_MEM_LNREG 	: out std_logic_vector(31 downto 0);
	op2Addr_EX_MEM_LNREG 	: out std_logic_vector(31 downto 0);
	inst_EX_MEM_LNREG 		: out std_logic_vector(31 downto 0);
); 
end EX;

architecture Behavioral of EX is
-- Declare some signals here to get shit set up

begin
	process(alu_op, alu_src, op1_ID_EX_REGLN, addr_ID_EX_REGLN)
		variable op1 : signed(31 downto 0);
		variable op2 : signed(31 downto 0);
	begin
		op1 := signed(op1_ID_EX_REGLN);
		
		if alu_src = '1' then
			op2 := signed(imm_ID_EX_REGLN);
		else 
			op2 := signed(op2_ID_EX_REGLN);
		end if;

		case alu_op is
			when "0000" =>		-- Add
				result_EX_MEM_LNREG <= std_logic_vector(op1 + op2);

			when "0001" =>		-- Sub
				-- could be for branch cmp
				-- also some other cases? look closer
				result_EX_MEM_LNREG <= std_logic_vector(op1 - op2);

			when "0010" =>		-- multiply
				-- only occurs when we have reg so no check
				result_EX_MEM_LNREG <= std_logic_vector(op1 * op2);

			when "0011" =>		-- and
				result_EX_MEM_LNREG <= std_logic_vector(op1 AND op2);
			
			when "0100" =>		-- or
				result_EX_MEM_LNREG <= std_logic_vector(op1 OR op2);
				
			when "0101" =>		-- xor
				result_EX_MEM_LNREG <= std_logic_vector(op1 XOR op2);
			
			when "0110" =>		-- srl
				-- use register value
				result_EX_MEM_LNREG <= shift_right(unsigned(op1_ID_EX_REGLN), op2_ID_EX_REGLN);
				
			when "0111" =>		-- sra
				-- use register value
				result_EX_MEM_LNREG <= shift_right(signed(op1_ID_EX_REGLN), op2_ID_EX_REGLN);
			
			when "1000" =>		-- sll
				-- use register value
				result_EX_MEM_LNREG <= shift_left(op1_ID_EX_REGLN, op2Addr_EX_MEM_LNREG);
				
			when "1001" =>		-- slti
				-- Use the immediate value
				if op1 < op2 then
					result_EX_MEM_LNREG <= x"00000001";
				else
					result_EX_MEM_LNREG <= x"00000000";
				end if;
			when others =>
				result_EX_MEM_LNREG <= (others => '0');
		end case;
	end process;
end Behavioral;