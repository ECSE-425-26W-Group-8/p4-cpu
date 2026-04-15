library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity MEM is
port(
	result_EX_MEM_REGLN     : in  std_logic_vector(31 downto 0);
	op2_EX_MEM_REGLN    : in  std_logic_vector(31 downto 0);
    pc_EX_MEM_REGLN         : in  STD_LOGIC_VECTOR(31 downto 0);
    npc_EX_MEM_REGLN        : in  STD_LOGIC_VECTOR(31 downto 0);
    inst_EX_MEM_REGLN       : in  std_logic_vector(31 downto 0);
	data_MEM_WB_LNREG       : out std_logic_vector(31 downto 0);
    result_MEM_WB_LNREG     : out std_logic_vector(31 downto 0);
	pc_MEM_WB_LNREG         : out std_logic_vector(31 downto 0);
	npc_MEM_WB_LNREG        : out std_logic_vector(31 downto 0);
    inst_MEM_WB_LNREG       : out std_logic_vector(31 downto 0);
    clk                     : in STD_LOGIC;

    -- for control process
	-- alu_src: out std_logic; -- tell rest of CPU to use imm or reg
	-- alu_op : out std_logic_vector(3 downto 0); -- what ALU does

    -- memory control signals
	mem_read_EX_MEM_REGLN   : in  std_logic;
	-- mem_read_MEM_WB_LNREG   : out std_logic;
	mem_write_EX_MEM_REGLN  : in  std_logic;
	-- mem_write_MEM_WB_LNREG  : out std_logic;

    -- write back control signals
	reg_write_EX_MEM_REGLN  : in  std_logic; -- write to reg
	reg_write_MEM_WB_LNREG  : out std_logic; -- write to reg
	wb_sel_EX_MEM_REGLN     : in std_logic_vector(1 downto 0); --what to write back
	wb_sel_MEM_WB_LNREG      : out std_logic_vector(1 downto 0); --what to write back

    -- control flow signals
	branch_EX_MEM_REGLN     : in std_logic; -- control flow
	branch_MEM_WB_LNREG     : out std_logic; -- control flow
	jump_EX_MEM_REGLN       : in std_logic; -- control flow
	jump_MEM_WB_LNREG       : out std_logic -- control flow

);
end MEM;

architecture Behavioral of MEM is
    -- signals
    signal s_address : integer range 0 to 32767;

    signal vec_address : std_logic_vector(31 downto 0) := (others => '0');

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
        address => s_address,
        memread => mem_read_EX_MEM_REGLN,
        memwrite => mem_write_EX_MEM_REGLN,
        readdata => data_MEM_WB_LNREG,
        writedata => op2_EX_MEM_REGLN
        -- ,
        -- waitrequest => s_waitrequest
    );

    vec_address <= result_EX_MEM_REGLN when mem_write_EX_MEM_REGLN = '1' or mem_read_EX_MEM_REGLN = '1'
                else (others => '0');
    s_address <= to_integer(unsigned(vec_address));


    -- alu result pass through
    result_MEM_WB_LNREG <= result_EX_MEM_REGLN;

    -- instruction pass through
    inst_MEM_WB_LNREG <= inst_EX_MEM_REGLN;

    -- control signals pass through
    reg_write_MEM_WB_LNREG  <= reg_write_EX_MEM_REGLN;
    wb_sel_MEM_WB_LNREG     <= wb_sel_EX_MEM_REGLN;
    branch_MEM_WB_LNREG     <= branch_EX_MEM_REGLN;
    jump_MEM_WB_LNREG       <= jump_EX_MEM_REGLN;


	pc_MEM_WB_LNREG <= pc_EX_MEM_REGLN;
	npc_MEM_WB_LNREG <= npc_EX_MEM_REGLN;
end Behavioral;
