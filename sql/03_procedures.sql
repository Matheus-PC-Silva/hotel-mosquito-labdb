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
