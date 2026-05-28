"""Autenticacao via sp_Login."""
from __future__ import annotations

from typing import TypedDict

from .connection import call_proc


class UserInfo(TypedDict):
    id_funcionario: int
    nome: str
    perfil: str  # 'Recepcionista' | 'Gerente'


def login(conn, login_usuario: str, senha: str) -> UserInfo:
    rs = call_proc(conn, "sp_Login", (login_usuario, senha))
    if not rs or not rs[0]:
        raise RuntimeError("Credenciais invalidas")
    row = rs[0][0]
    return UserInfo(id_funcionario=row[0], nome=row[1], perfil=row[2])
