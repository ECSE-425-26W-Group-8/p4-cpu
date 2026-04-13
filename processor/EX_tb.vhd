library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity EX_tb is
end EX_tb;

architecture sim of EX_tb is
    -- Component Declaration
    component EX is
        port(
            addr_ID_EX_REGLN, op1_ID_EX_REGLN, op2_ID_EX_REGLN, imm_ID_EX_REGLN, inst_ID_EX_REGLN : in std_logic_vector(31 downto 0);
            alu_src, branch, jump, mem_read_in, mem_write_in, reg_write_in : in std_logic;
            alu_op : in std_logic_vector(3 downto 0);
            wb_sel_in : in std_logic_vector(1 downto 0);
            branchTake_EX_IF_LNREG, result_EX_MEM_LNREG, op2Addr_EX_MEM_LNREG, inst_EX_MEM_LNREG : out std_logic_vector(31 downto 0);
            alu_src_out, branch_out, jump_out, mem_read_out, mem_write_out, reg_write_out : out std_logic;
            alu_op_out : out std_logic_vector(3 downto 0);
            wb_sel_out : out std_logic_vector(1 downto 0)
        );
    end component;

    -- Signal Declarations
    signal s_addr, s_op1, s_op2, s_imm, s_inst : std_logic_vector(31 downto 0) := (others => '0');
    signal s_alu_src, s_branch, s_jump, s_mem_rd, s_mem_wr, s_reg_wr : std_logic := '0';
    signal s_alu_op : std_logic_vector(3 downto 0) := "0000";
    signal s_wb_sel : std_logic_vector(1 downto 0) := "00";
    
    signal r_branch_tk, r_result, r_op2_addr, r_inst_out : std_logic_vector(31 downto 0);

begin
    dut: EX port map (
        addr_ID_EX_REGLN => s_addr, op1_ID_EX_REGLN => s_op1, op2_ID_EX_REGLN => s_op2,
        imm_ID_EX_REGLN => s_imm, inst_ID_EX_REGLN => s_inst, alu_src => s_alu_src,
        alu_op => s_alu_op, branch => s_branch, jump => s_jump, mem_read_in => s_mem_rd,
        mem_write_in => s_mem_wr, reg_write_in => s_reg_wr, wb_sel_in => s_wb_sel,
        branchTake_EX_IF_LNREG => r_branch_tk, result_EX_MEM_LNREG => r_result,
        op2Addr_EX_MEM_LNREG => r_op2_addr, inst_EX_MEM_LNREG => r_inst_out
    );

    process
    begin
        -- Test Case 1: ADD (R-type) -> 10 + 20 = 30
        s_op1 <= x"0000000A"; -- 10
        s_op2 <= x"00000014"; -- 20
        s_alu_src <= '0';     -- Use Register
        s_alu_op  <= "0000";  -- Add
        wait for 10 ns;
		assert (r_result = x"0000001E") 
		report "Test Case 1 Failed: ADD 10+20 should be 30 (0x1E)" severity error;
        
        -- Test Case 2: ADDI (I-type) -> 10 + 5 = 15
        s_imm <= x"00000005"; -- 5
        s_alu_src <= '1';     -- Use Immediate
        wait for 10 ns;
		assert (r_result = x"0000000F") 
		report "Test Case 2 Failed: ADDI 10+5 should be 15 (0x0F)" severity error;

        -- Test Case 3: BEQ (Branch Equal) -> 10 == 10? Yes.
        s_op1 <= x"0000000A";
        s_op2 <= x"0000000A";
        s_addr <= x"00001000"; -- PC
        s_imm  <= x"00000004"; -- Offset
        s_branch <= '1';
        s_inst(14 downto 12) <= "000"; -- BEQ funct3
        wait for 10 ns;
		assert (r_branch_tk = x"00000001" and r_result = x"00001004")
		report "Test Case 3 Failed: BEQ should take branch to 0x1004" severity error;


			-- Initialize Control Signals
		s_branch <= '0'; s_jump <= '0'; s_alu_src <= '0';
		
		-------------------------------------------------------
		-- ARITHMETIC & LOGIC TESTS (alu_op)
		-------------------------------------------------------
		s_op1 <= x"0000000A"; -- 10
		s_op2 <= x"00000005"; -- 5
		
		-- SUB (0001) -> 10 - 5 = 5
		s_alu_op <= "0001"; wait for 10 ns;
		assert (r_result = x"00000005") report "SUB Failed" severity error;

		-- AND (0011) -> 1010 & 0101 = 0
		s_op2 <= x"00000005"; s_alu_op <= "0011"; wait for 10 ns;
		assert (r_result = x"00000000") report "AND Failed" severity error;

		-- OR (0100) -> 1010 | 0101 = 15 (F)
		s_alu_op <= "0100"; wait for 10 ns;
		assert (r_result = x"0000000F") report "OR Failed" severity error;

		-- XOR (0101)
		s_alu_op <= "0101"; wait for 10 ns;
		assert (r_result = x"0000000F") report "XOR Failed" severity error;

		-- SLL (1000) -> 10 << 2 = 40 (0x28)
		s_op2 <= x"00000002"; s_alu_op <= "1000"; wait for 10 ns;
		assert (r_result = x"00000028") report "SLL Failed" severity error;

		-- SRL (0110) -> 10 >> 1 = 5
		s_op2 <= x"00000001"; s_alu_op <= "0110"; wait for 10 ns;
		assert (r_result = x"00000005") report "SRL Failed" severity error;

		-- SLTI (1001) -> Is 10 < 5? No (0)
		s_op2 <= x"00000005"; s_alu_op <= "1001"; wait for 10 ns;
		assert (r_result = x"00000000") report "SLTI False Failed" severity error;

		-------------------------------------------------------
		-- BRANCH CONDITION TESTS (branchCode = inst(14:12))
		-------------------------------------------------------
		s_branch <= '1';
		s_op1 <= x"00000064"; -- 100
		s_op2 <= x"00000064"; -- 100
		s_addr <= x"00001000"; -- PC
		s_imm  <= x"00000008"; -- Offset
		s_alu_op <= "0000";    -- Add for target calc

		-- BNE (001) -> 100 != 100? No.
		s_inst(14 downto 12) <= "001"; wait for 10 ns;
		assert (r_branch_tk = x"00000000") report "BNE False Failed" severity error;

		-- BLT (100) -> 100 < 200? Yes.
		s_op2 <= x"000000C8"; -- 200
		s_inst(14 downto 12) <= "100"; wait for 10 ns;
		assert (r_branch_tk = x"00000001") report "BLT True Failed" severity error;

		-- BGE (101) -> 100 >= 50? Yes.
		s_op2 <= x"00000032"; -- 50
		s_inst(14 downto 12) <= "101"; wait for 10 ns;
		assert (r_branch_tk = x"00000001") report "BGE True Failed" severity error;

		-------------------------------------------------------
		-- JUMP TESTS
		-------------------------------------------------------
		s_branch <= '0'; s_jump <= '1';
		
		-- JAL -> Result = PC (addr) + Imm
		s_alu_op <= "0000"; wait for 10 ns;
		assert (r_result = x"00001008") report "JAL Failed" severity error;

		-- JALR -> Result = Reg1 (op1) + Imm
		s_alu_op <= "1100"; s_op1 <= x"00002000"; wait for 10 ns;
		assert (r_result = x"00002008") report "JALR Failed" severity error;

		report "--- ALL TESTS COMPLETED ---" severity note;
		report "Simulation Finished Successfully!" severity note;
		assert false report "End of Sim" severity failure;
        wait;
    end process;
end sim;
