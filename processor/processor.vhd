-- =============================================================================
-- Group 8: RISC-V 5-Stage Pipelined Processor (RV32I + RV32M subset)
-- ECSE 425 W26
--
-- This file is the top-level structural entity.  It does NOT contain any
-- datapath computation; all computation lives in the sub-components.
--
-- Responsibilities:
--   1. Instantiate the five pipeline stages and the hazard detection unit.
--   2. Hold and update the four inter-stage pipeline registers (IF/ID, ID/EX,
--      EX/MEM, MEM/WB) in a single clocked process.
--   3. Implement stall logic (freeze IF/ID, insert NOP into ID/EX).
--   4. Implement flush logic (3-cycle branch/jump penalty: flush IF/ID, ID/EX,
--      EX/MEM when exmem_branch_taken is asserted).
--
-- Signal naming:
--   if_*, id_*, ex_*, mem_*, wb_*  : combinational outputs of each stage
--   ifid_*, idex_*, exmem_*, memwb_*: pipeline register values (clocked)
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity processor is
port(
    clk   : in std_logic;
    reset : in std_logic
);
end processor;

architecture Behavioral of processor is

    -- =========================================================================
    -- NOP instruction: addi x0, x0, 0
    -- =========================================================================
    constant NOP : std_logic_vector(31 downto 0) := x"00000013";

    -- =========================================================================
    -- Component declarations
    -- =========================================================================

    component InstructionFetch is
    port(
        reset               : in  std_logic;
        clk                 : in  std_logic;
        stall               : in  std_logic;
        branchTake_EX_IF_LN : in  std_logic;
        result_EX_IF_REGLN  : in  std_logic_vector(31 downto 0);
        pc_IF_ID_LNREG      : out std_logic_vector(31 downto 0);
        npc_IF_ID_LNREG     : out std_logic_vector(31 downto 0);
        inst_IF_ID_LNREG    : out std_logic_vector(31 downto 0)
    );
    end component;

    component ID is
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
    end component;

    component EX is
    port(
        -- Data inputs
        pc_ID_EX_REGLN         : in  std_logic_vector(31 downto 0);
        npc_ID_EX_REGLN          : in  std_logic_vector(31 downto 0);
        op1_ID_EX_REGLN          : in  std_logic_vector(31 downto 0);
        op2_ID_EX_REGLN          : in  std_logic_vector(31 downto 0);
        imm_ID_EX_REGLN          : in  std_logic_vector(31 downto 0);
        inst_ID_EX_REGLN         : in  std_logic_vector(31 downto 0);
        -- Control inputs
        alu_src		: in std_logic; 	-- 1 for imm, 0 for registers
        alu_op 		: in std_logic_vector(3 downto 0); -- ALU operations
        branch		: in std_logic; -- control flow
        jump		: in std_logic; -- control flow
        
        mem_read_in		: in std_logic; -- mem access
        mem_write_in	: in std_logic; -- mem access
        reg_write_in	: in std_logic; -- write to reg
        wb_sel_in		: in std_logic_vector(1 downto 0); --what to write back
        -- Data outputs
        result_EX_MEM_LNREG      : out std_logic_vector(31 downto 0);
        op2_EX_MEM_LNREG         : out std_logic_vector(31 downto 0);
        npc_EX_MEM_LNREG         : out std_logic_vector(31 downto 0);
        pc_EX_MEM_LNREG         : out std_logic_vector(31 downto 0);
        inst_EX_MEM_LNREG        : out std_logic_vector(31 downto 0);
        branch_taken_EX_MEM_LNREG : out std_logic;
        -- Control outputs
        branch_out		: out std_logic; -- control flow
        jump_out		: out std_logic; -- control flow
        mem_read_out	: out std_logic; -- mem access
        mem_write_out	: out std_logic; -- mem access
        reg_write_out	: out std_logic; -- write to reg
        wb_sel_out		: out std_logic_vector(1 downto 0) --what to write back
    );
    end component;

    component MEM is
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

        mem_read_EX_MEM_REGLN   : in  std_logic;
        mem_write_EX_MEM_REGLN  : in  std_logic;

        reg_write_EX_MEM_REGLN  : in  std_logic;
        reg_write_MEM_WB_LNREG  : out std_logic;
        wb_sel_EX_MEM_REGLN     : in std_logic_vector(1 downto 0); 
        wb_sel_MEM_WB_LNREG      : out std_logic_vector(1 downto 0);

        branch_EX_MEM_REGLN     : in std_logic;
        branch_MEM_WB_LNREG     : out std_logic;
        jump_EX_MEM_REGLN       : in std_logic;
        jump_MEM_WB_LNREG       : out std_logic
        );
    end component;

    component WB is
    port(
        data_MEM_WB_REGLN      : in  std_logic_vector(31 downto 0);
        result_MEM_WB_REGLN    : in  std_logic_vector(31 downto 0);
        pc_MEM_WB_REGLN        : in  std_logic_vector(31 downto 0);
        npc_MEM_WB_REGLN       : in  std_logic_vector(31 downto 0);
        reg_write_MEM_WB_REGLN : in  std_logic;
        wb_sel_MEM_WB_REGLN    : in  std_logic_vector(1 downto 0);
        branch_MEM_WB_REGLN    : in  std_logic;
        jump_MEM_WB_REGLN      : in  std_logic;
        data_WB_ID_LN          : out std_logic_vector(31 downto 0);
        reg_write_WB_ID_LN     : out std_logic
    );
    end component;

    component hazard_detection is
    port(
        rs1_ID       : in  std_logic_vector(4 downto 0);
        rs2_ID       : in  std_logic_vector(4 downto 0);
        opcode_ID    : in  std_logic_vector(6 downto 0);
        rd_EX        : in  std_logic_vector(4 downto 0);
        regWrite_EX  : in  std_logic;
        rd_MEM       : in  std_logic_vector(4 downto 0);
        regWrite_MEM : in  std_logic;
        rd_WB        : in std_logic_vector(4 downto 0);
        regWrite_WB  : in std_logic;
        stall        : out std_logic
    );
    end component;

    -- =========================================================================
    -- Combinational wires: unregistered outputs of each stage
    -- =========================================================================

    -- IF stage outputs
    signal if_pc   : std_logic_vector(31 downto 0);
    signal if_npc  : std_logic_vector(31 downto 0);
    signal if_inst : std_logic_vector(31 downto 0);

    -- ID stage outputs (data)
    signal id_pc    : std_logic_vector(31 downto 0);
    signal id_npc   : std_logic_vector(31 downto 0);
    signal id_op1   : std_logic_vector(31 downto 0);
    signal id_op2   : std_logic_vector(31 downto 0);
    signal id_imm   : std_logic_vector(31 downto 0);
    signal id_inst  : std_logic_vector(31 downto 0);

    -- ID stage outputs (control)
    signal id_alu_src   : std_logic;
    signal id_alu_op    : std_logic_vector(3 downto 0);
    signal id_mem_read  : std_logic;
    signal id_mem_write : std_logic;
    signal id_reg_write : std_logic;
    signal id_branch    : std_logic;
    signal id_jump      : std_logic;
    signal id_wb_sel    : std_logic_vector(1 downto 0);

    -- EX stage outputs (data)
    signal ex_result      : std_logic_vector(31 downto 0);
    signal ex_op2         : std_logic_vector(31 downto 0);
    signal ex_pc          : std_logic_vector(31 downto 0);
    signal ex_npc         : std_logic_vector(31 downto 0);
    signal ex_inst        : std_logic_vector(31 downto 0);
    -- EX stage outputs (control)
    signal ex_branch_taken : std_logic;
    signal ex_mem_read    : std_logic;
    signal ex_mem_write   : std_logic;
    signal ex_reg_write   : std_logic;
    signal ex_branch      : std_logic;
    signal ex_jump        : std_logic;
    signal ex_wb_sel      : std_logic_vector(1 downto 0);

    -- MEM stage outputs (data)
    signal mem_data          : std_logic_vector(31 downto 0);
    signal mem_result        : std_logic_vector(31 downto 0);
    signal mem_pc            : std_logic_vector(31 downto 0);
    signal mem_npc           : std_logic_vector(31 downto 0);
    signal mem_inst          : std_logic_vector(31 downto 0);
    -- MEM stage outputs (control)
    signal mem_reg_write : std_logic;
    signal mem_wb_sel    : std_logic_vector(1 downto 0);
    signal mem_branch      : std_logic;
    signal mem_jump        : std_logic;
    -- WB stage outputs
    signal wb_data      : std_logic_vector(31 downto 0);
    signal wb_regwrite  : std_logic;

    -- =========================================================================
    -- Pipeline register signals (clocked, updated in pipeline_regs process)
    -- =========================================================================

    -- IF/ID register
    signal ifid_pc   : std_logic_vector(31 downto 0) := (others => '0');
    signal ifid_npc  : std_logic_vector(31 downto 0) := (others => '0');
    signal ifid_inst : std_logic_vector(31 downto 0) := NOP;

    -- ID/EX register (data)
    signal idex_pc   : std_logic_vector(31 downto 0) := (others => '0');
    signal idex_npc  : std_logic_vector(31 downto 0) := (others => '0');
    signal idex_op1  : std_logic_vector(31 downto 0) := (others => '0');
    signal idex_op2  : std_logic_vector(31 downto 0) := (others => '0');
    signal idex_imm  : std_logic_vector(31 downto 0) := (others => '0');
    signal idex_inst : std_logic_vector(31 downto 0) := NOP;
    -- ID/EX register (control)
    signal idex_alu_src   : std_logic := '0';
    signal idex_alu_op    : std_logic_vector(3 downto 0) := (others => '0');
    signal idex_mem_read  : std_logic := '0';
    signal idex_mem_write : std_logic := '0';
    signal idex_reg_write : std_logic := '0';
    signal idex_branch    : std_logic := '0';
    signal idex_jump      : std_logic := '0';
    signal idex_wb_sel    : std_logic_vector(1 downto 0) := (others => '0');

    -- EX/MEM register (data)
    signal exmem_result : std_logic_vector(31 downto 0) := (others => '0');
    signal exmem_op2    : std_logic_vector(31 downto 0) := (others => '0');
    signal exmem_pc     : std_logic_vector(31 downto 0) := (others => '0');
    signal exmem_npc    : std_logic_vector(31 downto 0) := (others => '0');
    signal exmem_inst   : std_logic_vector(31 downto 0) := NOP;
    -- EX/MEM register (control)
    signal exmem_branch_taken : std_logic := '0';
    signal exmem_mem_read    : std_logic := '0';
    signal exmem_mem_write   : std_logic := '0';
    signal exmem_reg_write   : std_logic := '0';
    signal exmem_branch      : std_logic := '0';
    signal exmem_jump        : std_logic := '0';
    signal exmem_wb_sel      : std_logic_vector(1 downto 0) := (others => '0');

    -- MEM/WB register (data)
    signal memwb_data   : std_logic_vector(31 downto 0) := (others => '0');
    signal memwb_result : std_logic_vector(31 downto 0) := (others => '0');
    signal memwb_pc    : std_logic_vector(31 downto 0) := (others => '0');
    signal memwb_npc    : std_logic_vector(31 downto 0) := (others => '0');
    signal memwb_inst   : std_logic_vector(31 downto 0) := NOP;
    -- MEM/WB register (control)
    signal memwb_reg_write : std_logic := '0';
    signal memwb_wb_sel    : std_logic_vector(1 downto 0) := (others => '0');
    signal memwb_branch    : std_logic := '0';
    signal memwb_jump      : std_logic := '0';

    -- =========================================================================
    -- Instruction Decode input signal to account for nop insertion while stalling
    -- =========================================================================
    signal idin_pc   : std_logic_vector(31 downto 0) := (others => '0');
    signal idin_npc  : std_logic_vector(31 downto 0) := (others => '0');
    signal idin_inst : std_logic_vector(31 downto 0) := NOP;
    -- =========================================================================
    -- Hazard and flush control
    -- =========================================================================
    signal stall        : std_logic := '0';
    signal branch_flush : std_logic := '0';

