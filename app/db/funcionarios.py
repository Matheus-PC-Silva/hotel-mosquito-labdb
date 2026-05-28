"""CRUD de Funcionario — restrito a Gerente (validado no banco)."""
from __future__ import annotations

from .connection import call_proc


def listar(conn, id_executor: int):
    rs = call_proc(conn, "sp_Funcionario_Read", (id_executor, None))
    return rs[0] if rs else []


def obter(conn, id_executor: int, id_funcionario: int):
    rs = call_proc(conn, "sp_Funcionario_Read", (id_executor, id_funcionario))
    return rs[0][0] if rs and rs[0] else None


def criar(conn, id_executor, nome, cpf, cargo, login, senha, perfil) -> int:
    rs = call_proc(
        conn, "sp_Funcionario_Create",
        (id_executor, nome, cpf, cargo, login, senha, perfil),
    )
    return int(rs[0][0][0])


def atualizar(conn, id_executor, id_funcionario, nome, cpf, cargo,
              login, senha_ou_vazio, perfil):
    call_proc(
        conn, "sp_Funcionario_Update",
        (id_executor, id_funcionario, nome, cpf, cargo, login,
         senha_ou_vazio, perfil),
    )


def excluir(conn, id_executor, id_funcionario):
    call_proc(conn, "sp_Funcionario_Delete", (id_executor, id_funcionario))
