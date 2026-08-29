-- RN15/RN16: rota passa a ter veículos (capacidade real, usada na ocupação da
-- lista e no resumo do painel) e paradas ordenadas (trajeto). Sem isso a tela
-- do aluno não tem como mostrar "18 / 45" nem o trajeto da rota.
CREATE TABLE vehicles (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id   UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    label      VARCHAR(100) NOT NULL,
    capacity   INT NOT NULL CHECK (capacity > 0),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE stops (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id   UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    name       VARCHAR(150) NOT NULL,
    latitude   DOUBLE PRECISION,
    longitude  DOUBLE PRECISION,
    -- Ordem de passagem: o trajeto é uma sequência, não um conjunto.
    sequence   INT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (route_id, sequence)
);

CREATE INDEX idx_vehicles_route ON vehicles(route_id);
CREATE INDEX idx_stops_route ON stops(route_id);

-- Dado de demonstração pras rotas que já existem, senão a capacidade aparece
-- zerada em toda tela nova.
INSERT INTO vehicles (route_id, label, capacity)
SELECT id, 'Ônibus 01', 45 FROM routes WHERE is_active = true;

INSERT INTO stops (route_id, name, sequence)
SELECT r.id, s.name, s.seq
FROM routes r
CROSS JOIN (VALUES
    ('Rodoviária', 1),
    ('Centro', 2),
    ('Av. Washington Soares', 3),
    ('Campus Unifor', 4)
) AS s(name, seq)
WHERE r.is_active = true;
