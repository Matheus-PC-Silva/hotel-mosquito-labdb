"""Conexao com MySQL e helpers de chamada de procedure."""
from __future__ import annotations

import configparser
from pathlib import Path
from typing import Any, Iterable, List, Tuple

import mysql.connector
from mysql.connector import Error as MySQLError
from mysql.connector.connection import MySQLConnection
from mysql.connector.constants import ClientFlag


def load_config(path: str | Path | None = None) -> dict[str, Any]:
    """Le config.ini e retorna dict com host/port/user/password/database."""
    if path is None:
        path = Path(__file__).resolve().parent.parent / "config.ini"
    cfg = configparser.ConfigParser()
    if not cfg.read(path, encoding="utf-8"):
        raise FileNotFoundError(f"config.ini nao encontrado em {path}")
    db = cfg["database"]
    return {
        "host":     db.get("host", "localhost"),
        "port":     int(db.get("port", "3306")),
        "user":     db.get("user", "root"),
        "password": db.get("password", ""),
        "database": db.get("database", "hotel_mosquito"),
    }


def connect(config: dict[str, Any] | None = None) -> MySQLConnection:
    """Abre conexao MySQL com base no config.ini."""
    if config is None:
        config = load_config()
    try:
        conn = mysql.connector.connect(
            **config,
            autocommit=True,
            client_flags=[ClientFlag.FOUND_ROWS],  # ROW_COUNT() conta linhas encontradas, nao so modificadas
        )
    except MySQLError as e:
        raise RuntimeError(f"Falha ao conectar ao MySQL: {e.msg}") from e
    return conn


def call_proc(
    conn: MySQLConnection,
    proc_name: str,
    params: Iterable[Any] = (),
) -> List[List[Tuple[Any, ...]]]:
    """Chama uma stored procedure e retorna a lista de resultsets.

    Cada resultset eh uma lista de tuplas. Mensagens de SIGNAL viram RuntimeError.
    """
    cursor = conn.cursor()
    try:
        cursor.callproc(proc_name, tuple(params))
        results: List[List[Tuple[Any, ...]]] = []
        for rs in cursor.stored_results():
            results.append(rs.fetchall())
        return results
    except MySQLError as e:
        raise RuntimeError(e.msg or str(e)) from e
    finally:
        cursor.close()


def query_view(
    conn: MySQLConnection,
    view_name: str,
    where_clause: str = "",
    params: Iterable[Any] = (),
) -> List[dict[str, Any]]:
    """Le linhas de uma view (apenas leitura). where_clause precisa comecar com WHERE."""
    sql = f"SELECT * FROM {view_name} {where_clause}".strip()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(sql, tuple(params))
        return cursor.fetchall()
    except MySQLError as e:
        raise RuntimeError(e.msg or str(e)) from e
    finally:
        cursor.close()
