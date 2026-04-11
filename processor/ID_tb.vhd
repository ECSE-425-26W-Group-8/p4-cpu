library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- corrected

entity ID_tb is
end entity ID_tb;

architecture sim of ID_tb is

    component ID is
    port(
        clk: in std_logic;
        addr_IF_ID_REGLN: in std_logic_vector(31 downto 0);
        inst_IF_ID_REGLN: in std_logic_vector(31 downto 0);
        addr_ID_EX_LNREG: out std_logic_vector(31 downto 0);
        op1_ID_EX_LNREG: out std_logic_vector(31 downto 0);
        op2_ID_EX_LNREG: out std_logic_vector(31 downto 0);
        imm_ID_EX_LNREG: out std_logic_vector(31 downto 0);
        inst_ID_EX_LNREG: out std_logic_vector(31 downto 0);
        inst_MEM_ID_REGLN: out std_logic_vector(31 downto 0);
        data_WB_ID_LN: in std_logic_vector(31 downto 0);
        inst_MEM_WB_REGLN: in std_logic_vector(31 downto 0);
        alu_src: out std_logic;
        alu_op: out std_logic_vector(3 downto 0);
        mem_read: out std_logic;
        mem_write: out std_logic;
        reg_write: out std_logic;
        branch: out std_logic;
        jump: out std_logic;
        wb_sel: out std_logic_vector(1 downto 0)
    );
    end component;

    constant CLK_PERIOD: time := 10 ns;
    signal clk : std_logic:= '0';

    signal addr_IF_ID_REGLN: std_logic_vector(31 downto 0) := (others => '0');
    signal inst_IF_ID_REGLN: std_logic_vector(31 downto 0) := (others => '0');
    signal addr_ID_EX_LNREG: std_logic_vector(31 downto 0);
    signal op1_ID_EX_LNREG: std_logic_vector(31 downto 0);
    signal op2_ID_EX_LNREG: std_logic_vector(31 downto 0);
    signal imm_ID_EX_LNREG: std_logic_vector(31 downto 0);
    signal inst_ID_EX_LNREG : std_logic_vector(31 downto 0);
    signal inst_MEM_ID_REGLN: std_logic_vector(31 downto 0);
    signal data_WB_ID_LN: std_logic_vector(31 downto 0) := (others => '0');
    signal inst_MEM_WB_REGLN: std_logic_vector(31 downto 0) := (others => '0');

    signal alu_src: std_logic;
    signal alu_op: std_logic_vector(3 downto 0);
    signal mem_read: std_logic;
    signal mem_write: std_logic;
    signal reg_write: std_logic;
    signal branch: std_logic;
    signal jump: std_logic;
    signal wb_sel: std_logic_vector(1 downto 0);

