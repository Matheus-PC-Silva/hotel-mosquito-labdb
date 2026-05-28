USE hotel_mosquito;

-- =====================================================
-- Demonstracao de transacoes puras (fora de stored procedures).
-- Este script eh para apresentacao manual no Workbench.
-- Executar bloco por bloco e observar os SELECTs.
-- =====================================================

-- =====================================================
-- Cenario 1: COMMIT bem-sucedido
-- Registra uma reserva nova e lanca um consumo numa hospedagem ativa.
-- =====================================================
START TRANSACTION;
  -- registra uma reserva futura para o cliente 1 no quarto 12
  CALL sp_RegistrarReserva(1, 12, 3, '2026-07-01', '2026-07-05');
  -- lanca um consumo na hospedagem ativa de id 6
  CALL sp_LancarConsumo(6, 1, 2);
  SELECT 'Cenario 1: reserva criada e consumo lancado' AS resultado;
COMMIT;
SELECT COUNT(*) AS reservas_apos_commit FROM Reserva;

-- =====================================================
-- Cenario 2: ROLLBACK manual
-- Altera o preco do quarto 1, observa o novo Historico_Preco,
-- depois faz ROLLBACK e mostra que o historico foi desfeito.
-- =====================================================
SELECT id_historico, preco_praticado, data_inicio_vigencia, data_fim_vigencia
FROM Historico_Preco WHERE id_quarto = 1
ORDER BY id_historico;

START TRANSACTION;
  CALL sp_AtualizarPrecoQuarto(1, 999.99);
  SELECT 'DENTRO da transacao - apos UPDATE' AS momento;
  SELECT id_historico, preco_praticado, data_inicio_vigencia, data_fim_vigencia
  FROM Historico_Preco WHERE id_quarto = 1
  ORDER BY id_historico;
ROLLBACK;

SELECT 'DEPOIS do ROLLBACK' AS momento;
SELECT id_historico, preco_praticado, data_inicio_vigencia, data_fim_vigencia
FROM Historico_Preco WHERE id_quarto = 1
ORDER BY id_historico;

-- =====================================================
-- Cenario 3: SAVEPOINT (rollback parcial)
-- Insere dois clientes, faz rollback so do segundo, commita o primeiro.
-- =====================================================
START TRANSACTION;
  CALL sp_Cliente_Create('Cliente Demo A', '30303030301',
                         'demo.a@example.com', '11900000000', 'End A');
  SAVEPOINT antes_b;
  CALL sp_Cliente_Create('Cliente Demo B', '30303030302',
                         'demo.b@example.com', '11900000001', 'End B');
  SELECT 'Antes do rollback parcial' AS momento;
  SELECT id_cliente, nome FROM Cliente WHERE nome LIKE 'Cliente Demo%';
  ROLLBACK TO SAVEPOINT antes_b;
  SELECT 'Apos rollback parcial' AS momento;
  SELECT id_cliente, nome FROM Cliente WHERE nome LIKE 'Cliente Demo%';
COMMIT;
SELECT 'Depois do COMMIT' AS momento;
SELECT id_cliente, nome FROM Cliente WHERE nome LIKE 'Cliente Demo%';