begin

    -- =========================================================================
    -- Flush signal: assert on the cycle exmem_branch_taken or exmem_jump is '1'
    -- (3-cycle penalty: flushes IF/ID, ID/EX, and EX/MEM on that cycle)
    -- =========================================================================
    branch_flush <= exmem_branch_taken or exmem_jump;

    -- =========================================================================
    -- Component instantiations
    -- =========================================================================

    -- --- IF Stage ---
    if_stage : InstructionFetch port map(
        reset               => reset,
        clk                 => clk,
        stall               => stall,
        branchTake_EX_IF_LN => exmem_branch_taken,
        result_EX_IF_REGLN  => exmem_result,
        pc_IF_ID_LNREG      => if_pc,
        npc_IF_ID_LNREG     => if_npc,
        inst_IF_ID_LNREG    => if_inst
    );

    -- --- ID Stage ---
    id_stage : ID port map(
        clk               => clk,
        pc_IF_ID_REGLN    => idin_pc,
        npc_IF_ID_REGLN   => idin_npc,
        inst_IF_ID_REGLN  => idin_inst,
        pc_ID_EX_LNREG    => id_pc,
        npc_ID_EX_LNREG   => id_npc,
        op1_ID_EX_LNREG   => id_op1,
        op2_ID_EX_LNREG   => id_op2,
        imm_ID_EX_LNREG   => id_imm,
        inst_ID_EX_LNREG  => id_inst,
        reg_write_WB_ID_LN => wb_regwrite,
        data_WB_ID_LN     => wb_data,
        inst_MEM_WB_REGLN => memwb_inst,
        alu_src           => id_alu_src,
        alu_op            => id_alu_op,
        mem_read          => id_mem_read,
        mem_write         => id_mem_write,
        reg_write         => id_reg_write,
        branch            => id_branch,
        jump              => id_jump,
        wb_sel            => id_wb_sel
    );

    -- --- EX Stage ---
    ex_stage : EX port map(
        pc_ID_EX_REGLN         => idex_pc,
        npc_ID_EX_REGLN          => idex_npc, -- missing from EX
        op1_ID_EX_REGLN          => idex_op1,
        op2_ID_EX_REGLN          => idex_op2,
        imm_ID_EX_REGLN          => idex_imm,
        inst_ID_EX_REGLN         => idex_inst,
        alu_src                  => idex_alu_src,
        alu_op                   => idex_alu_op,
        branch                   => idex_branch,
        jump                     => idex_jump,
        mem_read_in              => idex_mem_read,
        mem_write_in             => idex_mem_write,
        reg_write_in             => idex_reg_write,
        wb_sel_in                => idex_wb_sel,
        branch_taken_EX_MEM_LNREG=> ex_branch_taken,
        result_EX_MEM_LNREG      => ex_result,
        op2_EX_MEM_LNREG     => ex_op2,
        pc_EX_MEM_LNREG         => ex_pc,
        npc_EX_MEM_LNREG         => ex_npc,
        inst_EX_MEM_LNREG        => ex_inst,
        mem_read_out             => ex_mem_read,
        mem_write_out            => ex_mem_write,
        reg_write_out            => ex_reg_write,
        branch_out               => ex_branch,
        jump_out                 => ex_jump,
        wb_sel_out               => ex_wb_sel
    );

    -- --- MEM Stage ---
    mem_stage : MEM port map(
        clk                     => clk,
        result_EX_MEM_REGLN     => exmem_result,
        op2_EX_MEM_REGLN        => exmem_op2,
        pc_EX_MEM_REGLN         => exmem_pc,
        inst_EX_MEM_REGLN       => exmem_inst,
        npc_EX_MEM_REGLN        => exmem_npc,
        mem_read_EX_MEM_REGLN   => exmem_mem_read,
        mem_write_EX_MEM_REGLN  => exmem_mem_write,
        reg_write_EX_MEM_REGLN  => exmem_reg_write,
        wb_sel_EX_MEM_REGLN     => exmem_wb_sel,
        branch_EX_MEM_REGLN     => exmem_branch,
        jump_EX_MEM_REGLN       => exmem_jump,
        data_MEM_WB_LNREG       => mem_data,
        result_MEM_WB_LNREG     => mem_result,
        inst_MEM_WB_LNREG       => mem_inst,
        pc_MEM_WB_LNREG         => mem_pc,
        npc_MEM_WB_LNREG        => mem_npc,
        reg_write_MEM_WB_LNREG  => mem_reg_write,
        wb_sel_MEM_WB_LNREG     => mem_wb_sel,
        branch_MEM_WB_LNREG     => mem_branch,
        jump_MEM_WB_LNREG       => mem_jump
    );

    -- --- WB Stage ---
    wb_stage : WB port map(
        data_MEM_WB_REGLN      => memwb_data,
        result_MEM_WB_REGLN    => memwb_result,
        pc_MEM_WB_REGLN        => memwb_pc,
        npc_MEM_WB_REGLN       => memwb_npc,
        reg_write_MEM_WB_REGLN => memwb_reg_write,
        wb_sel_MEM_WB_REGLN    => memwb_wb_sel,
        branch_MEM_WB_REGLN    => memwb_branch,
        jump_MEM_WB_REGLN      => memwb_jump,
        data_WB_ID_LN          => wb_data,
        reg_write_WB_ID_LN     => wb_regwrite
    );

    -- --- Hazard Detection ---
    hazard_unit : hazard_detection port map(
        rs1_ID       => ifid_inst(19 downto 15),
        rs2_ID       => ifid_inst(24 downto 20),
        opcode_ID    => ifid_inst(6  downto  0),
        rd_EX        => idex_inst(11 downto  7),
        regWrite_EX  => idex_reg_write,
        rd_MEM       => exmem_inst(11 downto 7),
        rd_WB        => memwb_inst(11 downto 7),
        regWrite_WB  => memwb_reg_write,
        regWrite_MEM => exmem_reg_write,
        stall        => stall
    );

    -- --- input to Instruction decode with stalls ---
    idin_inst <= NOP when stall = '1' else ifid_inst;
    idin_pc   <= (others => '0') when stall = '1' else ifid_pc;
    idin_npc  <= (others => '0') when stall = '1' else ifid_npc;

    -- =========================================================================
    -- Pipeline register update process
    -- =========================================================================
    pipeline_regs : process(clk, reset)
    begin
        if reset = '1' then
            -- IF/ID
            ifid_pc   <= (others => '0');
            ifid_npc  <= (others => '0');
            ifid_inst <= NOP;
            -- ID/EX
            idex_pc        <= (others => '0');
            idex_npc       <= (others => '0');
            idex_op1       <= (others => '0');
            idex_op2       <= (others => '0');
            idex_imm       <= (others => '0');
            idex_inst      <= NOP;
            idex_alu_src   <= '0';
            idex_alu_op    <= (others => '0');
            idex_mem_read  <= '0';
            idex_mem_write <= '0';
            idex_reg_write <= '0';
            idex_branch    <= '0';
            idex_jump      <= '0';
            idex_wb_sel    <= (others => '0');
            -- EX/MEM
            exmem_result      <= (others => '0');
            exmem_op2         <= (others => '0');
            exmem_pc          <= (others => '0');
            exmem_npc         <= (others => '0');
            exmem_inst        <= NOP;
            exmem_branch_taken <= '0';
            exmem_mem_read    <= '0';
            exmem_mem_write   <= '0';
            exmem_reg_write   <= '0';
            exmem_branch      <= '0';
            exmem_jump        <= '0';
            exmem_wb_sel      <= (others => '0');
            -- MEM/WB
            memwb_data      <= (others => '0');
            memwb_result    <= (others => '0');
            memwb_pc        <= (others => '0');
            memwb_npc       <= (others => '0');
            memwb_inst      <= NOP;
            memwb_reg_write <= '0';
            memwb_wb_sel    <= (others => '0');
            mem_branch      <= '0';
            mem_jump        <= '0';

        elsif rising_edge(clk) then

            -- ─── MEM/WB: always update ────────────────────────────────────────
            memwb_data      <= mem_data;
            memwb_result    <= mem_result;
            memwb_pc        <= mem_pc;
            memwb_npc       <= mem_npc;
            memwb_inst      <= mem_inst;
            memwb_reg_write <= mem_reg_write;
            memwb_wb_sel    <= mem_wb_sel;

            -- ─── EX/MEM: flush on branch_flush, else normal ───────────────────
            if branch_flush = '1' then
                exmem_result      <= (others => '0');
                exmem_op2         <= (others => '0');
                exmem_pc          <= (others => '0');
                exmem_npc         <= (others => '0');
                exmem_inst        <= NOP;
                exmem_branch_taken <= '0';
                exmem_mem_read    <= '0';
                exmem_mem_write   <= '0';
                exmem_reg_write   <= '0';
                exmem_branch      <= '0';
                exmem_jump        <= '0';
                exmem_wb_sel      <= (others => '0');
            else
                exmem_result      <= ex_result;
                exmem_op2         <= ex_op2;
                exmem_pc          <= ex_pc;
                exmem_npc         <= ex_npc;
                exmem_inst        <= ex_inst;
                exmem_branch_taken <= ex_branch_taken;
                exmem_mem_read    <= ex_mem_read;
                exmem_mem_write   <= ex_mem_write;
                exmem_reg_write   <= ex_reg_write;
                exmem_branch      <= ex_branch;
                exmem_jump        <= ex_jump;
                exmem_wb_sel      <= ex_wb_sel;
            end if;

            -- ─── ID/EX: NOP on stall or branch_flush, else normal ─────────────
            if stall = '1' or branch_flush = '1' then
                idex_pc        <= (others => '0');
                idex_npc       <= (others => '0');
                idex_op1       <= (others => '0');
                idex_op2       <= (others => '0');
                idex_imm       <= (others => '0');
                idex_inst      <= NOP;
                idex_alu_src   <= '0';
                idex_alu_op    <= (others => '0');
                idex_mem_read  <= '0';
                idex_mem_write <= '0';
                idex_reg_write <= '0';
                idex_branch    <= '0';
                idex_jump      <= '0';
                idex_wb_sel    <= (others => '0');
            else
                idex_pc        <= ifid_pc;
                idex_npc       <= ifid_npc;
                idex_op1       <= id_op1;
                idex_op2       <= id_op2;
                idex_imm       <= id_imm;
                idex_inst      <= ifid_inst;
                idex_alu_src   <= id_alu_src;
                idex_alu_op    <= id_alu_op;
                idex_mem_read  <= id_mem_read;
                idex_mem_write <= id_mem_write;
                idex_reg_write <= id_reg_write;
                idex_branch    <= id_branch;
                idex_jump      <= id_jump;
                idex_wb_sel    <= id_wb_sel;
            end if;

            -- ─── IF/ID: flush on branch_flush; freeze on stall; else normal ───
            -- stall='1' and branch_flush='0' → no assignment → register holds
            if branch_flush = '1' then
                ifid_inst <= NOP;
                ifid_pc   <= (others => '0');
                ifid_npc  <= (others => '0');
            elsif stall = '0' then
                ifid_inst <= if_inst;
                ifid_pc   <= if_pc;
                ifid_npc  <= if_npc;
            end if;

        end if;
    end process pipeline_regs;

end Behavioral;
