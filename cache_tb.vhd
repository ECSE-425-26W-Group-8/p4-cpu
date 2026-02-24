library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache_tb is
end cache_tb;

architecture behavior of cache_tb is

component cache is
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
	
-- test signals 
signal reset : std_logic := '0';
signal clk : std_logic := '0';
constant clk_period : time := 1 ns;

signal s_addr : std_logic_vector (31 downto 0) := (others => '0');
signal s_read : std_logic := '0';
signal s_readdata : std_logic_vector (31 downto 0);
signal s_write : std_logic := '0';
signal s_writedata : std_logic_vector (31 downto 0) := (others => '0');
signal s_waitrequest : std_logic;

signal m_addr : integer range 0 to 2147483647;
signal m_read : std_logic;
signal m_readdata : std_logic_vector (7 downto 0);
signal m_write : std_logic;
signal m_writedata : std_logic_vector (7 downto 0);
signal m_waitrequest : std_logic; 

signal sim_done : boolean := false;

begin

-- Connect the components which we instantiated above to their
-- respective signals.
dut: cache 
port map(
    clock => clk,
    reset => reset,

    s_addr => s_addr,
    s_read => s_read,
    s_readdata => s_readdata,
    s_write => s_write,
    s_writedata => s_writedata,
    s_waitrequest => s_waitrequest,

    m_addr => m_addr,
    m_read => m_read,
    m_readdata => m_readdata,
    m_write => m_write,
    m_writedata => m_writedata,
    m_waitrequest => m_waitrequest
);

MEM : memory
generic map (ram_size => 32768)
port map (
    clock => clk,
    writedata => m_writedata,
    address => m_addr,
    memwrite => m_write,
    memread => m_read,
    readdata => m_readdata,
    waitrequest => m_waitrequest
);
				

clk_process : process
begin
	if not sim_done then
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	else
		wait;
	end if;
end process;

test_process : process
procedure request_cpu (
    constant is_write : in boolean;
    constant addr     : in integer;
    constant data     : in std_logic_vector(31 downto 0)
) is
begin
    -- 1. Setup the address and data
    s_addr  <= std_logic_vector(to_unsigned(addr, 32));
    s_writedata <= data;
    
    -- 2. Assert the appropriate command signal
    if is_write then
        s_write <= '1';
        s_read  <= '0';
    else
        s_write <= '0';
        s_read  <= '1';
    end if;

    -- 3. Wait for the cache controller handshaking
    wait until s_waitrequest = '1';
    wait until s_waitrequest = '0';

    -- 4. Deassert command signals
    s_write <= '0';
    s_read  <= '0';
    
    -- 5. Small buffer to separate consecutive requests
    wait for clk_period;
end procedure;

begin
-- 1 - reset the system
	reset <= '1';
	wait for clk_period * 2;
	reset <= '0';
	wait until rising_edge(clk);
	report "Reset Complete";
	wait until rising_edge(clk);
	report "write test start";
	
-- CONVERT THE ADDRESSES TO ACTUALLY WHAT WE WANT
	
	request_cpu(false, 0, x"00000000");	-- read&!valid&!dirty&!equal	
	-- read from a bad addr	- what do we return here? - should pull from whatever is in memory
	wait until rising_edge(clk);
	request_cpu(true, 0, x"10101010");	-- write valid&!dirty&equal
	wait until rising_edge(clk);
	request_cpu(false, 0, x"00000000");	-- read&valid&dirty&equal
	assert s_readdata = x"" report "read success" severity error;
	wait until rising_edge(clk);
	request_cpu(true, 0, x"00000000");	-- write&valid&dirty&equal	- should just overwrite
	wait until rising_edge(clk);
	request_cpu(false, 0, x"00000000");	-- already tested
	wait until rising_edge(clk);
	-- addr = 65024 is bin1111111000000000 which maps to 0
	request_cpu(true, 65024, x"11111111");	-- write&valid&dirty&!equal	- should write to mem and then write to cache
	wait until rising_edge(clk);
	
	request_cpu(false, 4, x"00000000");	-- read&!valid&!dirty&!equal
	wait until rising_edge(clk);
	request_cpu(false, 4, x"00000000");	-- read&valid&!dirty&equal
	wait until rising_edge(clk);
	request_cpu(true, 4, x"00000000");	-- write&valid&!dirty&!equal - we should NOT write to mem bc not dirty
	wait until rising_edge(clk);
	request_cpu(false, 65028, x"00000000");	-- read&valid&dirty&!equal - should bring in new mem
	wait until rising_edge(clk);
	request_cpu(true, 4, x"11111111");	-- write&valid&!dirty&!equal
	wait until rising_edge(clk);
	request_cpu(false, 65028, x"11111111");	-- read valid&dirty&!equal
	wait until rising_edge(clk);
	request_cpu(false, 4, x"00000000");	-- read valid&!dirty&!equal	- we need to pull from mem and not write back
	wait until rising_edge(clk);
	

    wait for 2 * clk_period;
	report "Should be done now";
	sim_done <= true;
	std.env.stop;
	
	wait;
end process;
	
end;

-- assure:
	-- cache looks how we want it to at the end of each test
	-- should I check to make sure we aren't sending things to memory and
		-- waiting when we don't have to send to mem?

-- additionally:
	-- a slave device should assert waitrequest when in reset
		-- check the assignment details
	-- read & write signals at same time?
	-- read twice, write twice in a row
		
-- we are reading and writing 
