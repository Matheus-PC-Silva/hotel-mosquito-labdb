"""Janela modal de login."""
from __future__ import annotations

import tkinter as tk
from tkinter import ttk, messagebox

from app.db.auth import login, UserInfo


class LoginWindow:
    def __init__(self, root: tk.Tk, conn):
        self.conn = conn
        self.result: UserInfo | None = None
        self.top = tk.Toplevel(root)
        self.top.title("Hotel do Mosquito — Login")
        self.top.resizable(False, False)
        self.top.transient(root)  # vincula ao root: sem entrada separada na barra de tarefas
        self.top.grab_set()

        frm = ttk.Frame(self.top, padding=20)
        frm.grid(row=0, column=0)

        ttk.Label(frm, text="Login:").grid(row=0, column=0, sticky="w", pady=4)
        self.entry_login = ttk.Entry(frm, width=30)
        self.entry_login.grid(row=0, column=1, pady=4)

        ttk.Label(frm, text="Senha:").grid(row=1, column=0, sticky="w", pady=4)
        self.entry_senha = ttk.Entry(frm, show="*", width=30)
        self.entry_senha.grid(row=1, column=1, pady=4)

        btn_frame = ttk.Frame(frm)
        btn_frame.grid(row=2, column=0, columnspan=2, pady=(12, 0))
        ttk.Button(btn_frame, text="Entrar", command=self._try_login)\
            .pack(side=tk.LEFT, padx=4)
        ttk.Button(btn_frame, text="Cancelar", command=self._cancel)\
            .pack(side=tk.LEFT, padx=4)

        self.top.update_idletasks()  # garante que o tamanho do Toplevel foi calculado
        sw = self.top.winfo_screenwidth()
        sh = self.top.winfo_screenheight()
        w = self.top.winfo_reqwidth()
        h = self.top.winfo_reqheight()
        x = (sw - w) // 2
        y = (sh - h) // 2
        self.top.geometry(f"+{x}+{y}")

        self.entry_login.focus_set()
        self.top.bind("<Return>", lambda _e: self._try_login())
        self.top.protocol("WM_DELETE_WINDOW", self._cancel)

    def _try_login(self):
        try:
            self.result = login(
                self.conn,
                self.entry_login.get().strip(),
                self.entry_senha.get(),
            )
            self.top.destroy()
        except RuntimeError as e:
            messagebox.showerror("Login", str(e), parent=self.top)
            self.entry_senha.delete(0, tk.END)

    def _cancel(self):
        self.result = None
        self.top.destroy()

    def run(self) -> UserInfo | None:
        self.top.wait_window()
        return self.result
