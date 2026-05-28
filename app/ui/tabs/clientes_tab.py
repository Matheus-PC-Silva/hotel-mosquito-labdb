"""Aba de CRUD de Clientes."""
from __future__ import annotations

import tkinter as tk
from tkinter import ttk, messagebox

from app.db import clientes


class ClientesTab(ttk.Frame):
    def __init__(self, parent, conn, user):
        super().__init__(parent)
        self.conn = conn
        self._build()
        self._reload()

    def _build(self):
        left = ttk.Frame(self)
        left.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=4, pady=4)

        filt = ttk.Frame(left)
        filt.pack(fill=tk.X, pady=(0, 4))
        ttk.Label(filt, text="Filtro (nome ou CPF):").pack(side=tk.LEFT)
        self.entry_filtro = ttk.Entry(filt)
        self.entry_filtro.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=4)
        ttk.Button(filt, text="Buscar", command=self._reload).pack(side=tk.LEFT)

        cols = ("id", "nome", "cpf", "email", "telefone")
        self.tree = ttk.Treeview(left, columns=cols, show="headings", height=20)
        for c, w in zip(cols, (50, 200, 120, 200, 120)):
            self.tree.heading(c, text=c.capitalize())
            self.tree.column(c, width=w)
        self.tree.pack(fill=tk.BOTH, expand=True)
        self.tree.bind("<<TreeviewSelect>>", self._on_select)

        form = ttk.LabelFrame(self, text="Cliente", padding=8)
        form.pack(side=tk.RIGHT, fill=tk.Y, padx=4, pady=4)
        self.vars = {k: tk.StringVar() for k in
                     ("nome", "cpf", "email", "telefone", "endereco")}
        for i, (k, label) in enumerate([
            ("nome", "Nome"), ("cpf", "CPF"), ("email", "E-mail"),
            ("telefone", "Telefone"), ("endereco", "Endereco"),
        ]):
            ttk.Label(form, text=label + ":").grid(row=i, column=0, sticky="w", pady=2)
            ttk.Entry(form, textvariable=self.vars[k], width=30)\
                .grid(row=i, column=1, pady=2)

        self.selected_id: int | None = None

        btns = ttk.Frame(form)
        btns.grid(row=10, column=0, columnspan=2, pady=8)
        ttk.Button(btns, text="Novo",    command=self._novo).pack(side=tk.LEFT, padx=2)
        ttk.Button(btns, text="Salvar",  command=self._salvar).pack(side=tk.LEFT, padx=2)
        ttk.Button(btns, text="Excluir", command=self._excluir).pack(side=tk.LEFT, padx=2)

    def _reload(self):
        for i in self.tree.get_children():
            self.tree.delete(i)
        try:
            rows = clientes.listar(self.conn, self.entry_filtro.get().strip() or None)
        except RuntimeError as e:
            messagebox.showerror("Erro", str(e))
            return
        for r in rows:
            self.tree.insert("", tk.END, values=(r[0], r[1], r[2], r[3], r[4]))

    def _on_select(self, _evt):
        sel = self.tree.selection()
        if not sel:
            return
        vals = self.tree.item(sel[0])["values"]
        self.selected_id = int(vals[0])
        try:
            full = clientes.obter(self.conn, self.selected_id)
        except RuntimeError as e:
            messagebox.showerror("Erro", str(e))
            return
        if not full:
            return
        self.vars["nome"].set(full[1])
        self.vars["cpf"].set(full[2])
        self.vars["email"].set(full[3])
        self.vars["telefone"].set(full[4])
        self.vars["endereco"].set(full[5])

    def _novo(self):
        self.selected_id = None
        for v in self.vars.values():
            v.set("")
        self.tree.selection_remove(*self.tree.selection())

    def _salvar(self):
        try:
            if self.selected_id is None:
                clientes.criar(self.conn,
                               self.vars["nome"].get().strip(),
                               self.vars["cpf"].get().strip(),
                               self.vars["email"].get().strip(),
                               self.vars["telefone"].get().strip(),
                               self.vars["endereco"].get().strip())
            else:
                clientes.atualizar(self.conn, self.selected_id,
                                   self.vars["nome"].get().strip(),
                                   self.vars["cpf"].get().strip(),
                                   self.vars["email"].get().strip(),
                                   self.vars["telefone"].get().strip(),
                                   self.vars["endereco"].get().strip())
        except RuntimeError as e:
            messagebox.showerror("Erro ao salvar", str(e))
            return
        messagebox.showinfo("Sucesso", "Cliente salvo")
        self._novo()
        self._reload()

    def _excluir(self):
        if self.selected_id is None:
            return
        if not messagebox.askyesno("Confirmar", "Excluir este cliente?"):
            return
        try:
            clientes.excluir(self.conn, self.selected_id)
        except RuntimeError as e:
            messagebox.showerror("Erro ao excluir", str(e))
            return
        self._novo()
        self._reload()
