DROP DATABASE IF EXISTS hotel_mosquito;
CREATE DATABASE hotel_mosquito
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE hotel_mosquito;

-- =====================================================
-- Categoria_Quarto
-- =====================================================
CREATE TABLE Categoria_Quarto (
  id_categoria INT AUTO_INCREMENT PRIMARY KEY,
  nome         VARCHAR(30)  NOT NULL UNIQUE,
  descricao    VARCHAR(255) NOT NULL
) ENGINE=InnoDB;

-- =====================================================
-- Quarto
-- =====================================================
CREATE TABLE Quarto (
  id_quarto       INT AUTO_INCREMENT PRIMARY KEY,
  numero          VARCHAR(10)   NOT NULL UNIQUE,
  andar           TINYINT       NOT NULL,
  capacidade      TINYINT       NOT NULL,
  status          ENUM('Disponivel','Ocupado','Limpeza','Manutencao')
                    NOT NULL DEFAULT 'Disponivel',
  preco_praticado DECIMAL(10,2) NOT NULL,
  id_categoria    INT NOT NULL,
  CONSTRAINT chk_quarto_andar      CHECK (andar BETWEEN 0 AND 50),
  CONSTRAINT chk_quarto_capacidade CHECK (capacidade BETWEEN 1 AND 10),
  CONSTRAINT chk_quarto_preco      CHECK (preco_praticado >= 0),
  CONSTRAINT fk_quarto_categoria
    FOREIGN KEY (id_categoria) REFERENCES Categoria_Quarto(id_categoria)
    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- =====================================================
-- Historico_Preco
-- =====================================================
CREATE TABLE Historico_Preco (
  id_historico         INT AUTO_INCREMENT PRIMARY KEY,
  id_quarto            INT NOT NULL,
  preco_praticado      DECIMAL(10,2) NOT NULL,
  data_inicio_vigencia DATETIME NOT NULL,
  data_fim_vigencia    DATETIME NULL,
  CONSTRAINT chk_historico_preco CHECK (preco_praticado >= 0),
  CONSTRAINT fk_historico_quarto
    FOREIGN KEY (id_quarto) REFERENCES Quarto(id_quarto)
    ON DELETE RESTRICT,
  INDEX idx_historico_quarto_vigencia (id_quarto, data_fim_vigencia)
) ENGINE=InnoDB;

-- =====================================================
-- Cliente
-- =====================================================
CREATE TABLE Cliente (
  id_cliente INT AUTO_INCREMENT PRIMARY KEY,
  nome       VARCHAR(100) NOT NULL,
  cpf        CHAR(11)     NOT NULL UNIQUE,
  email      VARCHAR(120) NOT NULL UNIQUE,
  telefone   VARCHAR(20)  NOT NULL,
  endereco   VARCHAR(255) NOT NULL,
  CONSTRAINT chk_cliente_cpf CHECK (cpf REGEXP '^[0-9]{11}$')
) ENGINE=InnoDB;

-- =====================================================
-- Funcionario
-- =====================================================
CREATE TABLE Funcionario (
  id_funcionario INT AUTO_INCREMENT PRIMARY KEY,
  nome           VARCHAR(100) NOT NULL,
  cpf            CHAR(11)     NOT NULL UNIQUE,
  cargo          VARCHAR(50)  NOT NULL,
  login          VARCHAR(40)  NOT NULL UNIQUE,
  senha_hash     CHAR(64)     NOT NULL,
  perfil         ENUM('Recepcionista','Gerente') NOT NULL,
  CONSTRAINT chk_funcionario_cpf CHECK (cpf REGEXP '^[0-9]{11}$')
) ENGINE=InnoDB;

-- =====================================================
-- Reserva
-- =====================================================
CREATE TABLE Reserva (
  id_reserva         INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente         INT NOT NULL,
  id_quarto          INT NOT NULL,
  id_funcionario     INT NOT NULL,
  data_checkin_prev  DATE NOT NULL,
  data_checkout_prev DATE NOT NULL,
  status             ENUM('Confirmada','Cancelada','Efetivada','NoShow')
                       NOT NULL DEFAULT 'Confirmada',
  data_criacao       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_reserva_datas CHECK (data_checkout_prev > data_checkin_prev),
  CONSTRAINT fk_reserva_cliente
    FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente) ON DELETE RESTRICT,
  CONSTRAINT fk_reserva_quarto
    FOREIGN KEY (id_quarto) REFERENCES Quarto(id_quarto) ON DELETE RESTRICT,
  CONSTRAINT fk_reserva_funcionario
    FOREIGN KEY (id_funcionario) REFERENCES Funcionario(id_funcionario) ON DELETE RESTRICT,
  INDEX idx_reserva_quarto_periodo (id_quarto, data_checkin_prev, data_checkout_prev),
  INDEX idx_reserva_cliente_status (id_cliente, status)
) ENGINE=InnoDB;

