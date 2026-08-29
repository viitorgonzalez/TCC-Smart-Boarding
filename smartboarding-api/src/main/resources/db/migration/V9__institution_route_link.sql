-- RN15: a rota do aluno é derivada da instituição, e uma rota atende VÁRIAS
-- instituições (em Formiga, IFMG e UNIFOR-MG dividem o mesmo transporte e a
-- mesma lista). Até aqui não havia elo nenhum: users.institution era texto solto
-- e institutions não conhecia rota, então toda lista aparecia pra todo aluno.
ALTER TABLE institutions ADD COLUMN route_id UUID REFERENCES routes(id);
ALTER TABLE users        ADD COLUMN institution_id UUID REFERENCES institutions(id);

-- ── Cenário real de Formiga ─────────────────────────────────────────────────
UPDATE routes SET name = 'Rota Universitária de Formiga'
 WHERE name = 'Rota Rodoviaria - Campus';

-- Uma rota só no cenário; as demais saem de circulação sem perder histórico.
UPDATE routes SET is_active = false
 WHERE name <> 'Rota Universitária de Formiga';

-- A instituição criada em runtime durante os testes vira UNIFOR-MG, que é como
-- os alunos do seed já se identificam.
UPDATE institutions SET name = 'UNIFOR-MG' WHERE name = 'Unifor - Campus Central';

INSERT INTO institutions (name, address)
SELECT 'UNIFOR-MG', 'Av. Dr. Arnaldo de Senna, 328 - Formiga/MG'
 WHERE NOT EXISTS (SELECT 1 FROM institutions WHERE name = 'UNIFOR-MG');

INSERT INTO institutions (name, address)
SELECT 'IFMG', 'R. Padre Alberico, 440 - Formiga/MG'
 WHERE NOT EXISTS (SELECT 1 FROM institutions WHERE name = 'IFMG');

UPDATE institutions
   SET route_id = (SELECT id FROM routes WHERE name = 'Rota Universitária de Formiga')
 WHERE name IN ('UNIFOR-MG', 'IFMG');

-- ── users.institution: texto → referência ───────────────────────────────────
UPDATE users u
   SET institution_id = i.id
  FROM institutions i
 WHERE i.name = u.institution;

-- Aluno cujo texto não casava com instituição nenhuma (variações do seed) vai
-- pra UNIFOR-MG: sem instituição ele não teria rota e não veria lista alguma.
UPDATE users
   SET institution_id = (SELECT id FROM institutions WHERE name = 'UNIFOR-MG')
 WHERE role = 'STUDENT' AND institution_id IS NULL;

-- Parte dos alunos passa pro IFMG pra a divisão por instituição na lista ter o
-- que mostrar — as duas instituições dividem o mesmo transporte.
UPDATE users
   SET institution_id = (SELECT id FROM institutions WHERE name = 'IFMG')
 WHERE role = 'STUDENT'
   AND email IN ('bruno@student.com', 'carla@student.com', 'daniela@student.com');

ALTER TABLE users DROP COLUMN institution;

-- ── Frota: um ônibus e uma van na rota ──────────────────────────────────────
DELETE FROM vehicles;
INSERT INTO vehicles (route_id, label, capacity)
SELECT id, 'Ônibus', 45 FROM routes WHERE name = 'Rota Universitária de Formiga';
INSERT INTO vehicles (route_id, label, capacity)
SELECT id, 'Van', 15 FROM routes WHERE name = 'Rota Universitária de Formiga';

CREATE INDEX idx_institutions_route ON institutions(route_id);
CREATE INDEX idx_users_institution ON users(institution_id);
