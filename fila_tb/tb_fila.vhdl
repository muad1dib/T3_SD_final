library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fila_tb is
end fila_tb;

architecture Behavioral of fila_tb is
    component fila
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
    
    signal clock_10KHz    : STD_LOGIC := '0';
    signal reset          : STD_LOGIC := '0';
    signal data_in        : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal enqueue_in     : STD_LOGIC := '0';
    signal dequeue_in     : STD_LOGIC := '0';
    signal data_out       : STD_LOGIC_VECTOR(7 downto 0);
    signal len_out        : STD_LOGIC_VECTOR(7 downto 0);
    
    constant CLOCK_PERIOD : time := 100 us; -- 10KHz = 100us periodo
    signal sim_finished   : boolean := false;
    
    procedure enqueue(
        signal data  : out STD_LOGIC_VECTOR(7 downto 0);
        signal enq   : out STD_LOGIC;
        value        : in integer
    ) is
    begin
        data <= std_logic_vector(to_unsigned(value, 8));
        enq <= '1';
        wait for CLOCK_PERIOD;
        enq <= '0';
        wait for CLOCK_PERIOD;
    end procedure;
    
    procedure dequeue_and_check_fifo(
        signal deq   : out STD_LOGIC;
        expected     : in integer;
        signal len   : in STD_LOGIC_VECTOR(7 downto 0)
    ) is
    begin
        deq <= '1';
        wait for CLOCK_PERIOD;
        deq <= '0';
        
        assert to_integer(unsigned(data_out)) = expected
            report "ERRO FIFO: Esperado " & integer'image(expected) & 
                   ", obtido " & integer'image(to_integer(unsigned(data_out)))
            severity error;
        
        wait for CLOCK_PERIOD;
    end procedure;
    
    procedure simultaneous_enqueue_dequeue(
        signal data  : out STD_LOGIC_VECTOR(7 downto 0);
        signal enq   : out STD_LOGIC;
        signal deq   : out STD_LOGIC;
        enq_value    : in integer;
        expected_deq : in integer
    ) is
    begin
        data <= std_logic_vector(to_unsigned(enq_value, 8));
        enq <= '1';
        deq <= '1';
        wait for CLOCK_PERIOD;
        enq <= '0';
        deq <= '0';
        
        assert to_integer(unsigned(data_out)) = expected_deq
            report "ERRO operacao simultanea: Esperado " & integer'image(expected_deq) & 
                   ", obtido " & integer'image(to_integer(unsigned(data_out)))
            severity error;
        
        wait for CLOCK_PERIOD;
    end procedure;
    
