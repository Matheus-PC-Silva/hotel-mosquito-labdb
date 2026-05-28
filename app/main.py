"""Entry point da aplicacao Hotel do Mosquito."""
from __future__ import annotations

import tkinter as tk
from tkinter import messagebox

from app.db.connection import connect, load_config
from app.ui.login_window import LoginWindow
from app.ui.main_window import MainWindow


def main():
    root = tk.Tk()
    root.withdraw()  # esconde root ate o login

    try:
        load_config()
    except FileNotFoundError as e:
        messagebox.showerror("Configuracao", str(e))
        root.destroy()
        return

    try:
        conn = connect()
    except RuntimeError as e:
        messagebox.showerror("Conexao", str(e))
        root.destroy()
        return

    root.state("zoomed")   # maximiza antes de exibir o login
    root.deiconify()

    user_info = LoginWindow(root, conn).run()
    if not user_info:
        root.destroy()
        conn.close()
        return

    MainWindow(root, conn, user_info)
    root.mainloop()

    conn.close()


if __name__ == "__main__":
    main()
