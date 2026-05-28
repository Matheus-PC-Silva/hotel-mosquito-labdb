"""Catalogos auxiliares: Categoria_Quarto e Produto_Servico."""
from __future__ import annotations

from .connection import call_proc


# --------- Categorias ----------
def listar_categorias(conn):
    rs = call_proc(conn, "sp_Categoria_Read", ())
    return rs[0] if rs else []


def criar_categoria(conn, nome, descricao) -> int:
    rs = call_proc(conn, "sp_Categoria_Create", (nome, descricao))
    return int(rs[0][0][0])


def atualizar_categoria(conn, id_categoria, nome, descricao):
    call_proc(conn, "sp_Categoria_Update", (id_categoria, nome, descricao))


def excluir_categoria(conn, id_categoria):
    call_proc(conn, "sp_Categoria_Delete", (id_categoria,))


# --------- Produtos/Servicos ----------
def listar_produtos(conn):
    rs = call_proc(conn, "sp_ProdutoServico_Read", ())
    return rs[0] if rs else []


def criar_produto(conn, nome, preco, tipo) -> int:
    rs = call_proc(conn, "sp_ProdutoServico_Create", (nome, preco, tipo))
    return int(rs[0][0][0])


def atualizar_produto(conn, id_ps, nome, preco, tipo):
    call_proc(conn, "sp_ProdutoServico_Update", (id_ps, nome, preco, tipo))


def excluir_produto(conn, id_ps):
    call_proc(conn, "sp_ProdutoServico_Delete", (id_ps,))
