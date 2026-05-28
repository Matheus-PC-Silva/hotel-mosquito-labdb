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
