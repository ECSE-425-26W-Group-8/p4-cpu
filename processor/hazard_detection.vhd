library ieee;
use ieee.std_logic_1164.all;

entity hazard_detection is
port(
    rs1_ID : in std_logic_vector(4 downto 0);
    rs2_ID : in std_logic_vector(4 downto 0);
    opcode_ID : in std_logic_vector(6 downto 0);

    rd_EX  : in std_logic_vector(4 downto 0);
    regWrite_EX : in std_logic;

    rd_MEM : in std_logic_vector(4 downto 0);
    regWrite_MEM : in std_logic;

    rd_WB : in std_logic_vector(4 downto 0);
    regWrite_WB : in std_logic;

    stall : out std_logic
);
end hazard_detection;

architecture rtl of hazard_detection is
begin

    process(rs1_ID, rs2_ID, opcode_ID, rd_EX, regWrite_EX, rd_MEM, regWrite_MEM, rd_WB, regWrite_WB)
        variable useRs1 : std_logic;
        variable useRs2 : std_logic;
    begin
        stall  <= '0';
        useRs1 := '0';
        useRs2 := '0';

        -- Determine whether current ID instruction actually uses rs1/rs2
        case opcode_ID is
            when "0110011" => -- R-type
                useRs1 := '1';
                useRs2 := '1';

            when "0010011" => -- I-type ALU
                useRs1 := '1';
                useRs2 := '0';

            when "0000011" => -- load
                useRs1 := '1';
                useRs2 := '0';

            when "0100011" => -- store
                useRs1 := '1';
                useRs2 := '1';

            when "1100011" => -- branch
                useRs1 := '1';
                useRs2 := '1';

            when "1100111" => -- jalr
                useRs1 := '1';
                useRs2 := '0';

            when others =>    -- jal, lui, auipc, etc.
                useRs1 := '0';
                useRs2 := '0';
        end case;

        -- Check EX hazard
        if (regWrite_EX = '1' and rd_EX /= "00000" and
            ((useRs1 = '1' and rd_EX = rs1_ID) or
             (useRs2 = '1' and rd_EX = rs2_ID))) then
            stall <= '1';
        end if;

        -- Check MEM hazard
        if (regWrite_MEM = '1' and rd_MEM /= "00000" and
            ((useRs1 = '1' and rd_MEM = rs1_ID) or
             (useRs2 = '1' and rd_MEM = rs2_ID))) then
            stall <= '1';
        end if;

        if (regWrite_WB = '1' and rd_WB /= "00000" and
            ((useRs1 = '1' and rd_WB = rs1_ID) or
             (useRs2 = '1' and rd_WB = rs2_ID))) then
            stall <= '1';
        end if;
    end process;

end rtl;
