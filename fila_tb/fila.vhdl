library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fila is
    Port (
        clock_10KHz    : in  STD_LOGIC;                     
        reset          : in  STD_LOGIC;                     
        data_in        : in  STD_LOGIC_VECTOR(7 downto 0);  
        enqueue_in     : in  STD_LOGIC;                    
        dequeue_in     : in  STD_LOGIC;                     
        data_out       : out STD_LOGIC_VECTOR(7 downto 0);  
        len_out        : out STD_LOGIC_VECTOR(7 downto 0)   
    );
end fila;

architecture Behavioral of fila is
    
    type fila_memory is array (0 to 7) of STD_LOGIC_VECTOR(7 downto 0);
    signal memory : fila_memory := (others => (others => '0'));
    
    signal head_ptr : integer range 0 to 7 := 0;  
    signal tail_ptr : integer range 0 to 7 := 0;  
    signal count    : integer range 0 to 8 := 0;  
    
begin
    process(clock_10KHz, reset)
    begin
        if reset = '1' then
            memory <= (others => (others => '0'));
            head_ptr <= 0;
            tail_ptr <= 0;
            count <= 0;
            data_out <= (others => '0');  -- Reset explícito da saída
            
        elsif rising_edge(clock_10KHz) then
            
            if dequeue_in = '1' and enqueue_in = '1' and count > 0 and count < 8 then
                data_out <= memory(head_ptr); 
                memory(tail_ptr) <= data_in;  
                
                if head_ptr = 7 then
                    head_ptr <= 0;
                else
                    head_ptr <= head_ptr + 1;
                end if;
                
                if tail_ptr = 7 then
                    tail_ptr <= 0;
                else
                    tail_ptr <= tail_ptr + 1;
                end if;
                
            elsif dequeue_in = '1' and count > 0 then
                data_out <= memory(head_ptr);
                
                if head_ptr = 7 then
                    head_ptr <= 0;
                else
                    head_ptr <= head_ptr + 1;
                end if;
                
                count <= count - 1;
                
            elsif enqueue_in = '1' and count < 8 then
                memory(tail_ptr) <= data_in;
                
                if tail_ptr = 7 then
                    tail_ptr <= 0;
                else
                    tail_ptr <= tail_ptr + 1;
                end if;
                
                count <= count + 1;
            end if;
            
            if dequeue_in = '0' and count > 0 then
                data_out <= memory(head_ptr);
            end if;
            
        end if;
    end process;
    
    len_out <= std_logic_vector(to_unsigned(count, 8));
    
end Behavioral;
