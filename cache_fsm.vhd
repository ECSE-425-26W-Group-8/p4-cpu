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
        WRITE_TO_MEM, REQ_MEM,
        MEM_TO_CACHE_WRITE
    );

    signal state, next_state : state_t;

begin
    process(clk, reset)
    begin
        if reset = '1' then
            state <= IDLE;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    process(state, s_read, s_write, hit, clean_miss, dirty_miss, m_waitrequest)
        variable req_vec: std_logic_vector(1 downto 0);
        variable miss_vec: std_logic_vector(2 downto 0);
    begin
        req_vec:= s_read & s_write; -- "10" read, "01" write
        miss_vec:= hit & clean_miss & dirty_miss; -- "100" hit, "010" clean, "001" dirty
        -- Defaults
        next_state    <= state;
        s_waitrequest <= '0';
        m_read        <= '0';
        m_write       <= '0';
        writeback     <= '0';
        data_we       <= '0';
        set_dirty     <= '0';

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
                s_waitrequest <= '1';
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
                s_waitrequest <= '1';
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
                s_waitrequest <= '0';
                next_state <= IDLE;

            when WRITE_DATA =>
                data_we   <= '1';
                set_dirty <= '1';
                s_waitrequest <= '0';
                next_state <= IDLE;

            when WRITE_TO_MEM =>
                m_write <= '1';
                writeback <= '1';
                s_waitrequest <= '1';
                case m_waitrequest is
                    when '0' =>
                        next_state <= REQ_MEM;
                    when others =>
                        next_state <= WRITE_TO_MEM;
                end case;

            when REQ_MEM =>
                m_read <= '1';
                s_waitrequest <= '1';
                case m_waitrequest is
                    when '0' =>
                        next_state <= MEM_TO_CACHE_WRITE;  
                    when others =>
                        next_state <= REQ_MEM;
                end case;

            when MEM_TO_CACHE_WRITE =>
                data_we <= '1';
                s_waitrequest <= '1';
                case req_vec is
                    when "10" =>
                        next_state <= READ_DATA;
                    when "01" =>
                        next_state <= WRITE_DATA;
                    when others =>
                        next_state <= IDLE;  -- not sure if we need this ??? ( did not draw in diagram)
                end case;

            when others =>
                next_state <= IDLE; --  not sure if we need this???

        end case;
    end process;

end architecture rtl;
