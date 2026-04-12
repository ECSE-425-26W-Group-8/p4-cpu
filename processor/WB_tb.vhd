-- =============================================================================
-- WB_tb.vhd
-- Testbench for the WB (Write-Back) stage of the 5-stage RISC-V pipeline.
--
-- Architecture:
--   WB_tb
--     └── dut : WB   (the DUT — write-back stage, purely combinational)
--
-- The WB stage is a simple 3-way multiplexer plus a pass-through wire:
--
--   wb_sel = "00" → data_WB_ID_LN = result_MEM_WB_REGLN  (ALU result)
--   wb_sel = "01" → data_WB_ID_LN = data_MEM_WB_REGLN    (memory read data)
--   wb_sel = "10" → data_WB_ID_LN = npc_MEM_WB_REGLN     (PC+4, return addr)
--
--   reg_write_WB_ID_LN is a direct pass-through of reg_write_MEM_WB_REGLN.
--
-- Because the DUT has no sequential logic, assertions are checked after a short
-- propagation delay (10 ns) rather than on a clock edge.  A free-running clock
-- is included for waveform aesthetics and consistency with other stage testbenches.
--
-- Test cases:
--   Test 1 - MUX select "00" (ALU result path):
--       Drives distinct values on all three data inputs.
--       Verifies data_WB_ID_LN equals result_MEM_WB_REGLN.
--
--   Test 2 - MUX select "01" (memory read path):
--       Verifies data_WB_ID_LN equals data_MEM_WB_REGLN.
--
--   Test 3 - MUX select "10" (PC+4 / return-address path):
--       Verifies data_WB_ID_LN equals npc_MEM_WB_REGLN.
--
--   Test 4 - reg_write pass-through, asserted:
--       Drives reg_write_MEM_WB_REGLN = '1', verifies reg_write_WB_ID_LN = '1'.
--
--   Test 5 - reg_write pass-through, deasserted:
--       Drives reg_write_MEM_WB_REGLN = '0', verifies reg_write_WB_ID_LN = '0'.
--
--   Test 6 - Input isolation (only selected bus propagates):
--       Sweeps wb_sel through "00", "01", "10" with all three data inputs
--       set to different distinctive values.  Confirms that each selection
--       picks exactly the right input and ignores the others.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;

entity WB_tb is
end entity WB_tb;

architecture sim of WB_tb is

    -- =========================================================================
    -- DUT component declaration — matches WB.vhd entity exactly
    -- =========================================================================
    component WB is
        port(
            data_MEM_WB_REGLN        : in  std_logic_vector(31 downto 0);
            result_MEM_WB_REGLN      : in  std_logic_vector(31 downto 0);
            pc_MEM_WB_REGLN          : in  std_logic_vector(31 downto 0);
            npc_MEM_WB_REGLN         : in  std_logic_vector(31 downto 0);
            data_WB_ID_LN            : out std_logic_vector(31 downto 0);
            reg_write_MEM_WB_REGLN  : in  std_logic;
            reg_write_WB_ID_LN       : out std_logic;
            wb_sel_MEM_WB_REGLN      : in  std_logic_vector(1 downto 0);
            branch_MEM_WB_REGLN      : in  std_logic;
            jump_MEM_WB_REGLN        : in  std_logic
        );
    end component;

    -- =========================================================================
    -- Clock — free-running, included for waveform consistency
    -- =========================================================================
    constant CLK_PERIOD : time := 1 ns;
    signal clk : std_logic := '0';

    -- =========================================================================
    -- DUT I/O signals
    -- =========================================================================
    signal data_MEM_WB_REGLN        : std_logic_vector(31 downto 0) := (others => '0');
    signal result_MEM_WB_REGLN      : std_logic_vector(31 downto 0) := (others => '0');
    signal pc_MEM_WB_REGLN          : std_logic_vector(31 downto 0) := (others => '0');
    signal npc_MEM_WB_REGLN         : std_logic_vector(31 downto 0) := (others => '0');
    signal data_WB_ID_LN            : std_logic_vector(31 downto 0);
    signal reg_write_MEM_WB_REGLN  : std_logic := '0';
    signal reg_write_WB_ID_LN       : std_logic;
    signal wb_sel_MEM_WB_REGLN      : std_logic_vector(1 downto 0) := "00";
    signal branch_MEM_WB_REGLN      : std_logic := '0';
    signal jump_MEM_WB_REGLN        : std_logic := '0';

    signal sim_done : boolean := false;

    -- Propagation delay: enough for combinational outputs to settle
    constant PROP : time := 1 ps;

