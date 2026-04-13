library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ID_tb is
end entity ID_tb;

architecture sim of ID_tb is

    component ID is
    port(
        clk : in std_logic;
        pc_IF_ID_REGLN : in std_logic_vector(31 downto 0);
        npc_IF_ID_REGLN : in std_logic_vector(31 downto 0);
        inst_IF_ID_REGLN : in std_logic_vector(31 downto 0);
        pc_ID_EX_LNREG : out std_logic_vector(31 downto 0);
        npc_ID_EX_LNREG : out std_logic_vector(31 downto 0);
        op1_ID_EX_LNREG : out std_logic_vector(31 downto 0);
        op2_ID_EX_LNREG : out std_logic_vector(31 downto 0);
        imm_ID_EX_LNREG : out std_logic_vector(31 downto 0);
        inst_ID_EX_LNREG : out std_logic_vector(31 downto 0);
        reg_write_WB_ID_LN : in std_logic;
        data_WB_ID_LN : in std_logic_vector(31 downto 0);
        inst_MEM_WB_REGLN : in std_logic_vector(31 downto 0);
        alu_src : out std_logic;
        alu_op : out std_logic_vector(3 downto 0);
        mem_read : out std_logic;
        mem_write : out std_logic;
        reg_write : out std_logic;
        branch : out std_logic;
        jump : out std_logic;
        wb_sel : out std_logic_vector(1 downto 0)
    );
    end component;

    constant CLK_PERIOD : time := 10 ns;
    signal clk : std_logic := '0';

    signal pc_IF_ID_REGLN : std_logic_vector(31 downto 0) := (others => '0');
    signal npc_IF_ID_REGLN : std_logic_vector(31 downto 0) := (others => '0');
    signal inst_IF_ID_REGLN : std_logic_vector(31 downto 0) := (others => '0');

    signal pc_ID_EX_LNREG : std_logic_vector(31 downto 0);
    signal npc_ID_EX_LNREG : std_logic_vector(31 downto 0);
    signal op1_ID_EX_LNREG : std_logic_vector(31 downto 0);
    signal op2_ID_EX_LNREG : std_logic_vector(31 downto 0);
    signal imm_ID_EX_LNREG : std_logic_vector(31 downto 0);
    signal inst_ID_EX_LNREG : std_logic_vector(31 downto 0);

    signal reg_write_WB_ID_LN : std_logic := '0';
    signal data_WB_ID_LN : std_logic_vector(31 downto 0) := (others => '0');
    signal inst_MEM_WB_REGLN : std_logic_vector(31 downto 0) := (others => '0');

    signal alu_src: std_logic;
    signal alu_op: std_logic_vector(3 downto 0);
    signal mem_read : std_logic;
    signal mem_write: std_logic;
    signal reg_write: std_logic;
    signal branch: std_logic;
    signal jump : std_logic;
    signal wb_sel : std_logic_vector(1 downto 0);

