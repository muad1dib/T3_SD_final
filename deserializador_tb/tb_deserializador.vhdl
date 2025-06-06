library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity deserializador_tb is
end deserializador_tb; 

architecture Behavioral of deserializador_tb is
    
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
    
    signal clk : STD_LOGIC := '0';
    signal reset : STD_LOGIC := '0';
    signal data_in : STD_LOGIC := '0';
    signal write_in : STD_LOGIC := '0';
    signal ack_in : STD_LOGIC := '0';
    signal data_out : STD_LOGIC_VECTOR(7 downto 0);
    signal data_ready : STD_LOGIC;
    signal status_out : STD_LOGIC;
    
    constant CLK_PERIOD : time := 10 us;
    signal sim_end : boolean := false;
    
    procedure send_byte(
        constant byte_value : in STD_LOGIC_VECTOR(7 downto 0);
        signal data_signal : out STD_LOGIC;
        signal write_signal : out STD_LOGIC;
        signal clk_signal : in STD_LOGIC
    ) is
    begin
        write_signal <= '1';
        for i in 0 to 7 loop
            data_signal <= byte_value(i);
            wait until rising_edge(clk_signal);
        end loop;
        write_signal <= '0';
    end procedure;
    
    procedure wait_cycles(
        constant num_cycles : in integer;
        signal clk_signal : in STD_LOGIC
    ) is
    begin
        for i in 1 to num_cycles loop
            wait until rising_edge(clk_signal);
        end loop;
    end procedure;

begin
    
    uut: deserializador
        port map (
            clock_100KHz => clk,
            reset => reset,
            data_in => data_in,
            write_in => write_in,
            ack_in => ack_in,
            data_out => data_out,
            data_ready => data_ready,
            status_out => status_out
        );
    
    clk_process: process
    begin
        while not sim_end loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;
    
    test_process: process
    begin
        
        report "TESTE 1: Reset e Estado Inicial";
        reset <= '1';
        wait_cycles(2, clk);
        
        assert (data_ready = '0') report "ERRO: data_ready deveria ser 0 apos reset" severity error;
        assert (status_out = '0') report "ERRO: status_out deveria ser 0 apos reset" severity error;
        assert (data_out = "00000000") report "ERRO: data_out deveria ser zero apos reset" severity error;
        
        reset <= '0';
        wait_cycles(1, clk);
        report "TESTE 1: PASSOU - Estado inicial correto";
        
        report "TESTE 2: Recepcao de byte 10101010";
        
        send_byte("10101010", data_in, write_in, clk);
        wait_cycles(2, clk);
        
        assert (data_ready = '1') report "ERRO: data_ready deveria estar ativo" severity error;
        assert (status_out = '1') report "ERRO: status_out deveria estar ativo" severity error;
        assert (data_out = "10101010") report "ERRO: data_out incorreto" severity error;
        
        wait until rising_edge(clk);
        ack_in <= '1';
        wait until rising_edge(clk);
        ack_in <= '0';
        
        wait_cycles(1, clk);
        assert (data_ready = '0') report "ERRO: data_ready deveria estar inativo apos ACK" severity error;
        assert (status_out = '0') report "ERRO: status_out deveria estar inativo apos ACK" severity error;
        
        report "TESTE 2: PASSOU - Recepcao e ACK corretos";
        
        report "TESTE 3: Recepcao de byte 11001100";
        
        send_byte("11001100", data_in, write_in, clk);
        wait_cycles(2, clk);
        
        assert (data_ready = '1') report "ERRO: data_ready deveria estar ativo" severity error;
        assert (data_out = "11001100") report "ERRO: data_out incorreto" severity error;
        
        wait until rising_edge(clk);
        ack_in <= '1';
        wait until rising_edge(clk);
        ack_in <= '0';
        wait_cycles(1, clk);
        
        report "TESTE 3: PASSOU - Segundo byte recebido corretamente";
        
        report "TESTE 4: Verificacao de status_out durante recepcao";
        
        assert (status_out = '0') report "ERRO: status_out deveria estar inativo em IDLE" severity error;
        
        wait until rising_edge(clk);
        data_in <= '1';
        write_in <= '1';
        wait until falling_edge(clk);
        write_in <= '0';
        
        wait_cycles(1, clk);
        assert (status_out = '1') report "ERRO: status_out deveria estar ativo durante recepcao" severity error;
        
        for i in 1 to 7 loop
            wait until rising_edge(clk);
            case i is
                when 1 => data_in <= '0';
                when 2 => data_in <= '1';
                when 3 => data_in <= '1';
                when 4 => data_in <= '0';
                when 5 => data_in <= '1';
                when 6 => data_in <= '0';
                when 7 => data_in <= '1';
                when others => data_in <= '0';
            end case;
            write_in <= '1';
            wait until falling_edge(clk);
            write_in <= '0';
        end loop;
        
        wait_cycles(2, clk);
        
        assert (data_out = "10110101") report "ERRO: Byte final incorreto" severity error;
        assert (data_ready = '1') report "ERRO: data_ready deveria estar ativo" severity error;
        assert (status_out = '1') report "ERRO: status_out deveria estar ativo esperando ACK" severity error;
        
        wait until rising_edge(clk);
        ack_in <= '1';
        wait until rising_edge(clk);
        ack_in <= '0';
        wait_cycles(1, clk);
        
        report "TESTE 4: PASSOU - Status durante recepcao correto";
        
        report "TESTE 5: Teste sem write_in (sem dados)";
        
        wait until rising_edge(clk);
        data_in <= '1';
        wait_cycles(5, clk);
        
        assert (data_ready = '0') report "ERRO: data_ready nao deveria estar ativo sem write_in" severity error;
        assert (status_out = '0') report "ERRO: status_out nao deveria estar ativo sem write_in" severity error;
        
        report "TESTE 5: PASSOU - Corretamente ignora dados sem write_in";
        
        report "TESTE 6: Multiplos bytes sequenciais";
        
        send_byte("00001111", data_in, write_in, clk);
        wait_cycles(1, clk);
        assert (data_out = "00001111") report "ERRO: Primeiro byte incorreto" severity error;
        wait until rising_edge(clk);
        ack_in <= '1';
        wait until rising_edge(clk);
        ack_in <= '0';
        wait_cycles(1, clk);
        
        send_byte("11110000", data_in, write_in, clk);
        wait_cycles(1, clk);
        assert (data_out = "11110000") report "ERRO: Segundo byte incorreto" severity error;
        wait until rising_edge(clk);
        ack_in <= '1';
        wait until rising_edge(clk);
        ack_in <= '0';
        wait_cycles(1, clk);
        
        report "TESTE 6: PASSOU - Multiplos bytes sequenciais corretos";
        
        report "TESTE 7: Reset durante operacao";
        
        wait until rising_edge(clk);
        data_in <= '1';
        write_in <= '1';
        wait until falling_edge(clk);
        write_in <= '0';
        
        wait until rising_edge(clk);
        data_in <= '0';
        write_in <= '1';
        wait until falling_edge(clk);
        write_in <= '0';
        
        reset <= '1';
        wait_cycles(2, clk);
        reset <= '0';
        
        assert (data_ready = '0') report "ERRO: data_ready deveria ser 0 apos reset" severity error;
        assert (status_out = '0') report "ERRO: status_out deveria ser 0 apos reset" severity error;
        
        report "TESTE 7: PASSOU - Reset durante operacao funciona corretamente";
        
        report "TODOS OS TESTES CONCLUIDOS COM SUCESSO";
        
        wait_cycles(5, clk);
        sim_end <= true;
        wait;
        
    end process;

end Behavioral;
