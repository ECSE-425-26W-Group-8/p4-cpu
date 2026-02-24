library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cache_package.all;

entity cache_fsm is
    port(
        clk   : in std_logic;
        reset : in std_logic;

        -- CPU -> FSM
        s_read  : in std_logic;
        s_write : in std_logic;

        -- Internal status signals
        clean_miss : in std_logic;
        dirty_miss : in std_logic;
        hit        : in std_logic;

        -- FSM -> CPU / internal
        s_waitrequest : out std_logic;
        writeback     : out std_logic;
        m_index       : out integer := 0;
        read_byte     : out std_logic;

        -- Memory -> FSM
        m_waitrequest : in std_logic;

        -- FSM -> memory
        m_read  : out std_logic;
        m_write : out std_logic;

        -- FSM -> blocks array
        data_we   : out std_logic;
        set_dirty : out std_logic
    );
end entity cache_fsm;

architecture rtl of cache_fsm is
    -- typedef FSM states:8 states
    type state_t is (
        IDLE, READ_REQ, READ_DATA,
        WRITE_REQ, WRITE_DATA,
        WRITE_TO_MEM, WRITE_TO_MEM_PAUSE, WRITE_TO_MEM_WAIT,
        REQ_MEM, REQ_MEM_PAUSE, REQ_MEM_WAIT,
        MEM_TO_CACHE_WRITE
    );

    signal state, next_state : state_t := IDLE;

    signal fsm_mem_index : integer range 0 to 15 := 0;
    signal fsm_next_mem_index : integer range 0 to 15 := 0;

