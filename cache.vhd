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

-- Address fields
signal addr15      : std_logic_vector(14 downto 0);
signal tag         : std_logic_vector(5 downto 0);
signal index       : std_logic_vector(4 downto 0);
signal word_off    : std_logic_vector(1 downto 0);


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
signal fsm_writeback  : std_logic;
signal fsm_data_we    : std_logic;
signal fsm_set_dirty  : std_logic;

-- Write-hit helper
signal next_line   : block_line_t;

signal req_tag     : std_logic_vector(5 downto 0);
signal req_index   : std_logic_vector(4 downto 0);
signal req_wordoff : std_logic_vector(1 downto 0);
signal req_is_write: std_logic;
signal req_is_read : std_logic;
signal req_wdata   : std_logic_vector(31 downto 0);

-- Line Builder signals (for refill and write-hit updates)
signal refill_line : std_logic_vector(127 downto 0) := (others => '0');
signal byte_cnt : integer range 0 to 15 := 0;
signal refill_words : block_line_t;
signal refill_done : std_logic := '0';
signal merged_line : block_line_t;
signal fsm_refill_write : std_logic;  -- 1 = write-miss refill, 0 = write hit

-- Memory
signal mem_addr : integer range 0 to ram_size-1;
signal mem_addr_base : std_logic_vector(14 downto 0);

signal m_read_pulse : std_logic := '0';
signal waiting_r    : std_logic := '0';

-- Writeback
signal wb_addr_base    : std_logic_vector(14 downto 0);
signal wb_byte_cnt     : integer range 0 to 15 := 0;
signal writeback_done  : std_logic := '0';

signal wb_line_flat    : std_logic_vector(127 downto 0);
signal wb_byte         : std_logic_vector(7 downto 0);

signal m_write_pulse   : std_logic := '0';
signal waiting_w       : std_logic := '0';

begin	
---------------------------------------------------------------------
-- Memory Address Logic
---------------------------------------------------------------------
mem_addr_base <= req_tag & req_index & "0000";  -- Block-aligned byte address
mem_addr <= to_integer(unsigned(mem_addr_base)); -- Set to integer for memory interface

m_addr <= mem_addr + byte_cnt when (fsm_m_read = '1') else 0;
m_writedata <= (others => '0');

--------------------------------------------------------------------
-- Address decode
--------------------------------------------------------------------
addr15   <= s_addr(14 downto 0);
-- Address fields driven from latched request
tag      <= req_tag;
index    <= req_index;
word_off <= req_wordoff;

--------------------------------------------------------------------
-- Cache block storage
--------------------------------------------------------------------
u_blocks: entity work.cache_blocks
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
u_fsm: entity work.cache_fsm
port map(
  clk           => clock,
  reset         => reset,
  s_read        => s_read,
  s_write       => s_write,
  clean_miss    => clean_miss,
  dirty_miss    => dirty_miss,
  hit           => hit,
  s_waitrequest => fsm_wait,
  writeback     => fsm_writeback,
  m_waitrequest => m_waitrequest,
  m_read        => fsm_m_read,
  m_write       => fsm_m_write,
  data_we       => fsm_data_we,
  set_dirty     => fsm_set_dirty
);

s_waitrequest <= fsm_wait;
m_read <= m_read_pulse;
m_write <= m_write_pulse;  
data_we       <= fsm_data_we;
set_dirty     <= fsm_set_dirty;

--------------------------------------------------------------------
-- Hit / Miss logic
--------------------------------------------------------------------
hit        <= '1' when (cur_block.valid='1' and cur_block.tag=tag) else '0';
miss       <= not hit;

dirty_miss <= '1' when (miss='1' and cur_block.valid='1' and cur_block.dirty='1') else '0';
clean_miss <= '1' when (miss='1' and (cur_block.valid='0' or cur_block.dirty='0')) else '0';

--------------------------------------------------------------------
-- Read hit mux 
-- word_off "00" should select word 0 (lowest word in block)
--------------------------------------------------------------------
with word_off select
    s_readdata <= cur_block.block_line(0) when "00",
                  cur_block.block_line(1) when "01",
                  cur_block.block_line(2) when "10",
                  cur_block.block_line(3) when others;

--------------------------------------------------------------------
-- Build new line for write hit
--------------------------------------------------------------------
process(all)
begin
    next_line <= cur_block.block_line;  -- default copy

    case word_off is
		when "00" => next_line(0) <= req_wdata;
		when "01" => next_line(1) <= req_wdata;
		when "10" => next_line(2) <= req_wdata;
  		when others => next_line(3) <= req_wdata;
	end case;
