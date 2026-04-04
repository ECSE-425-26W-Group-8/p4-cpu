library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity InstructionFetch is
port(
	result_EX_IF_REGLN 		: in std_logic_vector(31 downto 0 );
	branchTake_EX_IF_LN 	: in std_logic;
	addr_IF_ID_LNREG 		: out std_logic_vector(31 downto 0);
	inst_IF_ID_LNREG 		: out std_logic_vector(31 downto 0);
    clk                     : in std_logic
); 
end InstructionFetch;

architecture Behavioral of InstructionFetch is
    -- SIGNALS
    -- unclocked
    signal s_memread : STD_LOGIC;
    signal s_instruction : STD_LOGIC_VECTOR(31 downto 0);
    signal next_pc : std_logic_vector(31 downto 0);
    signal int_pc : INTEGER;
    signal s_waitrequest : STD_LOGIC;

    -- clocked
    signal pc : std_logic_vector(31 downto 0) := (others => '0');

    -- COMPONENTS
    component memory is 
    GENERIC(
        ram_size : INTEGER := 32768;
        mem_delay : time := 1 ns;
        clock_period : time := 1 ns
    );
    PORT (
        clock: IN STD_LOGIC;
        address: IN INTEGER RANGE 0 TO ram_size-1;
        memread: IN STD_LOGIC;
        readdata: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
        waitrequest: OUT STD_LOGIC
    );
    end component;

begin

    instruction_mem : memory port map(
        clock => clk,
        address => int_pc,
        memread => s_memread,
        readdata => s_instruction,
        waitrequest => s_waitrequest
    );

    
    pc_update: process(clk)
    begin
        if rising_edge(clk) then
            pc <= next_pc;
        end if;
    end process pc_update;

    next_pc_calc: process
    begin
        if branchTake_EX_IF_LN = '1' then
            next_pc <= result_EX_IF_REGLN;
        else
            next_pc <= std_logic_vector(unsigned(pc) + 4);
        end if;
    end process next_pc_calc;

end Behavioral;
