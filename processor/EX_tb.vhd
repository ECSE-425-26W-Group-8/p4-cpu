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
        
        -- Test Case 2: ADDI (I-type) -> 10 + 5 = 15
        s_imm <= x"00000005"; -- 5
        s_alu_src <= '1';     -- Use Immediate
        wait for 10 ns;

        -- Test Case 3: BEQ (Branch Equal) -> 10 == 10? Yes.
        s_op1 <= x"0000000A";
        s_op2 <= x"0000000A";
        s_addr <= x"00001000"; -- PC
        s_imm  <= x"00000004"; -- Offset
        s_branch <= '1';
        s_inst(14 downto 12) <= "000"; -- BEQ funct3
        wait for 10 ns;

        wait;
    end process;
end sim;
