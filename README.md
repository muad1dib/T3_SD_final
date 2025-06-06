
# Trabalho T3 - Múltiplos Domínios de Relógio
# NOME: Marcelo Henrique Fernandes

## Descrição do Projeto

Este projeto implementa dois módulos digitais funcionando em domínios de relógio diferentes:

### DESERIALIZADOR (100KHz)
- **Função**: Recebe bits seriais e os converte em palavras de 8 bits
- **Entrada**: `data_in` (1 bit), `write_in` (controle), `ack_in` (confirmação)
- **Saída**: `data_out` (8 bits), `data_ready` (flag), `status_out` (ocupado/livre)
- **Funcionamento**: Coleta 8 bits sequenciais quando `write_in` está alto, disponibiliza a palavra completa em `data_out` com `data_ready` ativo, aguarda confirmação via `ack_in`

### FILA FIFO (10KHz)
- **Função**: Buffer circular de 8 posições, cada uma com 8 bits
- **Entrada**: `data_in` (8 bits), `enqueue_in` (inserir), `dequeue_in` (remover)
- **Saída**: `data_out` (8 bits), `len_out` (número de elementos)
- **Funcionamento**: Implementa política FIFO (First In, First Out) com controle de overflow/underflow

## Estrutura dos Arquivos

```
T3-SD_final/
├── deserializador_tb/
│   ├── deserializador.vhdl      # Módulo deserializador
│   ├── tb_deserializador.vhdl   # Testbench do deserializador
│   └── sim.do                   # Script para simulação do deserializador
├── fila_tb/
│   ├── fila.vhdl               # Módulo da fila FIFO
│   ├── tb_fila.vhdl            # Testbench da fila
│   └── sim.do                  # Script para simulação da fila
├── top_module_tb/
│   ├── tb_top_module           # Testbench do módulo top (não implementado)
│   └── top_module              # Módulo top integrado (não implementado)
└── README.md                   # Este arquivo
```

## Como Executar no Questa/ModelSim

### Testbench do Deserializador:
1. Abra o Questa/ModelSim
2. No console, navegue até o diretório do deserializador:
   ```
   cd /caminho/para/T3-SD_final/deserializador_tb
   ```
3. Execute o script de simulação:
   ```
   do sim.do
   ```

### Testbench da Fila FIFO:
1. No console do Questa, navegue até o diretório da fila:
   ```
   cd /caminho/para/T3-SD_final/fila_tb
   ```
2. Execute o script de simulação:
   ```
   do sim.do
   ```


## Resultados dos Testes

### Deserializador
**Problemas Iniciais**:
- ❌ Erro de compilação (vcom-1294) - conflito de nomes entre `data_ready` (sinal) e `DATA_READY` (estado)
- ❌ Script de simulação com parâmetros não suportados

**Após Correções**:
- ✅ Reset e estado inicial
- ✅ Recepção correta de bytes (10101010, 11001100)
- ✅ Controle de status durante operação (`status_out` ativo durante recepção)
- ✅ Ignorar dados sem `write_in` (comportamento correto sem sinal de controle)
- ✅ Múltiplos bytes sequenciais
- ✅ Reset durante operação (interrupção segura do processo)
- ✅ Todos os 7 testes passaram com sucesso

### Fila FIFO
**Problemas Iniciais**:
- ❌ Desalinhamento temporal - `data_out` mostrava sempre o próximo valor
- ❌ Falhas nos testes FIFO: esperado 10, obtido 20; esperado 20, obtido 30

**Após Correções**:
- ✅ Estado inicial (tamanho 0)
- ✅ Comportamento FIFO básico (ordem correta First-In-First-Out)
- ✅ Controle de overflow (rejeita inserção quando cheia - 8 elementos)
- ✅ Controle de underflow (mantém estado quando vazia)
- ✅ Operações intercaladas (enqueue/dequeue alternados)
- ✅ Operações simultâneas (enqueue + dequeue no mesmo ciclo)
- ✅ Teste de wraparound circular (ponteiros head/tail funcionando corretamente)
- ✅ Múltiplos resets consecutivos
- ✅ Todos os 10 testes passaram com sucesso

**Observação**: Ambos os módulos foram validados através de testbenches abrangentes que cobrem casos normais, casos extremos (edge cases) e condições de erro.

## Problemas Encontrados e Soluções

### Fila FIFO - Desalinhamento Temporal
**Problema**: O código original tinha um desalinhamento temporal na operação de dequeue. A saída `data_out` era combinacional e mostrava sempre o valor seguinte ao esperado.

**Causa**: 
- Ciclo N: `dequeue_in = '1'` ativado, mas `data_out` ainda mostra valor antigo
- Ciclo N+1: `head_ptr` incrementado, causando leitura do próximo elemento

**Solução**: Transformação de `data_out` para síncrona, lendo o valor **antes** de incrementar `head_ptr`:
```vhdl
if dequeue_in = '1' and count > 0 then
    data_out <= memory(head_ptr);  -- Lê ANTES de incrementar
    head_ptr <= head_ptr + 1;      -- Depois atualiza ponteiro
```

### Deserializador - Conflito de Nomes
**Problema**: Erro de compilação (vcom-1294) devido a conflito entre sinal `data_ready` e estado `DATA_READY`.

**Causa**: Em VHDL, identificadores são case-insensitive, gerando ambiguidade.

**Solução**: Renomeação do estado para `BYTE_READY`:
```vhdl
-- Antes: type state_type is (IDLE, RECEIVING, DATA_READY, WAIT_ACK);
-- Depois: type state_type is (IDLE, RECEIVING, BYTE_READY, WAIT_ACK);
```

## Limitações

**Nota**: Por limitações de tempo, falta de manejo em definir o que é prioridade e por quebrar a cabeça em torno do tb do deserializador, o módulo top integrando ambos os componentes com divisores de clock (1MHz → 100KHz/10KHz) não foi implementado. Embora a estrutura de diretórios `top_module_tb/` tenha sido criada, os arquivos `top_module` e `tb_top_module` não foram desenvolvidos plenamente, no caso de `tb_top_module` e, por isso, não foram testados, especialmente no caso de `top_module` . Os testbenches individuais demonstram o correto funcionamento de cada módulo em seus respectivos domínios de relógio.

## Características Implementadas

- **Deserializador**: Máquina de estados robusta com controle de fluxo
- **Fila**: Implementação circular eficiente com ponteiros head/tail
- **Testbenches**: Cobertura completa de casos de teste incluindo edge cases. Como parte do aprendizado de testbenches, tive de aprender o que é wraparound, por exemplo.
- **Documentação**: Scripts de simulação prontos para uso

O projeto demonstra o correto funcionamento dos módulos individuais, preparando a base para a integração em um sistema com múltiplos domínios de relógio.