begin

    -- =========================================================================
    -- Clock generation
    -- =========================================================================
    clk_process : process
    begin
        if sim_done then
            wait;
        else
            clk <= '0'; wait for CLK_PERIOD / 2;
            clk <= '1'; wait for CLK_PERIOD / 2;
        end if;
    end process clk_process;

    -- =========================================================================
    -- DUT instantiation
    -- =========================================================================
    dut : WB
        port map (
            data_MEM_WB_REGLN        => data_MEM_WB_REGLN,
            result_MEM_WB_REGLN      => result_MEM_WB_REGLN,
            pc_MEM_WB_REGLN          => pc_MEM_WB_REGLN,
            npc_MEM_WB_REGLN         => npc_MEM_WB_REGLN,
            data_WB_ID_LN            => data_WB_ID_LN,
            reg_write_MEM_WB_REGLN  => reg_write_MEM_WB_REGLN,
            reg_write_WB_ID_LN       => reg_write_WB_ID_LN,
            wb_sel_MEM_WB_REGLN      => wb_sel_MEM_WB_REGLN,
            branch_MEM_WB_REGLN      => branch_MEM_WB_REGLN,
            jump_MEM_WB_REGLN        => jump_MEM_WB_REGLN
        );

    -- =========================================================================
    -- Stimulus and verification
    -- =========================================================================
    stim_process : process
    begin

        -- =====================================================================
        -- TEST 1: MUX select "00" — ALU result path
        -- Expected: data_WB_ID_LN = result_MEM_WB_REGLN = 0xABCD1234
        -- =====================================================================
        report "=== TEST 1: wb_sel=00 selects ALU result ===" severity note;

        result_MEM_WB_REGLN     <= x"ABCD1234";   -- ALU result
        data_MEM_WB_REGLN       <= x"DEADBEEF";   -- memory data  (should not appear)
        npc_MEM_WB_REGLN        <= x"00000008";   -- PC+4         (should not appear)
        wb_sel_MEM_WB_REGLN     <= "00";
        reg_write_MEM_WB_REGLN <= '1';
        wait for PROP;

        assert data_WB_ID_LN = x"ABCD1234"
            report "FAIL 1: expected 0xABCD1234 (ALU result), got 0x" &
                   to_hstring(data_WB_ID_LN)
            severity error;
        report "  PASS 1: wb_sel=00 correctly outputs ALU result 0xABCD1234" severity note;

        -- =====================================================================
        -- TEST 2: MUX select "01" — memory read path
        -- Expected: data_WB_ID_LN = data_MEM_WB_REGLN = 0xDEADBEEF
        -- =====================================================================
        report "=== TEST 2: wb_sel=01 selects memory read data ===" severity note;

        wb_sel_MEM_WB_REGLN <= "01";
        wait for PROP;

        assert data_WB_ID_LN = x"DEADBEEF"
            report "FAIL 2: expected 0xDEADBEEF (mem read data), got 0x" &
                   to_hstring(data_WB_ID_LN)
            severity error;
        report "  PASS 2: wb_sel=01 correctly outputs memory read data 0xDEADBEEF" severity note;

        -- =====================================================================
        -- TEST 3: MUX select "10" — PC+4 / return-address path (JAL, JALR)
        -- Expected: data_WB_ID_LN = npc_MEM_WB_REGLN = 0x00000008
        -- =====================================================================
        report "=== TEST 3: wb_sel=10 selects PC+4 (return address) ===" severity note;

        wb_sel_MEM_WB_REGLN <= "10";
        wait for PROP;

        assert data_WB_ID_LN = x"00000008"
            report "FAIL 3: expected 0x00000008 (PC+4), got 0x" &
                   to_hstring(data_WB_ID_LN)
            severity error;
        report "  PASS 3: wb_sel=10 correctly outputs PC+4 0x00000008" severity note;

        -- =====================================================================
        -- TEST 4: reg_write pass-through — asserted
        -- Expected: reg_write_WB_ID_LN = '1'
        -- =====================================================================
        report "=== TEST 4: reg_write pass-through (asserted) ===" severity note;

        wb_sel_MEM_WB_REGLN     <= "00";
        reg_write_MEM_WB_REGLN <= '1';
        wait for PROP;

        assert reg_write_WB_ID_LN = '1'
            report "FAIL 4: expected reg_write_WB_ID_LN='1', got '" &
                   std_logic'image(reg_write_WB_ID_LN) & "'"
            severity error;
        report "  PASS 4: reg_write_WB_ID_LN='1' when input='1'" severity note;

        -- =====================================================================
        -- TEST 5: reg_write pass-through — deasserted
        -- Expected: reg_write_WB_ID_LN = '0'
        -- =====================================================================
        report "=== TEST 5: reg_write pass-through (deasserted) ===" severity note;

        reg_write_MEM_WB_REGLN <= '0';
        wait for PROP;

        assert reg_write_WB_ID_LN = '0'
            report "FAIL 5: expected reg_write_WB_ID_LN='0', got '" &
                   std_logic'image(reg_write_WB_ID_LN) & "'"
            severity error;
        report "  PASS 5: reg_write_WB_ID_LN='0' when input='0'" severity note;

        -- =====================================================================
        -- TEST 6: Input isolation — sweep wb_sel with distinct data on every bus
        -- All three input buses carry different distinctive values.
        -- Each wb_sel setting should select exactly its own bus.
        -- =====================================================================
        report "=== TEST 6: Input isolation sweep ===" severity note;

        result_MEM_WB_REGLN <= x"11111111";   -- ALU result bus
        data_MEM_WB_REGLN   <= x"22222222";   -- memory read bus
        npc_MEM_WB_REGLN    <= x"33333333";   -- PC+4 bus

        -- Select "00" → expect ALU result
        wb_sel_MEM_WB_REGLN <= "00";
        wait for PROP;
        assert data_WB_ID_LN = x"11111111"
            report "FAIL 6a: wb_sel=00 isolation failed, got 0x" &
                   to_hstring(data_WB_ID_LN)
            severity error;
        report "  PASS 6a: wb_sel=00 isolation correct (0x11111111)" severity note;

        -- Select "01" → expect memory read data
        wb_sel_MEM_WB_REGLN <= "01";
        wait for PROP;
        assert data_WB_ID_LN = x"22222222"
            report "FAIL 6b: wb_sel=01 isolation failed, got 0x" &
                   to_hstring(data_WB_ID_LN)
            severity error;
        report "  PASS 6b: wb_sel=01 isolation correct (0x22222222)" severity note;

        -- Select "10" → expect PC+4
        wb_sel_MEM_WB_REGLN <= "10";
        wait for PROP;
        assert data_WB_ID_LN = x"33333333"
            report "FAIL 6c: wb_sel=10 isolation failed, got 0x" &
                   to_hstring(data_WB_ID_LN)
            severity error;
        report "  PASS 6c: wb_sel=10 isolation correct (0x33333333)" severity note;

        -- =====================================================================
        report "=== ALL TESTS COMPLETE ===" severity note;

        sim_done <= true;
        wait;

    end process stim_process;

end architecture sim;
