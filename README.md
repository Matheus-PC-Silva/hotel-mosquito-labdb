# Hotel do Mosquito — Sistema de Gerenciamento

Trabalho prático da disciplina Laboratório de Banco de Dados. Sistema CRUD em
MySQL + Python/Tkinter com comunicação 100% encapsulada em stored procedures e
views.

## Pré-requisitos

- MySQL 8+ e MySQL Workbench
- Python 3.10+ (com Tkinter — vem no instalador padrão do Windows)
- Acesso administrativo ao MySQL local (para criar database)

## Passo 1 — Executar o script SQL

1. Abra o MySQL Workbench e conecte ao servidor local.
2. Abra o arquivo `sql/hotel_mosquito_full.sql`.
3. Execute todo o script (Ctrl+Shift+Enter).
4. Verifique a saída final — deve aparecer a linha de contagem com
   `5, 15, 10, 5, 10, 10, 8, 15, 15`.

> **Nota:** o script faz `DROP DATABASE IF EXISTS hotel_mosquito` no início — se você
> já tem dados nesse schema, eles serão apagados.

## Passo 2 — (Opcional) Demo de transações puras

Execute `sql/99_demo_transacoes.sql` bloco a bloco no Workbench para ver os
cenários de COMMIT, ROLLBACK e SAVEPOINT em ação.

## Passo 3 — Configurar e rodar a aplicação

1. Edite `app/config.ini` com seu host/usuário/senha do MySQL.
2. Instale dependências:

```powershell
pip install -r app\requirements.txt
```

3. Rode (a partir da raiz do projeto):

```powershell
python -m app.main
```

## Credenciais de teste

| Login    | Senha    | Perfil        |
|----------|----------|---------------|
| gerente1 | senha123 | Gerente       |
| gerente2 | senha123 | Gerente       |
| recep1   | senha123 | Recepcionista |
| recep2   | senha123 | Recepcionista |
| recep3   | senha123 | Recepcionista |

## Estrutura do projeto

- `sql/` — scripts SQL (schema, views, procedures, triggers, seed, full, demo)
- `app/` — aplicação Python
  - `db/` — camada de acesso (uma função por procedure)
  - `ui/` — janelas e abas Tkinter
- `docs/` — relatório técnico, apresentação, diagramas

## Diagramas MER e Modelo Lógico

Os diagramas são gerados a partir do banco já carregado via
**Workbench → Database → Reverse Engineer**. Exporte como PNG e salve em
`docs/mer.png` e `docs/modelo_logico.png`.

## Segurança

O usuário MySQL usado pela aplicação deve ter apenas EXECUTE em procedures e
SELECT em views. Exemplo de grant mínimo:

```sql
CREATE USER 'hotel_app'@'localhost' IDENTIFIED BY 'senha_app';
GRANT EXECUTE ON hotel_mosquito.* TO 'hotel_app'@'localhost';
GRANT SELECT ON hotel_mosquito.vw_quartos_disponiveis TO 'hotel_app'@'localhost';
GRANT SELECT ON hotel_mosquito.vw_ocupacao_atual TO 'hotel_app'@'localhost';
GRANT SELECT ON hotel_mosquito.vw_historico_reservas_cliente TO 'hotel_app'@'localhost';
FLUSH PRIVILEGES;
```
