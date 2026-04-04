-- =============================================================================
-- InstructionFetch_tb.vhd
-- Testbench for the IF stage of the 5-stage RISC-V pipeline.
--
-- Assumptions:
--   - Memory is pre-loaded by IF_sim.tcl BEFORE `run` is called,
--     so no initial wait is needed; assertions start from the first rising edge.
--   - factorial_hex.txt is used as the instruction source.
--     Known instruction values (little-endian reassembly):
--       PC 0x00 -> 0x00500513
--       PC 0x04 -> 0x010000EF
--       PC 0x08 -> 0x0000006F
--       PC 0x0C -> 0x00A002B3
--       PC 0x10 -> 0x00100513
--       PC 0x20 -> (branch target used in Test 2)
--
-- Test cases:
--   Test 1 - Sequential fetch (no branch):
--       addr_IF_ID_LNREG increments by 4 each cycle.
--       inst_IF_ID_LNREG matches the instruction at that address.
--   Test 2 - Branch taken:
--       branchTake_EX_IF_LN = '1', result_EX_IF_REGLN = 0x00000020.
--       addr_IF_ID_LNREG must jump to 0x00000020.
--   Test 3 - Sequential resume after branch:
--       branchTake_EX_IF_LN = '0' again.
--       addr_IF_ID_LNREG continues as 0x24, 0x28.
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
            result_EX_IF_REGLN   : in  std_logic_vector(31 downto 0);
            branchTake_EX_IF_LN  : in  std_logic;
            addr_IF_ID_LNREG     : out std_logic_vector(31 downto 0);
            inst_IF_ID_LNREG     : out std_logic_vector(31 downto 0);
            clk                  : in  std_logic
        );
    end component;

    -- -------------------------------------------------------------------------
    -- Clock
    -- Must match the memory component's clock_period generic (default 1 ns).
    -- -------------------------------------------------------------------------
    constant CLK_PERIOD : time := 1 ns;
    signal clk : std_logic := '0';

    -- -------------------------------------------------------------------------
    -- DUT I/O signals
    -- -------------------------------------------------------------------------
    signal result_EX_IF_REGLN  : std_logic_vector(31 downto 0) := (others => '0');
    signal branchTake_EX_IF_LN : std_logic := '0';
    signal addr_IF_ID_LNREG    : std_logic_vector(31 downto 0);
    signal inst_IF_ID_LNREG    : std_logic_vector(31 downto 0);

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
            addr_IF_ID_LNREG    => addr_IF_ID_LNREG,
            inst_IF_ID_LNREG    => inst_IF_ID_LNREG,
            clk                 => clk
        );

    -- -------------------------------------------------------------------------
    -- Stimulus and verification
    --
    -- Timing convention:
    --   Stimuli are applied combinationally (before the rising edge).
    --   Outputs are sampled CLK_PERIOD/4 after the rising edge, giving all
    --   clocked and combinational logic time to settle within the same cycle.
    -- -------------------------------------------------------------------------
    stim_process : process
    begin

        -- =====================================================================
        -- TEST 1: Sequential fetch — no branch
        -- Expected: PC starts at 0x00000000, increments by 4 each cycle.
        -- =====================================================================
        report "=== TEST 1: Sequential Fetch (no branch) ===" severity note;
        branchTake_EX_IF_LN <= '0';

        -- Cycle 1: PC = 0x00000000
        wait until rising_edge(clk);
        wait for CLK_PERIOD / 4;

        assert addr_IF_ID_LNREG = x"00000000"
            report "FAIL T1C1 addr: expected 0x00000000, got 0x"
                   & to_hstring(addr_IF_ID_LNREG)
            severity error;

        assert inst_IF_ID_LNREG = x"00500513"
            report "FAIL T1C1 inst: expected 0x00500513, got 0x"
                   & to_hstring(inst_IF_ID_LNREG)
            severity error;

        -- Cycle 2: PC = 0x00000004
        wait until rising_edge(clk);
        wait for CLK_PERIOD / 4;

        assert addr_IF_ID_LNREG = x"00000004"
            report "FAIL T1C2 addr: expected 0x00000004, got 0x"
                   & to_hstring(addr_IF_ID_LNREG)
            severity error;

        assert inst_IF_ID_LNREG = x"010000EF"
            report "FAIL T1C2 inst: expected 0x010000EF, got 0x"
                   & to_hstring(inst_IF_ID_LNREG)
            severity error;

        -- Cycle 3: PC = 0x00000008
        wait until rising_edge(clk);
        wait for CLK_PERIOD / 4;

        assert addr_IF_ID_LNREG = x"00000008"
            report "FAIL T1C3 addr: expected 0x00000008, got 0x"
                   & to_hstring(addr_IF_ID_LNREG)
            severity error;

        assert inst_IF_ID_LNREG = x"0000006F"
            report "FAIL T1C3 inst: expected 0x0000006F, got 0x"
                   & to_hstring(inst_IF_ID_LNREG)
            severity error;

        report "TEST 1 complete." severity note;

        -- =====================================================================
        -- TEST 2: Branch taken
        -- Drive branchTake = '1' and a target address before the rising edge.
        -- Expected: on the next rising edge, PC jumps to the branch target.
        -- =====================================================================
        report "=== TEST 2: Branch Taken ===" severity note;
        branchTake_EX_IF_LN <= '1';
        result_EX_IF_REGLN  <= x"00000020";   -- branch to address 0x20

        wait until rising_edge(clk);
        wait for CLK_PERIOD / 4;

        assert addr_IF_ID_LNREG = x"00000020"
            report "FAIL T2 addr: expected branch target 0x00000020, got 0x"
                   & to_hstring(addr_IF_ID_LNREG)
            severity error;

        -- inst_IF_ID_LNREG should carry whatever is at address 0x20 in memory.
        -- Not asserting a specific value here since factorial_hex.txt contents
        -- at that offset are not predefined in this testbench.

        report "TEST 2 complete." severity note;

        -- =====================================================================
        -- TEST 3: Sequential resume after branch
        -- Deassert branch. PC should continue from 0x24.
        -- =====================================================================
        report "=== TEST 3: Sequential Resume After Branch ===" severity note;
        branchTake_EX_IF_LN <= '0';

        -- Cycle after branch: PC = 0x00000024
        wait until rising_edge(clk);
        wait for CLK_PERIOD / 4;

        assert addr_IF_ID_LNREG = x"00000024"
            report "FAIL T3C1 addr: expected 0x00000024, got 0x"
                   & to_hstring(addr_IF_ID_LNREG)
            severity error;

        -- One more cycle: PC = 0x00000028
        wait until rising_edge(clk);
        wait for CLK_PERIOD / 4;

        assert addr_IF_ID_LNREG = x"00000028"
            report "FAIL T3C2 addr: expected 0x00000028, got 0x"
                   & to_hstring(addr_IF_ID_LNREG)
            severity error;

        report "TEST 3 complete." severity note;

        -- =====================================================================
        report "=== ALL TESTS COMPLETE ===" severity note;
        wait;

    end process stim_process;

end architecture sim;
