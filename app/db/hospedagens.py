"""Operacoes de hospedagem: check-in, check-out, lancamento de consumo."""
from __future__ import annotations

from .connection import call_proc, query_view


def ocupacao_atual(conn):
    return query_view(conn, "vw_ocupacao_atual")


def consumos_da_hospedagem(conn, id_hospedagem):
    return query_view(
        conn, "vw_ocupacao_atual",
        where_clause="WHERE id_hospedagem = %s", params=(id_hospedagem,),
    )


def realizar_checkin(conn, id_reserva, id_funcionario) -> int:
    rs = call_proc(conn, "sp_RealizarCheckIn", (id_reserva, id_funcionario))
    return int(rs[0][0][0])


def realizar_checkout(conn, id_hospedagem, id_funcionario) -> dict:
    rs = call_proc(conn, "sp_RealizarCheckOut", (id_hospedagem, id_funcionario))
    row = rs[0][0]
    return {
        "id_hospedagem":         row[0],
        "quantidade_diarias":    row[1],
        "preco_diaria_aplicado": row[2],
        "total_diarias":         row[3],
        "total_consumo":         row[4],
        "valor_total":           row[5],
    }


def lancar_consumo(conn, id_hospedagem, id_produto_servico, quantidade) -> int:
    rs = call_proc(
        conn, "sp_LancarConsumo",
        (id_hospedagem, id_produto_servico, quantidade),
    )
    return int(rs[0][0][0])
