# Documentação do Banco de Dados — Hotel do Mosquito

Este documento apresenta todos os objetos do banco de dados com exemplos de uso, queries de verificação e demonstração dos requisitos do trabalho.

---

## Índice

1. [Configuração inicial](#1-configuração-inicial)
2. [Schema — Tabelas](#2-schema--tabelas)
3. [Views](#3-views)
4. [Stored Procedures — CRUD](#4-stored-procedures--crud)
5. [Stored Procedures — Operações transacionais](#5-stored-procedures--operações-transacionais)
6. [Stored Procedures — Relatórios](#6-stored-procedures--relatórios)
7. [Triggers](#7-triggers)
8. [Transações puras](#8-transações-puras)
9. [Queries de verificação e auditoria](#9-queries-de-verificação-e-auditoria)

---

## 1. Configuração inicial

### Criar o banco do zero (script único)

```sql
-- No MySQL Workbench: File → Open SQL Script → hotel_mosquito_full.sql
-- Ctrl+Shift+Enter para executar tudo

-- OU via linha de comando:
-- mysql -u root -p < sql/hotel_mosquito_full.sql
```

### Selecionar o banco após conectar

```sql
USE hotel_mosquito;
```

---

## 2. Schema — Tabelas

O banco possui **9 tabelas** normalizadas até 3FN.

### Diagrama de dependências

```
Categoria_Quarto ←── Quarto ←── Historico_Preco (trigger)
                        │
                        ▼
Funcionario ─────► Reserva ◄─── Cliente
                        │
                        ▼
                  Hospedagem ──► Consumo ◄── Produto_Servico
```

### Listar todas as tabelas

```sql
USE hotel_mosquito;
SHOW TABLES;
```

### Ver a estrutura de uma tabela

```sql
DESCRIBE Quarto;
DESCRIBE Hospedagem;
DESCRIBE Reserva;
```

### Ver constraints e chaves estrangeiras

```sql
SELECT
  TABLE_NAME,
  CONSTRAINT_NAME,
  CONSTRAINT_TYPE
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = 'hotel_mosquito'
ORDER BY TABLE_NAME, CONSTRAINT_TYPE;
```

### Ver índices

```sql
SELECT
  TABLE_NAME,
  INDEX_NAME,
  COLUMN_NAME,
  NON_UNIQUE
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'hotel_mosquito'
ORDER BY TABLE_NAME, INDEX_NAME;
```

---

## 3. Views

O banco possui **7 views** — 3 obrigatórias + 4 de relatório.

### Listar todas as views

```sql
SHOW FULL TABLES WHERE Table_type = 'VIEW';
```

---

### 3.1 `vw_quartos_disponiveis` (obrigatória)

Quartos com status `Disponivel` ou `Limpeza`, prontos para nova reserva ou check-in.

```sql
SELECT * FROM vw_quartos_disponiveis;

-- Filtrar por categoria
SELECT * FROM vw_quartos_disponiveis WHERE categoria_nome = 'Luxo';

-- Filtrar por capacidade mínima
SELECT * FROM vw_quartos_disponiveis WHERE capacidade >= 3;
```

---

### 3.2 `vw_ocupacao_atual` (obrigatória)

Todas as hospedagens ativas (check-in feito, check-out pendente), com o total de consumo acumulado até o momento.

```sql
SELECT * FROM vw_ocupacao_atual;

-- Ver apenas uma hospedagem específica
SELECT * FROM vw_ocupacao_atual WHERE id_hospedagem = 6;

-- Ordenar por maior consumo
SELECT * FROM vw_ocupacao_atual ORDER BY total_consumo_ate_agora DESC;
```

---

### 3.3 `vw_historico_reservas_cliente` (obrigatória)

Histórico completo de reservas e hospedagens por cliente. Filtrável por CPF na aplicação.

```sql
SELECT * FROM vw_historico_reservas_cliente;

-- Histórico de um cliente específico por CPF
SELECT * FROM vw_historico_reservas_cliente WHERE cpf = '11111111111';

-- Histórico de hospedagens finalizadas
SELECT * FROM vw_historico_reservas_cliente WHERE hospedagem_status = 'Finalizada';
```

---

### 3.4 `vw_taxa_ocupacao_mensal`

Taxa de ocupação por mês: diárias ocupadas ÷ (nº quartos × dias no mês) × 100.

```sql
SELECT * FROM vw_taxa_ocupacao_mensal;

-- Taxa de um mês específico
SELECT * FROM vw_taxa_ocupacao_mensal WHERE ano = 2026 AND mes = 3;

-- Todos os meses ordenados
SELECT * FROM vw_taxa_ocupacao_mensal ORDER BY ano, mes;
```

---

### 3.5 `vw_top_clientes_assiduos`

Clientes ranqueados pelo total de diárias acumuladas.

```sql
SELECT * FROM vw_top_clientes_assiduos LIMIT 10;
```

---

### 3.6 `vw_top_quartos_reservados`

Quartos ranqueados pelo número de reservas.

```sql
SELECT * FROM vw_top_quartos_reservados LIMIT 10;
```

---

### 3.7 `vw_faturamento_mensal`

Faturamento por mês de check-out: total de diárias + consumos.

```sql
SELECT * FROM vw_faturamento_mensal;

-- Faturamento de um mês específico
SELECT * FROM vw_faturamento_mensal WHERE ano = 2026 AND mes = 3;
```

---

## 4. Stored Procedures — CRUD

### Listar todas as procedures

```sql
SELECT ROUTINE_NAME
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = 'hotel_mosquito'
  AND ROUTINE_TYPE = 'PROCEDURE'
ORDER BY ROUTINE_NAME;
```

---

### 4.1 Autenticação

```sql
-- Login com credenciais corretas (retorna id, nome, perfil)
CALL sp_Login('gerente1', 'senha123');

-- Login com senha errada (lança SIGNAL)
CALL sp_Login('gerente1', 'errada');
-- Erro: Credenciais invalidas
```

---

### 4.2 Clientes

```sql
-- Criar novo cliente
CALL sp_Cliente_Create(
  'Novo Cliente',
  '12345678901',
  'novo@example.com',
  '11999990000',
  'Rua Teste, 1, São Paulo, SP'
);

-- Listar todos os clientes
CALL sp_Cliente_Read(NULL, NULL);

-- Buscar por nome ou CPF (filtro LIKE)
CALL sp_Cliente_Read(NULL, 'Ana');
CALL sp_Cliente_Read(NULL, '11111111111');

-- Buscar por ID específico
CALL sp_Cliente_Read(1, NULL);

-- Atualizar cliente (id=1)
CALL sp_Cliente_Update(1, 'Ana Souza', '11111111111', 'ana@novo.com', '11999990001', 'Rua Nova, 10, SP');

-- Excluir cliente
CALL sp_Cliente_Delete(1);
-- Erro se tiver reservas: FK RESTRICT
```

---

### 4.3 Quartos

```sql
-- Listar todos os quartos (com categoria)
CALL sp_Quarto_Read(NULL);

-- Buscar quarto específico
CALL sp_Quarto_Read(1);

-- Criar novo quarto (numero, andar, capacidade, status, preco_inicial, id_categoria)
CALL sp_Quarto_Create('601', 6, 2, 'Disponivel', 250.00, 1);

-- Atualizar quarto (sem alterar preço)
CALL sp_Quarto_Update(1, '101', 1, 2, 'Manutencao', 1);

-- Alterar preço (dispara trigger trg_atualiza_preco_quarto)
CALL sp_AtualizarPrecoQuarto(1, 250.00);

-- Ver histórico de preços de um quarto
CALL sp_HistoricoPreco_ReadPorQuarto(1);

-- Excluir quarto
CALL sp_Quarto_Delete(16);
```

---

### 4.4 Funcionários (restrito a Gerente)

```sql
-- Listar funcionários (id_executor precisa ser Gerente)
CALL sp_Funcionario_Read(1, NULL);  -- 1 = id de gerente1

-- Buscar um funcionário específico
CALL sp_Funcionario_Read(1, 3);

-- Criar funcionário (executor=1 = gerente1)
CALL sp_Funcionario_Create(1, 'Novo Func', '30303030303', 'Recepcionista', 'recep4', 'senha456', 'Recepcionista');

-- Atualizar (senha vazia = não altera senha)
CALL sp_Funcionario_Update(1, 3, 'Joana Lima', '20202020203', 'Recepcionista Sr.', 'recep1', '', 'Recepcionista');

-- Excluir
CALL sp_Funcionario_Delete(1, 6);

-- Tentar com Recepcionista (deve falhar)
CALL sp_Funcionario_Read(3, NULL);
-- Erro: Acesso negado: operacao restrita a Gerentes
```

---

### 4.5 Categorias e Produtos/Serviços

```sql
-- Listar categorias
CALL sp_Categoria_Read();

-- Criar categoria
CALL sp_Categoria_Create('Chalé', 'Acomodação rústica com lareira');

-- Atualizar categoria
CALL sp_Categoria_Update(6, 'Chalé', 'Chalé rústico com lareira e vista para o lago');

-- Excluir categoria
CALL sp_Categoria_Delete(6);

-- Listar produtos/serviços
CALL sp_ProdutoServico_Read();

-- Criar produto
CALL sp_ProdutoServico_Create('Suco Natural', 12.00, 'Restaurante');

-- Atualizar produto
CALL sp_ProdutoServico_Update(11, 'Suco Natural 300ml', 14.00, 'Restaurante');

-- Excluir produto
CALL sp_ProdutoServico_Delete(11);
```

---

## 5. Stored Procedures — Operações transacionais

Estas procedures usam `START TRANSACTION / COMMIT` internamente com `DECLARE EXIT HANDLER FOR SQLEXCEPTION ROLLBACK`.

---

### 5.1 `sp_RegistrarReserva`

```sql
-- Registrar reserva futura (id_cliente, id_quarto, id_funcionario, checkin, checkout)
CALL sp_RegistrarReserva(1, 12, 3, '2026-07-01', '2026-07-05');

-- Erro: período sobreposto (quarto 2 já está Efetivada em 2026-05-20 a 2026-05-30)
CALL sp_RegistrarReserva(2, 2, 3, '2026-05-25', '2026-05-28');
-- Erro: Periodo sobreposto: o quarto ja possui reserva nesse intervalo

-- Erro: datas invertidas
CALL sp_RegistrarReserva(1, 12, 3, '2026-08-05', '2026-08-01');
-- Erro: Data de checkout deve ser apos checkin
```

---

### 5.2 `sp_RealizarCheckIn`

```sql
-- Ver reservas confirmadas disponíveis para check-in
CALL sp_Reserva_Read(NULL, 'Confirmada');

-- Realizar check-in (id_reserva=9 está Confirmada no seed)
CALL sp_RealizarCheckIn(9, 3);
-- Retorna: id_hospedagem=9

-- Tentar check-in em reserva já efetivada
CALL sp_RealizarCheckIn(1, 3);
-- Erro: Reserva nao esta Confirmada

-- Tentar check-in em reserva cancelada
CALL sp_RealizarCheckIn(10, 3);
-- Erro: Reserva nao esta Confirmada
```

---

### 5.3 `sp_LancarConsumo`

```sql
-- Lançar consumo em hospedagem ativa (id_hospedagem=6 está Ativa no seed)
CALL sp_LancarConsumo(6, 1, 3);   -- 3x Agua Mineral
CALL sp_LancarConsumo(6, 5, 1);   -- 1x Cafe da Manha

-- Verificar consumos na view
SELECT * FROM vw_ocupacao_atual WHERE id_hospedagem = 6;

-- Erro: quantidade zero
CALL sp_LancarConsumo(6, 1, 0);
-- Erro: Quantidade deve ser positiva

-- Erro: hospedagem finalizada
CALL sp_LancarConsumo(1, 1, 1);
-- Erro: Hospedagem nao esta Ativa
```

---

### 5.4 `sp_RealizarCheckOut`

```sql
-- Realizar check-out (id_hospedagem=6)
CALL sp_RealizarCheckOut(6, 3);
-- Retorna: id_hospedagem, quantidade_diarias, preco_diaria_aplicado,
--          total_diarias, total_consumo, valor_total

-- Verificar que hospedagem está Finalizada
SELECT status FROM Hospedagem WHERE id_hospedagem = 6;
-- Resultado: Finalizada

-- Verificar que quarto voltou para Limpeza
SELECT status FROM Quarto WHERE id_quarto = 2;
-- Resultado: Limpeza

-- Erro: tentar check-out novamente
CALL sp_RealizarCheckOut(6, 3);
-- Erro: Hospedagem nao esta Ativa
```

---

## 6. Stored Procedures — Relatórios

Todas requerem que o executor seja Gerente (validado no banco).

```sql
-- Taxa de ocupação de março/2026 (executor=1 = gerente1)
CALL sp_Relatorio_TaxaOcupacao(1, 2026, 3);

-- Top 10 clientes por diárias
CALL sp_Relatorio_TopClientes(1);

-- Top 10 quartos por número de reservas
CALL sp_Relatorio_TopQuartos(1);

-- Faturamento de março/2026
CALL sp_Relatorio_FaturamentoMensal(1, 2026, 3);

-- Tentativa com Recepcionista (executor=3 = recep1) → deve falhar
CALL sp_Relatorio_TopClientes(3);
-- Erro: Acesso negado: operacao restrita a Gerentes
```

---

## 7. Triggers

### Listar triggers

```sql
SHOW TRIGGERS;
```

---

### 7.1 `trg_preco_inicial_quarto` — AFTER INSERT em Quarto

Ao inserir um quarto, o trigger cria automaticamente a primeira entrada em `Historico_Preco`.

```sql
-- Inserir um quarto de teste
CALL sp_Quarto_Create('999', 9, 2, 'Disponivel', 350.00, 1);
SET @novo_id = LAST_INSERT_ID();

-- Verificar que o histórico foi criado automaticamente (trigger disparou)
SELECT * FROM Historico_Preco WHERE id_quarto = @novo_id;
-- Deve mostrar 1 linha com preco=350.00 e data_fim_vigencia=NULL
```

---

### 7.2 `trg_atualiza_preco_quarto` — AFTER UPDATE em Quarto (obrigatória)

Quando `preco_praticado` de um quarto é alterado, o trigger:
1. Fecha a vigência aberta (`data_fim_vigencia = NOW()`)
2. Abre uma nova entrada com o novo preço e `data_fim_vigencia = NULL`

```sql
-- Ver histórico ANTES da alteração
SELECT * FROM Historico_Preco WHERE id_quarto = 1 ORDER BY id_historico;

-- Alterar o preço via procedure (única forma pelo encapsulamento)
CALL sp_AtualizarPrecoQuarto(1, 280.00);

-- Ver histórico DEPOIS: a linha anterior foi fechada, nova linha aberta
SELECT * FROM Historico_Preco WHERE id_quarto = 1 ORDER BY id_historico;
-- Resultado: linha 1 tem data_fim_vigencia preenchida; linha 2 com NULL

-- O trigger funciona mesmo com UPDATE direto (não via procedure)
UPDATE Quarto SET preco_praticado = 300.00 WHERE id_quarto = 1;
SELECT * FROM Historico_Preco WHERE id_quarto = 1 ORDER BY id_historico;
-- Resultado: agora 3 linhas no histórico
```

---

## 8. Transações puras

Esta seção demonstra o uso de transações explícitas **fora de stored procedures** (requisito do trabalho).

> ⚠️ Execute os cenários abaixo **bloco a bloco** no Workbench para observar os efeitos.
> O script completo está em `sql/99_demo_transacoes.sql`.

---

### 8.1 Cenário 1 — COMMIT bem-sucedido

```sql
START TRANSACTION;

  -- Registra nova reserva
  CALL sp_RegistrarReserva(1, 12, 3, '2026-07-01', '2026-07-05');

  -- Lança consumo em hospedagem ativa
  CALL sp_LancarConsumo(6, 1, 2);

  SELECT 'Dentro da transacao: operacoes realizadas' AS momento;

COMMIT;

-- Verificar que as alterações persistiram
SELECT COUNT(*) AS total_reservas FROM Reserva;
-- Deve ser 11 (10 do seed + 1 nova)
```

---

### 8.2 Cenário 2 — ROLLBACK manual

```sql
-- Estado ANTES
SELECT id_historico, preco_praticado, data_fim_vigencia
FROM Historico_Preco WHERE id_quarto = 1
ORDER BY id_historico;

START TRANSACTION;

  CALL sp_AtualizarPrecoQuarto(1, 999.99);

  SELECT 'DENTRO da transacao — preco alterado para 999.99' AS momento;
  SELECT id_historico, preco_praticado, data_fim_vigencia
  FROM Historico_Preco WHERE id_quarto = 1
  ORDER BY id_historico;

ROLLBACK;

-- Estado DEPOIS do ROLLBACK — deve ser igual ao ANTES
SELECT 'APOS ROLLBACK — historico desfeito' AS momento;
SELECT id_historico, preco_praticado, data_fim_vigencia
FROM Historico_Preco WHERE id_quarto = 1
ORDER BY id_historico;
```

**Resultado esperado:** a linha de 999.99 inserida pelo trigger **desaparece** após o ROLLBACK, voltando ao estado original.

---

### 8.3 Cenário 3 — SAVEPOINT (rollback parcial)

```sql
START TRANSACTION;

  -- Insere cliente A
  CALL sp_Cliente_Create('Cliente Demo A', '30303030301',
                         'demo.a@example.com', '11900000000', 'End A');

  SAVEPOINT antes_b;

  -- Insere cliente B
  CALL sp_Cliente_Create('Cliente Demo B', '30303030302',
                         'demo.b@example.com', '11900000001', 'End B');

  SELECT 'Antes do rollback parcial — ambos visíveis' AS momento;
  SELECT id_cliente, nome FROM Cliente WHERE nome LIKE 'Cliente Demo%';

  -- Desfaz apenas o cliente B
  ROLLBACK TO SAVEPOINT antes_b;

  SELECT 'Apos rollback parcial — so A esta presente' AS momento;
  SELECT id_cliente, nome FROM Cliente WHERE nome LIKE 'Cliente Demo%';

COMMIT;

-- Verificar após commit — apenas A deve persistir
SELECT 'Depois do COMMIT — apenas A' AS momento;
SELECT id_cliente, nome FROM Cliente WHERE nome LIKE 'Cliente Demo%';
```

**Resultado esperado:**
- Após `ROLLBACK TO SAVEPOINT antes_b`: apenas Demo A
- Após `COMMIT`: apenas Demo A (B nunca foi persistido)

---

## 9. Queries de verificação e auditoria

### Verificar encapsulamento total (nenhum INSERT/UPDATE/DELETE direto pela app)

O código Python usa exclusivamente:
```python
cursor.callproc("sp_Nome", (param1, param2, ...))   # para procedures
cursor.execute("SELECT * FROM vw_nome WHERE ...")    # para views
```

### Verificar a constraint de sobreposição de reserva

```sql
-- Esta query mostra a lógica usada na sp_RegistrarReserva
-- Detecta reservas que se sobrepõem com o período 2026-05-25 a 2026-05-28 no quarto 2
SELECT id_reserva, data_checkin_prev, data_checkout_prev, status
FROM Reserva
WHERE id_quarto = 2
  AND status IN ('Confirmada', 'Efetivada')
  AND NOT (data_checkout_prev <= '2026-05-25'
        OR data_checkin_prev  >= '2026-05-28');
-- Retorna a reserva 6 (que vai de 2026-05-20 a 2026-05-30)
```

### Verificar snapshot de preço em hospedagens

```sql
-- Mostra que preco_diaria_aplicado em Hospedagem é independente do preço atual
SELECT
  h.id_hospedagem,
  h.preco_diaria_aplicado   AS preco_no_checkin,
  q.preco_praticado          AS preco_atual,
  CASE WHEN h.preco_diaria_aplicado = q.preco_praticado
       THEN 'igual' ELSE 'DIVERGE (snap funcionou)' END AS situacao
FROM Hospedagem h
JOIN Reserva r ON r.id_reserva = h.id_reserva
JOIN Quarto q  ON q.id_quarto  = r.id_quarto;
```

### Verificar hash de senha (nunca retorna a senha)

```sql
-- sp_Login retorna id, nome, perfil — nunca senha_hash
CALL sp_Login('gerente1', 'senha123');

-- Confirmar que senha_hash não é selecionada por nenhuma procedure pública
SELECT ROUTINE_NAME, ROUTINE_DEFINITION
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = 'hotel_mosquito'
  AND ROUTINE_TYPE = 'PROCEDURE'
  AND ROUTINE_DEFINITION LIKE '%senha_hash%';
-- Resultado: apenas sp_Login, sp_Funcionario_Create, sp_Funcionario_Update, sp_AssertGerente
-- E apenas para gravar/comparar, nunca para retornar ao cliente
```

### Verificar FK RESTRICT na prática

```sql
-- Tentar excluir cliente que tem reservas — deve falhar com erro FK
DELETE FROM Cliente WHERE id_cliente = 1;
-- Erro 1451: Cannot delete or update a parent row: a foreign key constraint fails

-- Tentar excluir quarto com reservas
DELETE FROM Quarto WHERE id_quarto = 1;
-- Erro 1451: Cannot delete or update a parent row
```

### Verificar o controle de acesso por perfil no banco

```sql
-- Recepcionista não pode acessar relatórios (bloqueio no banco, não só na UI)
CALL sp_Relatorio_FaturamentoMensal(3, 2026, 5);  -- 3 = recep1
-- Erro: Acesso negado: operacao restrita a Gerentes

-- Recepcionista não pode criar funcionários
CALL sp_Funcionario_Create(3, 'Teste', '09876543210', 'Cargo', 'login_x', 'senha', 'Recepcionista');
-- Erro: Acesso negado: operacao restrita a Gerentes
```
