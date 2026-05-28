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
