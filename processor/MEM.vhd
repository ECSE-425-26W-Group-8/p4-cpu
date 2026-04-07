library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity MEM is
port(
	result_EX_MEM_REGLN     : in  std_logic_vector(31 downto 0);
	op2Addr_EX_MEM_REGLN    : in  std_logic_vector(31 downto 0);
    inst_EX_MEM_REGLN       : in  std_logic_vector(31 downto 0);
	data_MEM_WB_LNREG       : out std_logic_vector(31 downto 0);
    result_MEM_WB_LNREG     : out std_logic_vector(31 downto 0);
	inst_MEM_WB_LNREG       : out std_logic_vector(31 downto 0);
	result_EX_IF_LN         : out std_logic_vector(31 downto 0);
    clk                     : in STD_LOGIC;

    -- for control process
	-- alu_src: out std_logic; -- tell rest of CPU to use imm or reg
	-- alu_op : out std_logic_vector(3 downto 0); -- what ALU does

    -- memory control signals
	mem_read_EX_MEM_REGLN   : in  std_logic;
	mem_read_MEM_WB_LNREG   : out std_logic;
	mem_write_EX_MEM_REGLN  : in  std_logic;
	mem_write_MEM_WB_LNREG  : out std_logic;

    -- write back control signals
	reg_write_EX_MEM_REGLN  : in  std_logic; -- write to reg
	reg_write_MEM_WB_LNREG  : out std_logic; -- write to reg
	wb_sel_EX_MEM_REGLN     : in std_logic_vector(1 downto 0); --what to write back
	wb_selMEM_WB_LNREG      : out std_logic_vector(1 downto 0); --what to write back

    -- control flow signals
	branch_EX_MEM_REGLN     : in std_logic; -- control flow
	branch_MEM_WB_LNREG     : out std_logic; -- control flow
	jump_EX_MEM_REGLN       : in std_logic; -- control flow
	jump_MEM_WB_LNREG       : out std_logic -- control flow

); 
end MEM;

architecture Behavioral of MEM is
    -- signals

    -- components
    component memory IS
        GENERIC(
            ram_size : INTEGER := 32768;
            -- mem_delay : time := 10 ns;
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
    END component;

begin
    data_mem : memory port map(
        clock => clk,
        address => to_integer(unsigned(result_EX_MEM_REGLN)),
        memread => mem_read_EX_MEM_REGLN,
        memwrite => mem_write_EX_MEM_REGLN,
        readdata => data_MEM_WB_LNREG,
        writedata => op2Addr_EX_MEM_REGLN
        -- ,
        -- waitrequest => s_waitrequest
    );


end Behavioral;
