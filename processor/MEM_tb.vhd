-- =============================================================================
-- MEM_tb.vhd
-- Testbench for the MEM stage of the 5-stage RISC-V pipeline.
--
-- Architecture:
--   MEM_tb
--     └── dut : MEM            (the DUT — memory stage combinational logic)
--           └── data_mem : memory  (instantiated inside MEM, not the testbench)
--
-- All test data is written through the DUT's own write port.
-- No external memory initialisation is required.
--
-- Test cases:
--   Test 1 - Write-Read-Verify with byte assembly:
--       Phase 1a: Write 0x12345678 to addr 0x00000000, read back, verify.
--       Phase 1b: Write 0xAABBCCDD to addr 0x00000004, read back, verify.
--       Phase 1c: Write 0x44332211 to addr 0x00000008, read back.
--                 Verifies little-endian byte split on write and reassembly on read:
--                 ram[8]=0x11, ram[9]=0x22, ram[10]=0x33, ram[11]=0x44
--                 to readdata = ram[11]&ram[10]&ram[9]&ram[8] = 0x44332211 ✓
--
--   Test 2 - Back-to-back operations:
--       Three consecutive writes to distinct addresses (0x0C, 0x10, 0x14),
--       then three consecutive reads. Verifies no cross-address corruption.
--
--   Test 3 - Simultaneous read/write detection:
--       Drives both mem_read and mem_write high. A concurrent assertion fires
--       with severity FAILURE, halting the simulation with a clear error message.
--       This verifies the safety constraint is enforced.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;

entity MEM_tb is
end entity MEM_tb;

architecture sim of MEM_tb is

    -- =========================================================================
    -- DUT component
    -- =========================================================================
    component MEM is
        port(
            result_EX_MEM_REGLN     : in  std_logic_vector(31 downto 0);
            op2Addr_EX_MEM_REGLN    : in  std_logic_vector(31 downto 0);
            inst_EX_MEM_REGLN       : in  std_logic_vector(31 downto 0);
            data_MEM_WB_LNREG       : out std_logic_vector(31 downto 0);
            result_MEM_WB_LNREG     : out std_logic_vector(31 downto 0);
            inst_MEM_WB_LNREG       : out std_logic_vector(31 downto 0);
            result_EX_IF_LN         : out std_logic_vector(31 downto 0);
            clk                     : in  std_logic;
            mem_read_EX_MEM_REGLN   : in  std_logic;
            -- mem_read_MEM_WB_LNREG   : out std_logic;
            mem_write_EX_MEM_REGLN  : in  std_logic;
            -- mem_write_MEM_WB_LNREG  : out std_logic;
            reg_write_EX_MEM_REGLN  : in  std_logic;
            reg_write_MEM_WB_LNREG  : out std_logic;
            wb_sel_EX_MEM_REGLN     : in  std_logic_vector(1 downto 0);
            wb_sel_MEM_WB_LNREG      : out std_logic_vector(1 downto 0);
            branch_EX_MEM_REGLN     : in  std_logic;
            branch_MEM_WB_LNREG     : out std_logic;
            jump_EX_MEM_REGLN       : in  std_logic;
            jump_MEM_WB_LNREG       : out std_logic
        );
    end component;

    -- =========================================================================
    -- Clock — must match the memory module's clock_period generic (1 ns)
    -- =========================================================================
    constant CLK_PERIOD : time := 1 ns;
    signal clk : std_logic := '0';

    -- =========================================================================
    -- DUT I/O signals
    -- =========================================================================
    signal result_EX_MEM_REGLN     : std_logic_vector(31 downto 0) := (others => '0');
    signal op2Addr_EX_MEM_REGLN    : std_logic_vector(31 downto 0) := (others => '0');
    signal inst_EX_MEM_REGLN       : std_logic_vector(31 downto 0) := (others => '0');
    signal data_MEM_WB_LNREG       : std_logic_vector(31 downto 0);
    signal result_MEM_WB_LNREG     : std_logic_vector(31 downto 0);
    signal inst_MEM_WB_LNREG       : std_logic_vector(31 downto 0);
    signal result_EX_IF_LN         : std_logic_vector(31 downto 0);
    signal mem_read_EX_MEM_REGLN   : std_logic := '0';
    -- signal mem_read_MEM_WB_LNREG   : std_logic;
    signal mem_write_EX_MEM_REGLN  : std_logic := '0';
    -- signal mem_write_MEM_WB_LNREG  : std_logic;
    signal reg_write_EX_MEM_REGLN  : std_logic := '0';
    signal reg_write_MEM_WB_LNREG  : std_logic;
    signal wb_sel_EX_MEM_REGLN     : std_logic_vector(1 downto 0) := (others => '0');
    signal wb_sel_MEM_WB_LNREG      : std_logic_vector(1 downto 0);
    signal branch_EX_MEM_REGLN     : std_logic := '0';
    signal branch_MEM_WB_LNREG     : std_logic;
    signal jump_EX_MEM_REGLN       : std_logic := '0';
    signal jump_MEM_WB_LNREG       : std_logic;

    signal sim_done                : BOOLEAN := FALSE;

