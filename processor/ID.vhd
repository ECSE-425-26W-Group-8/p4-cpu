library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- compiled ok

entity ID is
port(
    clk: in std_logic;
	pc_IF_ID_REGLN 	: in std_logic_vector(31 downto 0);
	npc_IF_ID_REGLN 	: in std_logic_vector(31 downto 0);
	inst_IF_ID_REGLN 	: in std_logic_vector(31 downto 0);
	pc_ID_EX_LNREG 	: out std_logic_vector(31 downto 0);
	npc_ID_EX_LNREG 	: out std_logic_vector(31 downto 0);
	op1_ID_EX_LNREG		: out std_logic_vector(31 downto 0);
	op2_ID_EX_LNREG 	: out std_logic_vector(31 downto 0);
	imm_ID_EX_LNREG 	: out std_logic_vector(31 downto 0);
	inst_ID_EX_LNREG 	: out std_logic_vector(31 downto 0);
	-- inst_MEM_ID_REGLN	: out std_logic_vector(31 downto 0);
    reg_write_WB_ID_LN  : in STD_LOGIC;
	data_WB_ID_LN		: in std_logic_vector(31 downto 0);
    inst_MEM_WB_REGLN : in std_logic_vector(31 downto 0);
    -- for control process
	alu_src: out std_logic; -- tell rest of CPU to use imm or reg
	alu_op : out std_logic_vector(3 downto 0); -- what ALU does
	mem_read: out std_logic; -- mem access
	mem_write: out std_logic; -- mem access
	reg_write: out std_logic; -- write to reg
	branch: out std_logic; -- control flow
	jump: out std_logic; -- control flow
	wb_sel: out std_logic_vector(1 downto 0) --what to write back

); 
end ID;

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

    -- clock the register write process
    process(clk)
        variable wb_opcode: std_logic_vector(6 downto 0);
        variable wb_rd_int: integer;
    begin
        if rising_edge(clk) then
            wb_opcode := inst_MEM_WB_REGLN(6 downto 0);
            wb_rd_int := to_integer(unsigned(wb_rd));
        -- write back for instructions that write rd (so no store/branch)
            if wb_rd_int /= 0 and reg_write_WB_ID_LN = '1' then
                regs(wb_rd_int) <= data_WB_ID_LN;
            end if;
        end if;
    end process;
    -- x0 always stay zero
    regs(0) <= (others => '0');

    -- Read register operands
    op1_val <= regs(to_integer(unsigned(rs1)));
    op2_val <= regs(to_integer(unsigned(rs2)));
    -- Immediate generator (not from registers)
    process(inst_IF_ID_REGLN, opcode)
        variable imm_i : signed(31 downto 0);
        variable imm_s : signed(31 downto 0);
        variable imm_b : signed(31 downto 0);
        variable imm_j : signed(31 downto 0);
        variable imm_u : std_logic_vector(31 downto 0);
    begin
        imm_val <= (others => '0');

        imm_i := (others => '0');
        imm_s := (others => '0');
        imm_b := (others => '0');
        imm_j := (others => '0');
        imm_u := (others => '0');

        case opcode is
            -- R-type: no immediate
            when "0110011" =>
                imm_val <= (others => '0');

            -- I-type immediate
            when "0010011" | "0000011" | "1100111" =>
                imm_i := resize(signed(inst_IF_ID_REGLN(31 downto 20)), 32);
                imm_val <= std_logic_vector(imm_i);

            -- S-type immediate
            when "0100011" =>
                imm_s := resize(
                    signed(std_logic_vector'(
                        inst_IF_ID_REGLN(31 downto 25) &
                        inst_IF_ID_REGLN(11 downto 7)
                    )),
                    32
                );
                imm_val <= std_logic_vector(imm_s);

            -- B-type immediate
            when "1100011" =>
                imm_b := resize(
                    signed(std_logic_vector'(
                        inst_IF_ID_REGLN(31) &
                        inst_IF_ID_REGLN(7) &
                        inst_IF_ID_REGLN(30 downto 25) &
                        inst_IF_ID_REGLN(11 downto 8) &
                        '0'
                    )),
                    32
                );
                imm_val <= std_logic_vector(imm_b);

            -- U-type immediate
            when "0110111" | "0010111" =>
                imm_u := inst_IF_ID_REGLN(31 downto 12) & "000000000000";
                imm_val <= imm_u;

            -- J-type immediate
            when "1101111" =>
                imm_j := resize(
                    signed(std_logic_vector'(
                        inst_IF_ID_REGLN(31) &
                        inst_IF_ID_REGLN(19 downto 12) &
                        inst_IF_ID_REGLN(20) &
                        inst_IF_ID_REGLN(30 downto 21) &
                        '0'
                    )),
                    32
                );
                imm_val <= std_logic_vector(imm_j);

            when others =>
                imm_val <= (others => '0');
        end case;
    end process;
	-- control process
	process(opcode, funct3, funct7)
	begin
    -- defaults 
    alu_src <= '0';
    alu_op <= "0000";
    mem_read <= '0';
    mem_write <= '0';
    reg_write <= '0';
    branch <= '0';
    jump <= '0';
    wb_sel <= "00";
    case opcode is
        -- R-TYPE (add, sub, mul, and, or) use rs1 rs2 for alu inputs
        when "0110011" =>
            reg_write <= '1'; -- write to rd
            alu_src <= '0'; -- 2nd operandis from reg
            wb_sel <= "00"; -- write back ALU result
            case funct3 is --for add sub mul
                when "000" => -- func3 is 0x00
                    if funct7 = "0000000" then  --0x00
                        alu_op <= "0000"; -- ADD rs1+rs2
                    elsif funct7 = "0100000" then --0x20
                        alu_op <= "0001"; -- SUB rs1-rs2
                    elsif funct7 = "0000001" then --0x01
                        alu_op <= "0010"; -- MUL rs1*rs2
                    end if;
                when "111" => -- func3 is 0x7
                    alu_op <= "0011"; -- AND
                when "110" => -- func3 is 0x6
                    alu_op <= "0100"; -- OR
				when "001" => -- func3 is 0x1
					alu_op <= "1000"; -- sll log shift left
				when "101" => -- func3 is 0x5
					if funct7 = "0000000" then -- 0x00
						alu_op <= "0110";	-- srl
					else	-- funct7 is 0x20
						alu_op <= "0111";	-- sra
					end if;
                when others =>
                    null;
            end case;
        -- I-TYPE (addi, andi, ori, xori) use rs1 and immVal
        when "0010011" =>
            reg_write <= '1'; --write result to rd
            alu_src <= '1'; -- 2nd operand is from immval
            wb_sel <= "00";
            case funct3 is
                when "000" => alu_op <= "0000"; -- ADDI rs1+imm
                when "111" => alu_op <= "0011"; -- ANDI
                when "110" => alu_op <= "0100"; -- ORI
                when "100" => alu_op <= "0101"; -- XORI
                when others => null;
            end case;
        -- LOAD (lw) addr : rs1 + imm
        when "0000011" =>
            reg_write <= '1';
            alu_src <= '1'; -- use imm
            mem_read <= '1'; -- enable mem read
            wb_sel <= "01"; -- write back memory data
            alu_op <= "0000"; -- use ADD for address calc
        -- STORE (sw) addr: rs1 + imm
        when "0100011" =>
            alu_src <= '1';
            mem_write <= '1'; -- enable mem write; nothing written to rd
            alu_op <= "0000";-- ADD for add calc
        -- BRANCH compare rs1 rs2
        when "1100011" =>
            branch <= '1';
            alu_src <= '0'; -- compare 2 regs
            alu_op <= "0001"; -- SUB for compare
        -- JAL jump link to PC + imm
        when "1101111" =>
            jump <= '1';
            reg_write <= '1';
            wb_sel <= "10"; -- write PC+4
        -- JALR jump and link reg to rs1 + imm
        when "1100111" =>
            jump <= '1';
            reg_write <= '1';
            alu_src <= '1'; -- compute target = rs1 + imm
            wb_sel <= "10"; -- write pc + 4
        -- LUI
        when "0110111" =>
            reg_write <= '1';
            alu_src <= '1';
            wb_sel <= "00";
        when others =>
            null;
    end case;
end process;

    -- Outputs to EX stage
    pc_ID_EX_LNREG <= pc_IF_ID_REGLN;
    npc_ID_EX_LNREG <= npc_IF_ID_REGLN;
    op1_ID_EX_LNREG <= op1_val;
    op2_ID_EX_LNREG <= op2_val;
    imm_ID_EX_LNREG <= imm_val;
    inst_ID_EX_LNREG <= inst_IF_ID_REGLN;
    -- Enforce x0 = 0
    --regs(0) <= (others => '0');

end Behavioral;
