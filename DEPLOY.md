# Guia de Deploy — Hotel do Mosquito

Este documento guia qualquer pessoa do grupo a colocar o projeto funcionando do zero em sua máquina, do banco de dados até a interface gráfica.

Escolha **uma** das duas opções de banco de dados:
- **Opção Docker** (recomendada — sem instalação de MySQL) → vá direto para a [seção Docker](#-opção-docker-recomendada)
- **Opção MySQL local** (MySQL Workbench instalado) → siga os passos 1–4 abaixo

---

## Índice

- [Opção Docker (recomendada)](#-opção-docker-recomendada)
  - [D1. Pré-requisitos Docker](#d1-pré-requisitos)
  - [D2. Subir o container](#d2-subir-o-container-mysql)
  - [D3. Carregar o banco](#d3-carregar-o-banco-de-dados)
  - [D4. Verificar o banco](#d4-verificar-o-banco)
  - [D5. Instalar Python e dependências](#d5-instalar-python-e-dependências)
  - [D6. Configurar e rodar](#d6-configurar-e-rodar-a-aplicação)
- [Opção MySQL local](#opção-mysql-local)
  1. [Pré-requisitos](#1-pré-requisitos)
  2. [Instalar MySQL 8+](#2-instalar-mysql-8)
  3. [Criar o banco de dados](#3-criar-o-banco-de-dados)
  4. [Verificar o banco](#4-verificar-o-banco)
  5. [Instalar Python e dependências](#5-instalar-python-e-dependências)
  6. [Configurar a aplicação](#6-configurar-a-aplicação)
  7. [Rodar a aplicação](#7-rodar-a-aplicação)
- [Credenciais de teste](#8-credenciais-de-teste)
- [Solução de problemas](#9-solução-de-problemas)

---

## 🐳 Opção Docker (recomendada)

Use esta opção se você **não tem MySQL instalado localmente** ou prefere não instalar. Requer apenas Docker Desktop.

### D1. Pré-requisitos

| Software | Versão mínima | Download |
|---|---|---|
| Docker Desktop | 4.0+ | https://www.docker.com/products/docker-desktop/ |
| Python | 3.10+ | https://www.python.org/downloads/ |

> **Windows:** ao instalar o Python, marque **"Add Python to PATH"**.
>
> Verifique que o Docker Desktop está rodando antes de prosseguir (ícone na bandeja do sistema).

### D2. Subir o container MySQL

Na raiz do projeto (pasta `Trabalho_Crud`):

```powershell
docker compose up -d
```

Aguarde o container ficar saudável (~15 segundos). Para confirmar:

```powershell
docker ps
# Deve mostrar hotel_mosquito_db com status "Up" e "(healthy)"
```

> O container usa a porta **3307** no host (para não colidir com MySQL local na 3306).  
> Credenciais: usuário `root`, senha `hotel123`, banco `hotel_mosquito`.

### D3. Carregar o banco de dados

Execute o script SQL completo dentro do container:

```powershell
# Windows PowerShell
Get-Content sql\hotel_mosquito_full.sql -Raw | docker exec -i hotel_mosquito_db mysql -uroot -photel123
```

> ⚠️ O script começa com `DROP DATABASE IF EXISTS hotel_mosquito`. Dados anteriores serão apagados.

Resultado esperado ao final (contagem das tabelas):
```
categorias | quartos | clientes | funcionarios | produtos | reservas | hospedagens | consumos | historicos_preco
5          | 15      | 10       | 5            | 10       | 10       | 8           | 15       | 15
```

### D4. Verificar o banco

```powershell
# Abre o mysql client no container
docker exec -it hotel_mosquito_db mysql -uroot -photel123 hotel_mosquito
```

Dentro do mysql client:

```sql
-- 9 tabelas
SHOW TABLES;

-- 7 views
SHOW FULL TABLES WHERE Table_type = 'VIEW';

-- 2 triggers
SHOW TRIGGERS;

-- contagem dos dados
SELECT
  (SELECT COUNT(*) FROM Categoria_Quarto) AS categorias,
  (SELECT COUNT(*) FROM Quarto)           AS quartos,
  (SELECT COUNT(*) FROM Cliente)          AS clientes,
  (SELECT COUNT(*) FROM Funcionario)      AS funcionarios,
  (SELECT COUNT(*) FROM Produto_Servico)  AS produtos,
  (SELECT COUNT(*) FROM Reserva)          AS reservas,
  (SELECT COUNT(*) FROM Hospedagem)       AS hospedagens,
  (SELECT COUNT(*) FROM Consumo)          AS consumos,
  (SELECT COUNT(*) FROM Historico_Preco)  AS historicos_preco;

EXIT
```

### D5. Instalar Python e dependências

```powershell
# (Opcional) ambiente virtual
python -m venv .venv
.venv\Scripts\Activate.ps1

# Instalar dependência
pip install -r app\requirements.txt
```

### D6. Configurar e rodar a aplicação

O arquivo `app\config.ini` já vem configurado para Docker:

```ini
[database]
host     = localhost
port     = 3307
user     = root
password = hotel123
database = hotel_mosquito
```

Rodar a aplicação (sempre da raiz do projeto):

```powershell
python -m app.main
```

A janela de login aparecerá. Use as [credenciais da seção 8](#8-credenciais-de-teste).

#### Parar / reiniciar o container

```powershell
docker compose stop    # para sem apagar dados
docker compose start   # retoma
docker compose down    # para e remove o container (dados persistem no volume)
docker compose down -v # apaga tudo, incluindo os dados
```

---

## Opção MySQL local

---

## 1. Pré-requisitos

| Software | Versão mínima | Download |
|---|---|---|
| MySQL Server | 8.0+ | https://dev.mysql.com/downloads/mysql/ |
| MySQL Workbench | 8.0+ | https://dev.mysql.com/downloads/workbench/ |
| Python | 3.10+ | https://www.python.org/downloads/ |

> **Windows:** ao instalar o Python, marque a opção **"Add Python to PATH"**.
>
> **Tkinter** já vem incluído no instalador padrão do Python para Windows. No Ubuntu/Debian instale separado: `sudo apt install python3-tk`.

---

## 2. Instalar MySQL 8+

### Windows (instalador)
1. Baixe o **MySQL Installer** em https://dev.mysql.com/downloads/installer/
2. Escolha **"Developer Default"** (inclui MySQL Server + Workbench)
3. Durante a instalação, defina uma senha para o usuário `root` — **anote essa senha**
4. Conclua a instalação e inicie o serviço

### Verificar se o MySQL está rodando
```powershell
# Windows
Get-Service -Name "MySQL*"
# Deve aparecer "MySQL80" com Status "Running"
```

---

## 3. Criar o banco de dados

### Opção A — MySQL Workbench (recomendada)

1. Abra o **MySQL Workbench**
2. Clique em **"Local instance MySQL80"** (ou sua conexão local)
3. No menu: **File → Open SQL Script…**
4. Navegue até a pasta do projeto e selecione: `sql/hotel_mosquito_full.sql`
5. Pressione **Ctrl+Shift+Enter** para executar o script completo
6. Aguarde a execução. Ao final você verá uma linha com os contadores:

```
categorias | quartos | clientes | funcionarios | produtos | reservas | hospedagens | consumos | historicos_preco
5          | 15      | 10       | 5            | 10       | 10       | 8           | 15       | 15
```

> ⚠️ O script começa com `DROP DATABASE IF EXISTS hotel_mosquito`. Se você já tinha dados nesse schema, eles serão apagados.

### Opção B — Linha de comando

```powershell
# Substitua "SUA_SENHA" pela senha do root
mysql -u root -p hotel_mosquito < sql\hotel_mosquito_full.sql
# Quando pedir senha, digite e pressione Enter
```

Ou diretamente no mysql client:
```sql
SOURCE C:/caminho/para/o/projeto/sql/hotel_mosquito_full.sql;
```

---

## 4. Verificar o banco

Após executar o script, abra uma nova aba no Workbench e rode as queries abaixo para confirmar que tudo foi criado corretamente.

### 4.1 Tabelas (deve listar 9)
```sql
USE hotel_mosquito;
SHOW TABLES;
```

Resultado esperado:
```
Categoria_Quarto
Cliente
Consumo
Funcionario
Historico_Preco
Hospedagem
Produto_Servico
Quarto
Reserva
```

### 4.2 Views (deve listar 7)
```sql
SHOW FULL TABLES WHERE Table_type = 'VIEW';
```

Resultado esperado:
```
vw_faturamento_mensal
vw_historico_reservas_cliente
vw_ocupacao_atual
vw_quartos_disponiveis
vw_taxa_ocupacao_mensal
vw_top_clientes_assiduos
vw_top_quartos_reservados
```

### 4.3 Stored Procedures (deve listar ~25)
```sql
SELECT ROUTINE_NAME
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = 'hotel_mosquito'
  AND ROUTINE_TYPE = 'PROCEDURE'
ORDER BY ROUTINE_NAME;
```

### 4.4 Triggers (deve listar 2)
```sql
SHOW TRIGGERS;
```

Resultado esperado:
```
trg_atualiza_preco_quarto   | AFTER UPDATE | Quarto
trg_preco_inicial_quarto    | AFTER INSERT | Quarto
```

### 4.5 Contagem dos dados de exemplo
```sql
SELECT
  (SELECT COUNT(*) FROM Categoria_Quarto) AS categorias,
  (SELECT COUNT(*) FROM Quarto)           AS quartos,
  (SELECT COUNT(*) FROM Cliente)          AS clientes,
  (SELECT COUNT(*) FROM Funcionario)      AS funcionarios,
  (SELECT COUNT(*) FROM Produto_Servico)  AS produtos,
  (SELECT COUNT(*) FROM Reserva)          AS reservas,
  (SELECT COUNT(*) FROM Hospedagem)       AS hospedagens,
  (SELECT COUNT(*) FROM Consumo)          AS consumos,
  (SELECT COUNT(*) FROM Historico_Preco)  AS historicos_preco;
```

Resultado esperado: `5, 15, 10, 5, 10, 10, 8, 15, 15`

---

## 5. Instalar Python e dependências

### 5.1 Verificar Python
```powershell
python --version
# Deve mostrar Python 3.10 ou superior
```

### 5.2 (Recomendado) Criar ambiente virtual
```powershell
# Na raiz do projeto (pasta Trabalho_Crud)
python -m venv .venv
.venv\Scripts\Activate.ps1
```

> Se receber erro de permissão no PowerShell:
> ```powershell
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

### 5.3 Instalar dependências
```powershell
pip install -r app\requirements.txt
```

Isso instala: `mysql-connector-python==8.4.0`

### 5.4 Verificar instalação
```powershell
python -c "import mysql.connector; print('OK:', mysql.connector.__version__)"
# Deve imprimir: OK: 8.4.0
```

---

## 6. Configurar a aplicação

Edite o arquivo `app\config.ini` com os dados da sua instalação MySQL:

```ini
[database]
host = localhost
port = 3306
user = root
password = SUA_SENHA_AQUI
database = hotel_mosquito
```

> Substitua `SUA_SENHA_AQUI` pela senha que você definiu durante a instalação do MySQL.
>
> Se o MySQL não estiver rodando localmente, ajuste `host` e `port` conforme necessário.

---

## 7. Rodar a aplicação

**Sempre execute a partir da raiz do projeto** (pasta `Trabalho_Crud`):

```powershell
python -m app.main
```

A janela de login aparecerá. Use as credenciais da seção abaixo.

---

## 8. Credenciais de teste

| Login    | Senha    | Perfil        | Abas visíveis |
|----------|----------|---------------|---------------|
| gerente1 | senha123 | Gerente       | Clientes, Quartos, **Funcionários**, Reservas, Hospedagem, **Relatórios** |
| gerente2 | senha123 | Gerente       | Clientes, Quartos, **Funcionários**, Reservas, Hospedagem, **Relatórios** |
| recep1   | senha123 | Recepcionista | Clientes, Quartos, Reservas, Hospedagem |
| recep2   | senha123 | Recepcionista | Clientes, Quartos, Reservas, Hospedagem |
| recep3   | senha123 | Recepcionista | Clientes, Quartos, Reservas, Hospedagem |

---

## 9. Solução de problemas

### ❌ `No module named 'app'`
Você está rodando o comando de dentro da pasta `app/`. Volte para a raiz:
```powershell
cd ..   # sobe uma pasta
python -m app.main
```

### ❌ `Falha ao conectar ao MySQL: ...`
- **Docker:** verifique se o container está rodando com `docker ps`. Se não aparecer, rode `docker compose up -d`.
- **MySQL local:** verifique se o serviço está rodando (`Get-Service MySQL*`).
- Confira host, porta, usuário e senha em `app\config.ini`.
- Teste a conexão diretamente (Docker):
  ```powershell
  docker exec -it hotel_mosquito_db mysql -uroot -photel123
  ```

### ❌ Docker: `cannot find //./pipe/dockerDesktopLinuxEngine`
O Docker Desktop não terminou de iniciar. Aguarde ~30 segundos e tente novamente. O ícone do Docker na bandeja do sistema deve estar estático (não animado).

### ❌ Docker: porta 3307 em uso
Outro processo está usando a porta 3307. Verifique com:
```powershell
netstat -ano | findstr :3307
```
Encerre o processo conflitante ou edite `docker-compose.yml` para mapear outra porta (ex: `3308:3306`) e atualize `app\config.ini` correspondentemente.

### ❌ `config.ini nao encontrado`
Confirme que o arquivo `app\config.ini` existe e que você está executando `python -m app.main` da pasta raiz do projeto.

### ❌ `Unknown database 'hotel_mosquito'`
O banco ainda não foi criado. Execute o passo 3 novamente.

### ❌ PowerShell não reconhece `.venv\Scripts\Activate.ps1`
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### ❌ `mysql.connector` não instala (`pip` falha)
Tente com `pip3`:
```powershell
pip3 install mysql-connector-python==8.4.0
```

### ❌ Tkinter não encontrado (Linux/WSL)
```bash
sudo apt-get install python3-tk
```

---

## Estrutura do projeto (referência rápida)

```
Trabalho_Crud/
├── sql/
│   ├── hotel_mosquito_full.sql    ← script único de entrega (use este)
│   ├── 01_schema.sql              ← apenas tabelas + índices
│   ├── 02_views.sql               ← 7 views
│   ├── 03_procedures.sql          ← ~25 stored procedures
│   ├── 04_triggers.sql            ← 2 triggers
│   ├── 05_seed_data.sql           ← dados de exemplo (transacional)
│   └── 99_demo_transacoes.sql     ← demo COMMIT/ROLLBACK/SAVEPOINT
├── app/
│   ├── main.py                    ← entry point: python -m app.main
│   ├── config.ini                 ← EDITAR com sua senha MySQL
│   ├── requirements.txt
│   ├── db/                        ← camada de acesso ao banco
│   └── ui/                        ← interface Tkinter
├── docs/
│   ├── relatorio_tecnico.md
│   └── apresentacao.md
├── DEPLOY.md                      ← este arquivo
└── README.md
```