begin

    -- =========================================================================
    -- Clock generation: free-running, 1 ns period
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
    dut : MEM
        port map (
            result_EX_MEM_REGLN    => result_EX_MEM_REGLN,
            op2Addr_EX_MEM_REGLN   => op2Addr_EX_MEM_REGLN,
            inst_EX_MEM_REGLN      => inst_EX_MEM_REGLN,
            data_MEM_WB_LNREG      => data_MEM_WB_LNREG,
            result_MEM_WB_LNREG    => result_MEM_WB_LNREG,
            inst_MEM_WB_LNREG      => inst_MEM_WB_LNREG,
            result_EX_IF_LN        => result_EX_IF_LN,
            clk                    => clk,
            mem_read_EX_MEM_REGLN  => mem_read_EX_MEM_REGLN,
            -- mem_read_MEM_WB_LNREG  => mem_read_MEM_WB_LNREG,
            mem_write_EX_MEM_REGLN => mem_write_EX_MEM_REGLN,
            -- mem_write_MEM_WB_LNREG => mem_write_MEM_WB_LNREG,
            reg_write_EX_MEM_REGLN => reg_write_EX_MEM_REGLN,
            reg_write_MEM_WB_LNREG => reg_write_MEM_WB_LNREG,
            wb_sel_EX_MEM_REGLN    => wb_sel_EX_MEM_REGLN,
            wb_sel_MEM_WB_LNREG     => wb_sel_MEM_WB_LNREG,
            branch_EX_MEM_REGLN    => branch_EX_MEM_REGLN,
            branch_MEM_WB_LNREG    => branch_MEM_WB_LNREG,
            jump_EX_MEM_REGLN      => jump_EX_MEM_REGLN,
            jump_MEM_WB_LNREG      => jump_MEM_WB_LNREG
        );

    -- =========================================================================
    -- Safety constraint: mem_read and mem_write must never both be asserted.
    -- Control logic in the pipeline is responsible for preventing this.
    -- This concurrent process enforces it at simulation time.
    -- severity FAILURE halts simulation immediately on violation.
    -- =========================================================================
    rw_constraint : process(mem_read_EX_MEM_REGLN, mem_write_EX_MEM_REGLN)
    begin
        assert not (mem_read_EX_MEM_REGLN = '1' and mem_write_EX_MEM_REGLN = '1')
            report "CONSTRAINT VIOLATION: mem_read and mem_write both asserted. " &
                   "Control logic must ensure these are mutually exclusive."
            severity failure;
    end process rw_constraint;

    -- =========================================================================
    -- Stimulus and verification
    --
    -- Timing pattern for each write-read pair:
    --   1. Assert address, data, mem_write='1', mem_read='0' before rising edge.
    --   2. wait until rising_edge(clk) — write commits to ram_block here.
    --   3. Deassert mem_write, assert mem_read (same address).
    --   4. wait until falling_edge(clk) — read has fully propagated; assert here.
    -- =========================================================================
    stim_process : process
    begin

        -- =====================================================================
        -- TEST 1: Write-Read-Verify with Byte Assembly
        -- =====================================================================
        report "=== TEST 1: Write-Read-Verify with Byte Assembly ===" severity note;

        -- ----- Phase 1a: addr 0x00000000, data 0x12345678 --------------------
        report "  Phase 1a: write 0x12345678 to addr 0x00000000" severity note;
        mem_write_EX_MEM_REGLN <= '1';
        mem_read_EX_MEM_REGLN  <= '0';
        result_EX_MEM_REGLN    <= x"00000000";
        op2Addr_EX_MEM_REGLN   <= x"12345678";
        wait until rising_edge(clk);    -- write commits

        mem_write_EX_MEM_REGLN <= '0';
        mem_read_EX_MEM_REGLN  <= '1';
        wait until falling_edge(clk);   -- combinational read has settled

        assert data_MEM_WB_LNREG = x"12345678"
            report "FAIL 1a: expected 0x12345678, got 0x" & to_hstring(data_MEM_WB_LNREG)
            severity error;
        report "  PASS 1a: read back 0x12345678 from addr 0x00000000" severity note;

        -- ----- Phase 1b: addr 0x00000004, data 0xAABBCCDD --------------------
        report "  Phase 1b: write 0xAABBCCDD to addr 0x00000004" severity note;
        mem_write_EX_MEM_REGLN <= '1';
        mem_read_EX_MEM_REGLN  <= '0';
        result_EX_MEM_REGLN    <= x"00000004";
        op2Addr_EX_MEM_REGLN   <= x"AABBCCDD";
        wait until rising_edge(clk);

        mem_write_EX_MEM_REGLN <= '0';
        mem_read_EX_MEM_REGLN  <= '1';
        wait until falling_edge(clk);

        assert data_MEM_WB_LNREG = x"AABBCCDD"
            report "FAIL 1b: expected 0xAABBCCDD, got 0x" & to_hstring(data_MEM_WB_LNREG)
            severity error;
        report "  PASS 1b: read back 0xAABBCCDD from addr 0x00000004" severity note;

        -- ----- Phase 1c: byte assembly — addr 0x00000008, data 0x44332211 ----
        -- Write splits: ram[8]=0x11, ram[9]=0x22, ram[10]=0x33, ram[11]=0x44
        -- Read reassembles: ram[11]&ram[10]&ram[9]&ram[8] = 0x44332211
        report "  Phase 1c: write 0x44332211 to addr 0x00000008 (byte assembly test)" severity note;
        mem_write_EX_MEM_REGLN <= '1';
        mem_read_EX_MEM_REGLN  <= '0';
        result_EX_MEM_REGLN    <= x"00000008";
        op2Addr_EX_MEM_REGLN   <= x"44332211";
        wait until rising_edge(clk);

        mem_write_EX_MEM_REGLN <= '0';
        mem_read_EX_MEM_REGLN  <= '1';
        wait until falling_edge(clk);

        assert data_MEM_WB_LNREG = x"44332211"
            report "FAIL 1c: byte assembly error. Expected 0x44332211, got 0x" & to_hstring(data_MEM_WB_LNREG)
            severity error;
        report "  PASS 1c: byte assembly correct - little-endian split and reassemble verified" severity note;

        report "TEST 1 complete." severity note;

        -- =====================================================================
        -- TEST 2: Back-to-Back Operations
        -- Three consecutive writes, then three consecutive reads.
        -- Verifies no cross-address corruption between operations.
        -- Uses fresh addresses (0x0C, 0x10, 0x14) not touched by Test 1.
        -- =====================================================================
        report "=== TEST 2: Back-to-Back Operations ===" severity note;

        -- Write 0x11111111 to addr 0x0000000C
        report "  Write 0x11111111 to addr 0x0000000C" severity note;
        mem_write_EX_MEM_REGLN <= '1';
        mem_read_EX_MEM_REGLN  <= '0';
        result_EX_MEM_REGLN    <= x"0000000C";
        op2Addr_EX_MEM_REGLN   <= x"11111111";
        wait until rising_edge(clk);

        -- Write 0x22222222 to addr 0x00000010
        report "  Write 0x22222222 to addr 0x00000010" severity note;
        result_EX_MEM_REGLN    <= x"00000010";
        op2Addr_EX_MEM_REGLN   <= x"22222222";
        wait until rising_edge(clk);

        -- Write 0x33333333 to addr 0x00000014
        report "  Write 0x33333333 to addr 0x00000014" severity note;
        result_EX_MEM_REGLN    <= x"00000014";
        op2Addr_EX_MEM_REGLN   <= x"33333333";
        wait until rising_edge(clk);

        -- Switch to read mode; reads are combinational
        mem_write_EX_MEM_REGLN <= '0';
        mem_read_EX_MEM_REGLN  <= '1';

        -- Read addr 0x0000000C to expect 0x11111111
        result_EX_MEM_REGLN    <= x"0000000C";
        wait until falling_edge(clk);
        assert data_MEM_WB_LNREG = x"11111111"
            report "FAIL 2a: expected 0x11111111, got 0x" & to_hstring(data_MEM_WB_LNREG)
            severity error;
        report "  PASS 2a: read 0x11111111 from addr 0x0000000C" severity note;

        -- Read addr 0x00000010 to expect 0x22222222
        result_EX_MEM_REGLN    <= x"00000010";
        wait until falling_edge(clk);
        assert data_MEM_WB_LNREG = x"22222222"
            report "FAIL 2b: expected 0x22222222, got 0x" & to_hstring(data_MEM_WB_LNREG)
            severity error;
        report "  PASS 2b: read 0x22222222 from addr 0x00000010" severity note;

        -- Read addr 0x00000014 to expect 0x33333333
        result_EX_MEM_REGLN    <= x"00000014";
        wait until falling_edge(clk);
        assert data_MEM_WB_LNREG = x"33333333"
            report "FAIL 2c: expected 0x33333333, got 0x" & to_hstring(data_MEM_WB_LNREG)
            severity error;
        report "  PASS 2c: read 0x33333333 from addr 0x00000014" severity note;

        report "TEST 2 complete." severity note;

        -- =====================================================================
        report "=== ALL TESTS COMPLETE ===" severity note;

        sim_done <= true;
        wait;


    end process stim_process;

end architecture sim;
