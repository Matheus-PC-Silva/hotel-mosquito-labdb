"""Aba de Hospedagem: vista unificada de check-in, ativas, consumo e check-out."""
from __future__ import annotations

import tkinter as tk
from tkinter import ttk, messagebox

from app.db import reservas, hospedagens, catalogos


class HospedagensTab(ttk.Frame):
    def __init__(self, parent, conn, user):
        super().__init__(parent)
        self.conn = conn
        self.user = user
        self._build()
        self._reload_produtos()
        self._reload()

    def _build(self):
        # ---- Secao superior: Reservas Confirmadas aguardando Check-in ----
        frm_ci = ttk.LabelFrame(self, text="Reservas Agendadas — Aguardando Chegada do Cliente",
                                 padding=6)
        frm_ci.pack(fill=tk.X, padx=6, pady=(6, 2))

        cols_ci = ("id", "cliente", "quarto", "checkin_prev", "checkout_prev")
        self.tree_ci = ttk.Treeview(frm_ci, columns=cols_ci, show="headings", height=5)
        for c, w in zip(cols_ci, (40, 200, 100, 120, 120)):
            self.tree_ci.heading(c, text=c.capitalize())
            self.tree_ci.column(c, width=w)
        self.tree_ci.pack(fill=tk.X, side=tk.LEFT, expand=True)

        ttk.Button(frm_ci, text="Realizar\nCheck-in",
                   command=self._realizar_checkin).pack(side=tk.LEFT, padx=8)

        # ---- Secao inferior: Hospedagens Ativas + Consumo + Check-out ----
        frm_at = ttk.LabelFrame(self, text="Hospedagens Ativas", padding=6)
        frm_at.pack(fill=tk.BOTH, expand=True, padx=6, pady=(2, 6))

        cols_at = ("id", "cliente", "quarto", "checkin", "preco_diaria", "consumo_atual")
        self.tree_at = ttk.Treeview(frm_at, columns=cols_at, show="headings", height=10)
        for c, w in zip(cols_at, (40, 200, 80, 150, 100, 120)):
            self.tree_at.heading(c, text=c.capitalize())
            self.tree_at.column(c, width=w)
        self.tree_at.pack(fill=tk.X, padx=2, pady=(2, 4))

        consumo_frame = ttk.LabelFrame(frm_at, text="Lancar Consumo", padding=6)
        consumo_frame.pack(fill=tk.X, padx=2, pady=2)
        ttk.Label(consumo_frame, text="Produto/Servico:").grid(row=0, column=0, sticky="w")
        self.cb_produto = ttk.Combobox(consumo_frame, state="readonly", width=40)
        self.cb_produto.grid(row=0, column=1, padx=4)
        ttk.Label(consumo_frame, text="Quantidade:").grid(row=0, column=2, sticky="w")
        self.entry_qtd = ttk.Entry(consumo_frame, width=8)
        self.entry_qtd.grid(row=0, column=3, padx=4)
        ttk.Button(consumo_frame, text="Lancar", command=self._lancar_consumo)\
            .grid(row=0, column=4, padx=4)

        ttk.Button(frm_at, text="Realizar Check-out",
                   command=self._realizar_checkout).pack(pady=4)

    def _reload_produtos(self):
        try:
            self._produtos = catalogos.listar_produtos(self.conn)
        except RuntimeError as e:
            messagebox.showerror("Erro", str(e))
            self._produtos = []
        self.cb_produto["values"] = [
            f"{p[0]} - {p[1]} ({p[3]}) R$ {p[2]}" for p in self._produtos
        ]

    def _reload(self):
        for i in self.tree_ci.get_children():
            self.tree_ci.delete(i)
        try:
            confs = reservas.listar(self.conn, status="Confirmada")
        except RuntimeError as e:
            messagebox.showerror("Erro", str(e))
            confs = []
        for r in confs:
            self.tree_ci.insert("", tk.END, values=(r[0], r[2], r[4], r[7], r[8]))

        for i in self.tree_at.get_children():
            self.tree_at.delete(i)
        try:
            ativas = hospedagens.ocupacao_atual(self.conn)
        except RuntimeError as e:
            messagebox.showerror("Erro", str(e))
            ativas = []
        for r in ativas:
            self.tree_at.insert("", tk.END, values=(
                r["id_hospedagem"], r["cliente_nome"], r["quarto_numero"],
                r["data_checkin_real"], r["preco_diaria_aplicado"],
                r["total_consumo_ate_agora"],
            ))

    def _realizar_checkin(self):
        sel = self.tree_ci.selection()
        if not sel:
            messagebox.showinfo("Aviso", "Selecione uma reserva confirmada")
            return
        id_reserva = int(self.tree_ci.item(sel[0])["values"][0])
        try:
            id_hosp = hospedagens.realizar_checkin(
                self.conn, id_reserva, self.user["id_funcionario"])
        except RuntimeError as e:
            messagebox.showerror("Erro", str(e))
            return
        messagebox.showinfo("Sucesso", f"Check-in realizado. Hospedagem id {id_hosp}")
        self._reload()

    def _lancar_consumo(self):
        sel = self.tree_at.selection()
        if not sel:
            messagebox.showinfo("Aviso", "Selecione uma hospedagem ativa")
            return
        id_hosp = int(self.tree_at.item(sel[0])["values"][0])
        if not self.cb_produto.get():
            messagebox.showinfo("Aviso", "Selecione um produto/servico")
            return
        try:
            id_ps = int(self.cb_produto.get().split(" - ", 1)[0])
            qtd   = int(self.entry_qtd.get())
        except ValueError:
            messagebox.showerror("Erro", "Quantidade invalida")
            return
        try:
            hospedagens.lancar_consumo(self.conn, id_hosp, id_ps, qtd)
        except RuntimeError as e:
            messagebox.showerror("Erro", str(e))
            return
        messagebox.showinfo("OK", "Consumo lancado")
        self.entry_qtd.delete(0, tk.END)
        self._reload()

    def _realizar_checkout(self):
        sel = self.tree_at.selection()
        if not sel:
            messagebox.showinfo("Aviso", "Selecione uma hospedagem ativa na lista acima")
            return
        id_hosp = int(self.tree_at.item(sel[0])["values"][0])
        if not messagebox.askyesno("Confirmar", f"Realizar check-out da hospedagem {id_hosp}?"):
            return
        try:
            resumo = hospedagens.realizar_checkout(
                self.conn, id_hosp, self.user["id_funcionario"])
        except RuntimeError as e:
            messagebox.showerror("Erro", str(e))
            return
        msg = (
            f"Check-out realizado!\n\n"
            f"Diarias: {resumo['quantidade_diarias']} x R$ {resumo['preco_diaria_aplicado']}\n"
            f"Total diarias: R$ {resumo['total_diarias']}\n"
            f"Total consumo: R$ {resumo['total_consumo']}\n"
            f"VALOR TOTAL:   R$ {resumo['valor_total']}"
        )
        messagebox.showinfo("Check-out", msg)
        self._reload()
