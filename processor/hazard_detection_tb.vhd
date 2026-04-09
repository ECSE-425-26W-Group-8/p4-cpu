library ieee;
use ieee.std_logic_1164.all;

entity hazard_detection_tb is
end hazard_detection_tb;

architecture tb of hazard_detection_tb is

    -- DUT signals
    signal rs1_ID       : std_logic_vector(4 downto 0);
    signal rs2_ID       : std_logic_vector(4 downto 0);
    signal opcode_ID    : std_logic_vector(6 downto 0);

    signal rd_EX        : std_logic_vector(4 downto 0);
    signal regWrite_EX  : std_logic;

    signal rd_MEM       : std_logic_vector(4 downto 0);
    signal regWrite_MEM : std_logic;

    signal stall        : std_logic;

begin

    -- Instantiate DUT
    uut : entity work.hazard_detection
    port map(
        rs1_ID       => rs1_ID,
        rs2_ID       => rs2_ID,
        opcode_ID    => opcode_ID,
        rd_EX        => rd_EX,
        regWrite_EX  => regWrite_EX,
        rd_MEM       => rd_MEM,
        regWrite_MEM => regWrite_MEM,
        stall        => stall
    );

    stim_proc : process
    begin
        ----------------------------------------------------------------
        -- Test 1: No hazard
        ----------------------------------------------------------------
        rs1_ID       <= "00001"; -- x1
        rs2_ID       <= "00010"; -- x2
        opcode_ID    <= "0110011"; -- R-type, uses rs1 and rs2
        rd_EX        <= "00101"; -- x5
        regWrite_EX  <= '1';
        rd_MEM       <= "00110"; -- x6
        regWrite_MEM <= '1';
        wait for 10 ns;
        assert stall = '0'
            report "Test 1 failed: expected no stall"
            severity error;

        ----------------------------------------------------------------
        -- Test 2: EX hazard on rs1
        ----------------------------------------------------------------
        rs1_ID       <= "00101"; -- x5
        rs2_ID       <= "00010"; -- x2
        opcode_ID    <= "0110011"; -- R-type
        rd_EX        <= "00101"; -- x5
        regWrite_EX  <= '1';
        rd_MEM       <= "00000";
        regWrite_MEM <= '0';
        wait for 10 ns;
        assert stall = '1'
            report "Test 2 failed: expected stall from EX hazard on rs1"
            severity error;

        ----------------------------------------------------------------
        -- Test 3: EX hazard on rs2
        ----------------------------------------------------------------
        rs1_ID       <= "00001"; -- x1
        rs2_ID       <= "00111"; -- x7
        opcode_ID    <= "0110011"; -- R-type
        rd_EX        <= "00111"; -- x7
        regWrite_EX  <= '1';
        rd_MEM       <= "00000";
        regWrite_MEM <= '0';
        wait for 10 ns;
        assert stall = '1'
            report "Test 3 failed: expected stall from EX hazard on rs2"
            severity error;

        ----------------------------------------------------------------
        -- Test 4: MEM hazard on rs1
        ----------------------------------------------------------------
        rs1_ID       <= "01000"; -- x8
        rs2_ID       <= "00001"; -- x1
        opcode_ID    <= "0110011"; -- R-type
        rd_EX        <= "00011"; -- x3
        regWrite_EX  <= '0';
        rd_MEM       <= "01000"; -- x8
        regWrite_MEM <= '1';
        wait for 10 ns;
        assert stall = '1'
            report "Test 4 failed: expected stall from MEM hazard on rs1"
            severity error;

        ----------------------------------------------------------------
        -- Test 5: Ignore x0 destination in EX
        ----------------------------------------------------------------
        rs1_ID       <= "00000"; -- x0
        rs2_ID       <= "00001"; -- x1
        opcode_ID    <= "0110011"; -- R-type
        rd_EX        <= "00000"; -- x0
        regWrite_EX  <= '1';
        rd_MEM       <= "00000";
        regWrite_MEM <= '0';
        wait for 10 ns;
        assert stall = '0'
            report "Test 5 failed: should ignore rd_EX = x0"
            severity error;

        ----------------------------------------------------------------
        -- Test 6: I-type uses rs1 only, fake rs2 match should NOT stall
        -- Example: addi
        ----------------------------------------------------------------
        rs1_ID       <= "00011"; -- x3
        rs2_ID       <= "00101"; -- looks like x5, but for I-type this is imm bits
        opcode_ID    <= "0010011"; -- I-type ALU
        rd_EX        <= "00101"; -- x5
        regWrite_EX  <= '1';
        rd_MEM       <= "00000";
        regWrite_MEM <= '0';
        wait for 10 ns;
        assert stall = '0'
            report "Test 6 failed: I-type should not use rs2"
            severity error;

        ----------------------------------------------------------------
        -- Test 7: I-type uses rs1, real EX hazard should stall
        ----------------------------------------------------------------
        rs1_ID       <= "00110"; -- x6
        rs2_ID       <= "00101"; -- irrelevant for I-type
        opcode_ID    <= "0010011"; -- I-type ALU
        rd_EX        <= "00110"; -- x6
        regWrite_EX  <= '1';
        rd_MEM       <= "00000";
        regWrite_MEM <= '0';
        wait for 10 ns;
        assert stall = '1'
            report "Test 7 failed: I-type should stall on rs1 hazard"
            severity error;

        ----------------------------------------------------------------
        -- Test 8: Store uses both rs1 and rs2
        ----------------------------------------------------------------
        rs1_ID       <= "00010"; -- x2 base
        rs2_ID       <= "01001"; -- x9 store data
        opcode_ID    <= "0100011"; -- store
        rd_EX        <= "01001"; -- x9
        regWrite_EX  <= '1';
        rd_MEM       <= "00000";
        regWrite_MEM <= '0';
        wait for 10 ns;
        assert stall = '1'
            report "Test 8 failed: store should stall on rs2 hazard"
            severity error;

        ----------------------------------------------------------------
        -- Test 9: JAL uses neither rs1 nor rs2, so no stall
        ----------------------------------------------------------------
        rs1_ID       <= "00100";
        rs2_ID       <= "00101";
        opcode_ID    <= "1101111"; -- jal
        rd_EX        <= "00100";
        regWrite_EX  <= '1';
        rd_MEM       <= "00101";
        regWrite_MEM <= '1';
        wait for 10 ns;
        assert stall = '0'
            report "Test 9 failed: JAL should not use rs1/rs2"
            severity error;

        report "All hazard detection tests passed." severity note;
        wait;
    end process;

end tb;