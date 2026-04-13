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
	
	branchTake_EX_IF_LNREG 	: out std_logic_vector(31 downto 0);
	result_EX_MEM_LNREG 	: out std_logic_vector(31 downto 0);
	op2Addr_EX_MEM_LNREG 	: out std_logic_vector(31 downto 0);
	inst_EX_MEM_LNREG 		: out std_logic_vector(31 downto 0);
); 
end EX;

architecture Behavioral of EX is
-- Declare some signals here to get shit set up
	signal branchCode : std_logic_vector(3 downto 0); 	-- Stores the type of condition for branch

begin
	branchCode <= inst_ID_EX_REGLN(14 downto 12);
	-- Here is the overarching process
	process(all)
		variable op1 : signed(31 downto 0);	-- holds op1 value
		variable op2 : signed(31 downto 0);	-- holds op2 val or imm val from ID
		variable shift : integer range 0 to 63;
		variable branchOut : std_logic;
	begin
		-- set op1 to be a reg or the address depending on inst type
		if branch = '1' OR jump = '1' then 
			-- if we are branching/jump?
			op1 := signed(addr_ID_EX_REGLN);	-- the case where we need it to be the address
		else 
			op2 := signed(op1_ID_EX_REGLN);
		end if;
		
		-- set op2 to be the register or imm depending on the instruction type
		if alu_src = '1' then 
			op2 := signed(imm_ID_EX_REGLN);	-- imm val
		else 
			op2 := signed(op2_ID_EX_REGLN);	-- reg2 val
		end if;
		
		shift := to_integer(unsigned(std_logic_vector(op2(5 downto 0))));	-- how much to shift
		
		-- Here is where we get the ALU functions sorted
		case alu_op is
			when "0000" =>		-- Add
				result_EX_MEM_LNREG <= std_logic_vector(op1 + op2);
			when "0001" =>		-- Sub
				result_EX_MEM_LNREG <= std_logic_vector(op1 - op2);
			when "0010" =>		-- multiply
				result_EX_MEM_LNREG <= std_logic_vector(resize(op1 * op2), 32);
			when "0011" =>		-- and
				result_EX_MEM_LNREG <= std_logic_vector(op1 AND op2);
			when "0100" =>		-- or
				result_EX_MEM_LNREG <= std_logic_vector(op1 OR op2);
			when "0101" =>		-- xor
				result_EX_MEM_LNREG <= std_logic_vector(op1 XOR op2);
			when "0110" =>		-- srl
				result_EX_MEM_LNREG <= shift_right(unsigned(op1_ID_EX_REGLN), shift);
			when "0111" =>		-- sra
				result_EX_MEM_LNREG <= shift_right(signed(op1_ID_EX_REGLN), shift);
			when "1000" =>		-- sll
				result_EX_MEM_LNREG <= shift_left(op1_ID_EX_REGLN, shift);
			when "1001" =>		-- slti
				if op1 < op2 then
					result_EX_MEM_LNREG <= x"00000001";
				else
					result_EX_MEM_LNREG <= x"00000000";
				end if;
			when others =>
				result_EX_MEM_LNREG <= (others => '0');
		end case;
		
		branchOut := '0';
		
		if jump = '1' then
			branchOut := '1';
		elsif branch = '1' then	-- if we are branching then we need to have cmp
			case branchCode is
				when "0000" =>	-- ==
					if op1 = op2 then branchOut := '1'; end if;
				when "0001" =>	-- !=
					if op1 != op2 then branchOut := '1'; end if;
				when "0100" =>	-- <
					if op1 < op2 then branchOut := '1'; end if;
				when "0101" =>	-- GE
					if op1 >= op2 then branchOut := '1'; end if;
				when others =>
					branchOut := '0';
			end case; 
		else
			branchOut := '0';
		end if;
		
		if (branch = '1' AND branchCode = '1') OR jump = '1' then
			branchTake_EX_IF_LNREG <= (others +. '0') & "1";
			result_EX_MEM_LNREG <= std_logic_vector(op1 + op2);
		else branchTake_EX_IF_LNREG <= (others => '0');
		end if;
		
	end process;
	
end Behavioral;