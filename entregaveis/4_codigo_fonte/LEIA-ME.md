# Código-fonte — Interface Python/Tkinter

O código-fonte da interface está na pasta `app/` na raiz do projeto.

Estrutura relevante:

```
app/
├── main.py              ← ponto de entrada: python -m app.main
├── config.ini           ← configuração de conexão com o banco
├── requirements.txt     ← dependências Python
├── db/                  ← camada de acesso ao banco (uma função por procedure)
│   ├── auth.py
│   ├── clientes.py
│   ├── quartos.py
│   ├── reservas.py
│   ├── hospedagens.py
│   ├── relatorios.py
│   └── connection.py
└── ui/                  ← interface Tkinter
    ├── login_window.py
    ├── main_window.py
    └── tabs/
        ├── clientes_tab.py
        ├── quartos_tab.py
        ├── funcionarios_tab.py
        ├── reservas_tab.py
        ├── hospedagens_tab.py
        └── relatorios_tab.py
```

Consulte o `DEPLOY.md` na raiz do projeto para instruções completas de instalação.