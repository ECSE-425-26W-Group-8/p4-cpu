library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity EX is
port(
	addr_ID_EX_REGLN 		: in std_logic_vector(31 downto 0);
    npc_ID_EX_REGLN          : in  std_logic_vector(31 downto 0);
	op1_ID_EX_REGLN 		: in std_logic_vector(31 downto 0);
	op2_ID_EX_REGLN 		: in std_logic_vector(31 downto 0);
	imm_ID_EX_REGLN 		: in std_logic_vector(31 downto 0);
	inst_ID_EX_REGLN 		: in std_logic_vector(31 downto 0);	-- Holds the instruction - use for control
	
	alu_src		: in std_logic; 	-- 1 for imm, 0 for registers
	alu_op 		: in std_logic_vector(3 downto 0); -- ALU operations
	branch		: in std_logic; -- control flow
	jump		: in std_logic; -- control flow
	
	mem_read_in		: in std_logic; -- mem access
	mem_write_in	: in std_logic; -- mem access
	reg_write_in	: in std_logic; -- write to reg
	wb_sel_in		: in std_logic_vector(1 downto 0); --what to write back

	
	branch_taken_EX_MEM_LNREG 	: out std_logic;
	result_EX_MEM_LNREG 	: out std_logic_vector(31 downto 0);
	op2_EX_MEM_LNREG 	: out std_logic_vector(31 downto 0);
	inst_EX_MEM_LNREG 		: out std_logic_vector(31 downto 0);
    npc_EX_MEM_LNREG         : out std_logic_vector(31 downto 0);
	
	branch_out		: out std_logic; -- control flow
	jump_out		: out std_logic; -- control flow
	mem_read_out	: out std_logic; -- mem access
	mem_write_out	: out std_logic; -- mem access
	reg_write_out	: out std_logic; -- write to reg
	wb_sel_out		: out std_logic_vector(1 downto 0) --what to write back
); 
end EX;

architecture Behavioral of EX is
-- Declare some signals here to get shit set up
	signal branchCode : std_logic_vector(2 downto 0); 	-- Stores the type of condition for branch

begin
	branchCode <= inst_ID_EX_REGLN(14 downto 12);
	-- Here is the overarching process
	process(addr_ID_EX_REGLN, op1_ID_EX_REGLN, op2_ID_EX_REGLN, imm_ID_EX_REGLN, inst_ID_EX_REGLN, alu_src, alu_op)
		variable op1 : signed(31 downto 0);	-- holds op1 value
		variable op2 : signed(31 downto 0);	-- holds op2 val or imm val from ID
		variable shift : integer range 0 to 63;
		variable branchOut : std_logic;
		variable cmp_op1, cmp_op2	: signed(31 downto 0);
		
	begin
		cmp_op1 := signed(op1_ID_EX_REGLN);
		cmp_op2 := signed(op2_ID_EX_REGLN);
		
		-- set op1 to be a reg or the address depending on inst type
		if branch = '1' OR jump = '1' then 
			-- if we are branching/jump?
			op1 := signed(addr_ID_EX_REGLN);	-- the case where we need it to be the address
		else 
			op1 := signed(op1_ID_EX_REGLN);
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
				result_EX_MEM_LNREG <= std_logic_vector(resize(op1 * op2, 32));
			when "0011" =>		-- and
				result_EX_MEM_LNREG <= std_logic_vector(op1 AND op2);
			when "0100" =>		-- or
				result_EX_MEM_LNREG <= std_logic_vector(op1 OR op2);
			when "0101" =>		-- xor
				result_EX_MEM_LNREG <= std_logic_vector(op1 XOR op2);
			when "0110" =>		-- srl
				result_EX_MEM_LNREG <= std_logic_vector(shift_right(unsigned(op1_ID_EX_REGLN), shift));
			when "0111" =>		-- sra
				result_EX_MEM_LNREG <= std_logic_vector(shift_right(signed(op1_ID_EX_REGLN), shift));
			when "1000" =>		-- sll
				result_EX_MEM_LNREG <= std_logic_vector(shift_left(unsigned(op1_ID_EX_REGLN), shift));
			when "1001" =>		-- slti
				if op1 < op2 then
					result_EX_MEM_LNREG <= x"00000001";
				else
					result_EX_MEM_LNREG <= x"00000000";
				end if;
			when "1010" => -- lui
				result_EX_MEM_LNREG <= std_logic_vector(op2);
			when "1011" => -- auipc
				result_EX_MEM_LNREG <= std_logic_vector(op1 + op2);
			when others =>
				result_EX_MEM_LNREG <= (others => '0');
		end case;
		
		branchOut := '0';
		
		if jump = '1' then
			branchOut := '1';
		elsif branch = '1' then	-- if we are branching then we need to have cmp
			case branchCode is
				when "000" =>	-- ==
					if cmp_op1 = cmp_op2 then branchOut := '1'; end if;
				when "001" =>	-- !=
					if cmp_op1 /= cmp_op2 then branchOut := '1'; end if;
				when "100" =>	-- <
					if cmp_op1 < cmp_op2 then branchOut := '1'; end if;
				when "101" =>	-- GE
					if cmp_op1 >= cmp_op2 then branchOut := '1'; end if;
				when others =>
					branchOut := '0';
			end case; 
		else
			branchOut := '0';
		end if;
		
		if (branch = '1' AND branchOut = '1') then
			branch_taken_EX_MEM_LNREG <= '1';
			result_EX_MEM_LNREG <= std_logic_vector(op1 + op2);
		elsif jump = '1' then
			if alu_op = "1100" then	-- jalr
				result_EX_MEM_LNREG <= std_logic_vector(signed(op1_ID_EX_REGLN) + op2);
			else
				result_EX_MEM_LNREG <= std_logic_vector(op1 + op2);	-- jal
			end if;
		else branch_taken_EX_MEM_LNREG <= '0';
		end if;
		
	end process;
	
	op2_EX_MEM_LNREG 	<= op1_ID_EX_REGLN;
	inst_EX_MEM_LNREG 		<= inst_ID_EX_REGLN;
    npc_EX_MEM_LNREG        <= npc_ID_EX_REGLN;


	branch_out      <= branch;
	jump_out <= jump;
	mem_read_out <= mem_read_in;
	mem_write_out <= mem_write_in;
	reg_write_out <= reg_write_in;
	wb_sel_out <= wb_sel_in;
	
end Behavioral;