begin
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    dut:ID
    port map(
        clk => clk,
        addr_IF_ID_REGLN => addr_IF_ID_REGLN,
        inst_IF_ID_REGLN => inst_IF_ID_REGLN,
        addr_ID_EX_LNREG => addr_ID_EX_LNREG,
        op1_ID_EX_LNREG => op1_ID_EX_LNREG,
        op2_ID_EX_LNREG => op2_ID_EX_LNREG,
        imm_ID_EX_LNREG => imm_ID_EX_LNREG,
        inst_ID_EX_LNREG => inst_ID_EX_LNREG,
        inst_MEM_ID_REGLN => inst_MEM_ID_REGLN,
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

        report "=== TEST 1: ADDI decode ===" severity note;
        addr_IF_ID_REGLN <= x"00000000";
        inst_IF_ID_REGLN <= x"00500093"; -- addi x1, x0, 5
        wait until rising_edge(clk);
        wait for 1 ns;

        assert imm_ID_EX_LNREG = x"00000005"
            report "FAIL T1 imm: expected 0x00000005"
            severity error;
        assert reg_write = '1'
            report "FAIL T1 reg_write"
            severity error;
        assert alu_src = '1'
            report "FAIL T1 alu_src"
            severity error;
        assert alu_op = "0000"
            report "FAIL T1 alu_op"
            severity error;
        assert wb_sel = "00"
            report "FAIL T1 wb_sel"
            severity error;

        report "=== TEST 2: R-type ADD decode ===" severity note;
        inst_IF_ID_REGLN <= x"002081B3"; -- add x3, x1, x2
        wait for 1 ns;

        assert imm_ID_EX_LNREG = x"00000000"
            report "FAIL T2 imm"
            severity error;
        assert reg_write = '1'
            report "FAIL T2 reg_write"
            severity error;
        assert alu_src = '0'
            report "FAIL T2 alu_src"
            severity error;
        assert alu_op = "0000"
            report "FAIL T2 alu_op expected ADD"
            severity error;

        report "=== TEST 3: STORE decode ===" severity note;
        inst_IF_ID_REGLN <= x"0020A423"; -- sw x2, 8(x1)
        wait for 1 ns;

        assert imm_ID_EX_LNREG = x"00000008"
            report "FAIL T3 imm"
            severity error;
        assert mem_write = '1'
            report "FAIL T3 mem_write"
            severity error;
        assert reg_write = '0'
            report "FAIL T3 reg_write should be 0"
            severity error;
        assert alu_src = '1'
            report "FAIL T3 alu_src"
            severity error;
        assert alu_op = "0000"
            report "FAIL T3 alu_op should be ADD for address calc"
            severity error;

        report "=== TEST 4: BRANCH decode ===" severity note;
        inst_IF_ID_REGLN <= x"00208463"; -- beq x1, x2, 8
        wait for 1 ns;

        assert branch = '1'
            report "FAIL T4 branch"
            severity error;
        assert reg_write = '0'
            report "FAIL T4 reg_write should be 0"
            severity error;
        assert alu_src = '0'
            report "FAIL T4 alu_src"
            severity error;
        assert alu_op = "0001"
            report "FAIL T4 alu_op should be SUB for compare"
            severity error;

        report "=== TEST 5: JAL decode ===" severity note;
        inst_IF_ID_REGLN <= x"010000EF"; -- jal x1, 16
        wait for 1 ns;

        assert jump = '1'
            report "FAIL T5 jump"
            severity error;
        assert reg_write = '1'
            report "FAIL T5 reg_write"
            severity error;
        assert wb_sel = "10"
            report "FAIL T5 wb_sel should be PC+4"
            severity error;

                report "=== TEST 6: ADDI negative immediate (-1) ===" severity note;
        inst_IF_ID_REGLN <= x"FFF00293"; -- addi x5, x0, -1
        wait for 1 ns;

        assert imm_ID_EX_LNREG = x"FFFFFFFF"
            report "FAIL T6 imm should be -1"
            severity error;
        assert reg_write = '1'
            report "FAIL T6 reg_write"
            severity error;
        assert alu_src = '1'
            report "FAIL T6 alu_src"
            severity error;
        assert alu_op = "0000"
            report "FAIL T6 alu_op should be ADD"
            severity error;

        report "=== TEST 7: ADDI minimum 12-bit immediate (-2048) ===" severity note;
        inst_IF_ID_REGLN <= x"80000313"; -- addi x6, x0, -2048
        wait for 1 ns;

        assert imm_ID_EX_LNREG = x"FFFFF800"
            report "FAIL T7 imm should be 0xFFFFF800"
            severity error;
        assert reg_write = '1'
            report "FAIL T7 reg_write"
            severity error;
        assert alu_src = '1'
            report "FAIL T7 alu_src"
            severity error;

        report "=== TEST 8: LOAD negative offset (-16) ===" severity note;
        inst_IF_ID_REGLN <= x"FF00A383"; -- lw x7, -16(x1)
        wait for 1 ns;

        assert imm_ID_EX_LNREG = x"FFFFFFF0"
            report "FAIL T8 imm should be -16"
            severity error;
        assert mem_read = '1'
            report "FAIL T8 mem_read"
            severity error;
        assert reg_write = '1'
            report "FAIL T8 reg_write"
            severity error;
        assert wb_sel = "01"
            report "FAIL T8 wb_sel should be memory"
            severity error;

        report "=== TEST 9: STORE negative offset (-8) ===" severity note;
        inst_IF_ID_REGLN <= x"FE20AC23"; -- sw x2, -8(x1)
        wait for 1 ns;

        assert imm_ID_EX_LNREG = x"FFFFFFF8"
            report "FAIL T9 imm should be -8"
            severity error;
        assert mem_write = '1'
            report "FAIL T9 mem_write"
            severity error;
        assert reg_write = '0'
            report "FAIL T9 reg_write should be 0"
            severity error;

        report "=== TEST 10: BRANCH negative offset (-4) ===" severity note;
        inst_IF_ID_REGLN <= x"FE208EE3"; -- beq x1, x2, -4
        wait for 1 ns;

        assert imm_ID_EX_LNREG = x"FFFFFFFC"
            report "FAIL T10 imm should be -4"
            severity error;
        assert branch = '1'
            report "FAIL T10 branch"
            severity error;
        assert alu_op = "0001"
            report "FAIL T10 alu_op should be SUB"
            severity error;

        report "=== TEST 11: LUI immediate ===" severity note;
        inst_IF_ID_REGLN <= x"12345437"; -- lui x8, 0x12345
        wait for 1 ns;

        assert imm_ID_EX_LNREG = x"12345000"
            report "FAIL T11 imm should be 0x12345000"
            severity error;
        assert reg_write = '1'
            report "FAIL T11 reg_write"
            severity error;

        report "=== TEST 12: JAL negative offset (-4) ===" severity note;
        inst_IF_ID_REGLN <= x"FFDFF0EF"; -- jal x1, -4
        wait for 1 ns;

        assert imm_ID_EX_LNREG = x"FFFFFFFC"
            report "FAIL T12 imm should be -4"
            severity error;
        assert jump = '1'
            report "FAIL T12 jump"
            severity error;
        assert wb_sel = "10"
            report "FAIL T12 wb_sel should be PC+4"
            severity error;


        report "=== ALL TESTS COMPLETE ===" severity note;
        wait;
    end process;

end architecture sim;