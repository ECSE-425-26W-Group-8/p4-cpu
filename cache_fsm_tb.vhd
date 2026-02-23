library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cache_package.all;

entity cache_fsm_tb is
end entity cache_fsm_tb;

architecture behavior of cache_fsm_tb is
    component cache_fsm is
        port(
            clk   : in std_logic;
            reset : in std_logic;

            -- CPU -> FSM
            s_read  : in std_logic;
            s_write : in std_logic;

            -- Internal status signals
            clean_miss : in std_logic;
            dirty_miss : in std_logic;
            hit        : in std_logic;

            -- FSM -> CPU / internal
            s_waitrequest : out std_logic;
            writeback     : out std_logic;
            m_index       : out integer;

            -- Memory -> FSM
            m_waitrequest : in std_logic;

            -- FSM -> memory
            m_read  : out std_logic;
            m_write : out std_logic;

            -- FSM -> blocks array
            data_we   : out std_logic;
            set_dirty : out std_logic
        );
    end component;

    component memory is
        GENERIC(
            ram_size : INTEGER := 32768;
            mem_delay : time := 10 ns;
            clock_period : time := 1 ns
        );
        PORT (
            clock: IN STD_LOGIC;
            writedata: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
            address: IN INTEGER RANGE 0 TO ram_size-1;
            memwrite: IN STD_LOGIC;
            memread: IN STD_LOGIC;
            readdata: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
            waitrequest: OUT STD_LOGIC
        );
    end component;

    -- Signals to connect to UUT
    signal clk           : std_logic := '0';
    signal reset         : std_logic := '0';
    signal s_read        : std_logic := '0';
    signal s_write       : std_logic := '0';
    signal clean_miss    : std_logic := '0';
    signal dirty_miss    : std_logic := '0';
    signal hit           : std_logic := '0';
    signal s_waitrequest : std_logic;
    signal writeback     : std_logic;
    signal m_index       : integer := 0;
    signal m_waitrequest : std_logic;
    signal m_read        : std_logic;
    signal m_write       : std_logic;
    signal data_we       : std_logic;
    signal set_dirty     : std_logic;

    -- Memory signals
    signal mem_writedata : std_logic_vector(7 downto 0) := (others => '0');
    signal mem_addr      : integer range 0 to 32767 := 0;
    signal mem_readdata  : std_logic_vector(7 downto 0);
    
    -- Pulse generation for memory (converts level to event)
    signal m_read_pulse  : std_logic := '0';
    signal m_write_pulse : std_logic := '0';
    signal waiting_r     : std_logic := '0';
    signal waiting_w     : std_logic := '0';

    signal sim_done      : boolean := false;

    -- Clock period definitions
    constant clk_period : time := 10 ns;

begin
    -- Instantiate the Unit Under Test (UUT)
    uut: cache_fsm
    port map (
        clk           => clk,
        reset         => reset,
        s_read        => s_read,
        s_write       => s_write,
        clean_miss    => clean_miss,
        dirty_miss    => dirty_miss,
        hit           => hit,
        s_waitrequest => s_waitrequest,
        writeback     => writeback,
        m_index       => m_index,
        m_waitrequest => m_waitrequest,
        m_read        => m_read,
        m_write       => m_write,
        data_we       => data_we,
        set_dirty     => set_dirty
    );

    -- Instantiate the Memory
    mem_inst: memory
    port map (
        clock       => clk,
        writedata   => mem_writedata,
        address     => mem_addr,
        memwrite    => m_write_pulse,
        memread     => m_read_pulse,
        readdata    => mem_readdata,
        waitrequest => m_waitrequest
    );

    -- Address Logic for Memory Accesses
    mem_addr <= m_index; -- In this FSM-only test, we use index as the offset from address 0

    -- Memory Read Pulse Generation
    process(clk, reset)
    begin
        if reset = '1' then
            m_read_pulse <= '0';
            waiting_r    <= '0';
        elsif rising_edge(clk) then
            m_read_pulse <= '0';
            if m_read = '1' then
                if waiting_r = '0' then
                    m_read_pulse <= '1';
                    waiting_r    <= '1';
                elsif m_waitrequest = '0' then
                    waiting_r <= '0';
                end if;
            else
                waiting_r <= '0';
            end if;
        end if;
    end process;

    -- Memory Write Pulse Generation
    process(clk, reset)
    begin
        if reset = '1' then
            m_write_pulse <= '0';
            waiting_w     <= '0';
        elsif rising_edge(clk) then
            m_write_pulse <= '0';
            if m_write = '1' then
                if waiting_w = '0' then
                    m_write_pulse <= '1';
                    waiting_w     <= '1';
                elsif m_waitrequest = '0' then
                    waiting_w <= '0';
                end if;
            else
                waiting_w <= '0';
            end if;
        end if;
    end process;

    -- Clock process definitions
    clk_process : process
    begin
        if sim_done then
            wait;
        end if;
        while not sim_done loop
            clk <= '0';
            wait for clk_period/2;
            clk <= '1';
            wait for clk_period/2;
        end loop;
        wait;
    end process;

    -- Stimulus process
    stim_proc: process
    begin		
        -- 1. Reset the system
        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';
        wait until rising_edge(clk);
        report "Reset complete.";

        -- 2. Test Case: Read Hit
        -- Should transition: IDLE -> READ_REQ -> READ_DATA -> IDLE
        report "Testing Read Hit...";
        s_read <= '1';
        hit <= '1';
        wait until rising_edge(clk); -- IDLE -> READ_REQ
        wait until rising_edge(clk); -- READ_REQ -> READ_DATA
        wait until rising_edge(clk); -- READ_DATA -> IDLE
        s_read <= '0';
        hit <= '0';
        wait for clk_period * 2;

        -- 3. Test Case: Clean Read Miss
        -- Should transition: IDLE -> READ_REQ -> REQ_MEM (Burst 16) -> MEM_TO_CACHE_WRITE -> READ_DATA -> IDLE
        report "Testing Clean Read Miss...";
        s_read <= '1';
        clean_miss <= '1';
        
        -- Wait for FSM to exit REQ_MEM state after the 16-word burst handled by memory component
        wait until m_read = '1';
        report "FSM started memory read burst.";
        wait until m_read = '0';
        report "FSM finished memory read burst.";
        wait until s_waitrequest = '0';
        
        s_read <= '0';
        clean_miss <= '0';
        wait for clk_period * 5;

        -- 4. Test Case: Dirty Write Miss
        -- Should transition: IDLE -> WRITE_REQ -> WRITE_TO_MEM (Burst 16) -> REQ_MEM (Burst 16) -> MEM_TO_CACHE_WRITE -> WRITE_DATA -> IDLE
        report "Testing Dirty Write Miss...";
        s_write <= '1';
        dirty_miss <= '1';
        
        -- Phase A: Writeback to Memory
        wait until m_write = '1';
        report "Entering Write-to-Mem phase.";
        wait until m_write = '0';
        report "Finished Write-to-Mem phase.";
        
        -- Phase B: Refill from Memory
        wait until m_read = '1';
        report "Entering Req-Mem phase.";
        wait until m_read = '0';
        report "Finished Req-Mem phase.";
        wait until s_waitrequest = '0';
        
        s_write <= '0';
        dirty_miss <= '0';

        report "Simulation finished successfully.";
        wait for clk_period * 5;
        sim_done <= true;
        report "Stopping simulation.";
    end process;

end architecture behavior;
