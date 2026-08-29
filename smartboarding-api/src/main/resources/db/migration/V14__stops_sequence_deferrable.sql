-- Inserir uma parada no meio do trajeto exige empurrar as seguintes, e durante
-- esse remanejo duas paradas ocupam a mesma posição por um instante. O
-- Hibernate ainda executa o INSERT antes dos UPDATEs, então a checagem imediata
-- rejeitava a operação inteira.
--
-- Adiar pro commit mantém a garantia (ao final, nenhuma rota tem duas paradas
-- na mesma posição) sem proibir o estado intermediário.
ALTER TABLE stops DROP CONSTRAINT stops_route_id_sequence_key;
ALTER TABLE stops ADD CONSTRAINT stops_route_id_sequence_key
    UNIQUE (route_id, sequence) DEFERRABLE INITIALLY DEFERRED;
