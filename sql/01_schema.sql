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
