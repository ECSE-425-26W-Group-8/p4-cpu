library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cache_package.all;

entity cache is
generic(
    ram_size : INTEGER := 32768
);
port(
    clock : in std_logic;
    reset : in std_logic;

    -- Avalon interface --
    s_addr : in std_logic_vector (31 downto 0);
    s_read : in std_logic;
    s_readdata : out std_logic_vector (31 downto 0);
    s_write : in std_logic;
    s_writedata : in std_logic_vector (31 downto 0);
    s_waitrequest : out std_logic;

    m_addr : out integer range 0 to ram_size-1;
    m_read : out std_logic;
    m_readdata : in std_logic_vector (7 downto 0);
    m_write : out std_logic;
    m_writedata : out std_logic_vector (7 downto 0);
    m_waitrequest : in std_logic
);
end cache;

architecture arch of cache is

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
        read_data_ready : out std_logic;
        writeback     : out std_logic;
        m_index       : out integer := 0;
        read_byte     : out std_logic;

        -- Memory -> FSM
        m_waitrequest : in std_logic;

        -- FSM -> memory
        m_read  : out std_logic;
        m_write : out std_logic;

        -- FSM -> blocks array
        data_we   : out std_logic;
        set_dirty : out std_logic
    );
end component cache_fsm;

    component cache_blocks is
    port (
        clk: IN std_logic;
        reset: IN std_logic;
        -- indexing inputs
        block_index : IN std_logic_vector(4 downto 0);

        -- write inputs
        new_line	: IN block_line_t;
        new_tag		: IN std_logic_vector(5 downto 0);
        data_we		: IN std_logic;
        set_dirty	: IN std_logic;

        --outputs
        cache_block	: OUT cache_block_t
    );
    end component cache_blocks;

-- Cache blocks connections
signal new_line    : block_line_t;
signal new_tag     : std_logic_vector(5 downto 0);
signal data_we     : std_logic;
signal set_dirty   : std_logic;
signal cur_block   : cache_block_t;

-- Hit/miss
signal hit         : std_logic;
signal miss        : std_logic;
signal clean_miss  : std_logic;
signal dirty_miss  : std_logic;

-- FSM control signals
signal fsm_wait       : std_logic;
signal fsm_m_read     : std_logic;
signal fsm_m_write    : std_logic;
signal fsm_read_data_ready : std_logic;
signal fsm_writeback  : std_logic;
signal fsm_m_index    : integer range 0 to 15;
signal fsm_read_byte  : std_logic;
signal fsm_data_we    : std_logic;
signal fsm_set_dirty  : std_logic;

-- Write-hit helper
signal next_line   : block_line_t;

signal req_tag     : std_logic_vector(5 downto 0) := (others => '0');
signal req_index   : std_logic_vector(4 downto 0) := (others => '0');
signal req_wordoff : std_logic_vector(1 downto 0) := (others => '0');
signal req_is_write: std_logic := '0';
signal req_is_read : std_logic := '0';
signal req_wdata   : std_logic_vector(31 downto 0) := (others => '0');

-- Line Builder signals (for refill and write-hit updates)
signal refill_line : std_logic_vector(127 downto 0) := (others => '0');
signal refill_words : block_line_t;

-- Memory
signal req_mem_addr : integer range 0 to ram_size-1;
signal req_mem_addr_base : std_logic_vector(14 downto 0);

-- Writeback
signal wb_addr_base    : std_logic_vector(14 downto 0);
signal wb_addr         : integer range 0 to ram_size-1;
-- signal wb_byte_cnt     : integer range 0 to 15 := 0;
signal writeback_done  : std_logic := '0';

signal wb_wordoff      : integer range 0 to 3;
signal wb_byteoff      : integer range 0 to 3;
signal wb_line_flat    : std_logic_vector(127 downto 0);
signal wb_byte         : std_logic_vector(7 downto 0);

begin	
--------------------------------------------------------------------
-- Cache block storage
--------------------------------------------------------------------
u_blocks: cache_blocks
port map(
    clk         => clock,
    reset       => reset,
    block_index => req_index,
    new_line    => new_line,
    new_tag     => new_tag,
    data_we     => data_we,
    set_dirty   => set_dirty,
    cache_block => cur_block
);

---------------------------------------------------------------------
-- Cache FSM
---------------------------------------------------------------------
u_fsm: cache_fsm
port map(
  clk           => clock,
  reset         => reset,
  s_read        => s_read,
  s_write       => s_write,
  clean_miss    => clean_miss,
  dirty_miss    => dirty_miss,
  hit           => hit,
  s_waitrequest => fsm_wait,
  read_data_ready => fsm_read_data_ready,
  writeback     => fsm_writeback,
  m_index       => fsm_m_index,
  read_byte     => fsm_read_byte,
  m_waitrequest => m_waitrequest,
  m_read        => fsm_m_read,
  m_write       => fsm_m_write,
  data_we       => fsm_data_we,
  set_dirty     => fsm_set_dirty
);

