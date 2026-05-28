"""Aba de Reservas: listar, registrar nova, cancelar."""
from __future__ import annotations

import tkinter as tk
from tkinter import ttk, messagebox
from tkcalendar import DateEntry

from app.db import reservas, clientes, quartos


class ReservasTab(ttk.Frame):
    def __init__(self, parent, conn, user):
        super().__init__(parent)
        self.conn = conn
        self.user = user
        self._build()
        self._reload_combos()
        self._reload()

    def _build(self):
        top = ttk.Frame(self)
        top.pack(side=tk.TOP, fill=tk.X, padx=4, pady=4)

        ttk.Label(top, text="Cliente:").grid(row=0, column=0, sticky="w")
        self.cb_cliente = ttk.Combobox(top, state="readonly", width=40)
        self.cb_cliente.grid(row=0, column=1, padx=4)

        ttk.Label(top, text="Quarto:").grid(row=0, column=2, sticky="w")
        self.cb_quarto = ttk.Combobox(top, state="readonly", width=30)
        self.cb_quarto.grid(row=0, column=3, padx=4)

        ttk.Label(top, text="Check-in:").grid(row=1, column=0, sticky="w")
        self.entry_checkin = DateEntry(top, width=14, date_pattern="yyyy-mm-dd",
                                       showweeknumbers=False, firstweekday="sunday")
        self.entry_checkin.grid(row=1, column=1, sticky="w", padx=4)

        ttk.Label(top, text="Check-out:").grid(row=1, column=2, sticky="w")
        self.entry_checkout = DateEntry(top, width=14, date_pattern="yyyy-mm-dd",
                                        showweeknumbers=False, firstweekday="sunday")
        self.entry_checkout.grid(row=1, column=3, sticky="w", padx=4)

        ttk.Button(top, text="Registrar Reserva", command=self._registrar)\
            .grid(row=2, column=0, columnspan=2, sticky="w", pady=6)
        ttk.Button(top, text="Cancelar Reserva Selecionada", command=self._cancelar)\
            .grid(row=2, column=2, columnspan=2, sticky="w", pady=6)

        cols = ("id", "cliente", "quarto", "checkin_prev", "checkout_prev", "status")
        self.tree = ttk.Treeview(self, columns=cols, show="headings", height=18)
        for c, w in zip(cols, (40, 180, 100, 120, 120, 100)):
            self.tree.heading(c, text=c.capitalize())
            self.tree.column(c, width=w)
        self.tree.pack(fill=tk.BOTH, expand=True, padx=4, pady=4)

    def _reload_combos(self):
        try:
            self._clientes = clientes.listar(self.conn)
            self._quartos_disp = quartos.disponiveis(self.conn)
        except RuntimeError as e:
            messagebox.showerror("Erro", str(e))
            self._clientes = []
            self._quartos_disp = []
        self.cb_cliente["values"] = [f"{c[0]} - {c[1]}" for c in self._clientes]
        self.cb_quarto["values"] = [
            f"{q['id_quarto']} - {q['numero']} ({q['categoria_nome']}) R$ {q['preco_praticado']}"
            for q in self._quartos_disp
        ]

    def _reload(self):
        for i in self.tree.get_children():
            self.tree.delete(i)
        try:
            rows = reservas.listar(self.conn)
        except RuntimeError as e:
            messagebox.showerror("Erro", str(e))
            return
        for r in rows:
            # r = (id, id_cli, cli_nome, id_q, q_num, id_f, f_nome, ci, co, status, criacao)
            self.tree.insert("", tk.END, values=(r[0], r[2], r[4], r[7], r[8], r[9]))

    def _parse_id_from_combo(self, value: str) -> int | None:
        if not value:
            return None
        try:
            return int(value.split(" - ", 1)[0])
        except ValueError:
            return None

    def _registrar(self):
        id_cli = self._parse_id_from_combo(self.cb_cliente.get())
        id_q   = self._parse_id_from_combo(self.cb_quarto.get())
        if id_cli is None or id_q is None:
            messagebox.showerror("Erro", "Selecione cliente e quarto")
            return
        try:
            reservas.registrar(
                self.conn, id_cli, id_q, self.user["id_funcionario"],
                self.entry_checkin.get().strip(),
                self.entry_checkout.get().strip(),
            )
        except RuntimeError as e:
            messagebox.showerror("Erro ao registrar", str(e))
            return
        messagebox.showinfo("Sucesso", "Reserva registrada")
        self._reload_combos()
        self._reload()

    def _cancelar(self):
        sel = self.tree.selection()
        if not sel:
            messagebox.showinfo("Aviso", "Selecione uma reserva primeiro")
            return
        id_reserva = int(self.tree.item(sel[0])["values"][0])
        if not messagebox.askyesno("Confirmar", "Cancelar esta reserva?"):
            return
        try:
            reservas.cancelar(self.conn, id_reserva)
        except RuntimeError as e:
            messagebox.showerror("Erro ao cancelar", str(e))
            return
        self._reload()