begin
    DUT: fila
        Port map (
            clock_10KHz => clock_10KHz,
            reset       => reset,
            data_in     => data_in,
            enqueue_in  => enqueue_in,
            dequeue_in  => dequeue_in,
            data_out    => data_out,
            len_out     => len_out
        );
    
    clock_process: process
    begin
        while not sim_finished loop
            clock_10KHz <= '0';
            wait for CLOCK_PERIOD/2;
            clock_10KHz <= '1';
            wait for CLOCK_PERIOD/2;
        end loop;
        wait;
    end process;
    
    test_process: process
        variable data_before_empty : STD_LOGIC_VECTOR(7 downto 0);
    begin
        report "Iniciando teste da FILA FIFO";
        
        reset <= '1';
        wait for 2 * CLOCK_PERIOD;
        reset <= '0';
        wait for CLOCK_PERIOD;
        
        report "Teste 1: Estado inicial";
        assert to_integer(unsigned(len_out)) = 0 
            report "ERRO: Tamanho inicial deveria ser 0" severity error;
        
        report "Teste 2: Comportamento FIFO basico";
        enqueue(data_in, enqueue_in, 10);
        enqueue(data_in, enqueue_in, 20);
        enqueue(data_in, enqueue_in, 30);
        
        dequeue_and_check_fifo(dequeue_in, 10, len_out);
        dequeue_and_check_fifo(dequeue_in, 20, len_out);
        dequeue_and_check_fifo(dequeue_in, 30, len_out);
        
        report "Teste 3: Enchendo a fila";
        for i in 1 to 8 loop
            enqueue(data_in, enqueue_in, i*10);
            assert to_integer(unsigned(len_out)) = i 
                report "ERRO: Tamanho esperado " & integer'image(i) severity error;
        end loop;
        
        data_in <= x"FF";
        enqueue_in <= '1';
        wait for CLOCK_PERIOD;
        enqueue_in <= '0';
        wait for CLOCK_PERIOD;
        
        assert to_integer(unsigned(len_out)) = 8 
            report "ERRO: Tamanho deveria permanecer 8" severity error;
        
        report "Teste 4: Esvaziando a fila (ordem FIFO)";
        for i in 1 to 8 loop
            dequeue_and_check_fifo(dequeue_in, i*10, len_out);
            assert to_integer(unsigned(len_out)) = 8-i 
                report "ERRO: Tamanho esperado " & integer'image(8-i) severity error;
        end loop;
        
        report "Teste 5: Fila vazia - verificando comportamento";
        data_before_empty := data_out;
        dequeue_in <= '1';
        wait for CLOCK_PERIOD;
        dequeue_in <= '0';
        wait for CLOCK_PERIOD;
        
        assert to_integer(unsigned(len_out)) = 0 
            report "ERRO: Tamanho deveria ser 0" severity error;
        
        assert data_out = data_before_empty or to_integer(unsigned(len_out)) = 0
            report "AVISO: data_out mudou durante dequeue em fila vazia" severity note;
        
        report "Teste 6: Operacoes intercaladas FIFO";
        enqueue(data_in, enqueue_in, 100);
        enqueue(data_in, enqueue_in, 200);
        dequeue_and_check_fifo(dequeue_in, 100, len_out); 
        enqueue(data_in, enqueue_in, 250);
        dequeue_and_check_fifo(dequeue_in, 200, len_out); 
        dequeue_and_check_fifo(dequeue_in, 250, len_out);
        
        report "Teste 7: Operacoes simultaneas";
        enqueue(data_in, enqueue_in, 50);
        enqueue(data_in, enqueue_in, 60);
        enqueue(data_in, enqueue_in, 70);
        
        simultaneous_enqueue_dequeue(data_in, enqueue_in, dequeue_in, 80, 50);
        
        dequeue_and_check_fifo(dequeue_in, 60, len_out);
        dequeue_and_check_fifo(dequeue_in, 70, len_out);
        dequeue_and_check_fifo(dequeue_in, 80, len_out);
        
        report "Teste 8: Multiplos resets consecutivos";
        enqueue(data_in, enqueue_in, 90);
        enqueue(data_in, enqueue_in, 95);
        
        reset <= '1';
        wait for CLOCK_PERIOD;
        reset <= '0';
        wait for CLOCK_PERIOD;
        
        assert to_integer(unsigned(len_out)) = 0 
            report "ERRO: Fila deveria estar vazia apos primeiro reset" severity error;
        
        reset <= '1';
        wait for CLOCK_PERIOD;
        reset <= '0';
        wait for CLOCK_PERIOD;
        
        assert to_integer(unsigned(len_out)) = 0 
            report "ERRO: Fila deveria estar vazia apos segundo reset" severity error;
        
        report "Teste 9: Alternancia rapida";
        enqueue(data_in, enqueue_in, 110);
        dequeue_and_check_fifo(dequeue_in, 110, len_out);
        enqueue(data_in, enqueue_in, 120);
        dequeue_and_check_fifo(dequeue_in, 120, len_out);
        enqueue(data_in, enqueue_in, 130);
        dequeue_and_check_fifo(dequeue_in, 130, len_out);
        
        report "Teste 10: Teste de wraparound circular";
        for i in 1 to 8 loop
            enqueue(data_in, enqueue_in, i);
        end loop;
        
        dequeue_and_check_fifo(dequeue_in, 1, len_out);
        dequeue_and_check_fifo(dequeue_in, 2, len_out);
        dequeue_and_check_fifo(dequeue_in, 3, len_out);
        
        enqueue(data_in, enqueue_in, 91);
        enqueue(data_in, enqueue_in, 92);
        enqueue(data_in, enqueue_in, 93);
        
        dequeue_and_check_fifo(dequeue_in, 4, len_out);  
        dequeue_and_check_fifo(dequeue_in, 5, len_out);
        dequeue_and_check_fifo(dequeue_in, 6, len_out);
        dequeue_and_check_fifo(dequeue_in, 7, len_out);
        dequeue_and_check_fifo(dequeue_in, 8, len_out);
        dequeue_and_check_fifo(dequeue_in, 91, len_out); 
        dequeue_and_check_fifo(dequeue_in, 92, len_out);
        dequeue_and_check_fifo(dequeue_in, 93, len_out);
        
        
        report "Teste da FILA concluido com sucesso!";
        sim_finished <= true;
        wait;
    end process;
    
end Behavioral;
