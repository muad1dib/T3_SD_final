library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity deserializador is
    Port (
        clock_100KHz   : in  STD_LOGIC;   
        reset          : in  STD_LOGIC;   
        data_in        : in  STD_LOGIC;   
        write_in       : in  STD_LOGIC;   
        ack_in         : in  STD_LOGIC;   
        data_out       : out STD_LOGIC_VECTOR(7 downto 0); 
        data_ready     : out STD_LOGIC;   
        status_out     : out STD_LOGIC    
    );
end deserializador;

architecture Behavioral of deserializador is
    signal shift_reg : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal bit_counter : integer range 0 to 7 := 0;
    
    type state_type is (IDLE, RECEIVING, BYTE_READY, WAIT_ACK);
    signal state : state_type := IDLE;
    
begin
    process(clock_100KHz, reset)
    begin 
        if reset = '1' then
            shift_reg <= (others => '0');
            bit_counter <= 0;
            data_out <= (others => '0');
            data_ready <= '0';
            status_out <= '0';
            state <= IDLE;
            
        elsif rising_edge(clock_100KHz) then
            case state is

                when IDLE =>
                    status_out <= '0';
                    data_ready <= '0';
                    if write_in = '1' then
                        shift_reg <= shift_reg(6 downto 0) & data_in;
                        bit_counter <= 1;  
                        state <= RECEIVING;
                    end if;

                when RECEIVING =>
                    status_out <= '1';  
                    if write_in = '1' then
                        shift_reg <= shift_reg(6 downto 0) & data_in;
                        if bit_counter = 7 then 
                            state <= BYTE_READY;
                        else
                            bit_counter <= bit_counter + 1;
                        end if;
                    end if;
                    
                when BYTE_READY =>
                    data_out <= shift_reg;
                    status_out <= '1';
                    data_ready <= '1';
                    state <= WAIT_ACK;        
                
                when WAIT_ACK =>
                    status_out <= '1';
                    if ack_in = '1' then
                        shift_reg <= (others => '0');
                        bit_counter <= 0;
                        data_ready <= '0';
                        state <= IDLE;
                    end if;
            end case;
        end if;
    end process;
end Behavioral;
