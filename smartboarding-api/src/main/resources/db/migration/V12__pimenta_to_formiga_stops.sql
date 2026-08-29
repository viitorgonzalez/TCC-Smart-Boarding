-- Trajeto real da rota: sai da rodoviária de Pimenta/MG, faz quatro paradas na
-- cidade (a última na Distrimed, já na saída pela MG-050) e segue pra Formiga,
-- passando na UNIFOR-MG e terminando no IFMG.
--
-- Coordenadas obtidas do OpenStreetMap (Nominatim/Overpass), não estimadas:
--   • Rodoviária .... Rua João Rodrigues Sobrinho, endereço do terminal
--   • paradas ....... avenidas mapeadas no centro de Pimenta
--   • UNIFOR/IFMG ... registros próprios das instituições no OSM
--
-- ⚠️ Exceção: a Distrimed não existe como ponto no OSM e o número do endereço
-- (Rod. MG-050, Km 241, 2022) não resolve em geocodificação. O ponto usado é o
-- trecho da MG-050 dentro de Pimenta — aproximação da saída da cidade, não a
-- porta da empresa. O admin reposiciona pelo mapa.
DELETE FROM stops WHERE route_id IN (
    SELECT id FROM routes WHERE name = 'Rota Universitária de Formiga'
);

INSERT INTO stops (route_id, name, latitude, longitude, sequence)
SELECT r.id, s.name, s.lat, s.lon, s.seq
FROM routes r
CROSS JOIN (VALUES
    ('Rodoviária de Pimenta',            -20.4841262, -45.8067703, 1),
    ('Av. Aristides Garcia Leão',        -20.4860499, -45.8075674, 2),
    ('Av. Jair Leite',                   -20.4829497, -45.8055229, 3),
    ('Av. Juscelino Kubitschek',         -20.4798253, -45.7991373, 4),
    ('Distrimed (MG-050)',               -20.4713033, -45.7983842, 5),
    ('UNIFOR-MG — Formiga',              -20.4567147, -45.4512983, 6),
    ('IFMG — Campus Formiga',            -20.4527670, -45.4385239, 7)
) AS s(name, lat, lon, seq)
WHERE r.name = 'Rota Universitária de Formiga';
