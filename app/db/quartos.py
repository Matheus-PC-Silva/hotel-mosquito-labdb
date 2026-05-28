"""CRUD de Quarto + atualizacao de preco + historico."""
from __future__ import annotations

from .connection import call_proc, query_view


def listar(conn):
    rs = call_proc(conn, "sp_Quarto_Read", (None,))
    return rs[0] if rs else []


def obter(conn, id_quarto: int):
    rs = call_proc(conn, "sp_Quarto_Read", (id_quarto,))
    return rs[0][0] if rs and rs[0] else None


def criar(conn, numero, andar, capacidade, status, preco_inicial, id_categoria) -> int:
    rs = call_proc(
        conn, "sp_Quarto_Create",
        (numero, andar, capacidade, status, preco_inicial, id_categoria),
    )
    return int(rs[0][0][0])


def atualizar(conn, id_quarto, numero, andar, capacidade, status):
    call_proc(
        conn, "sp_Quarto_Update",
        (id_quarto, numero, andar, capacidade, status),
    )


def atualizar_categoria(conn, id_quarto, id_categoria, id_executor):
    call_proc(conn, "sp_AtualizarCategoriaQuarto", (id_quarto, id_categoria, id_executor))


def excluir(conn, id_quarto):
    call_proc(conn, "sp_Quarto_Delete", (id_quarto,))


def atualizar_preco(conn, id_quarto, novo_preco, id_executor):
    call_proc(conn, "sp_AtualizarPrecoQuarto", (id_quarto, novo_preco, id_executor))


def historico_preco(conn, id_quarto):
    rs = call_proc(conn, "sp_HistoricoPreco_ReadPorQuarto", (id_quarto,))
    return rs[0] if rs else []


def disponiveis(conn):
    """Le a view vw_quartos_disponiveis."""
    return query_view(conn, "vw_quartos_disponiveis")
