"""CRUD de Reserva."""
from __future__ import annotations

from .connection import call_proc, query_view


def listar(conn, status: str | None = None):
    rs = call_proc(conn, "sp_Reserva_Read", (None, status))
    return rs[0] if rs else []


def obter(conn, id_reserva: int):
    rs = call_proc(conn, "sp_Reserva_Read", (id_reserva, None))
    return rs[0][0] if rs and rs[0] else None


def registrar(conn, id_cliente, id_quarto, id_funcionario,
              data_checkin_prev, data_checkout_prev) -> int:
    rs = call_proc(
        conn, "sp_RegistrarReserva",
        (id_cliente, id_quarto, id_funcionario,
         data_checkin_prev, data_checkout_prev),
    )
    return int(rs[0][0][0])


def atualizar(conn, id_reserva, data_checkin_prev, data_checkout_prev, status):
    call_proc(
        conn, "sp_Reserva_Update",
        (id_reserva, data_checkin_prev, data_checkout_prev, status),
    )


def cancelar(conn, id_reserva):
    call_proc(conn, "sp_Reserva_Delete", (id_reserva,))


def historico_por_cpf(conn, cpf: str):
    return query_view(conn, "vw_historico_reservas_cliente",
                      where_clause="WHERE cpf = %s", params=(cpf,))
