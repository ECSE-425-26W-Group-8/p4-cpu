library ieee;
use ieee.std_logic_1164.all;

entity WB is
port(
	data_MEM_WB_REGLN   : in  std_logic_vector(31 downto 0);
    result_MEM_WB_REGLN : in  std_logic_vector(31 downto 0);
	pc_MEM_WB_REGLN     : in  std_logic_vector(31 downto 0);
    npc_MEM_WB_REGLN    : in  std_logic_vector(31 downto 0);
	data_WB_ID_LN       : out std_logic_vector(31 downto 0);

    -- control signals
    reg_write_MEM_WEB_REGLN : in std_logic;
    reg_write_WB_ID_LN : out std_logic;
    wb_sel_MEM_WB_REGLN : std_logic_vector(1 downto 0);
    
    branch_MEM_WB_REGLN : in std_logic;
    jump_MEM_WB_REGLN : in std_logic
); 
end WB;

architecture Behavioral of WB is
begin


    with wb_sel_MEM_WB_REGLN select
        data_WB_ID_LN <=
            result_MEM_WB_REGLN when "00",
            data_MEM_WB_REGLN   when "01",
            npc_MEM_WB_REGLN    when "10",
            (others => 'Z') when others;

    reg_write_WB_ID_LN <= reg_write_MEM_WEB_REGLN;

end Behavioral;
