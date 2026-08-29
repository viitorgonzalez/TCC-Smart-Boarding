-- As paradas da V8 nasceram sem coordenada e com nomes de Fortaleza, herdados
-- do cenário anterior. Sem latitude/longitude o mapa não tem o que desenhar, e
-- o trajeto por ruas (OSRM) não tem por onde traçar.
--
-- Coordenadas aproximadas de Formiga/MG, suficientes pra demonstração: o admin
-- reposiciona qualquer parada tocando no mapa.
DELETE FROM stops WHERE route_id IN (
    SELECT id FROM routes WHERE name = 'Rota Universitária de Formiga'
);

INSERT INTO stops (route_id, name, latitude, longitude, sequence)
SELECT r.id, s.name, s.lat, s.lon, s.seq
FROM routes r
CROSS JOIN (VALUES
    ('Rodoviária de Formiga',   -20.4658, -45.4283, 1),
    ('Centro',                  -20.4644, -45.4269, 2),
    ('UNIFOR-MG',               -20.4585, -45.4197, 3),
    ('IFMG — Campus Formiga',   -20.4477, -45.4218, 4)
) AS s(name, lat, lon, seq)
WHERE r.name = 'Rota Universitária de Formiga';
