"""Procedures de relatorio. Bloqueio de Recepcionista vem do banco."""
from __future__ import annotations

from .connection import call_proc


def taxa_ocupacao(conn, id_executor, ano, mes):
    rs = call_proc(conn, "sp_Relatorio_TaxaOcupacao", (id_executor, ano, mes))
    return rs[0] if rs else []


def top_clientes(conn, id_executor):
    rs = call_proc(conn, "sp_Relatorio_TopClientes", (id_executor,))
    return rs[0] if rs else []


def top_quartos(conn, id_executor):
    rs = call_proc(conn, "sp_Relatorio_TopQuartos", (id_executor,))
    return rs[0] if rs else []


def faturamento_mensal(conn, id_executor, ano, mes):
    rs = call_proc(
        conn, "sp_Relatorio_FaturamentoMensal", (id_executor, ano, mes),
    )
    return rs[0] if rs else []
