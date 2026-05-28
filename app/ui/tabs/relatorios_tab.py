"""Aba de Relatorios — so gerente. Banco bloqueia se chamarem mesmo assim."""
from __future__ import annotations

from datetime import date
import tkinter as tk
from tkinter import ttk, messagebox

from app.db import relatorios


class RelatoriosTab(ttk.Frame):
    def __init__(self, parent, conn, user):
        super().__init__(parent)
        self.conn = conn
        self.user = user
        self._build()

    def _build(self):
        nb = ttk.Notebook(self)
        nb.pack(fill=tk.BOTH, expand=True, padx=4, pady=4)

        # 1) Taxa de ocupacao
        f1 = ttk.Frame(nb)
        nb.add(f1, text="Taxa de Ocupacao")
        top1 = ttk.Frame(f1); top1.pack(fill=tk.X, pady=4)
        ttk.Label(top1, text="Ano:").pack(side=tk.LEFT)
        self.ano1 = ttk.Entry(top1, width=6); self.ano1.pack(side=tk.LEFT, padx=4)
        ttk.Label(top1, text="Mes:").pack(side=tk.LEFT)
        self.mes1 = ttk.Entry(top1, width=4); self.mes1.pack(side=tk.LEFT, padx=4)
        ttk.Button(top1, text="Gerar",
                   command=self._gerar_taxa).pack(side=tk.LEFT, padx=4)
        self.tree1 = self._mk_tree(f1,
            ("ano", "mes", "diarias_ocupadas", "total_quartos",
             "dias_no_mes", "taxa_ocupacao_pct"))
        self.ano1.insert(0, str(date.today().year))
        self.mes1.insert(0, str(date.today().month))

        # 2) Top clientes
        f2 = ttk.Frame(nb)
        nb.add(f2, text="Top 10 Clientes")
        ttk.Button(f2, text="Gerar", command=self._gerar_top_clientes).pack(pady=4)
        self.tree2 = self._mk_tree(f2,
            ("id_cliente", "nome", "cpf", "qtd_hospedagens", "total_diarias"))

        # 3) Top quartos
        f3 = ttk.Frame(nb)
        nb.add(f3, text="Top 10 Quartos")
        ttk.Button(f3, text="Gerar", command=self._gerar_top_quartos).pack(pady=4)
        self.tree3 = self._mk_tree(f3,
            ("id_quarto", "numero", "categoria", "qtd_reservas"))

        # 4) Faturamento mensal
        f4 = ttk.Frame(nb)
        nb.add(f4, text="Faturamento Mensal")
        top4 = ttk.Frame(f4); top4.pack(fill=tk.X, pady=4)
        ttk.Label(top4, text="Ano:").pack(side=tk.LEFT)
        self.ano4 = ttk.Entry(top4, width=6); self.ano4.pack(side=tk.LEFT, padx=4)
        ttk.Label(top4, text="Mes:").pack(side=tk.LEFT)
        self.mes4 = ttk.Entry(top4, width=4); self.mes4.pack(side=tk.LEFT, padx=4)
        ttk.Button(top4, text="Gerar",
                   command=self._gerar_faturamento).pack(side=tk.LEFT, padx=4)
        self.tree4 = self._mk_tree(f4,
            ("ano", "mes", "qtd_checkouts", "total_diarias",
             "total_consumos", "faturamento_total"))
        self.ano4.insert(0, str(date.today().year))
        self.mes4.insert(0, str(date.today().month))

    def _mk_tree(self, parent, cols):
        tree = ttk.Treeview(parent, columns=cols, show="headings", height=16)
        for c in cols:
            tree.heading(c, text=c)
            tree.column(c, width=130)
        tree.pack(fill=tk.BOTH, expand=True, padx=4, pady=4)
        return tree

    def _populate(self, tree, rows):
        for i in tree.get_children():
            tree.delete(i)
        for r in rows:
            tree.insert("", tk.END, values=tuple(r))

    def _gerar_taxa(self):
        try:
            rows = relatorios.taxa_ocupacao(
                self.conn, self.user["id_funcionario"],
                int(self.ano1.get()), int(self.mes1.get()))
        except (RuntimeError, ValueError) as e:
            messagebox.showerror("Erro", str(e)); return
        self._populate(self.tree1, rows)

    def _gerar_top_clientes(self):
        try:
            rows = relatorios.top_clientes(self.conn, self.user["id_funcionario"])
        except RuntimeError as e:
            messagebox.showerror("Erro", str(e)); return
        self._populate(self.tree2, rows)

    def _gerar_top_quartos(self):
        try:
            rows = relatorios.top_quartos(self.conn, self.user["id_funcionario"])
        except RuntimeError as e:
            messagebox.showerror("Erro", str(e)); return
        self._populate(self.tree3, rows)

    def _gerar_faturamento(self):
        try:
            rows = relatorios.faturamento_mensal(
                self.conn, self.user["id_funcionario"],
                int(self.ano4.get()), int(self.mes4.get()))
        except (RuntimeError, ValueError) as e:
            messagebox.showerror("Erro", str(e)); return
        self._populate(self.tree4, rows)
