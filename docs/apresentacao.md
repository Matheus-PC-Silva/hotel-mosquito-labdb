---
marp: true
theme: default
paginate: true
---

# Hotel do Mosquito
## Sistema de Gerenciamento de Hotel
### Laboratório de Banco de Dados — 2026

[Integrantes do grupo]

---

## Visão geral

- CRUD completo em MySQL com encapsulamento total
- Interface em Python/Tkinter
- Autenticação com hash SHA2 + controle de acesso por perfil
- 9 tabelas, ~25 procedures, 7 views, 2 triggers
- Transações dentro de procedures + transações puras fora

---

## Stack

- **Banco:** MySQL 8+ (InnoDB, utf8mb4)
- **Linguagem:** Python 3.10+
- **UI:** Tkinter (`ttk.Notebook` com abas)
- **Driver:** `mysql-connector-python`
- **Comunicação:** 100% via `CALL sp_*` e `SELECT * FROM vw_*`

---

## Modelo de dados (MER)

![bg right contain](mer.png)

- 9 entidades
- Normalizado até 3FN
- Snapshots de preço em Hospedagem e Consumo

---

## Normalização (3FN)

- **1FN:** atributos atômicos
- **2FN:** PKs simples — sem dependência parcial
- **3FN:** sem dependências transitivas
- Snapshots não violam 3FN — são decisão de modelagem (preservar histórico)

---

## Encapsulamento total

```python
# Em vez disso (PROIBIDO):
cursor.execute("INSERT INTO Cliente VALUES (...)")

# Sempre assim:
cursor.callproc("sp_Cliente_Create", (nome, cpf, email, ...))
```

Camada `app/db/` expõe uma função por procedure. Zero SQL cru pela rede.

---

## Views (3 obrigatórias + 4 de relatório)

- `vw_quartos_disponiveis` — quartos prontos para reserva/check-in
- `vw_ocupacao_atual` — hospedagens ativas com total de consumo
- `vw_historico_reservas_cliente` — histórico por cliente (filtrável por CPF)
- `vw_taxa_ocupacao_mensal` — diárias ocupadas / total disponível
- `vw_top_clientes_assiduos` — clientes por total de diárias
- `vw_top_quartos_reservados` — quartos por quantidade de reservas
- `vw_faturamento_mensal` — receita de diárias + consumos por mês

---

## Triggers

### `trg_preco_inicial_quarto`
`AFTER INSERT` em Quarto → registra primeira entrada em `Historico_Preco`

### `trg_atualiza_preco_quarto` (obrigatória)
`AFTER UPDATE` em Quarto (quando `preco_praticado` muda):
1. Fecha vigência aberta: `data_fim_vigencia = NOW()`
2. Abre nova linha com novo preço e `data_fim_vigencia = NULL`

> Mantém invariante mesmo para UPDATE direto via Workbench

---

## Procedures transacionais

| Procedure | Operação |
|---|---|
| `sp_RegistrarReserva` | Detecta sobreposição + INSERT em Reserva |
| `sp_RealizarCheckIn` | Valida reserva/quarto + UPDATE + INSERT Hospedagem |
| `sp_LancarConsumo` | Valida hospedagem ativa + snapshot preço + INSERT |
| `sp_RealizarCheckOut` | Calcula total + UPDATE Hospedagem/Quarto |

Todas com `START TRANSACTION` + `DECLARE EXIT HANDLER FOR SQLEXCEPTION ROLLBACK`.

---

## Controle de acesso (duas camadas)

**Camada 1 — Banco de dados:**
- `sp_AssertGerente(id_executor)` — lança `SIGNAL SQLSTATE '45000'`
- Procedures de relatório e CRUD de Funcionário bloqueiam Recepcionistas
- Funciona mesmo com acesso direto via Workbench

**Camada 2 — Interface:**
- Abas "Funcionários" e "Relatórios" não são criadas se `perfil != 'Gerente'`
- Defesa em profundidade

---

## Transações puras

### Seed transacional (`05_seed_data.sql`)
```sql
START TRANSACTION;
  INSERT INTO Categoria_Quarto ...
  SAVEPOINT sp_categorias;
  INSERT INTO Quarto ...
  SAVEPOINT sp_quartos;
  ...
COMMIT;
```

### Script demonstrativo (`99_demo_transacoes.sql`)
3 cenários: COMMIT, ROLLBACK manual, SAVEPOINT com rollback parcial

---

## Interface — fluxo

1. `main.py` → `LoginWindow` → `sp_Login`
2. Login OK → `MainWindow` com `ttk.Notebook`
3. Abas conforme perfil: Clientes, Quartos, [Funcionários], Reservas, Hospedagem, [Relatórios]
4. Status bar: "Logado como X (Perfil)" + botão Sair

---

## Aba Hospedagem (3 sub-abas)

1. **Check-in** — lista reservas Confirmadas → botão "Realizar Check-in"
2. **Hospedagens Ativas** — lista ativas + formulário "Lançar Consumo"
3. **Check-out** — seleciona ativa → modal com valor total detalhado

---

## Casos de teste principais

| Cenário | Resultado |
|---|---|
| Login com senha errada | "Credenciais invalidas" |
| Reserva com período sobreposto | "Periodo sobreposto" |
| Check-in em reserva já efetivada | "Reserva nao esta Confirmada" |
| Recepcionista chama relatório no Workbench | "Acesso negado: operacao restrita a Gerentes" |
| ROLLBACK de atualização de preço | `Historico_Preco` volta ao estado anterior |
| DELETE em Cliente com reservas | Erro FK RESTRICT |

---

## Principais Dificuldades

> [Preencher com dificuldades reais do grupo]

- Encapsulamento total: mapear cada operação da UI a uma procedure
- Sobreposição de reservas: lógica `NOT (a.fim ≤ b.inicio OR a.inicio ≥ b.fim)`
- Snapshot de preço: garantir que reajustes não afetam estadias em curso
- Configuração MySQL + driver Python no Windows
- Layout Tkinter com abas dinâmicas por perfil

---

## Resumo final

| Item | Quantidade |
|---|---:|
| Tabelas | 9 |
| Stored Procedures | ~25 |
| Procedures com transação | 4 |
| Transações puras fora de SP | 2 (seed + demo) |
| Views | 7 |
| Triggers | 2 |
| Telas da UI | 1 login + 1 principal com 4–6 abas |

---

# Obrigado!

**Perguntas?**

Credenciais de demo:
- `gerente1` / `senha123` — Gerente (6 abas)
- `recep1` / `senha123` — Recepcionista (4 abas)
