-- RN23: checkpoint so vale em ponto principal (rodoviaria + instituicoes da rota).
-- Parada comum continua no mapa, mas nao gera marcacao.
ALTER TABLE stops ADD COLUMN is_main_point BOOLEAN NOT NULL DEFAULT FALSE;

-- Marca as paradas ja existentes: rodoviarias e as que sao instituicao atendida.
UPDATE stops SET is_main_point = TRUE WHERE name LIKE 'Rodoviária%';
UPDATE stops s SET is_main_point = TRUE
  FROM institutions i
 WHERE i.route_id = s.route_id
   AND s.name LIKE i.name || '%';

-- Um trajeto por lista (relacao 1:1), entao o estado mora na propria lista.
ALTER TABLE daily_lists
    ADD COLUMN trip_started_at  TIMESTAMP,
    ADD COLUMN trip_finished_at TIMESTAMP;

CREATE TABLE trip_checkpoints (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    daily_list_id UUID      NOT NULL REFERENCES daily_lists(id) ON DELETE CASCADE,
    stop_id       UUID      NOT NULL REFERENCES stops(id) ON DELETE CASCADE,
    reached_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    -- A unicidade e o que torna o checkpoint idempotente: tocar duas vezes no
    -- botao nao gera duas chegadas nem dois avisos.
    UNIQUE (daily_list_id, stop_id)
);

CREATE INDEX idx_trip_checkpoints_list ON trip_checkpoints(daily_list_id);