begin
    process(clk, reset)
    begin
        if reset = '1' then
            state <= IDLE;
            fsm_mem_index <= 0;
        elsif rising_edge(clk) then
            state <= next_state;

            fsm_mem_index <= fsm_next_mem_index;
            -- Increment logic: only when memory is ready ('0')
            -- if (state = WRITE_TO_MEM or state = REQ_MEM) and m_waitrequest = '0' then
            -- if (state = WRITE_TO_MEM or state = REQ_MEM or state = WRITE_TO_MEM_WAIT or state = REQ_MEM_WAIT) and m_waitrequest = '0' then
            --     if fsm_mem_index = 15 then
            --         fsm_mem_index <= 0;
            --     else
            --         fsm_mem_index <= fsm_mem_index + 1;
            --     end if;
            -- -- elsif state /= WRITE_TO_MEM and state /= REQ_MEM then
            -- elsif state /= WRITE_TO_MEM and state /= REQ_MEM and state /= WRITE_TO_MEM_WAIT and state /= REQ_MEM_WAIT then
            --     fsm_mem_index <= 0; -- Reset when not in burst
            -- end if;
        end if;
    end process;

    process(state, s_read, s_write, hit, clean_miss, dirty_miss, m_waitrequest)
        variable req_vec: std_logic_vector(1 downto 0);
        variable miss_vec: std_logic_vector(2 downto 0);
    begin
        req_vec:= s_read & s_write; -- "10" read, "01" write
        miss_vec:= hit & clean_miss & dirty_miss; -- "100" hit, "010" clean, "001" dirty

        case state is
            when IDLE =>
                case req_vec is
                    when "10" => -- read
                        next_state <= READ_REQ;
                    when "01" => -- write
                        next_state <= WRITE_REQ;
                    when others =>
                        next_state <= IDLE;
                end case;  

            when READ_REQ =>
                case miss_vec is
                    when "100" => -- hit
                        next_state <= READ_DATA;
                    when "001" => -- dirty miss
                        next_state <= WRITE_TO_MEM;
                    when "010" => -- clean miss
                        next_state <= REQ_MEM;
                    when others =>
                        next_state <= READ_REQ;
                end case;

            when WRITE_REQ =>
                case miss_vec is
                    when "100" => -- hit
                        next_state <= WRITE_DATA;
                    when "001" => -- dirty miss
                        next_state <= WRITE_TO_MEM;
                    when "010" => -- clean miss
                        next_state <= REQ_MEM;
                    when others =>
                        next_state <= WRITE_REQ;
                end case;

            when READ_DATA =>
                next_state <= IDLE;

            when WRITE_DATA =>
                next_state <= IDLE;

            when WRITE_TO_MEM =>
                if m_waitrequest = '0' then
                    if fsm_mem_index = 15 then
                        next_state <= REQ_MEM;
                    else
                        next_state <= WRITE_TO_MEM_PAUSE;
                    end if;
                else
                    next_state <= WRITE_TO_MEM;
                end if;
                -- if m_waitrequest = '1' and fsm_mem_index = 15 then
                --     next_state <= WRITE_TO_MEM_WAIT;
                    -- next_state <= REQ_MEM;
                -- elsif m_waitrequest <= '1' then
                --     next_state <= WRITE_TO_MEM;
                -- else
                --     next_state <= WRITE_TO_MEM_PAUSE;
                --     -- next_state <= WRITE_TO_MEM_PAUSE;

            when WRITE_TO_MEM_PAUSE =>
                next_state <= WRITE_TO_MEM;

            -- when WRITE_TO_MEM_WAIT =>
            --     if m_waitrequest = '0' then
            --         next_state <= REQ_MEM;
            --     else
            --         next_state <= WRITE_TO_MEM_WAIT;
            --     end if;

            when REQ_MEM =>
                if m_waitrequest = '0' then
                    if fsm_mem_index = 15 then
                        next_state <= MEM_TO_CACHE_WRITE;
                    else
                        next_state <= REQ_MEM_PAUSE;
                    end if;
                else
                    next_state <= REQ_MEM;
                end if;
                -- if m_waitrequest = '0' and fsm_mem_index = 15 then
                --     next_state <= MEM_TO_CACHE_WRITE;
                -- -- if m_waitrequest = '1' and fsm_mem_index = 15 then
                -- --     next_state <= REQ_MEM_WAIT;  
                --     -- next_state <= MEM_TO_CACHE_WRITE;
                -- elsif m_waitrequest = '1' then
                --     next_state <= REQ_MEM;
                -- else
                --     -- next_state <= REQ_MEM;
                --     next_state <= REQ_MEM_PAUSE;
                -- end if;

            when REQ_MEM_PAUSE =>
                next_state <= REQ_MEM;
            

            -- when REQ_MEM_WAIT =>
            --     if m_waitrequest = '0' then
            --         next_state <= MEM_TO_CACHE_WRITE;
            --     else
            --         next_state <= REQ_MEM_WAIT;
            --     end if;

            when MEM_TO_CACHE_WRITE =>
                case req_vec is
                    when "10" =>
                        next_state <= READ_DATA;
                    when "01" =>
                        next_state <= WRITE_DATA;
                    when others =>
                        next_state <= IDLE; 
                end case;
            when others =>
                next_state <= IDLE;
        end case;
    end process;
    -- outputs 
    s_waitrequest <= '1' when state = READ_REQ or state = WRITE_REQ or state = WRITE_TO_MEM or state = REQ_MEM or state = MEM_TO_CACHE_WRITE or state = REQ_MEM_WAIT or state = WRITE_TO_MEM_WAIT or state = WRITE_DATA or state = REQ_MEM_PAUSE or state = WRITE_TO_MEM_PAUSE else '0';
    -- m_read <= '1' when state = REQ_MEM and not (fsm_mem_index = 15 and m_waitrequest = '0') else '0';
    m_read <= '1' when state = REQ_MEM else '0';
    m_write <= '1' when state = WRITE_TO_MEM and not (fsm_mem_index = 15 and m_waitrequest = '0') else '0';
    writeback <= '1' when state = WRITE_TO_MEM or state = WRITE_TO_MEM_WAIT else '0';
    data_we <= '1' when state = WRITE_DATA or state = MEM_TO_CACHE_WRITE else '0';
    set_dirty <= '1' when state = WRITE_DATA else '0';

    read_byte <= '1' when (state = REQ_MEM or state = REQ_MEM_WAIT) and m_waitrequest = '0' else '0';

    m_index <= fsm_mem_index;
    
    fsm_next_mem_index <= fsm_mem_index + 1 when state = REQ_MEM_PAUSE or state = WRITE_TO_MEM_PAUSE else
                          0 when 
                            state /= WRITE_TO_MEM and state /= REQ_MEM and state /= WRITE_TO_MEM_WAIT and state /= REQ_MEM_WAIT
                        else fsm_mem_index;
    -- fsm_next_mem_index <= fsm_mem_index + 1 when 
    --                       (state = WRITE_TO_MEM or state = REQ_MEM or state = WRITE_TO_MEM_WAIT or state = REQ_MEM_WAIT)
    --                       and m_waitrequest = '0'
    --                       and fsm_mem_index < 15
    --                   else 0 when
    --                       state /= WRITE_TO_MEM and state /= REQ_MEM and state /= WRITE_TO_MEM_WAIT and state /= REQ_MEM_WAIT
    --                   else fsm_mem_index;


end architecture rtl;
