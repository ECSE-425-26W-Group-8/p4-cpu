library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity InstructionFetch is
port(
	result_EX_IF_REGLN 		: in std_logic_vector(31 downto 0 );
	branchTake_EX_IF_LN 	: in std_logic;
	pc_IF_ID_LNREG 		    : out std_logic_vector(31 downto 0);
    npc_IF_ID_LNREG         : out std_logic_vector(31 downto 0);
	inst_IF_ID_LNREG 		: out std_logic_vector(31 downto 0);
    clk                     : in std_logic;
    stall                   : in STD_LOGIC
); 
end InstructionFetch;

architecture Behavioral of InstructionFetch is
    -- SIGNALS
    -- unclocked
    signal s_instruction : STD_LOGIC_VECTOR(31 downto 0);
    signal next_pc : std_logic_vector(31 downto 0);
    signal int_pc : INTEGER := 0;
    -- signal s_waitrequest : STD_LOGIC;
    signal s_writedata : std_logic_vector(7 downto 0);
    signal s_memread : STD_LOGIC;

    -- clocked
    signal pc : std_logic_vector(31 downto 0) := (others => '0');

    -- COMPONENTS
    component memory is 
    GENERIC(
        ram_size : INTEGER := 32768;
        -- mem_delay : time := 0.5 ns;
        clock_period : time := 1 ns
    );
    PORT (
		clock: IN STD_LOGIC;
		writedata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		address: IN INTEGER RANGE 0 TO ram_size-1;
		memwrite: IN STD_LOGIC;
		memread: IN STD_LOGIC;
		readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
        -- ;
		-- waitrequest: OUT STD_LOGIC
    );
    end component;

begin

    -- TODO implement stall logic

    instruction_mem : memory port map(
        clock => clk,
        address => int_pc,
        memread => s_memread,
        memwrite => '0',
        readdata => s_instruction,
        writedata => s_writedata
        -- ,
        -- waitrequest => s_waitrequest
    );

    
    pc_update: process(clk)
    begin
        if rising_edge(clk) and not stall = '1' then
            pc <= next_pc;
        end if;
    end process pc_update;

    int_pc <= TO_INTEGER(unsigned(pc));

    next_pc <= result_EX_IF_REGLN when branchTake_EX_IF_LN = '1' else
               std_logic_vector(unsigned(pc) + 4) ;

    s_memread <= '1' when stall = '0' else '1';

    inst_IF_ID_LNREG <= s_instruction;
    pc_IF_ID_LNREG <= pc;
    npc_IF_ID_LNREG <= next_pc;

end Behavioral;