begin
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    dut : ID
    port map(
        clk => clk,
        pc_IF_ID_REGLN => pc_IF_ID_REGLN,
        npc_IF_ID_REGLN => npc_IF_ID_REGLN,
        inst_IF_ID_REGLN=> inst_IF_ID_REGLN,
        pc_ID_EX_LNREG => pc_ID_EX_LNREG,
        npc_ID_EX_LNREG => npc_ID_EX_LNREG,
        op1_ID_EX_LNREG => op1_ID_EX_LNREG,
        op2_ID_EX_LNREG => op2_ID_EX_LNREG,
        imm_ID_EX_LNREG => imm_ID_EX_LNREG,
        inst_ID_EX_LNREG => inst_ID_EX_LNREG,
        reg_write_WB_ID_LN => reg_write_WB_ID_LN,
        data_WB_ID_LN => data_WB_ID_LN,
        inst_MEM_WB_REGLN => inst_MEM_WB_REGLN,
        alu_src => alu_src,
        alu_op => alu_op,
        mem_read => mem_read,
        mem_write => mem_write,
        reg_write => reg_write,
        branch => branch,
        jump => jump,
        wb_sel => wb_sel
    );

    stim_process : process
    begin
        -- Initialize passthrough inputs
        pc_IF_ID_REGLN  <= x"00000020";
        npc_IF_ID_REGLN <= x"00000024";
        wait for 1 ns;

        -- TEST 1: ADDI decode
        report "=== TEST 1: ADDI decode ===" severity note;
        inst_IF_ID_REGLN <= x"00500093"; -- addi x1, x0, 5
        wait for 1 ns;
        assert pc_ID_EX_LNREG = x"00000020"
            report "FAIL T1 pc passthrough" severity error;
        assert npc_ID_EX_LNREG = x"00000024"
            report "FAIL T1 npc passthrough" severity error;
        assert inst_ID_EX_LNREG = x"00500093"
            report "FAIL T1 inst passthrough" severity error;
        assert imm_ID_EX_LNREG = x"00000005"
            report "FAIL T1 imm" severity error;
        assert reg_write = '1'
            report "FAIL T1 reg_write" severity error;
        assert alu_src = '1'
            report "FAIL T1 alu_src" severity error;
        assert alu_op = "0000"
            report "FAIL T1 alu_op" severity error;
        assert mem_read = '0' and mem_write = '0' and branch = '0' and jump = '0'
            report "FAIL T1 control defaults" severity error;
        assert wb_sel = "00"
            report "FAIL T1 wb_sel" severity error;

        -- TEST 2: R-type ADD decode
        report "=== TEST 2: R-type ADD decode ===" severity note;
        inst_IF_ID_REGLN <= x"002081B3"; -- add x3, x1, x2
        wait for 1 ns;
        assert imm_ID_EX_LNREG = x"00000000"
            report "FAIL T2 imm" severity error;
        assert reg_write = '1'
            report "FAIL T2 reg_write" severity error;
        assert alu_src = '0'
            report "FAIL T2 alu_src" severity error;
        assert alu_op = "0000"
            report "FAIL T2 alu_op expected ADD" severity error;
        assert mem_read = '0' and mem_write = '0' and branch = '0' and jump = '0'
            report "FAIL T2 control defaults" severity error;
        assert wb_sel = "00"
            report "FAIL T2 wb_sel" severity error;

        -- TEST 3: R-type SUB decode
        report "=== TEST 3: R-type SUB decode ===" severity note;
        inst_IF_ID_REGLN <= x"402081B3"; -- sub x3, x1, x2
        wait for 1 ns;
        assert alu_op = "0001"
            report "FAIL T3 alu_op expected SUB" severity error;
        assert reg_write = '1' and alu_src = '0'
            report "FAIL T3 controls" severity error;

        -- TEST 4: R-type MUL decode
        report "=== TEST 4: R-type MUL decode ===" severity note;
        inst_IF_ID_REGLN <= x"022081B3"; -- mul x3, x1, x2
        wait for 1 ns;
        assert alu_op = "0010"
            report "FAIL T4 alu_op expected MUL" severity error;
        assert reg_write = '1' and alu_src = '0'
            report "FAIL T4 controls" severity error;

        -- TEST 5: R-type AND decode
        report "=== TEST 5: R-type AND decode ===" severity note;
        inst_IF_ID_REGLN <= x"0020F1B3"; -- and x3, x1, x2
        wait for 1 ns;
        assert alu_op = "0011"
            report "FAIL T5 alu_op expected AND" severity error;

        -- TEST 6: R-type OR decode
        report "=== TEST 6: R-type OR decode ===" severity note;
        inst_IF_ID_REGLN <= x"0020E1B3"; -- or x3, x1, x2
        wait for 1 ns;
        assert alu_op = "0100"
            report "FAIL T6 alu_op expected OR" severity error;

        -- TEST 7: R-type SLL decode
        report "=== TEST 7: R-type SLL decode ===" severity note;
        inst_IF_ID_REGLN <= x"002091B3"; -- sll x3, x1, x2
        wait for 1 ns;
        assert alu_op = "0101"
            report "FAIL T7 alu_op expected SLL" severity error;

        -- TEST 8: R-type SRL decode
        report "=== TEST 8: R-type SRL decode ===" severity note;
        inst_IF_ID_REGLN <= x"0020D1B3"; -- srl x3, x1, x2
        wait for 1 ns;
        assert alu_op = "0110"
            report "FAIL T8 alu_op expected SRL" severity error;

        -- TEST 9: R-type SRA decode
        report "=== TEST 9: R-type SRA decode ===" severity note;
        inst_IF_ID_REGLN <= x"4020D1B3"; -- sra x3, x1, x2
        wait for 1 ns;
        assert alu_op = "0111"
            report "FAIL T9 alu_op expected SRA" severity error;

        -- TEST 10: ORI decode
        report "=== TEST 10: ORI decode ===" severity note;
        inst_IF_ID_REGLN <= x"00F0E193"; -- ori x3, x1, 15
        wait for 1 ns;
        assert imm_ID_EX_LNREG = x"0000000F"
            report "FAIL T10 imm" severity error;
        assert reg_write = '1' and alu_src = '1'
            report "FAIL T10 controls" severity error;
        assert alu_op = "0100"
            report "FAIL T10 alu_op expected ORI/OR" severity error;

        -- TEST 11: XORI decode
        report "=== TEST 11: XORI decode ===" severity note;
        inst_IF_ID_REGLN <= x"0FF0C193"; -- xori x3, x1, 255
        wait for 1 ns;
        assert imm_ID_EX_LNREG = x"000000FF"
            report "FAIL T11 imm" severity error;
        assert alu_op = "0101"
            report "FAIL T11 alu_op expected XORI" severity error;

        -- TEST 12: LOAD decode with negative offset
        report "=== TEST 12: LOAD negative offset ===" severity note;
        inst_IF_ID_REGLN <= x"FF00A383"; -- lw x7, -16(x1)
        wait for 1 ns;
        assert imm_ID_EX_LNREG = x"FFFFFFF0"
            report "FAIL T12 imm should be -16" severity error;
        assert mem_read = '1'
            report "FAIL T12 mem_read" severity error;
        assert mem_write = '0'
            report "FAIL T12 mem_write should be 0" severity error;
        assert reg_write = '1'
            report "FAIL T12 reg_write" severity error;
        assert alu_src = '1'
            report "FAIL T12 alu_src" severity error;
        assert alu_op = "0000"
            report "FAIL T12 alu_op should be ADD" severity error;
        assert wb_sel = "01"
            report "FAIL T12 wb_sel should be memory" severity error;

        -- TEST 13: STORE positive offset
        report "=== TEST 13: STORE positive offset ===" severity note;
        inst_IF_ID_REGLN <= x"0020A423"; -- sw x2, 8(x1)
        wait for 1 ns;
        assert imm_ID_EX_LNREG = x"00000008"
            report "FAIL T13 imm" severity error;
        assert mem_write = '1'
            report "FAIL T13 mem_write" severity error;
        assert mem_read = '0'
            report "FAIL T13 mem_read should be 0" severity error;
        assert reg_write = '0'
            report "FAIL T13 reg_write should be 0" severity error;
        assert alu_src = '1'
            report "FAIL T13 alu_src" severity error;
        assert alu_op = "0000"
            report "FAIL T13 alu_op should be ADD" severity error;

        -- TEST 14: STORE negative offset
        report "=== TEST 14: STORE negative offset ===" severity note;
        inst_IF_ID_REGLN <= x"FE20AC23"; -- sw x2, -8(x1)
        wait for 1 ns;
        assert imm_ID_EX_LNREG = x"FFFFFFF8"
            report "FAIL T14 imm should be -8" severity error;
        assert mem_write = '1'
            report "FAIL T14 mem_write" severity error;

        -- TEST 15: BRANCH positive offset
        report "=== TEST 15: BRANCH positive offset ===" severity note;
        inst_IF_ID_REGLN <= x"00208463"; -- beq x1, x2, 8
        wait for 1 ns;
        assert imm_ID_EX_LNREG = x"00000008"
            report "FAIL T15 imm should be 8" severity error;
        assert branch = '1'
            report "FAIL T15 branch" severity error;
        assert reg_write = '0'
            report "FAIL T15 reg_write should be 0" severity error;
        assert alu_src = '0'
            report "FAIL T15 alu_src" severity error;
        assert alu_op = "0001"
            report "FAIL T15 alu_op should be SUB" severity error;

        -- TEST 16: BRANCH negative offset
        report "=== TEST 16: BRANCH negative offset ===" severity note;
        inst_IF_ID_REGLN <= x"FE208EE3"; -- beq x1, x2, -4
        wait for 1 ns;
        assert imm_ID_EX_LNREG = x"FFFFFFFC"
            report "FAIL T16 imm should be -4" severity error;
        assert branch = '1'
            report "FAIL T16 branch" severity error;

        -- TEST 17: LUI decode
        report "=== TEST 17: LUI decode ===" severity note;
        inst_IF_ID_REGLN <= x"12345437"; -- lui x8, 0x12345
        wait for 1 ns;
        assert imm_ID_EX_LNREG = x"12345000"
            report "FAIL T17 imm should be 0x12345000" severity error;
        assert reg_write = '1'
            report "FAIL T17 reg_write" severity error;
        assert alu_src = '1'
            report "FAIL T17 alu_src" severity error;
        assert wb_sel = "00"
            report "FAIL T17 wb_sel" severity error;

        -- TEST 18: JAL positive offset
        report "=== TEST 18: JAL positive offset ===" severity note;
        inst_IF_ID_REGLN <= x"010000EF"; -- jal x1, 16
        wait for 1 ns;
        assert imm_ID_EX_LNREG = x"00000010"
            report "FAIL T18 imm should be 16" severity error;
        assert jump = '1'
            report "FAIL T18 jump" severity error;
        assert reg_write = '1'
            report "FAIL T18 reg_write" severity error;
        assert wb_sel = "10"
            report "FAIL T18 wb_sel should be PC+4" severity error;

        -- TEST 19: JAL negative offset
        report "=== TEST 19: JAL negative offset ===" severity note;
        inst_IF_ID_REGLN <= x"FFDFF0EF"; -- jal x1, -4
        wait for 1 ns;
        assert imm_ID_EX_LNREG = x"FFFFFFFC"
            report "FAIL T19 imm should be -4" severity error;
        assert jump = '1'
            report "FAIL T19 jump" severity error;
        assert wb_sel = "10"
            report "FAIL T19 wb_sel should be PC+4" severity error;

        -- TEST 20: JALR decode
        report "=== TEST 20: JALR decode ===" severity note;
        inst_IF_ID_REGLN <= x"004080E7"; -- jalr x1, x1, 4
        wait for 1 ns;
        assert imm_ID_EX_LNREG = x"00000004"
            report "FAIL T20 imm should be 4" severity error;
        assert jump = '1'
            report "FAIL T20 jump" severity error;
        assert reg_write = '1'
            report "FAIL T20 reg_write" severity error;
        assert alu_src = '1'
            report "FAIL T20 alu_src" severity error;
        assert wb_sel = "10"
            report "FAIL T20 wb_sel should be PC+4" severity error;

        -- TEST 21: Writeback to x1, then read rs1
        report "=== TEST 21: WB then read x1 ===" severity note;
        reg_write_WB_ID_LN <= '1';
        inst_MEM_WB_REGLN  <= x"00500093"; -- any instruction with rd=x1
        data_WB_ID_LN      <= x"00000005";
        wait until rising_edge(clk);
        wait for 1 ns;
        reg_write_WB_ID_LN <= '0';
        inst_IF_ID_REGLN   <= x"002081B3"; -- add x3, x1, x2
        wait for 1 ns;
        assert op1_ID_EX_LNREG = x"00000005"
            report "FAIL T21 op1 should read back x1 = 5" severity error;

        -- TEST 22: Writeback to x2, then read rs2
        report "=== TEST 22: WB then read x2 ===" severity note;
        reg_write_WB_ID_LN <= '1';
        inst_MEM_WB_REGLN  <= x"00100113"; -- any instruction with rd=x2
        data_WB_ID_LN      <= x"0000000A";
        wait until rising_edge(clk);
        wait for 1 ns;
        reg_write_WB_ID_LN <= '0';
        inst_IF_ID_REGLN   <= x"002081B3"; -- add x3, x1, x2
        wait for 1 ns;
        assert op2_ID_EX_LNREG = x"0000000A"
            report "FAIL T22 op2 should read back x2 = 10" severity error;

        -- TEST 23: x0 must stay zero even if writeback tries to write it
        report "=== TEST 23: x0 remains zero ===" severity note;
        reg_write_WB_ID_LN <= '1';
        inst_MEM_WB_REGLN  <= x"00000013"; -- rd = x0
        data_WB_ID_LN      <= x"FFFFFFFF";
        wait until rising_edge(clk);
        wait for 1 ns;
        reg_write_WB_ID_LN <= '0';
        inst_IF_ID_REGLN   <= x"00000033"; -- add x0, x0, x0 => rs1=x0 rs2=x0
        wait for 1 ns;
        assert op1_ID_EX_LNREG = x"00000000"
            report "FAIL T23 op1 x0 should remain zero" severity error;
        assert op2_ID_EX_LNREG = x"00000000"
            report "FAIL T23 op2 x0 should remain zero" severity error;
            
        -- tests done
        report "=== ALL TESTS COMPLETE ===" severity note;
        wait;
    end process;

end architecture sim;