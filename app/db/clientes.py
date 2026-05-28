"""CRUD de Cliente via stored procedures."""
from __future__ import annotations

from .connection import call_proc


def listar(conn, filtro: str | None = None):
    rs = call_proc(conn, "sp_Cliente_Read", (None, filtro))
    return rs[0] if rs else []


def obter(conn, id_cliente: int):
    rs = call_proc(conn, "sp_Cliente_Read", (id_cliente, None))
    return rs[0][0] if rs and rs[0] else None


def criar(conn, nome, cpf, email, telefone, endereco) -> int:
    rs = call_proc(conn, "sp_Cliente_Create", (nome, cpf, email, telefone, endereco))
    return int(rs[0][0][0])


def atualizar(conn, id_cliente, nome, cpf, email, telefone, endereco):
    call_proc(conn, "sp_Cliente_Update", (id_cliente, nome, cpf, email, telefone, endereco))


def excluir(conn, id_cliente):
    call_proc(conn, "sp_Cliente_Delete", (id_cliente,))
