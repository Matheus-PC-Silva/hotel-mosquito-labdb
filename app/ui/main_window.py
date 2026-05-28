"""Janela principal com Notebook de abas. Conteudo varia por perfil."""
from __future__ import annotations

import tkinter as tk
from tkinter import ttk

from app.db.auth import UserInfo
from app.ui.tabs.clientes_tab import ClientesTab
from app.ui.tabs.quartos_tab import QuartosTab
from app.ui.tabs.funcionarios_tab import FuncionariosTab
from app.ui.tabs.reservas_tab import ReservasTab
from app.ui.tabs.hospedagens_tab import HospedagensTab
from app.ui.tabs.relatorios_tab import RelatoriosTab


class MainWindow:
    def __init__(self, root: tk.Tk, conn, user: UserInfo):
        self.root = root
        self.conn = conn
        self.user = user

        root.title(f"Hotel do Mosquito — {user['nome']} ({user['perfil']})")
        root.geometry("1100x650")

        notebook = ttk.Notebook(root)
        notebook.pack(fill=tk.BOTH, expand=True, padx=8, pady=(8, 0))

        notebook.add(ClientesTab(notebook, conn, user),    text="Clientes")
        notebook.add(QuartosTab(notebook, conn, user),     text="Quartos")
        if user["perfil"] == "Gerente":
            notebook.add(FuncionariosTab(notebook, conn, user), text="Funcionarios")
        notebook.add(ReservasTab(notebook, conn, user),    text="Reservas")
        hosp_tab = HospedagensTab(notebook, conn, user)
        notebook.add(hosp_tab, text="Hospedagem")
        if user["perfil"] == "Gerente":
            notebook.add(RelatoriosTab(notebook, conn, user),   text="Relatorios")

        def _on_tab_changed(_evt):
            tab = notebook.nametowidget(notebook.select())
            if hasattr(tab, "_reload"):
                tab._reload()

        notebook.bind("<<NotebookTabChanged>>", _on_tab_changed)

        if user["perfil"] == "Recepcionista":
            notebook.select(hosp_tab)

        # Status bar
        status = ttk.Frame(root, relief=tk.SUNKEN, padding=4)
        status.pack(fill=tk.X, side=tk.BOTTOM)
        ttk.Label(status, text=f"Logado como: {user['nome']} ({user['perfil']})")\
            .pack(side=tk.LEFT)
        ttk.Button(status, text="Sair", command=root.destroy)\
            .pack(side=tk.RIGHT)
