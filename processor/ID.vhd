library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ID is
port(
	addr_IF_ID_REGLN 	: in std_logic_vector(31 downto 0);
	inst_IF_ID_REGLN 	: in std_logic_vector(31 downto 0);
	addr_ID_EX_LNREG 	: out std_logic_vector(31 downto 0);
	op1_ID_EX_LNREG		: out std_logic_vector(31 downto 0);
	op2_ID_EX_LNREG 	: out std_logic_vector(31 downto 0);
	imm_ID_EX_LNREG 	: out std_logic_vector(31 downto 0);
	inst_ID_EX_LNREG 	: out std_logic_vector(31 downto 0);
	inst_MEM_ID_REGLN	: out std_logic_vector(31 downto 0);
	data_WB_ID_LN		: out std_logic_vector(31 downto 0)
); 
end ID;

--The ID stage decodes the instruction, reads register values, and generates the immediate. 
--It passes these to EX. Later, we need to add control signals, clocked register writeback, 
--hazard detection, and ensure correct handling of branches, loads/stores, and instructions that write rd.

architecture Behavioral of ID is
	-- register file: 32 reg of 32 bits
	type reg_file_type is array(0 to 31) of std_logic_vector(31 downto 0);
    signal regs : reg_file_type := (others => (others => '0'));

	-- instr fields
	signal opcode: std_logic_vector(6 downto 0);
    signal rd: std_logic_vector(4 downto 0);
    signal funct3: std_logic_vector(2 downto 0);
    signal rs1: std_logic_vector(4 downto 0);
    signal rs2: std_logic_vector(4 downto 0);
    signal funct7: std_logic_vector(6 downto 0);

    signal wb_rd: std_logic_vector(4 downto 0);

    signal op1_val: std_logic_vector(31 downto 0);
    signal op2_val: std_logic_vector(31 downto 0);
    signal imm_val: std_logic_vector(31 downto 0);
begin
	-- extract fields from current instruction
	opcode <= inst_IF_ID_REGLN(6 downto 0);
    rd <= inst_IF_ID_REGLN(11 downto 7);
    funct3 <= inst_IF_ID_REGLN(14 downto 12);
    rs1 <= inst_IF_ID_REGLN(19 downto 15);
    rs2 <= inst_IF_ID_REGLN(24 downto 20);
    funct7 <= inst_IF_ID_REGLN(31 downto 25);

    -- destination register of WB-stage instruction
    wb_rd  <= inst_MEM_WB_REGLN(11 downto 7);

    process(inst_MEM_WB_REGLN, data_WB_ID_LN, wb_rd)
        variable wb_opcode : std_logic_vector(6 downto 0);
        variable wb_rd_int : integer;
    begin
        wb_opcode := inst_MEM_WB_REGLN(6 downto 0);
        wb_rd_int := to_integer(unsigned(wb_rd));
        -- x0 always stay zero
        regs(0) <= (others => '0');
        -- write back for instructions that write rd (so no store/branch)
        if wb_rd_int /= 0 then
            case wb_opcode is
                when "0110011" => -- R-type
                    regs(wb_rd_int) <= data_WB_ID_LN;
                when "0010011" => -- I-type ALU
                    regs(wb_rd_int) <= data_WB_ID_LN;
                when "0000011" => -- I-type LOAD lw
                    regs(wb_rd_int) <= data_WB_ID_LN;
                when "1101111" =>  -- JAL
                    regs(wb_rd_int) <= data_WB_ID_LN;
                when "1100111" => -- JALR
                    regs(wb_rd_int) <= data_WB_ID_LN;
                when "0110111" => -- LUI
                    regs(wb_rd_int) <= data_WB_ID_LN;
                when "0010111" => -- AUIPC
                    regs(wb_rd_int) <= data_WB_ID_LN;
                when others =>
                    null;
            end case;
        end if;
    end process;
    -- Read register operands
    op1_val <= regs(to_integer(unsigned(rs1)));
    op2_val <= regs(to_integer(unsigned(rs2)));
    -- Immediate generator (not from registers)
    process(inst_IF_ID_REGLN, opcode)
        variable imm_i: signed(31 downto 0);
        variable imm_s: signed(31 downto 0);
        variable imm_b: signed(31 downto 0);
        variable imm_j: signed(31 downto 0);
        variable imm_u: std_logic_vector(31 downto 0);
    begin
        imm_val <= (others => '0');
        -- defaults
        imm_i:= (others => '0');
        imm_s:= (others => '0');
        imm_b:= (others => '0');
        imm_j:= (others => '0');
        imm_u:= (others => '0');
        case opcode is
			-- R-type: no immediate
            when "0110011" =>
                imm_val <= (others => '0');
            -- I-type immediate (addi, xori, ori, andi, jalr, loads)
            when "0010011" | "0000011" | "1100111" =>
                imm_i := resize(signed(inst_IF_ID_REGLN(31 downto 20)), 32);
                imm_val <= std_logic_vector(imm_i);
            -- S-type immediate (sb, sh, sw)
            when "0100011" =>
                imm_s := resize(
                    signed(inst_IF_ID_REGLN(31 downto 25) &
                           inst_IF_ID_REGLN(11 downto 7)),
                    32
                );
                imm_val <= std_logic_vector(imm_s);
            -- B-type immediate (beq, bne, blt, bge, bltu, bgeu)
            when "1100011" =>
                imm_b := resize(
                    signed(inst_IF_ID_REGLN(31) &
                           inst_IF_ID_REGLN(7) &
                           inst_IF_ID_REGLN(30 downto 25) &
                           inst_IF_ID_REGLN(11 downto 8) &
                           '0'),
                    32
                );
                imm_val <= std_logic_vector(imm_b);
			-- U-type immediate (lui, auipc)
            when "0110111" | "0010111" =>
                imm_u := inst_IF_ID_REGLN(31 downto 12) & "000000000000";
                imm_val <= imm_u;
            -- J-type immediate (jal)
            when "1101111" =>
                imm_j := resize(
                    signed(inst_IF_ID_REGLN(31) &
                           inst_IF_ID_REGLN(19 downto 12) &
                           inst_IF_ID_REGLN(20) &
                           inst_IF_ID_REGLN(30 downto 21) &
                           '0'),
                    32
                );
                imm_val <= std_logic_vector(imm_j);    
            when others =>
                imm_val <= (others => '0');
        end case;
    end process;
    -- Outputs to EX stage
    addr_ID_EX_LNREG <= addr_IF_ID_REGLN;
    op1_ID_EX_LNREG <= op1_val;
    op2_ID_EX_LNREG <= op2_val;
    imm_ID_EX_LNREG <= imm_val;
    inst_ID_EX_LNREG <= inst_IF_ID_REGLN;
    -- Enforce x0 = 0
    regs(0) <= (others => '0');

end Behavioral;