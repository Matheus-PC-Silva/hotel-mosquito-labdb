USE hotel_mosquito;

-- =====================================================
-- vw_quartos_disponiveis (OBRIGATORIA)
-- Quartos prontos para nova reserva/check-in.
-- =====================================================
DROP VIEW IF EXISTS vw_quartos_disponiveis;
CREATE VIEW vw_quartos_disponiveis AS
SELECT
  q.id_quarto,
  q.numero,
  q.andar,
  q.capacidade,
  q.status,
  q.preco_praticado,
  c.id_categoria,
  c.nome      AS categoria_nome,
  c.descricao AS categoria_descricao
FROM Quarto q
JOIN Categoria_Quarto c ON c.id_categoria = q.id_categoria
WHERE q.status IN ('Disponivel','Limpeza');

-- =====================================================
-- vw_ocupacao_atual (OBRIGATORIA)
-- Hospedagens em andamento (check-in feito, check-out pendente).
-- =====================================================
DROP VIEW IF EXISTS vw_ocupacao_atual;
CREATE VIEW vw_ocupacao_atual AS
SELECT
  h.id_hospedagem,
  h.id_reserva,
  h.data_checkin_real,
  h.preco_diaria_aplicado,
  cli.id_cliente,
  cli.nome AS cliente_nome,
  cli.cpf  AS cliente_cpf,
  q.id_quarto,
  q.numero AS quarto_numero,
  cat.nome AS categoria_nome,
  COALESCE((
    SELECT SUM(co.quantidade * co.preco_unitario_momento)
    FROM Consumo co
    WHERE co.id_hospedagem = h.id_hospedagem
  ), 0) AS total_consumo_ate_agora
FROM Hospedagem h
JOIN Reserva r          ON r.id_reserva    = h.id_reserva
JOIN Cliente cli        ON cli.id_cliente  = r.id_cliente
JOIN Quarto q           ON q.id_quarto     = r.id_quarto
JOIN Categoria_Quarto cat ON cat.id_categoria = q.id_categoria
WHERE h.status = 'Ativa';

-- =====================================================
-- vw_historico_reservas_cliente (OBRIGATORIA)
-- Historico de reservas e estadias por cliente; filtravel por CPF.
-- =====================================================
DROP VIEW IF EXISTS vw_historico_reservas_cliente;
CREATE VIEW vw_historico_reservas_cliente AS
SELECT
  cli.id_cliente,
  cli.cpf,
  cli.nome AS cliente_nome,
  r.id_reserva,
  r.data_checkin_prev,
  r.data_checkout_prev,
  r.status AS reserva_status,
  r.data_criacao,
  q.numero AS quarto_numero,
  cat.nome AS categoria_nome,
  h.id_hospedagem,
  h.data_checkin_real,
  h.data_checkout_real,
  h.valor_total_diarias,
  h.status AS hospedagem_status
FROM Cliente cli
JOIN Reserva r            ON r.id_cliente   = cli.id_cliente
JOIN Quarto q             ON q.id_quarto    = r.id_quarto
JOIN Categoria_Quarto cat ON cat.id_categoria = q.id_categoria
LEFT JOIN Hospedagem h    ON h.id_reserva   = r.id_reserva
ORDER BY cli.id_cliente, r.data_checkin_prev DESC;

-- =====================================================
-- vw_taxa_ocupacao_mensal
-- Diarias ocupadas no mes / (no de quartos x dias no mes).
-- =====================================================
DROP VIEW IF EXISTS vw_taxa_ocupacao_mensal;
CREATE VIEW vw_taxa_ocupacao_mensal AS
SELECT
  YEAR(h.data_checkin_real)  AS ano,
  MONTH(h.data_checkin_real) AS mes,
  SUM(DATEDIFF(
        COALESCE(h.data_checkout_real, LAST_DAY(h.data_checkin_real)),
        h.data_checkin_real
      ) + 1) AS diarias_ocupadas,
  (SELECT COUNT(*) FROM Quarto) AS total_quartos,
  DAY(LAST_DAY(MIN(h.data_checkin_real))) AS dias_no_mes,
  ROUND(
    SUM(DATEDIFF(
          COALESCE(h.data_checkout_real, LAST_DAY(h.data_checkin_real)),
          h.data_checkin_real
        ) + 1)
    / ((SELECT COUNT(*) FROM Quarto) * DAY(LAST_DAY(MIN(h.data_checkin_real))))
    * 100,
    2
  ) AS taxa_ocupacao_pct
FROM Hospedagem h
GROUP BY YEAR(h.data_checkin_real), MONTH(h.data_checkin_real);

-- =====================================================
-- vw_top_clientes_assiduos
-- Soma de diarias por cliente.
-- =====================================================
DROP VIEW IF EXISTS vw_top_clientes_assiduos;
CREATE VIEW vw_top_clientes_assiduos AS
SELECT
  cli.id_cliente,
  cli.nome,
  cli.cpf,
  COUNT(h.id_hospedagem) AS qtd_hospedagens,
  COALESCE(SUM(DATEDIFF(
    COALESCE(h.data_checkout_real, NOW()),
    h.data_checkin_real
  ) + 1), 0) AS total_diarias
FROM Cliente cli
LEFT JOIN Reserva r    ON r.id_cliente   = cli.id_cliente
LEFT JOIN Hospedagem h ON h.id_reserva   = r.id_reserva
GROUP BY cli.id_cliente, cli.nome, cli.cpf
ORDER BY total_diarias DESC;

-- =====================================================
-- vw_top_quartos_reservados
-- Contagem de reservas por quarto.
-- =====================================================
DROP VIEW IF EXISTS vw_top_quartos_reservados;
CREATE VIEW vw_top_quartos_reservados AS
SELECT
  q.id_quarto,
  q.numero,
  cat.nome AS categoria,
  COUNT(r.id_reserva) AS qtd_reservas
FROM Quarto q
JOIN Categoria_Quarto cat ON cat.id_categoria = q.id_categoria
LEFT JOIN Reserva r        ON r.id_quarto      = q.id_quarto
GROUP BY q.id_quarto, q.numero, cat.nome
ORDER BY qtd_reservas DESC;

-- =====================================================
-- vw_faturamento_mensal
-- Soma de valor_total_diarias + consumos por mes de check-out.
-- =====================================================
DROP VIEW IF EXISTS vw_faturamento_mensal;
CREATE VIEW vw_faturamento_mensal AS
SELECT
  YEAR(h.data_checkout_real)               AS ano,
  MONTH(h.data_checkout_real)              AS mes,
  COUNT(h.id_hospedagem)                   AS qtd_checkouts,
  COALESCE(SUM(h.valor_total_diarias), 0)  AS total_diarias,
  COALESCE(SUM(c.total_consumo_hosp), 0)   AS total_consumos,
  COALESCE(SUM(h.valor_total_diarias), 0)
    + COALESCE(SUM(c.total_consumo_hosp), 0) AS faturamento_total
FROM Hospedagem h
LEFT JOIN (
  SELECT id_hospedagem,
         SUM(quantidade * preco_unitario_momento) AS total_consumo_hosp
  FROM Consumo
  GROUP BY id_hospedagem
) c ON c.id_hospedagem = h.id_hospedagem
WHERE h.status = 'Finalizada' AND h.data_checkout_real IS NOT NULL
GROUP BY YEAR(h.data_checkout_real), MONTH(h.data_checkout_real);
