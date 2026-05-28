# Hotel do Mosquito — Sistema de Gerenciamento

Trabalho prático da disciplina Laboratório de Banco de Dados. Sistema CRUD em
MySQL + Python/Tkinter com comunicação 100% encapsulada em stored procedures e
views.

## Deploy rápido

Escolha a opção que se aplica à sua situação:

| Situação | Opção |
|---|---|
| Tem PC com Docker instalado | [Opção Docker](DEPLOY.md#-opção-docker-recomendada) ← recomendada |
| Tem PC com MySQL instalado | [Opção MySQL local](DEPLOY.md#opção-mysql-local) |
| **Sem PC — só celular** | [Rodar no Google Colab ↓](#-sem-pc-rodar-no-google-colab) |

---

## 🚀 Sem PC — Rodar no Google Colab

O notebook abre o sistema completo no navegador via noVNC. Funciona em **qualquer celular** com Chrome ou Firefox.

### Passo a passo (3 cliques)

**1.** Abra o notebook no Colab:

[![Abrir no Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/Matheus-PC-Silva/hotel-mosquito-labdb/blob/main/colab_hotel_mosquito.ipynb)

> Link direto: `https://colab.research.google.com/github/Matheus-PC-Silva/hotel-mosquito-labdb/blob/main/colab_hotel_mosquito.ipynb`

**2.** Execute as células em ordem clicando em ▶ em cada uma.
A **Célula 1** demora ~2 minutos (instala MySQL e configura o ambiente).

**3.** A **Célula 3** exibirá um link. Abra esse link no navegador — a janela do sistema aparecerá. Use as credenciais abaixo para entrar.

---

## Credenciais de teste

| Login    | Senha    | Perfil        |
|----------|----------|---------------|
| gerente1 | senha123 | Gerente       |
| gerente2 | senha123 | Gerente       |
| recep1   | senha123 | Recepcionista |
| recep2   | senha123 | Recepcionista |
| recep3   | senha123 | Recepcionista |

---

## Estrutura do projeto

```
hotel-mosquito-labdb/
├── sql/                        ← scripts SQL
│   ├── hotel_mosquito_full.sql ← script único (use este para deploy)
│   ├── 01_schema.sql
│   ├── 02_views.sql
│   ├── 03_procedures.sql
│   ├── 04_triggers.sql
│   ├── 05_seed_data.sql
│   └── 99_demo_transacoes.sql
├── app/                        ← aplicação Python/Tkinter
│   ├── main.py
│   ├── config.ini
│   ├── db/                     ← uma função por procedure
│   └── ui/                     ← abas Tkinter
├── docs/
│   ├── relatorio_tecnico.md
│   ├── apresentacao_db.html
│   ├── mer.png / mer.dbml
│   └── BANCO_DE_DADOS.md
├── colab_hotel_mosquito.ipynb  ← notebook para rodar no Colab
├── docker-compose.yml
├── DEPLOY.md                   ← guia completo de deploy
└── README.md
```

Para o guia completo de deploy com Docker ou MySQL local, veja [DEPLOY.md](DEPLOY.md).
