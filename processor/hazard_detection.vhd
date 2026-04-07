library ieee;
use ieee.std_logic_1164.all;

entity hazard_detection is
port(
    rs1_ID : in std_logic_vector(4 downto 0);
    rs2_ID : in std_logic_vector(4 downto 0);

    rd_EX  : in std_logic_vector(4 downto 0);
    regWrite_EX : in std_logic;

    rd_MEM : in std_logic_vector(4 downto 0);
    regWrite_MEM : in std_logic;

    useRs1_ID : in std_logic;
    useRs2_ID : in std_logic;

    stall : out std_logic
);
end hazard_detection;

architecture rtl of hazard_detection is

begin

    process(rs1_ID, rs2_ID, rd_EX, regWrite_EX, rd_MEM, regWrite_MEM, useRs1_ID, useRs2_ID)
    begin
        stall <= '0'; -- default no stall

        -- Check for hazards with EX stage
        if(regWrite_EX = '1' and rd_EX /= "00000" and 
            ((useRs1_ID = '1' and rd_EX = rs1_ID) or 
            (useRs2_ID = '1' and rd_EX = rs2_ID))) then

            stall <= '1'; 
        end if;

        -- Check for hazards with MEM stage
        if (regWrite_MEM = '1' and rd_MEM /= "00000" and 
            ((useRs1_ID = '1' and rd_MEM = rs1_ID) or 
            (useRs2_ID = '1' and rd_MEM = rs2_ID))) then

            stall <= '1'; 

        end if;
    end process;

end rtl;