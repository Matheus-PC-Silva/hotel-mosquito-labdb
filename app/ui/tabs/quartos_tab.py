"""Aba de Quartos. Gerentes: CRUD completo. Recepcionistas: somente leitura."""
from __future__ import annotations

import tkinter as tk
from tkinter import ttk, messagebox, simpledialog

from app.db import quartos, catalogos


STATUS_OPCOES = ("Disponivel", "Ocupado", "Limpeza", "Manutencao")

COLS     = ("id", "numero", "andar", "categoria", "capacidade", "status", "preco")
COL_WIDTHS = (40,  70,      60,      110,          80,           100,      80)


class QuartosTab(ttk.Frame):
    def __init__(self, parent, conn, user):
        super().__init__(parent)
        self.conn = conn
        self.user = user
        self._is_gerente = user["perfil"] == "Gerente"
        if self._is_gerente:
            self._build_gerente()
        else:
            self._build_readonly()
        self._reload()

    # ------------------------------------------------------------------
    # Layout somente-leitura (Recepcionista)
    # ------------------------------------------------------------------
    def _build_readonly(self):
        self.tree = ttk.Treeview(self, columns=COLS, show="headings", height=25)
        for c, w in zip(COLS, COL_WIDTHS):
            self.tree.heading(c, text=c.capitalize())
            self.tree.column(c, width=w)
        self.tree.pack(fill=tk.BOTH, expand=True, padx=4, pady=4)

    # ------------------------------------------------------------------
    # Layout completo (Gerente)
    # ------------------------------------------------------------------
    def _build_gerente(self):
        left = ttk.Frame(self)
        left.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=4, pady=4)

        self.tree = ttk.Treeview(left, columns=COLS, show="headings", height=22)
        for c, w in zip(COLS, COL_WIDTHS):
            self.tree.heading(c, text=c.capitalize())
            self.tree.column(c, width=w)
        self.tree.pack(fill=tk.BOTH, expand=True)
        self.tree.bind("<<TreeviewSelect>>", self._on_select)

        right = ttk.LabelFrame(self, text="Quarto", padding=8)
        right.pack(side=tk.RIGHT, fill=tk.Y, padx=4, pady=4)

        self.vars = {
            "numero":     tk.StringVar(),
            "andar":      tk.StringVar(),
            "capacidade": tk.StringVar(),
            "status":     tk.StringVar(value="Disponivel"),
            "preco":      tk.StringVar(),
            "categoria":  tk.StringVar(),
        }
        for i, (lbl, key) in enumerate([
            ("Numero",     "numero"),
            ("Andar",      "andar"),
            ("Capacidade", "capacidade"),
            ("Preco (apenas Novo)", "preco"),
        ]):
            ttk.Label(right, text=lbl + ":").grid(row=i, column=0, sticky="w", pady=2)
            ttk.Entry(right, textvariable=self.vars[key], width=24).grid(row=i, column=1, pady=2)

        ttk.Label(right, text="Status:").grid(row=4, column=0, sticky="w", pady=2)
        ttk.Combobox(right, textvariable=self.vars["status"],
                     values=STATUS_OPCOES, state="readonly", width=22)\
            .grid(row=4, column=1, pady=2)

        ttk.Label(right, text="Categoria:").grid(row=5, column=0, sticky="w", pady=2)
        self.cb_categoria = ttk.Combobox(right, textvariable=self.vars["categoria"],
                                         state="readonly", width=22)
        self.cb_categoria.grid(row=5, column=1, pady=2)
        self._reload_categorias()

        self.selected_id: int | None = None

        btns = ttk.Frame(right)
        btns.grid(row=10, column=0, columnspan=2, pady=8)
        ttk.Button(btns, text="Novo",    command=self._novo).pack(side=tk.LEFT, padx=2)
        ttk.Button(btns, text="Salvar",  command=self._salvar).pack(side=tk.LEFT, padx=2)
        ttk.Button(btns, text="Excluir", command=self._excluir).pack(side=tk.LEFT, padx=2)
        ttk.Button(right, text="Alterar Preco", command=self._alterar_preco)\
            .grid(row=11, column=0, columnspan=2, sticky="ew", pady=2)
        ttk.Button(right, text="Ver Historico de Preco", command=self._ver_historico)\
            .grid(row=12, column=0, columnspan=2, sticky="ew", pady=2)

    def _reload_categorias(self):
        try:
            self._categorias = catalogos.listar_categorias(self.conn)
        except RuntimeError as e:
            messagebox.showerror("Erro", str(e))
            self._categorias = []
        self.cb_categoria["values"] = [c[1] for c in self._categorias]
        if self._categorias:
            self.vars["categoria"].set(self._categorias[0][1])

    def _reload(self):
        for i in self.tree.get_children():
            self.tree.delete(i)
        try:
            rows = quartos.listar(self.conn)
        except RuntimeError as e:
            messagebox.showerror("Erro", str(e))
            return
        for r in rows:
            # r = (id, numero, andar, capacidade, status, preco, id_categoria, categoria_nome)
            self.tree.insert("", tk.END, values=(r[0], r[1], r[2], r[7], r[3], r[4], r[5]))

    # ------------------------------------------------------------------
    # Handlers (apenas Gerente chega aqui)
    # ------------------------------------------------------------------
    def _on_select(self, _evt):
        sel = self.tree.selection()
        if not sel:
            return
        vals = self.tree.item(sel[0])["values"]
        self.selected_id = int(vals[0])
        self.vars["numero"].set(vals[1])
        self.vars["andar"].set(vals[2])
        self.vars["categoria"].set(vals[3])
        self.vars["capacidade"].set(vals[4])
        self.vars["status"].set(vals[5])
        self.vars["preco"].set(vals[6])
        self.cb_categoria.config(state="readonly")

    def _novo(self):
        self.selected_id = None
        for k in self.vars:
            self.vars[k].set("")
        self.vars["status"].set("Disponivel")
        if self._categorias:
            self.vars["categoria"].set(self._categorias[0][1])
        self.cb_categoria.config(state="readonly")

    def _id_categoria_por_nome(self, nome):
        for c in self._categorias:
            if c[1] == nome:
                return c[0]
        return None

    def _salvar(self):
        id_cat = self._id_categoria_por_nome(self.vars["categoria"].get())
        if id_cat is None:
            messagebox.showerror("Erro", "Selecione uma categoria")
            return
        try:
            if self.selected_id is None:
                quartos.criar(
                    self.conn,
                    self.vars["numero"].get().strip(),
                    int(self.vars["andar"].get()),
                    int(self.vars["capacidade"].get()),
                    self.vars["status"].get(),
                    float(self.vars["preco"].get()),
                    id_cat,
                )
            else:
                quartos.atualizar(
                    self.conn, self.selected_id,
                    self.vars["numero"].get().strip(),
                    int(self.vars["andar"].get()),
                    int(self.vars["capacidade"].get()),
                    self.vars["status"].get(),
                )
                quartos.atualizar_categoria(
                    self.conn, self.selected_id, id_cat,
                    self.user["id_funcionario"],
                )
        except (RuntimeError, ValueError) as e:
            messagebox.showerror("Erro ao salvar", str(e))
            return
        messagebox.showinfo("Sucesso", "Quarto salvo")
        self._novo()
        self._reload()

    def _excluir(self):
        if self.selected_id is None:
            return
        if not messagebox.askyesno("Confirmar", "Excluir este quarto?"):
            return
        try:
            quartos.excluir(self.conn, self.selected_id)
        except RuntimeError as e:
            messagebox.showerror("Erro ao excluir", str(e))
            return
        self._novo()
        self._reload()

    def _alterar_preco(self):
        if self.selected_id is None:
            messagebox.showinfo("Aviso", "Selecione um quarto primeiro")
            return
        novo = simpledialog.askfloat("Alterar Preco", "Novo preco da diaria:", minvalue=0.0)
        if novo is None:
            return
        try:
            quartos.atualizar_preco(self.conn, self.selected_id, novo,
                                    self.user["id_funcionario"])
        except RuntimeError as e:
            messagebox.showerror("Erro", str(e))
            return
        messagebox.showinfo("OK", "Preco atualizado (trigger ativada)")
        self._reload()

    def _ver_historico(self):
        if self.selected_id is None:
            messagebox.showinfo("Aviso", "Selecione um quarto primeiro")
            return
        try:
            rows = quartos.historico_preco(self.conn, self.selected_id)
        except RuntimeError as e:
            messagebox.showerror("Erro", str(e))
            return
        win = tk.Toplevel(self)
        win.title(f"Historico de Preco — Quarto id {self.selected_id}")
        cols = ("id", "preco", "inicio", "fim")
        tree = ttk.Treeview(win, columns=cols, show="headings", height=12)
        for c, w in zip(cols, (50, 100, 180, 180)):
            tree.heading(c, text=c.capitalize())
            tree.column(c, width=w)
        tree.pack(fill=tk.BOTH, expand=True)
        for r in rows:
            tree.insert("", tk.END, values=(r[0], r[1], r[2], r[3] or "(vigente)"))
