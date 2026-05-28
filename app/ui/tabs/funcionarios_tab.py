"""Aba de CRUD de Funcionarios. So gerente acessa."""
from __future__ import annotations

import tkinter as tk
from tkinter import ttk, messagebox

from app.db import funcionarios


PERFIS = ("Recepcionista", "Gerente")


class FuncionariosTab(ttk.Frame):
    def __init__(self, parent, conn, user):
        super().__init__(parent)
        self.conn = conn
        self.user = user
        self._build()
        self._reload()

    def _build(self):
        left = ttk.Frame(self)
        left.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=4, pady=4)

        cols = ("id", "nome", "cpf", "cargo", "login", "perfil")
        self.tree = ttk.Treeview(left, columns=cols, show="headings", height=22)
        for c, w in zip(cols, (40, 180, 120, 150, 100, 120)):
            self.tree.heading(c, text=c.capitalize())
            self.tree.column(c, width=w)
        self.tree.pack(fill=tk.BOTH, expand=True)
        self.tree.bind("<<TreeviewSelect>>", self._on_select)

        form = ttk.LabelFrame(self, text="Funcionario", padding=8)
        form.pack(side=tk.RIGHT, fill=tk.Y, padx=4, pady=4)

        self.vars = {k: tk.StringVar() for k in
                     ("nome", "cpf", "cargo", "login", "senha", "perfil")}
        self.vars["perfil"].set("Recepcionista")
        rows = [
            ("Nome",  "nome"),
            ("CPF",   "cpf"),
            ("Cargo", "cargo"),
            ("Login", "login"),
            ("Senha (vazio = manter)", "senha"),
        ]
        for i, (lbl, key) in enumerate(rows):
            ttk.Label(form, text=lbl + ":").grid(row=i, column=0, sticky="w", pady=2)
            show = "*" if key == "senha" else None
            ttk.Entry(form, textvariable=self.vars[key], width=24, show=show or "")\
                .grid(row=i, column=1, pady=2)
        ttk.Label(form, text="Perfil:").grid(row=5, column=0, sticky="w", pady=2)
        ttk.Combobox(form, textvariable=self.vars["perfil"], values=PERFIS,
                     state="readonly", width=22)\
            .grid(row=5, column=1, pady=2)

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
            rows = funcionarios.listar(self.conn, self.user["id_funcionario"])
        except RuntimeError as e:
            messagebox.showerror("Erro", str(e))
            return
        for r in rows:
            self.tree.insert("", tk.END, values=r)

    def _on_select(self, _evt):
        sel = self.tree.selection()
        if not sel:
            return
        vals = self.tree.item(sel[0])["values"]
        self.selected_id = int(vals[0])
        self.vars["nome"].set(vals[1])
        self.vars["cpf"].set(vals[2])
        self.vars["cargo"].set(vals[3])
        self.vars["login"].set(vals[4])
        self.vars["perfil"].set(vals[5])
        self.vars["senha"].set("")

    def _novo(self):
        self.selected_id = None
        for v in self.vars.values():
            v.set("")
        self.vars["perfil"].set("Recepcionista")

    def _salvar(self):
        try:
            if self.selected_id is None:
                if not self.vars["senha"].get():
                    messagebox.showerror("Erro", "Senha obrigatoria para novo funcionario")
                    return
                funcionarios.criar(
                    self.conn, self.user["id_funcionario"],
                    self.vars["nome"].get().strip(),
                    self.vars["cpf"].get().strip(),
                    self.vars["cargo"].get().strip(),
                    self.vars["login"].get().strip(),
                    self.vars["senha"].get(),
                    self.vars["perfil"].get(),
                )
            else:
                funcionarios.atualizar(
                    self.conn, self.user["id_funcionario"], self.selected_id,
                    self.vars["nome"].get().strip(),
                    self.vars["cpf"].get().strip(),
                    self.vars["cargo"].get().strip(),
                    self.vars["login"].get().strip(),
                    self.vars["senha"].get(),
                    self.vars["perfil"].get(),
                )
        except RuntimeError as e:
            messagebox.showerror("Erro ao salvar", str(e))
            return
        messagebox.showinfo("Sucesso", "Funcionario salvo")
        self._novo()
        self._reload()

    def _excluir(self):
        if self.selected_id is None:
            return
        if not messagebox.askyesno("Confirmar", "Excluir este funcionario?"):
            return
        try:
            funcionarios.excluir(self.conn, self.user["id_funcionario"], self.selected_id)
        except RuntimeError as e:
            messagebox.showerror("Erro ao excluir", str(e))
            return
        self._novo()
        self._reload()
