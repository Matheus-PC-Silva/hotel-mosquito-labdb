# Entregáveis — Hotel do Mosquito

**Disciplina:** Laboratório de Banco de Dados  
**Entrega:** 01/06/2026  
**Grupo:** Camili de Moura Marangoni · Lucas Sobrinho Santos · Maria Eduarda Patu Ângelo da Silva · Matheus Pinheiro de Camargo Silva · Willian Alexandre Schwingel Ferreira

---

## Conteúdo desta pasta

| Pasta | Entregável | Arquivo principal |
|---|---|---|
| `1_script_sql/` | Script SQL completo | `hotel_mosquito_full.sql` |
| `2_relatorio_tecnico/` | Relatório Técnico | `relatorio_tecnico.pdf` |
| `3_apresentacao/` | Apresentação | `apresentacao_db.html` |
| `4_codigo_fonte/` | Código-fonte da interface | ver instruções abaixo |

---

## Como executar o código-fonte

O código-fonte completo está na pasta `app/` na raiz do projeto (acima desta pasta).  
Consulte o `DEPLOY.md` na raiz para instruções detalhadas de instalação e execução.

**Resumo rápido (com Docker):**

```powershell
# Na raiz do projeto (pasta pai desta)
docker compose up -d
Get-Content sql\hotel_mosquito_full.sql -Raw | docker exec -i hotel_mosquito_db mysql -uroot -photel123
pip install -r app\requirements.txt
python -m app.main
```

**Credenciais de teste:**

| Login | Senha | Perfil |
|---|---|---|
| gerente1 | senha123 | Gerente |
| recep1 | senha123 | Recepcionista |

---

## Como abrir a apresentação

Abra o arquivo `3_apresentacao/apresentacao_db.html` em qualquer navegador moderno (Chrome, Firefox, Edge).  
Navegue pelos slides com as **setas do teclado** (← →) ou com os botões na tela.