end process;

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
        byte_cnt    <= 0;
        refill_done <= '0';

    elsif rising_edge(clock) then
        -- Default: not done unless we finish this cycle
        refill_done <= '0';

        -- If we're not currently doing a memory read burst, reset counter
        if fsm_m_read = '0' then
            byte_cnt <= 0;

        else
            -- We're in refill: capture a byte when memory "accepts"/responds
            if m_waitrequest = '0' then

                -- store this byte into the correct slot in the 128-bit buffer
                refill_line(8*byte_cnt + 7 downto 8*byte_cnt) <= m_readdata;

                -- advance counter / detect completion
                if byte_cnt = 15 then
                    byte_cnt    <= 0; -- optional reset
                    refill_done <= '1';
                else
                    byte_cnt <= byte_cnt + 1;
                end if;
            end if;
        end if;
    end if;
end process;

---------------------------------------------------------------------------
-- Write word into correct slot in block line for write misses
---------------------------------------------------------------------------
process(all)
begin
    merged_line <= refill_words;  -- start from line fetched from memory

    case req_wordoff is
        when "00" => merged_line(0) <= req_wdata;
        when "01" => merged_line(1) <= req_wdata;
        when "10" => merged_line(2) <= req_wdata;
        when others => merged_line(3) <= req_wdata;
    end case;
end process;

-----------------------------------------------------------------------
-- Pulse generation for memory read
-----------------------------------------------------------------------
process(clock, reset)
begin
  if reset='1' then
    m_read_pulse <= '0';
    waiting_r    <= '0';
  elsif rising_edge(clock) then
    m_read_pulse <= '0'; -- set to low by default, only pulse high for one cycle when starting a new read

    if fsm_m_read='0' then -- we're not requesting a read, so make sure pulse is low and we're not waiting for anything
      waiting_r <= '0';
    else
      -- Start a new byte read only if we're not waiting for the completion pulse
      if waiting_r='0' then
        m_read_pulse <= '1';  -- creates rising edge
        waiting_r    <= '1';
      end if;

      -- Completion pulse from memory
      if m_waitrequest='0' then --m_waitrequest pulses low when memory read is finished
        waiting_r <= '0';     -- allow next read pulse next cycle
      end if;
    end if;
  end if;
end process;

-----------------------------------------------------------------------
-- Writeback address logic
-----------------------------------------------------------------------
wb_addr_base <= cur_block.tag & req_index & "0000";
wb_line_flat <= cur_block.block_line(3) &
                cur_block.block_line(2) &
                cur_block.block_line(1) &
                cur_block.block_line(0);

wb_byte <= wb_line_flat(8*wb_byte_cnt + 7 downto 8*wb_byte_cnt);

m_addr <= (to_integer(unsigned(wb_addr_base)) + wb_byte_cnt) when (fsm_m_write='1') else
          (mem_addr + byte_cnt)                              when (fsm_m_read='1')  else
          0;

m_writedata <= wb_byte when (fsm_m_write='1') else (others => '0');

-----------------------------------------------------------------------
-- Pulse generation for memory write
-----------------------------------------------------------------------
process(clock, reset)
begin
  if reset='1' then
    m_write_pulse <= '0';
    waiting_w     <= '0';
  elsif rising_edge(clock) then
    m_write_pulse <= '0';

    if fsm_m_write='0' then
      waiting_w <= '0';
    else
      if waiting_w='0' then
        m_write_pulse <= '1';
        waiting_w     <= '1';
      end if;

      if m_waitrequest='0' then
        waiting_w <= '0';
      end if;
    end if;
  end if;
end process;

-----------------------------------------------------------------------
-- Writeback byte counter process
-----------------------------------------------------------------------
process(clock, reset)
begin
  if reset='1' then
    wb_byte_cnt    <= 0;
    writeback_done <= '0';
  elsif rising_edge(clock) then
    writeback_done <= '0';

    if fsm_m_write='0' then
      wb_byte_cnt <= 0;
    else
      if m_waitrequest='0' then
        if wb_byte_cnt = 15 then
          wb_byte_cnt    <= 0;
          writeback_done <= '1';
        else
          wb_byte_cnt <= wb_byte_cnt + 1;
        end if;
      end if;
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

--------------------------------------------------------------------
-- Choose what line gets written into cache_blocks
-- On a write hit, we want to write the updated line (next_line) which incorporates the new word
-- On a read miss, we want to write the line fetched from memory (refill_words)
-- On a write miss, we want to write the merged line which combines the memory line with the new word
---------------------------------------------------------------------
new_line <= next_line     when (fsm_data_we='1' and fsm_set_dirty='1' and fsm_refill_write='0') else
            refill_words  when (fsm_data_we='1' and fsm_set_dirty='0') else
            merged_line   when (fsm_data_we='1' and fsm_set_dirty='1' and fsm_refill_write='1') else
            next_line;

fsm_refill_write <= req_is_write;

new_tag  <= req_tag;

end arch;	