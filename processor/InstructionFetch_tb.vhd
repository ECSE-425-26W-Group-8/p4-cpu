-- =============================================================================
-- InstructionFetch_tb.vhd
-- Testbench for the IF stage of the 5-stage RISC-V pipeline.
-- on the factorial.s compiled code
--
-- Test cases:
--   Test 1 - Sequential fetch (no branch):
--       pc_IF_ID_LNREG holds NPC (fetch addr + 4) on each falling edge.
--       inst_IF_ID_LNREG matches the instruction at the fetch address.
--   Test 2 - Branch taken:
--       branchTake_EX_IF_LN = '1', result_EX_IF_REGLN = 0x00000020.
--       pc_IF_ID_LNREG must latch the branch target.
--   Test 3 - Sequential resume after branch:
--       branchTake_EX_IF_LN = '0'. pc_IF_ID_LNREG continues from 0x24.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity InstructionFetch_tb is
end entity InstructionFetch_tb;

architecture sim of InstructionFetch_tb is

    -- -------------------------------------------------------------------------
    -- DUT component
    -- -------------------------------------------------------------------------
    component InstructionFetch is
        port (
            result_EX_IF_REGLN 		: in std_logic_vector(31 downto 0 );
            branchTake_EX_IF_LN 	: in std_logic;
            pc_IF_ID_LNREG 		    : out std_logic_vector(31 downto 0);
            npc_IF_ID_LNREG         : out std_logic_vector(31 downto 0);
            inst_IF_ID_LNREG 		: out std_logic_vector(31 downto 0);
            clk                     : in std_logic;
            stall                   : in STD_LOGIC
        );
    end component;

    -- -------------------------------------------------------------------------
    -- Clock — must match the memory component's clock_period generic (1 ns).
    -- -------------------------------------------------------------------------
    constant CLK_PERIOD : time := 1 ns;
    signal clk : std_logic := '0';

    -- -------------------------------------------------------------------------
    -- DUT I/O signals
    -- -------------------------------------------------------------------------
    signal result_EX_IF_REGLN  : std_logic_vector(31 downto 0) := (others => '0');
    signal branchTake_EX_IF_LN : std_logic := '0';
    signal pc_IF_ID_LNREG      : std_logic_vector(31 downto 0);
    signal npc_IF_ID_LNREG     : std_logic_vector(31 downto 0);
    signal inst_IF_ID_LNREG    : std_logic_vector(31 downto 0);
    signal stall               : std_logic;

begin

    -- -------------------------------------------------------------------------
    -- Clock generation: free-running, 1 ns period
    -- -------------------------------------------------------------------------
    clk_process : process
    begin
        clk <= '0'; wait for CLK_PERIOD / 2;
        clk <= '1'; wait for CLK_PERIOD / 2;
    end process clk_process;

    -- -------------------------------------------------------------------------
    -- DUT instantiation
    -- -------------------------------------------------------------------------
    dut : InstructionFetch
        port map (
            result_EX_IF_REGLN  => result_EX_IF_REGLN,
            branchTake_EX_IF_LN => branchTake_EX_IF_LN,
            inst_IF_ID_LNREG    => inst_IF_ID_LNREG,
            pc_IF_ID_LNREG => pc_IF_ID_LNREG,
            npc_IF_ID_LNREG => npc_IF_ID_LNREG,
            clk                 => clk,
            stall               => stall
        );

    -- -------------------------------------------------------------------------
    -- Stimulus and verification
    --
    -- Pattern: stimuli are applied combinationally between falling edges.
    -- Each `wait until falling_edge(clk)` samples the value latched at the
    -- immediately preceding rising edge. One falling edge = one pipeline cycle.
    -- -------------------------------------------------------------------------
    stim_process : process
    begin

        -- =====================================================================
        -- TEST 1: Sequential fetch — no branch
        -- Expected: addr increments by 4 each cycle; inst matches memory.
        -- =====================================================================
        report "=== TEST 1: Sequential Fetch (no branch) ===" severity note;
        branchTake_EX_IF_LN <= '0';

        -- Falling edge 1: IF/ID latched NPC=0x04 and IR=instruction@0x00.
        -- addr holds NPC (PC+4), not the fetch address, per P&H convention.
        wait until falling_edge(clk);
        assert pc_IF_ID_LNREG = x"00000004"
            report "FAIL T1C1 addr: expected NPC 0x00000004, got 0x"
                   & to_hstring(pc_IF_ID_LNREG)
            severity error;
        assert inst_IF_ID_LNREG = x"00500513"
            report "FAIL T1C1 inst: expected 0x00500513, got 0x"
                   & to_hstring(inst_IF_ID_LNREG)
            severity error;

        -- Falling edge 2: NPC=0x08, IR=instruction@0x04.
        wait until falling_edge(clk);
        assert pc_IF_ID_LNREG = x"00000008"
            report "FAIL T1C2 addr: expected NPC 0x00000008, got 0x"
                   & to_hstring(pc_IF_ID_LNREG)
            severity error;
        assert inst_IF_ID_LNREG = x"010000EF"
            report "FAIL T1C2 inst: expected 0x010000EF, got 0x"
                   & to_hstring(inst_IF_ID_LNREG)
            severity error;

        -- Falling edge 3: NPC=0x0C, IR=instruction@0x08.
        wait until falling_edge(clk);
        assert pc_IF_ID_LNREG = x"0000000C"
            report "FAIL T1C3 addr: expected NPC 0x0000000C, got 0x"
                   & to_hstring(pc_IF_ID_LNREG)
            severity error;
        assert inst_IF_ID_LNREG = x"0000006F"
            report "FAIL T1C3 inst: expected 0x0000006F, got 0x"
                   & to_hstring(inst_IF_ID_LNREG)
            severity error;

        report "TEST 1 complete." severity note;

        -- =====================================================================
        -- TEST 2: Branch taken
        -- Stimuli applied here (between falling edges) are visible to the
        -- combinational next_pc logic before the next rising edge, so the
        -- register latches the branch target on that rising edge.
        -- =====================================================================
        report "=== TEST 2: Branch Taken ===" severity note;
        branchTake_EX_IF_LN <= '1';
        result_EX_IF_REGLN  <= x"00000020";

        -- Falling edge: register latched addr=0x20 (branch target).
        wait until falling_edge(clk);
        assert pc_IF_ID_LNREG = x"00000020"
            report "FAIL T2 addr: expected branch target 0x00000020, got 0x"
                   & to_hstring(pc_IF_ID_LNREG)
            severity error;

        report "TEST 2 complete." severity note;

        -- =====================================================================
        -- TEST 3: Sequential resume after branch
        -- Deassert branch; PC continues from 0x24.
        -- =====================================================================
        report "=== TEST 3: Sequential Resume After Branch ===" severity note;
        branchTake_EX_IF_LN <= '0';

        -- Falling edge: register latched addr=0x24.
        wait until falling_edge(clk);
        assert pc_IF_ID_LNREG = x"00000024"
            report "FAIL T3C1 addr: expected 0x00000024, got 0x"
                   & to_hstring(pc_IF_ID_LNREG)
            severity error;

        -- Falling edge: register latched addr=0x28.
        wait until falling_edge(clk);
        assert pc_IF_ID_LNREG = x"00000028"
            report "FAIL T3C2 addr: expected 0x00000028, got 0x"
                   & to_hstring(pc_IF_ID_LNREG)
            severity error;

        report "TEST 3 complete." severity note;

        -- =====================================================================
        report "=== ALL TESTS COMPLETE ===" severity note;
        wait;

    end process stim_process;

end architecture sim;
