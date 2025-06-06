library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_module is
    Port (
        clk_1MHz : in STD_LOGIC;           
        reset : in STD_LOGIC;              
        data_in : in STD_LOGIC;            
        write_in : in STD_LOGIC;           
        dequeue_in : in STD_LOGIC;        
        data_out : out STD_LOGIC_VECTOR(7 downto 0);  
        len_out : out STD_LOGIC_VECTOR(7 downto 0);   
        status_out : out STD_LOGIC         
    );
end top_module;

architecture Behavioral of top_module is
    
    component deserializador is
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
    end component;
    
    component fifo is
        Port (
            clock_10KHz    : in  STD_LOGIC;
            reset          : in  STD_LOGIC;
            data_in        : in  STD_LOGIC_VECTOR(7 downto 0);
            enqueue_in     : in  STD_LOGIC;
            dequeue_in     : in  STD_LOGIC;
            data_out       : out STD_LOGIC_VECTOR(7 downto 0);
            len_out        : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;
    
    signal clk_100KHz : STD_LOGIC := '0';
    signal clk_10KHz : STD_LOGIC := '0';
    
    signal counter_100k : integer range 0 to 4 := 0;   
    signal counter_10k : integer range 0 to 49 := 0;   
    
    signal deser_data : STD_LOGIC_VECTOR(7 downto 0);
    signal deser_data_ready : STD_LOGIC;
    signal deser_status : STD_LOGIC;
    signal deser_ack : STD_LOGIC;
    
    signal fila_len : STD_LOGIC_VECTOR(7 downto 0);
    signal fila_full : STD_LOGIC;
    signal enqueue_signal : STD_LOGIC;
    
    signal data_ready_sync : STD_LOGIC_VECTOR(2 downto 0) := "000";
    signal data_sync_reg : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal data_captured : STD_LOGIC := '0';
    
    signal ack_sync : STD_LOGIC_VECTOR(2 downto 0) := "000";
    
begin
    
    process(clk_1MHz, reset)
    begin
        if reset = '1' then
            counter_100k <= 0;
            counter_10k <= 0;
            clk_100KHz <= '0';
            clk_10KHz <= '0';
        elsif rising_edge(clk_1MHz) then
            if counter_100k >= 4 then
                counter_100k <= 0;
                clk_100KHz <= not clk_100KHz;
            else
                counter_100k <= counter_100k + 1;
            end if;
            
            if counter_10k >= 49 then
                counter_10k <= 0;
                clk_10KHz <= not clk_10KHz;
            else
                counter_10k <= counter_10k + 1;
            end if;
        end if;
    end process;
    
    deser_inst: deserializador
        port map (
            clock_100KHz => clk_100KHz,
            reset => reset,
            data_in => data_in,
            write_in => write_in,
            ack_in => deser_ack,
            data_out => deser_data,
            data_ready => deser_data_ready,
            status_out => deser_status
        );
    
    fila_inst: fifo
        port map (
            clock_10KHz => clk_10KHz,
            reset => reset,
            data_in => data_sync_reg,
            enqueue_in => enqueue_signal,
            dequeue_in => dequeue_in,
            data_out => data_out,
            len_out => fila_len
        );
    
    fila_full <= '1' when unsigned(fila_len) >= 8 else '0';
    
    process(clk_10KHz, reset)
    begin
        if reset = '1' then
            data_ready_sync <= "000";
            data_sync_reg <= (others => '0');
            enqueue_signal <= '0';
            data_captured <= '0';
        elsif rising_edge(clk_10KHz) then
            data_ready_sync <= data_ready_sync(1 downto 0) & deser_data_ready;
            
            if data_ready_sync(2) = '0' and data_ready_sync(1) = '1' then
                if fila_full = '0' then
                    data_sync_reg <= deser_data;
                    enqueue_signal <= '1';
                    data_captured <= '1';
                else
                    enqueue_signal <= '0';
                    data_captured <= '0';
                end if;
            else
                enqueue_signal <= '0';
            end if;
            
            if ack_sync(2) = '1' then
                data_captured <= '0';
            end if;
        end if;
    end process;
    
    
    process(clk_100KHz, reset)
    begin
        if reset = '1' then
            ack_sync <= "000";
        elsif rising_edge(clk_100KHz) then
            ack_sync <= ack_sync(1 downto 0) & data_captured;
        end if;
    end process;
    
    deser_ack <= ack_sync(2);                     
    len_out <= fila_len;                          
    status_out <= deser_status or fila_full;      

end Behavioral;