s_waitrequest <= fsm_wait;
m_read <= fsm_m_read;
m_write <= fsm_m_write;  
data_we       <= fsm_data_we;
set_dirty     <= fsm_set_dirty;

---------------------------------------------------------------------
-- Memory & write back Address Logic
---------------------------------------------------------------------
req_mem_addr_base <= req_tag & req_index & "0000";  -- Block-aligned byte address
req_mem_addr <= to_integer(unsigned(req_mem_addr_base)); -- Set to integer for memory interface

wb_addr_base <= cur_block.tag & req_index & "0000";
wb_addr <= to_integer(unsigned(wb_addr_base));

m_addr <= (wb_addr + fsm_m_index) when (dirty_miss ='1' or fsm_writeback='1') else
          (req_mem_addr + fsm_m_index);

wb_wordoff <= to_integer(TO_UNSIGNED(fsm_m_index,4)(3 downto 2));
wb_byteoff <= to_integer(TO_UNSIGNED(fsm_m_index,4)(1 downto 0));

m_writedata <= cur_block.block_line(wb_wordoff)(wb_byteoff+7 downto wb_byteoff);

--------------------------------------------------------------------
-- Hit / Miss logic
--------------------------------------------------------------------
hit        <= '1' when (cur_block.valid='1' and cur_block.tag=req_tag) else '0';
miss       <= not hit;

dirty_miss <= '1' when (miss='1' and cur_block.valid='1' and cur_block.dirty='1') else '0';
clean_miss <= '1' when (miss='1' and (cur_block.valid='0' or cur_block.dirty='0')) else '0';

--------------------------------------------------------------------
-- Read hit mux 
-- word_off "00" should select word 0 (lowest word in block)
--------------------------------------------------------------------
with fsm_read_data_ready&req_wordoff select
    s_readdata <= cur_block.block_line(0) when "100",
                  cur_block.block_line(1) when "101",
                  cur_block.block_line(2) when "110",
                  cur_block.block_line(3) when "111",
                  (others => 'Z') when others;
-- with req_wordoff select
--     s_readdata <= cur_block.block_line(0) when "00",
--                   cur_block.block_line(1) when "01",
--                   cur_block.block_line(2) when "10",
--                   cur_block.block_line(3) when others;

--------------------------------------------------------------------
-- Build new line for write hit
--------------------------------------------------------------------
next_line_generate: for i in 0 to 3 generate
    next_line(i) <= req_wdata when to_integer(unsigned(req_wordoff)) = i else cur_block.block_line(i);
end generate next_line_generate;
    
-----------------------------------------------------------------------
-- Request latching process
-- Latches the address and control signals from the CPU when a new request arrives
-----------------------------------------------------------------------
process(clock, reset)
begin
    if reset = '1' then
        req_tag      <= (others => '0');
        req_index    <= (others => '0');
        req_wordoff  <= (others => '0');
        req_wdata    <= (others => '0');
        req_is_write <= '0';
        req_is_read  <= '0';
    elsif rising_edge(clock) then
        -- Latch a new request only when cache is not stalling
        -- and the CPU is asserting a request.
        if (fsm_wait = '0') and ((s_read = '1') xor (s_write = '1')) then
            req_tag      <= s_addr(14 downto 9);
            req_index    <= s_addr(8 downto 4);
            req_wordoff  <= s_addr(3 downto 2);
            req_wdata    <= s_writedata;
            req_is_write <= s_write;
            req_is_read  <= s_read;
        end if;
    end if;
end process;

----------------------------------------------------------------------
-- Line builder
----------------------------------------------------------------------
process(clock, reset)
begin
    if reset = '1' then
        refill_line  <= (others => '0');
    elsif rising_edge(clock) then
        if fsm_read_byte = '1' then
            refill_line(8*fsm_m_index + 7 downto 8*fsm_m_index) <= m_readdata;
        end if;
    end if;
end process;


--------------------------------------------------------------------
-- Convert 128-bit refill buffer into 4x32-bit words
--------------------------------------------------------------------
refill_words(0) <= refill_line(31 downto 0);
refill_words(1) <= refill_line(63 downto 32);
refill_words(2) <= refill_line(95 downto 64);
refill_words(3) <= refill_line(127 downto 96);



new_line <= next_line     when (fsm_data_we='1' and fsm_set_dirty='1') else
            refill_words  when (fsm_data_we='1' and fsm_set_dirty='0') else
            (others => ( others => '0'));
new_tag  <= req_tag;

end arch;