-- =====================================================
-- Hospedagem
-- =====================================================
CREATE TABLE Hospedagem (
  id_hospedagem         INT AUTO_INCREMENT PRIMARY KEY,
  id_reserva            INT NOT NULL UNIQUE,
  data_checkin_real     DATETIME NOT NULL,
  data_checkout_real    DATETIME NULL,
  preco_diaria_aplicado DECIMAL(10,2) NOT NULL,
  valor_total_diarias   DECIMAL(10,2) NULL,
  status                ENUM('Ativa','Finalizada') NOT NULL DEFAULT 'Ativa',
  CONSTRAINT chk_hospedagem_preco CHECK (preco_diaria_aplicado >= 0),
  CONSTRAINT fk_hospedagem_reserva
    FOREIGN KEY (id_reserva) REFERENCES Reserva(id_reserva) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- =====================================================
-- Produto_Servico
-- =====================================================
CREATE TABLE Produto_Servico (
  id_produto_servico INT AUTO_INCREMENT PRIMARY KEY,
  nome               VARCHAR(80)  NOT NULL UNIQUE,
  preco_venda        DECIMAL(10,2) NOT NULL,
  tipo               ENUM('Frigobar','Restaurante','Lavanderia','Outro') NOT NULL,
  CONSTRAINT chk_produto_preco CHECK (preco_venda >= 0)
) ENGINE=InnoDB;

-- =====================================================
-- Consumo
-- =====================================================
CREATE TABLE Consumo (
  id_consumo             INT AUTO_INCREMENT PRIMARY KEY,
  id_hospedagem          INT NOT NULL,
  id_produto_servico     INT NOT NULL,
  quantidade             INT NOT NULL,
  preco_unitario_momento DECIMAL(10,2) NOT NULL,
  data_hora              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_consumo_quantidade CHECK (quantidade > 0),
  CONSTRAINT fk_consumo_hospedagem
    FOREIGN KEY (id_hospedagem) REFERENCES Hospedagem(id_hospedagem) ON DELETE CASCADE,
  CONSTRAINT fk_consumo_produto
    FOREIGN KEY (id_produto_servico) REFERENCES Produto_Servico(id_produto_servico)
    ON DELETE RESTRICT,
  INDEX idx_consumo_hospedagem (id_hospedagem)
) ENGINE=InnoDB;
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
  DAY(LAST_DAY(h.data_checkin_real)) AS dias_no_mes,
  ROUND(
    SUM(DATEDIFF(
          COALESCE(h.data_checkout_real, LAST_DAY(h.data_checkin_real)),
          h.data_checkin_real
        ) + 1)
    / ((SELECT COUNT(*) FROM Quarto) * DAY(LAST_DAY(h.data_checkin_real)))
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
  YEAR(h.data_checkout_real)  AS ano,
  MONTH(h.data_checkout_real) AS mes,
  COUNT(h.id_hospedagem)      AS qtd_checkouts,
  COALESCE(SUM(h.valor_total_diarias), 0) AS total_diarias,
  COALESCE((
    SELECT SUM(co.quantidade * co.preco_unitario_momento)
    FROM Consumo co
    JOIN Hospedagem hh ON hh.id_hospedagem = co.id_hospedagem
    WHERE hh.status = 'Finalizada'
      AND YEAR(hh.data_checkout_real)  = YEAR(h.data_checkout_real)
      AND MONTH(hh.data_checkout_real) = MONTH(h.data_checkout_real)
  ), 0) AS total_consumos,
  COALESCE(SUM(h.valor_total_diarias), 0) + COALESCE((
    SELECT SUM(co.quantidade * co.preco_unitario_momento)
    FROM Consumo co
    JOIN Hospedagem hh ON hh.id_hospedagem = co.id_hospedagem
    WHERE hh.status = 'Finalizada'
      AND YEAR(hh.data_checkout_real)  = YEAR(h.data_checkout_real)
      AND MONTH(hh.data_checkout_real) = MONTH(h.data_checkout_real)
  ), 0) AS faturamento_total
FROM Hospedagem h
WHERE h.status = 'Finalizada' AND h.data_checkout_real IS NOT NULL
GROUP BY YEAR(h.data_checkout_real), MONTH(h.data_checkout_real);
USE hotel_mosquito;
DELIMITER $$

-- =====================================================
-- sp_Login
-- Verifica credenciais e retorna identidade + perfil.
-- =====================================================
DROP PROCEDURE IF EXISTS sp_Login$$
CREATE PROCEDURE sp_Login(
  IN p_login VARCHAR(40),
  IN p_senha VARCHAR(255)
)
BEGIN
  DECLARE v_id    INT;
  DECLARE v_nome  VARCHAR(100);
  DECLARE v_perfil ENUM('Recepcionista','Gerente');

  SELECT id_funcionario, nome, perfil
    INTO v_id, v_nome, v_perfil
  FROM Funcionario
  WHERE login = p_login
    AND senha_hash = SHA2(p_senha, 256)
  LIMIT 1;

  IF v_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credenciais invalidas';
  END IF;

  SELECT v_id AS id_funcionario, v_nome AS nome, v_perfil AS perfil;
END$$

-- =====================================================
-- sp_AssertGerente
-- Helper interno para validar que executor e Gerente.
-- =====================================================
DROP PROCEDURE IF EXISTS sp_AssertGerente$$
CREATE PROCEDURE sp_AssertGerente(IN p_id_executor INT)
BEGIN
  DECLARE v_perfil ENUM('Recepcionista','Gerente');
  SELECT perfil INTO v_perfil FROM Funcionario WHERE id_funcionario = p_id_executor;
  IF v_perfil IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executor nao encontrado';
  END IF;
  IF v_perfil <> 'Gerente' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Acesso negado: operacao restrita a Gerentes';
  END IF;
END$$

-- =====================================================
-- sp_Funcionario_Create
-- =====================================================
DROP PROCEDURE IF EXISTS sp_Funcionario_Create$$
CREATE PROCEDURE sp_Funcionario_Create(
  IN p_executor INT,
  IN p_nome     VARCHAR(100),
  IN p_cpf      CHAR(11),
  IN p_cargo    VARCHAR(50),
  IN p_login    VARCHAR(40),
  IN p_senha    VARCHAR(255),
  IN p_perfil   ENUM('Recepcionista','Gerente')
)
BEGIN
  CALL sp_AssertGerente(p_executor);
  INSERT INTO Funcionario(nome, cpf, cargo, login, senha_hash, perfil)
  VALUES (p_nome, p_cpf, p_cargo, p_login, SHA2(p_senha, 256), p_perfil);
  SELECT LAST_INSERT_ID() AS id_funcionario;
END$$

-- =====================================================
-- sp_Funcionario_Read
-- =====================================================
DROP PROCEDURE IF EXISTS sp_Funcionario_Read$$
CREATE PROCEDURE sp_Funcionario_Read(
  IN p_executor INT,
  IN p_id       INT
)
BEGIN
  CALL sp_AssertGerente(p_executor);
  IF p_id IS NULL THEN
    SELECT id_funcionario, nome, cpf, cargo, login, perfil
    FROM Funcionario ORDER BY nome;
  ELSE
    SELECT id_funcionario, nome, cpf, cargo, login, perfil
    FROM Funcionario WHERE id_funcionario = p_id;
  END IF;
END$$

-- =====================================================
-- sp_Funcionario_Update
-- =====================================================
DROP PROCEDURE IF EXISTS sp_Funcionario_Update$$
CREATE PROCEDURE sp_Funcionario_Update(
  IN p_executor INT,
  IN p_id       INT,
  IN p_nome     VARCHAR(100),
  IN p_cpf      CHAR(11),
  IN p_cargo    VARCHAR(50),
  IN p_login    VARCHAR(40),
  IN p_senha    VARCHAR(255),
  IN p_perfil   ENUM('Recepcionista','Gerente')
)
BEGIN
  CALL sp_AssertGerente(p_executor);
  IF p_senha IS NULL OR p_senha = '' THEN
    UPDATE Funcionario
       SET nome = p_nome, cpf = p_cpf, cargo = p_cargo,
           login = p_login, perfil = p_perfil
     WHERE id_funcionario = p_id;
  ELSE
    UPDATE Funcionario
       SET nome = p_nome, cpf = p_cpf, cargo = p_cargo,
           login = p_login, senha_hash = SHA2(p_senha, 256), perfil = p_perfil
     WHERE id_funcionario = p_id;
  END IF;
  IF ROW_COUNT() = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Funcionario nao encontrado';
  END IF;
END$$

-- =====================================================
-- sp_Funcionario_Delete
-- =====================================================
DROP PROCEDURE IF EXISTS sp_Funcionario_Delete$$
CREATE PROCEDURE sp_Funcionario_Delete(
  IN p_executor INT,
  IN p_id       INT
)
BEGIN
  CALL sp_AssertGerente(p_executor);
  IF p_id = p_executor THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nao e permitido excluir o proprio usuario logado';
  END IF;
  DELETE FROM Funcionario WHERE id_funcionario = p_id;
  IF ROW_COUNT() = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Funcionario nao encontrado';
  END IF;
END$$

-- =====================================================
-- sp_Cliente_Create
-- =====================================================
DROP PROCEDURE IF EXISTS sp_Cliente_Create$$
CREATE PROCEDURE sp_Cliente_Create(
  IN p_nome     VARCHAR(100),
  IN p_cpf      CHAR(11),
  IN p_email    VARCHAR(120),
  IN p_telefone VARCHAR(20),
  IN p_endereco VARCHAR(255)
)
BEGIN
  INSERT INTO Cliente(nome, cpf, email, telefone, endereco)
  VALUES (p_nome, p_cpf, p_email, p_telefone, p_endereco);
  SELECT LAST_INSERT_ID() AS id_cliente;
END$$

-- =====================================================
-- sp_Cliente_Read
-- =====================================================
DROP PROCEDURE IF EXISTS sp_Cliente_Read$$
CREATE PROCEDURE sp_Cliente_Read(
  IN p_id     INT,
  IN p_filtro VARCHAR(120)
)
BEGIN
  IF p_id IS NOT NULL THEN
    SELECT id_cliente, nome, cpf, email, telefone, endereco
    FROM Cliente WHERE id_cliente = p_id;
  ELSEIF p_filtro IS NULL OR p_filtro = '' THEN
    SELECT id_cliente, nome, cpf, email, telefone, endereco
    FROM Cliente ORDER BY nome;
  ELSE
    SELECT id_cliente, nome, cpf, email, telefone, endereco
    FROM Cliente
    WHERE nome LIKE CONCAT('%', p_filtro, '%')
       OR cpf  LIKE CONCAT('%', p_filtro, '%')
    ORDER BY nome;
  END IF;
END$$

-- =====================================================
-- sp_Cliente_Update
-- =====================================================
DROP PROCEDURE IF EXISTS sp_Cliente_Update$$
CREATE PROCEDURE sp_Cliente_Update(
  IN p_id       INT,
  IN p_nome     VARCHAR(100),
  IN p_cpf      CHAR(11),
  IN p_email    VARCHAR(120),
  IN p_telefone VARCHAR(20),
  IN p_endereco VARCHAR(255)
)
BEGIN
  UPDATE Cliente
     SET nome = p_nome, cpf = p_cpf, email = p_email,
         telefone = p_telefone, endereco = p_endereco
   WHERE id_cliente = p_id;
  IF ROW_COUNT() = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cliente nao encontrado';
  END IF;
END$$

-- =====================================================
-- sp_Cliente_Delete
-- =====================================================
DROP PROCEDURE IF EXISTS sp_Cliente_Delete$$
CREATE PROCEDURE sp_Cliente_Delete(IN p_id INT)
BEGIN
  DELETE FROM Cliente WHERE id_cliente = p_id;
  IF ROW_COUNT() = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cliente nao encontrado';
  END IF;
END$$

-- =====================================================
-- sp_Categoria_Read
-- =====================================================
DROP PROCEDURE IF EXISTS sp_Categoria_Read$$
CREATE PROCEDURE sp_Categoria_Read()
BEGIN
  SELECT id_categoria, nome, descricao FROM Categoria_Quarto ORDER BY nome;
END$$

-- =====================================================
-- sp_Categoria_Create
-- =====================================================
DROP PROCEDURE IF EXISTS sp_Categoria_Create$$
CREATE PROCEDURE sp_Categoria_Create(IN p_nome VARCHAR(30), IN p_descricao VARCHAR(255))
BEGIN
  INSERT INTO Categoria_Quarto(nome, descricao) VALUES (p_nome, p_descricao);
  SELECT LAST_INSERT_ID() AS id_categoria;
END$$

-- =====================================================
-- sp_Categoria_Update
-- =====================================================
DROP PROCEDURE IF EXISTS sp_Categoria_Update$$
CREATE PROCEDURE sp_Categoria_Update(IN p_id INT, IN p_nome VARCHAR(30), IN p_descricao VARCHAR(255))
BEGIN
  UPDATE Categoria_Quarto SET nome = p_nome, descricao = p_descricao WHERE id_categoria = p_id;
  IF ROW_COUNT() = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Categoria nao encontrada';
  END IF;
END$$

-- =====================================================
-- sp_Categoria_Delete
-- =====================================================
DROP PROCEDURE IF EXISTS sp_Categoria_Delete$$
CREATE PROCEDURE sp_Categoria_Delete(IN p_id INT)
BEGIN
  DELETE FROM Categoria_Quarto WHERE id_categoria = p_id;
  IF ROW_COUNT() = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Categoria nao encontrada';
  END IF;
END$$

-- =====================================================
-- sp_ProdutoServico_Read
-- =====================================================
DROP PROCEDURE IF EXISTS sp_ProdutoServico_Read$$
CREATE PROCEDURE sp_ProdutoServico_Read()
BEGIN
  SELECT id_produto_servico, nome, preco_venda, tipo
  FROM Produto_Servico ORDER BY tipo, nome;
END$$

-- =====================================================
-- sp_ProdutoServico_Create
-- =====================================================
DROP PROCEDURE IF EXISTS sp_ProdutoServico_Create$$
CREATE PROCEDURE sp_ProdutoServico_Create(
  IN p_nome VARCHAR(80), IN p_preco DECIMAL(10,2),
  IN p_tipo ENUM('Frigobar','Restaurante','Lavanderia','Outro')
)
BEGIN
  INSERT INTO Produto_Servico(nome, preco_venda, tipo) VALUES (p_nome, p_preco, p_tipo);
  SELECT LAST_INSERT_ID() AS id_produto_servico;
END$$

-- =====================================================
-- sp_ProdutoServico_Update
-- =====================================================
DROP PROCEDURE IF EXISTS sp_ProdutoServico_Update$$
CREATE PROCEDURE sp_ProdutoServico_Update(
  IN p_id INT, IN p_nome VARCHAR(80), IN p_preco DECIMAL(10,2),
  IN p_tipo ENUM('Frigobar','Restaurante','Lavanderia','Outro')
)
BEGIN
  UPDATE Produto_Servico SET nome = p_nome, preco_venda = p_preco, tipo = p_tipo
   WHERE id_produto_servico = p_id;
  IF ROW_COUNT() = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Produto/Servico nao encontrado';
  END IF;
END$$

-- =====================================================
-- sp_ProdutoServico_Delete
-- =====================================================
DROP PROCEDURE IF EXISTS sp_ProdutoServico_Delete$$
CREATE PROCEDURE sp_ProdutoServico_Delete(IN p_id INT)
BEGIN
  DELETE FROM Produto_Servico WHERE id_produto_servico = p_id;
  IF ROW_COUNT() = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Produto/Servico nao encontrado';
  END IF;
END$$

-- =====================================================
-- sp_Quarto_Create
-- =====================================================
DROP PROCEDURE IF EXISTS sp_Quarto_Create$$
CREATE PROCEDURE sp_Quarto_Create(
  IN p_numero VARCHAR(10), IN p_andar TINYINT, IN p_capacidade TINYINT,
  IN p_status ENUM('Disponivel','Ocupado','Limpeza','Manutencao'),
  IN p_preco_inicial DECIMAL(10,2), IN p_id_categoria INT
)
BEGIN
  INSERT INTO Quarto(numero, andar, capacidade, status, preco_praticado, id_categoria)
  VALUES (p_numero, p_andar, p_capacidade, p_status, p_preco_inicial, p_id_categoria);
  SELECT LAST_INSERT_ID() AS id_quarto;
END$$

-- =====================================================
-- sp_Quarto_Read
-- =====================================================
DROP PROCEDURE IF EXISTS sp_Quarto_Read$$
CREATE PROCEDURE sp_Quarto_Read(IN p_id INT)
BEGIN
  IF p_id IS NULL THEN
    SELECT q.id_quarto, q.numero, q.andar, q.capacidade, q.status,
           q.preco_praticado, q.id_categoria, c.nome AS categoria_nome
    FROM Quarto q JOIN Categoria_Quarto c ON c.id_categoria = q.id_categoria
    ORDER BY q.numero;
  ELSE
    SELECT q.id_quarto, q.numero, q.andar, q.capacidade, q.status,
           q.preco_praticado, q.id_categoria, c.nome AS categoria_nome
    FROM Quarto q JOIN Categoria_Quarto c ON c.id_categoria = q.id_categoria
    WHERE q.id_quarto = p_id;
  END IF;
END$$

-- =====================================================
-- sp_Quarto_Update (nao altera preco_praticado nem categoria)
-- =====================================================
DROP PROCEDURE IF EXISTS sp_Quarto_Update$$
CREATE PROCEDURE sp_Quarto_Update(
  IN p_id INT, IN p_numero VARCHAR(10), IN p_andar TINYINT,
  IN p_capacidade TINYINT,
  IN p_status ENUM('Disponivel','Ocupado','Limpeza','Manutencao')
)
BEGIN
  UPDATE Quarto
     SET numero = p_numero, andar = p_andar, capacidade = p_capacidade,
         status = p_status
   WHERE id_quarto = p_id;
  IF ROW_COUNT() = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quarto nao encontrado';
  END IF;
END$$

-- =====================================================
-- sp_AtualizarCategoriaQuarto (somente Gerente)
-- =====================================================
DROP PROCEDURE IF EXISTS sp_AtualizarCategoriaQuarto$$
CREATE PROCEDURE sp_AtualizarCategoriaQuarto(
  IN p_id_quarto   INT,
  IN p_id_categoria INT,
  IN p_id_executor  INT
)
BEGIN
  CALL sp_AssertGerente(p_id_executor);
  UPDATE Quarto SET id_categoria = p_id_categoria WHERE id_quarto = p_id_quarto;
  IF ROW_COUNT() = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quarto nao encontrado';
  END IF;
END$$

-- =====================================================
-- sp_Quarto_Delete
-- =====================================================
DROP PROCEDURE IF EXISTS sp_Quarto_Delete$$
CREATE PROCEDURE sp_Quarto_Delete(IN p_id INT)
BEGIN
  DELETE FROM Quarto WHERE id_quarto = p_id;
  IF ROW_COUNT() = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quarto nao encontrado';
  END IF;
END$$

-- =====================================================
-- sp_AtualizarPrecoQuarto (dispara o trigger; somente Gerente)
-- =====================================================
DROP PROCEDURE IF EXISTS sp_AtualizarPrecoQuarto$$
CREATE PROCEDURE sp_AtualizarPrecoQuarto(
  IN p_id_quarto   INT,
  IN p_novo_preco  DECIMAL(10,2),
  IN p_id_executor INT
)
BEGIN
  CALL sp_AssertGerente(p_id_executor);
  IF p_novo_preco < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Preco nao pode ser negativo';
  END IF;
  UPDATE Quarto SET preco_praticado = p_novo_preco WHERE id_quarto = p_id_quarto;
  IF ROW_COUNT() = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quarto nao encontrado';
  END IF;
END$$

-- =====================================================
-- sp_HistoricoPreco_ReadPorQuarto
-- =====================================================
DROP PROCEDURE IF EXISTS sp_HistoricoPreco_ReadPorQuarto$$
CREATE PROCEDURE sp_HistoricoPreco_ReadPorQuarto(IN p_id_quarto INT)
BEGIN
  SELECT id_historico, preco_praticado, data_inicio_vigencia, data_fim_vigencia
  FROM Historico_Preco
  WHERE id_quarto = p_id_quarto
  ORDER BY data_inicio_vigencia DESC;
END$$

-- =====================================================
-- sp_RegistrarReserva (transacional)
-- =====================================================
DROP PROCEDURE IF EXISTS sp_RegistrarReserva$$
CREATE PROCEDURE sp_RegistrarReserva(
  IN p_id_cliente         INT,
  IN p_id_quarto          INT,
  IN p_id_funcionario     INT,
  IN p_data_checkin_prev  DATE,
  IN p_data_checkout_prev DATE
)
BEGIN
  DECLARE v_conflitos INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_data_checkout_prev <= p_data_checkin_prev THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Data de checkout deve ser apos checkin';
  END IF;

  START TRANSACTION;

    SELECT COUNT(*) INTO v_conflitos
    FROM Reserva
    WHERE id_quarto = p_id_quarto
      AND status IN ('Confirmada','Efetivada')
      AND NOT (data_checkout_prev <= p_data_checkin_prev
            OR data_checkin_prev  >= p_data_checkout_prev);

    IF v_conflitos > 0 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Periodo sobreposto: o quarto ja possui reserva nesse intervalo';
    END IF;

    INSERT INTO Reserva(id_cliente, id_quarto, id_funcionario,
                        data_checkin_prev, data_checkout_prev, status)
    VALUES (p_id_cliente, p_id_quarto, p_id_funcionario,
            p_data_checkin_prev, p_data_checkout_prev, 'Confirmada');

  COMMIT;

  SELECT LAST_INSERT_ID() AS id_reserva;
END$$

-- =====================================================
-- sp_Reserva_Read
-- =====================================================
DROP PROCEDURE IF EXISTS sp_Reserva_Read$$
CREATE PROCEDURE sp_Reserva_Read(
  IN p_id      INT,
  IN p_status  VARCHAR(20)
)
BEGIN
  IF p_id IS NOT NULL THEN
    SELECT r.id_reserva, r.id_cliente, cli.nome AS cliente_nome,
           r.id_quarto, q.numero AS quarto_numero,
           r.id_funcionario, f.nome AS funcionario_nome,
           r.data_checkin_prev, r.data_checkout_prev, r.status, r.data_criacao
    FROM Reserva r
    JOIN Cliente cli   ON cli.id_cliente   = r.id_cliente
    JOIN Quarto q      ON q.id_quarto      = r.id_quarto
    JOIN Funcionario f ON f.id_funcionario = r.id_funcionario
    WHERE r.id_reserva = p_id;
  ELSEIF p_status IS NULL OR p_status = '' THEN
    SELECT r.id_reserva, r.id_cliente, cli.nome AS cliente_nome,
           r.id_quarto, q.numero AS quarto_numero,
           r.id_funcionario, f.nome AS funcionario_nome,
           r.data_checkin_prev, r.data_checkout_prev, r.status, r.data_criacao
    FROM Reserva r
    JOIN Cliente cli   ON cli.id_cliente   = r.id_cliente
    JOIN Quarto q      ON q.id_quarto      = r.id_quarto
    JOIN Funcionario f ON f.id_funcionario = r.id_funcionario
    ORDER BY r.data_checkin_prev DESC;
  ELSE
    SELECT r.id_reserva, r.id_cliente, cli.nome AS cliente_nome,
           r.id_quarto, q.numero AS quarto_numero,
           r.id_funcionario, f.nome AS funcionario_nome,
           r.data_checkin_prev, r.data_checkout_prev, r.status, r.data_criacao
    FROM Reserva r
    JOIN Cliente cli   ON cli.id_cliente   = r.id_cliente
    JOIN Quarto q      ON q.id_quarto      = r.id_quarto
    JOIN Funcionario f ON f.id_funcionario = r.id_funcionario
    WHERE r.status = p_status
    ORDER BY r.data_checkin_prev DESC;
  END IF;
END$$

-- =====================================================
-- sp_Reserva_Update
-- =====================================================
DROP PROCEDURE IF EXISTS sp_Reserva_Update$$
CREATE PROCEDURE sp_Reserva_Update(
  IN p_id                 INT,
  IN p_data_checkin_prev  DATE,
  IN p_data_checkout_prev DATE,
  IN p_status             ENUM('Confirmada','Cancelada','Efetivada','NoShow')
)
BEGIN
  DECLARE v_status_atual ENUM('Confirmada','Cancelada','Efetivada','NoShow');
  SELECT status INTO v_status_atual FROM Reserva WHERE id_reserva = p_id;
  IF v_status_atual IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reserva nao encontrada';
  END IF;
  IF v_status_atual IN ('Efetivada') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reserva ja efetivada nao pode ser alterada';
  END IF;
  IF p_data_checkout_prev <= p_data_checkin_prev THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Data de checkout deve ser apos checkin';
  END IF;
  UPDATE Reserva
     SET data_checkin_prev = p_data_checkin_prev,
         data_checkout_prev = p_data_checkout_prev,
         status = p_status
   WHERE id_reserva = p_id;
END$$

-- =====================================================
-- sp_Reserva_Delete (exclusao logica)
-- =====================================================
DROP PROCEDURE IF EXISTS sp_Reserva_Delete$$
CREATE PROCEDURE sp_Reserva_Delete(IN p_id INT)
BEGIN
  DECLARE v_status ENUM('Confirmada','Cancelada','Efetivada','NoShow');
  SELECT status INTO v_status FROM Reserva WHERE id_reserva = p_id;
  IF v_status IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reserva nao encontrada';
  END IF;
  IF v_status = 'Efetivada' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reserva efetivada nao pode ser cancelada';
  END IF;
  UPDATE Reserva SET status = 'Cancelada' WHERE id_reserva = p_id;
END$$

-- =====================================================
-- sp_RealizarCheckIn (transacional)
-- =====================================================
DROP PROCEDURE IF EXISTS sp_RealizarCheckIn$$
CREATE PROCEDURE sp_RealizarCheckIn(
  IN p_id_reserva    INT,
  IN p_id_funcionario INT
)
BEGIN
  DECLARE v_status_reserva ENUM('Confirmada','Cancelada','Efetivada','NoShow');
  DECLARE v_id_quarto      INT;
  DECLARE v_status_quarto  ENUM('Disponivel','Ocupado','Limpeza','Manutencao');
  DECLARE v_preco_atual    DECIMAL(10,2);
  DECLARE v_data_prev      DATE;
  DECLARE v_nova_id        INT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

    SELECT status, id_quarto, data_checkin_prev
      INTO v_status_reserva, v_id_quarto, v_data_prev
    FROM Reserva WHERE id_reserva = p_id_reserva
    FOR UPDATE;

    IF v_status_reserva IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reserva nao encontrada';
    END IF;
    IF v_status_reserva <> 'Confirmada' THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Reserva nao esta Confirmada (somente reservas Confirmadas permitem check-in)';
    END IF;

    SELECT status, preco_praticado INTO v_status_quarto, v_preco_atual
    FROM Quarto WHERE id_quarto = v_id_quarto
    FOR UPDATE;

    IF v_status_quarto NOT IN ('Disponivel','Limpeza') THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Quarto nao esta disponivel para check-in';
    END IF;

    UPDATE Quarto  SET status = 'Ocupado'   WHERE id_quarto  = v_id_quarto;
    UPDATE Reserva SET status = 'Efetivada' WHERE id_reserva = p_id_reserva;

    INSERT INTO Hospedagem(id_reserva, data_checkin_real, preco_diaria_aplicado, status)
    VALUES (p_id_reserva, NOW(), v_preco_atual, 'Ativa');

    SET v_nova_id = LAST_INSERT_ID();

  COMMIT;

  SELECT v_nova_id AS id_hospedagem;
END$$

-- =====================================================
-- sp_LancarConsumo (transacional)
-- =====================================================
DROP PROCEDURE IF EXISTS sp_LancarConsumo$$
CREATE PROCEDURE sp_LancarConsumo(
  IN p_id_hospedagem      INT,
  IN p_id_produto_servico INT,
  IN p_quantidade         INT
)
BEGIN
  DECLARE v_status_hosp  ENUM('Ativa','Finalizada');
  DECLARE v_preco_atual  DECIMAL(10,2);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_quantidade <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantidade deve ser positiva';
  END IF;

  START TRANSACTION;

    SELECT status INTO v_status_hosp FROM Hospedagem
    WHERE id_hospedagem = p_id_hospedagem FOR UPDATE;

    IF v_status_hosp IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hospedagem nao encontrada';
    END IF;
    IF v_status_hosp <> 'Ativa' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hospedagem nao esta Ativa';
    END IF;

    SELECT preco_venda INTO v_preco_atual FROM Produto_Servico
    WHERE id_produto_servico = p_id_produto_servico;

    IF v_preco_atual IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Produto/Servico nao encontrado';
    END IF;

    INSERT INTO Consumo(id_hospedagem, id_produto_servico, quantidade,
                        preco_unitario_momento)
    VALUES (p_id_hospedagem, p_id_produto_servico, p_quantidade, v_preco_atual);

  COMMIT;

  SELECT LAST_INSERT_ID() AS id_consumo;
END$$

-- =====================================================
-- sp_RealizarCheckOut (transacional)
-- =====================================================
DROP PROCEDURE IF EXISTS sp_RealizarCheckOut$$
CREATE PROCEDURE sp_RealizarCheckOut(
  IN p_id_hospedagem  INT,
  IN p_id_funcionario INT
)
BEGIN
  DECLARE v_status_hosp     ENUM('Ativa','Finalizada');
  DECLARE v_id_reserva      INT;
  DECLARE v_id_quarto       INT;
  DECLARE v_data_checkin    DATETIME;
  DECLARE v_preco_diaria    DECIMAL(10,2);
  DECLARE v_diarias         INT;
  DECLARE v_total_diarias   DECIMAL(10,2);
  DECLARE v_total_consumo   DECIMAL(10,2);
  DECLARE v_total           DECIMAL(10,2);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

    SELECT h.status, h.id_reserva, h.data_checkin_real, h.preco_diaria_aplicado,
           r.id_quarto
      INTO v_status_hosp, v_id_reserva, v_data_checkin, v_preco_diaria, v_id_quarto
    FROM Hospedagem h
    JOIN Reserva r ON r.id_reserva = h.id_reserva
    WHERE h.id_hospedagem = p_id_hospedagem
    FOR UPDATE;

    IF v_status_hosp IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hospedagem nao encontrada';
    END IF;
    IF v_status_hosp <> 'Ativa' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hospedagem nao esta Ativa';
    END IF;

    SET v_diarias = GREATEST(1, DATEDIFF(NOW(), v_data_checkin));
    SET v_total_diarias = v_diarias * v_preco_diaria;

    SELECT COALESCE(SUM(quantidade * preco_unitario_momento), 0)
      INTO v_total_consumo
    FROM Consumo WHERE id_hospedagem = p_id_hospedagem;

    SET v_total = v_total_diarias + v_total_consumo;

    UPDATE Hospedagem
       SET data_checkout_real  = NOW(),
           valor_total_diarias = v_total_diarias,
           status              = 'Finalizada'
     WHERE id_hospedagem = p_id_hospedagem;

    UPDATE Quarto SET status = 'Limpeza' WHERE id_quarto = v_id_quarto;

  COMMIT;

  SELECT p_id_hospedagem      AS id_hospedagem,
         v_diarias             AS quantidade_diarias,
         v_preco_diaria        AS preco_diaria_aplicado,
         v_total_diarias       AS total_diarias,
         v_total_consumo       AS total_consumo,
         v_total               AS valor_total;
END$$

-- =====================================================
-- sp_Relatorio_TaxaOcupacao (restrito a Gerente)
-- =====================================================
DROP PROCEDURE IF EXISTS sp_Relatorio_TaxaOcupacao$$
CREATE PROCEDURE sp_Relatorio_TaxaOcupacao(
  IN p_executor INT, IN p_ano INT, IN p_mes INT
)
BEGIN
  CALL sp_AssertGerente(p_executor);
  SELECT * FROM vw_taxa_ocupacao_mensal WHERE ano = p_ano AND mes = p_mes;
END$$

-- =====================================================
-- sp_Relatorio_TopClientes (restrito a Gerente)
-- =====================================================
DROP PROCEDURE IF EXISTS sp_Relatorio_TopClientes$$
CREATE PROCEDURE sp_Relatorio_TopClientes(IN p_executor INT)
BEGIN
  CALL sp_AssertGerente(p_executor);
  SELECT * FROM vw_top_clientes_assiduos LIMIT 10;
END$$

-- =====================================================
-- sp_Relatorio_TopQuartos (restrito a Gerente)
-- =====================================================
DROP PROCEDURE IF EXISTS sp_Relatorio_TopQuartos$$
CREATE PROCEDURE sp_Relatorio_TopQuartos(IN p_executor INT)
BEGIN
  CALL sp_AssertGerente(p_executor);
  SELECT * FROM vw_top_quartos_reservados LIMIT 10;
END$$

-- =====================================================
-- sp_Relatorio_FaturamentoMensal (restrito a Gerente)
-- =====================================================
DROP PROCEDURE IF EXISTS sp_Relatorio_FaturamentoMensal$$
CREATE PROCEDURE sp_Relatorio_FaturamentoMensal(
  IN p_executor INT, IN p_ano INT, IN p_mes INT
)
BEGIN
  CALL sp_AssertGerente(p_executor);
  SELECT * FROM vw_faturamento_mensal WHERE ano = p_ano AND mes = p_mes;
END$$

DELIMITER ;
USE hotel_mosquito;
DELIMITER $$

-- =====================================================
-- trg_preco_inicial_quarto
-- Garante que todo quarto tem uma vigencia de preco aberta
-- desde o seu nascimento.
-- =====================================================
DROP TRIGGER IF EXISTS trg_preco_inicial_quarto$$
CREATE TRIGGER trg_preco_inicial_quarto
AFTER INSERT ON Quarto
FOR EACH ROW
BEGIN
  INSERT INTO Historico_Preco(id_quarto, preco_praticado, data_inicio_vigencia, data_fim_vigencia)
  VALUES (NEW.id_quarto, NEW.preco_praticado, NOW(), NULL);
END$$

-- =====================================================
-- trg_atualiza_preco_quarto (OBRIGATORIA)
-- Quando preco_praticado de Quarto muda, fecha a vigencia
-- atual e abre uma nova em Historico_Preco.
-- =====================================================
DROP TRIGGER IF EXISTS trg_atualiza_preco_quarto$$
CREATE TRIGGER trg_atualiza_preco_quarto
AFTER UPDATE ON Quarto
FOR EACH ROW
BEGIN
  IF OLD.preco_praticado <> NEW.preco_praticado THEN
    UPDATE Historico_Preco
       SET data_fim_vigencia = NOW()
     WHERE id_quarto = NEW.id_quarto
       AND data_fim_vigencia IS NULL;

    INSERT INTO Historico_Preco(id_quarto, preco_praticado, data_inicio_vigencia, data_fim_vigencia)
    VALUES (NEW.id_quarto, NEW.preco_praticado, NOW(), NULL);
  END IF;
END$$

DELIMITER ;
USE hotel_mosquito;

-- =====================================================
-- Seed transacional. Todo o conteudo abaixo eh atomico.
-- Em caso de erro, basta ROLLBACK e nada fica pela metade.
-- =====================================================
START TRANSACTION;

-- 5 Categorias
INSERT INTO Categoria_Quarto(nome, descricao) VALUES
  ('Standard', 'Quarto basico com cama de casal e ar-condicionado'),
  ('Superior', 'Quarto ampliado com vista para o jardim'),
  ('Luxo',     'Acomodacao confortavel com varanda e frigobar'),
  ('Suite',    'Suite com sala de estar e banheira'),
  ('Master',   'Suite presidencial com hidromassagem e vista panoramica');

SAVEPOINT sp_categorias;

-- 15 Quartos (a insercao dispara trg_preco_inicial_quarto)
INSERT INTO Quarto(numero, andar, capacidade, status, preco_praticado, id_categoria) VALUES
  ('101', 1, 2, 'Disponivel', 200.00, 1),
  ('102', 1, 2, 'Disponivel', 200.00, 1),
  ('103', 1, 3, 'Disponivel', 220.00, 1),
  ('201', 2, 2, 'Disponivel', 280.00, 2),
  ('202', 2, 3, 'Disponivel', 300.00, 2),
  ('203', 2, 3, 'Disponivel', 300.00, 2),
  ('301', 3, 2, 'Disponivel', 380.00, 3),
  ('302', 3, 4, 'Disponivel', 420.00, 3),
  ('303', 3, 4, 'Disponivel', 420.00, 3),
  ('401', 4, 4, 'Disponivel', 550.00, 4),
  ('402', 4, 4, 'Disponivel', 550.00, 4),
  ('403', 4, 5, 'Disponivel', 600.00, 4),
  ('501', 5, 4, 'Disponivel', 850.00, 5),
  ('502', 5, 5, 'Disponivel', 900.00, 5),
  ('503', 5, 6, 'Disponivel', 980.00, 5);

SAVEPOINT sp_quartos;

-- 10 Clientes
INSERT INTO Cliente(nome, cpf, email, telefone, endereco) VALUES
  ('Ana Souza',          '11111111111', 'ana.souza@example.com',          '11999990001', 'Rua A, 100, Sao Paulo, SP'),
  ('Bruno Lima',         '22222222222', 'bruno.lima@example.com',         '11999990002', 'Av. B, 200, Sao Paulo, SP'),
  ('Carla Mendes',       '33333333333', 'carla.mendes@example.com',       '11999990003', 'Rua C, 300, Campinas, SP'),
  ('Diego Rocha',        '44444444444', 'diego.rocha@example.com',        '21999990004', 'Av. D, 400, Rio de Janeiro, RJ'),
  ('Eliane Tavares',     '55555555555', 'eliane.tavares@example.com',     '21999990005', 'Rua E, 500, Niteroi, RJ'),
  ('Fernando Costa',     '66666666666', 'fernando.costa@example.com',     '31999990006', 'Rua F, 600, Belo Horizonte, MG'),
  ('Gabriela Pinto',     '77777777777', 'gabriela.pinto@example.com',     '31999990007', 'Av. G, 700, Contagem, MG'),
  ('Henrique Almeida',   '88888888888', 'henrique.almeida@example.com',   '41999990008', 'Rua H, 800, Curitiba, PR'),
  ('Isabela Nogueira',   '99999999999', 'isabela.nogueira@example.com',   '41999990009', 'Av. I, 900, Curitiba, PR'),
  ('Joao Pereira',       '10101010101', 'joao.pereira@example.com',       '51999990010', 'Rua J, 1000, Porto Alegre, RS');

SAVEPOINT sp_clientes;

-- Senhas iniciais (documentadas no README):
--   gerente1 / senha123     -> Maria Silva
--   gerente2 / senha123     -> Carlos Pereira
--   recep1   / senha123     -> Joana Lima
--   recep2   / senha123     -> Pedro Santos
--   recep3   / senha123     -> Lucas Andrade
INSERT INTO Funcionario(nome, cpf, cargo, login, senha_hash, perfil) VALUES
  ('Maria Silva',     '20202020201', 'Gerente Geral',   'gerente1', SHA2('senha123', 256), 'Gerente'),
  ('Carlos Pereira',  '20202020202', 'Gerente Adjunto', 'gerente2', SHA2('senha123', 256), 'Gerente'),
  ('Joana Lima',      '20202020203', 'Recepcionista',   'recep1',   SHA2('senha123', 256), 'Recepcionista'),
  ('Pedro Santos',    '20202020204', 'Recepcionista',   'recep2',   SHA2('senha123', 256), 'Recepcionista'),
  ('Lucas Andrade',   '20202020205', 'Recepcionista',   'recep3',   SHA2('senha123', 256), 'Recepcionista');

SAVEPOINT sp_funcionarios;

-- 10 Produtos/Servicos
INSERT INTO Produto_Servico(nome, preco_venda, tipo) VALUES
  ('Agua Mineral 500ml',     6.00,  'Frigobar'),
  ('Refrigerante Lata',      8.00,  'Frigobar'),
  ('Cerveja Long Neck',     12.00,  'Frigobar'),
  ('Barra de Chocolate',     9.00,  'Frigobar'),
  ('Cafe da Manha',         45.00,  'Restaurante'),
  ('Almoco Buffet',         65.00,  'Restaurante'),
  ('Jantar a la Carte',     85.00,  'Restaurante'),
  ('Lavagem Simples',       25.00,  'Lavanderia'),
  ('Lavagem a Seco',        45.00,  'Lavanderia'),
  ('Late Checkout (extra 6h)', 80.00, 'Outro');

SAVEPOINT sp_produtos;

-- 10 Reservas (8 Efetivada, 1 Confirmada futura, 1 Cancelada)
INSERT INTO Reserva(id_cliente, id_quarto, id_funcionario,
                    data_checkin_prev, data_checkout_prev, status, data_criacao) VALUES
  ( 1,  1, 3, '2026-03-01', '2026-03-04', 'Efetivada', '2026-02-25 10:00:00'),
  ( 2,  4, 3, '2026-03-05', '2026-03-08', 'Efetivada', '2026-02-26 11:00:00'),
  ( 3,  7, 4, '2026-04-10', '2026-04-13', 'Efetivada', '2026-04-01 09:30:00'),
  ( 4, 10, 4, '2026-04-15', '2026-04-18', 'Efetivada', '2026-04-02 14:00:00'),
  ( 5, 13, 5, '2026-04-20', '2026-04-24', 'Efetivada', '2026-04-03 16:00:00'),
  ( 6,  2, 3, '2026-05-20', '2026-05-30', 'Efetivada', '2026-05-15 10:00:00'),
  ( 7,  5, 4, '2026-05-22', '2026-05-28', 'Efetivada', '2026-05-15 11:00:00'),
  ( 8,  8, 5, '2026-05-24', '2026-05-29', 'Efetivada', '2026-05-18 09:00:00'),
  ( 9, 11, 3, '2026-06-10', '2026-06-15', 'Confirmada', '2026-05-20 13:00:00'),
  (10, 14, 4, '2026-06-20', '2026-06-25', 'Cancelada',  '2026-05-21 15:00:00');

SAVEPOINT sp_reservas;

-- 8 Hospedagens (5 Finalizada + 3 Ativa)
INSERT INTO Hospedagem(id_reserva, data_checkin_real, data_checkout_real,
                       preco_diaria_aplicado, valor_total_diarias, status) VALUES
  (1, '2026-03-01 14:00:00', '2026-03-04 12:00:00', 200.00,  600.00, 'Finalizada'),
  (2, '2026-03-05 14:30:00', '2026-03-08 11:30:00', 280.00,  840.00, 'Finalizada'),
  (3, '2026-04-10 15:00:00', '2026-04-13 12:00:00', 380.00, 1140.00, 'Finalizada'),
  (4, '2026-04-15 16:00:00', '2026-04-18 12:00:00', 550.00, 1650.00, 'Finalizada'),
  (5, '2026-04-20 14:00:00', '2026-04-24 11:00:00', 850.00, 3400.00, 'Finalizada'),
  (6, '2026-05-20 15:00:00', NULL, 200.00, NULL, 'Ativa'),
  (7, '2026-05-22 14:00:00', NULL, 300.00, NULL, 'Ativa'),
  (8, '2026-05-24 16:00:00', NULL, 420.00, NULL, 'Ativa');

-- Marca os quartos das 3 hospedagens Ativas como Ocupado
UPDATE Quarto SET status = 'Ocupado' WHERE id_quarto IN (2, 5, 8);

SAVEPOINT sp_hospedagens;

-- 15 Consumos distribuidos
INSERT INTO Consumo(id_hospedagem, id_produto_servico, quantidade, preco_unitario_momento, data_hora) VALUES
  (1, 1, 2,  6.00, '2026-03-02 09:00:00'),
  (1, 5, 1, 45.00, '2026-03-02 08:00:00'),
  (2, 2, 3,  8.00, '2026-03-06 18:00:00'),
  (2, 6, 1, 65.00, '2026-03-07 13:00:00'),
  (3, 3, 4, 12.00, '2026-04-11 22:00:00'),
  (4, 7, 2, 85.00, '2026-04-16 20:00:00'),
  (5, 8, 1, 25.00, '2026-04-22 10:00:00'),
  (6, 1, 3,  6.00, '2026-05-21 11:00:00'),
  (6, 4, 2,  9.00, '2026-05-21 22:00:00'),
  (6, 6, 1, 65.00, '2026-05-22 13:00:00'),
  (7, 5, 1, 45.00, '2026-05-23 08:00:00'),
  (7, 2, 4,  8.00, '2026-05-23 21:00:00'),
  (7, 9, 1, 45.00, '2026-05-25 09:00:00'),
  (8, 3, 6, 12.00, '2026-05-25 23:00:00'),
  (8, 7, 2, 85.00, '2026-05-26 20:00:00');

SAVEPOINT sp_consumos;

COMMIT;

-- Verificacao rapida apos o seed
SELECT
  (SELECT COUNT(*) FROM Categoria_Quarto) AS categorias,
  (SELECT COUNT(*) FROM Quarto)           AS quartos,
  (SELECT COUNT(*) FROM Cliente)          AS clientes,
  (SELECT COUNT(*) FROM Funcionario)      AS funcionarios,
  (SELECT COUNT(*) FROM Produto_Servico)  AS produtos,
  (SELECT COUNT(*) FROM Reserva)          AS reservas,
  (SELECT COUNT(*) FROM Hospedagem)       AS hospedagens,
  (SELECT COUNT(*) FROM Consumo)          AS consumos,
  (SELECT COUNT(*) FROM Historico_Preco)  AS historicos_preco;
-- Esperado: 5, 15, 10, 5, 10, 10, 8, 15, 15
