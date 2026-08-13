-- Dado semente consolidado (antigas V2, V8, V9 e V11).
--
-- Cobre: contas de todos os papeis + dados de demonstracao suficientes pra
-- todas as telas terem conteudo (rotas ativas/inativa, lista do dia aberta com
-- inscritos, listas fechadas com relatorio).
--
-- Senha de TODOS os usuarios: sb@2026  (hash bcrypt compartilhado)
-- Excecao: vitor@student.com usa sb@2026@123 (hash proprio).
--
-- As datas sao relativas a CURRENT_DATE, entao a demo continua fazendo sentido
-- independente de quando o banco for criado.

-- ── Usuarios ──────────────────────────────────────────────────────────────────
INSERT INTO users (email, password, role, full_name, birth_date, course, institution, phone, is_active) VALUES
  ('admin@smartboarding.com',     '$2b$10$Hot5nGjLXrPmP772N4HTI.tViB4GCk3n/YW8778YUVIM4vNGFd56e', 'ADMIN',   'System Administrator',        '1990-01-01', NULL,                  'Smart Boarding Inc', '37999999999', TRUE),
  ('marina@admin.com',            '$2b$10$Hot5nGjLXrPmP772N4HTI.tViB4GCk3n/YW8778YUVIM4vNGFd56e', 'ADMIN',   'Marina Gestora',              '1988-12-03', NULL,                  'Smart Boarding Inc', '37955555555', TRUE),
  ('motorista@smartboarding.com', '$2b$10$Hot5nGjLXrPmP772N4HTI.tViB4GCk3n/YW8778YUVIM4vNGFd56e', 'DRIVER',  'Carlos Motorista',            '1985-08-10', NULL,                  'Smart Boarding Inc', '37966666666', TRUE),
  ('roberto@driver.com',          '$2b$10$Hot5nGjLXrPmP772N4HTI.tViB4GCk3n/YW8778YUVIM4vNGFd56e', 'DRIVER',  'Roberto Dias',                '1979-04-12', NULL,                  'Smart Boarding Inc', '37966666667', TRUE),
  ('vitor@student.com',           '$2b$10$gO.uV8wE1xvKImI.IMVl5.tVdo4OJ6OAJf1qtZ2LlAxo0XXM8L6M6', 'STUDENT', 'Vítor Silva Pastor Gonzalez', '2000-05-15', 'Computer Science',    'UNIFOR-MG', '37988888888', TRUE),
  ('ana@student.com',             '$2b$10$ms4D9e/PWi16v05AQzKE8OY7xra/JAi8zNeMvszN7Uaxa1ObMB.Ju', 'STUDENT', 'Ana Oliveira',                '2002-03-20', 'Civil Engineering',   'UNIFOR-MG', '37977777777', TRUE),
  ('bruno@student.com',           '$2b$10$Hot5nGjLXrPmP772N4HTI.tViB4GCk3n/YW8778YUVIM4vNGFd56e', 'STUDENT', 'Bruno Almeida',               '2001-02-10', 'Engenharia Civil',    'UNIFOR-MG', '37990000001', TRUE),
  ('carla@student.com',           '$2b$10$Hot5nGjLXrPmP772N4HTI.tViB4GCk3n/YW8778YUVIM4vNGFd56e', 'STUDENT', 'Carla Souza',                 '2002-06-22', 'Direito',             'UNIFOR-MG', '37990000002', TRUE),
  ('daniela@student.com',         '$2b$10$Hot5nGjLXrPmP772N4HTI.tViB4GCk3n/YW8778YUVIM4vNGFd56e', 'STUDENT', 'Daniela Rocha',               '2000-11-05', 'Medicina',            'UNIFOR-MG', '37990000003', TRUE),
  ('eduardo@student.com',         '$2b$10$Hot5nGjLXrPmP772N4HTI.tViB4GCk3n/YW8778YUVIM4vNGFd56e', 'STUDENT', 'Eduardo Lima',                '2001-09-14', 'Computacao',          'UNIFOR-MG', '37990000004', TRUE),
  ('fernanda@student.com',        '$2b$10$Hot5nGjLXrPmP772N4HTI.tViB4GCk3n/YW8778YUVIM4vNGFd56e', 'STUDENT', 'Fernanda Costa',              '2003-03-30', 'Arquitetura',         'UNIFOR-MG', '37990000005', TRUE),
  ('gabriel@student.com',         '$2b$10$Hot5nGjLXrPmP772N4HTI.tViB4GCk3n/YW8778YUVIM4vNGFd56e', 'STUDENT', 'Gabriel Martins',             '2002-01-18', 'Administracao',       'UNIFOR-MG', '37990000006', TRUE),
  ('helena@student.com',          '$2b$10$Hot5nGjLXrPmP772N4HTI.tViB4GCk3n/YW8778YUVIM4vNGFd56e', 'STUDENT', 'Helena Dias',                 '2000-07-27', 'Psicologia',          'UNIFOR-MG', '37990000007', TRUE);

-- ── Rotas (2 ativas + 1 inativa) ──────────────────────────────────────────────
INSERT INTO routes (name, description, is_active) VALUES
  ('Rota Rodoviaria - Campus', 'Principal: da rodoviaria ate o campus universitario', TRUE),
  ('Rota Bairro Norte',        'Atende os bairros da zona norte',                     TRUE),
  ('Rota Centro',              'Rota antiga do centro (desativada)',                  FALSE);

-- ── Lista do dia ABERTA (hoje) para a rota principal ──────────────────────────
INSERT INTO daily_lists (route_id, date, status)
SELECT id, CURRENT_DATE, 'OPEN' FROM routes WHERE name = 'Rota Rodoviaria - Campus';

-- 6 alunos inscritos ativos na lista de hoje (trip_type assume o default ROUND_TRIP)
INSERT INTO list_entries (user_id, daily_list_id, is_active)
SELECT u.id, dl.id, TRUE
FROM daily_lists dl
JOIN routes r ON r.id = dl.route_id AND r.name = 'Rota Rodoviaria - Campus'
JOIN users u ON u.email IN (
  'vitor@student.com','ana@student.com','bruno@student.com',
  'carla@student.com','daniela@student.com','eduardo@student.com'
)
WHERE dl.date = CURRENT_DATE;

-- ── Listas passadas FECHADAS (para gerar relatorios) ──────────────────────────
INSERT INTO daily_lists (route_id, date, status, closed_at)
SELECT id, CURRENT_DATE - 3, 'CLOSED', (CURRENT_DATE - 3 + TIME '16:00')
FROM routes WHERE name = 'Rota Rodoviaria - Campus';

INSERT INTO daily_lists (route_id, date, status, closed_at)
SELECT id, CURRENT_DATE - 4, 'CLOSED', (CURRENT_DATE - 4 + TIME '16:00')
FROM routes WHERE name = 'Rota Bairro Norte';

-- ── Relatorios das listas fechadas ────────────────────────────────────────────
-- snapshot ja inclui tripType (na versao antiga isso vinha de um UPDATE na V11).
INSERT INTO reports (daily_list_id, generated_at, total_entries, snapshot_data)
SELECT dl.id, (dl.date + TIME '16:00'), 5,
  '[{"id":"seed-a","fullName":"Ana Oliveira","email":"ana@student.com","tripType":"ROUND_TRIP"},{"id":"seed-b","fullName":"Bruno Almeida","email":"bruno@student.com","tripType":"ROUND_TRIP"},{"id":"seed-c","fullName":"Carla Souza","email":"carla@student.com","tripType":"TO_CAMPUS"},{"id":"seed-d","fullName":"Daniela Rocha","email":"daniela@student.com","tripType":"FROM_CAMPUS"},{"id":"seed-e","fullName":"Eduardo Lima","email":"eduardo@student.com","tripType":"ROUND_TRIP"}]'
FROM daily_lists dl
JOIN routes r ON r.id = dl.route_id AND r.name = 'Rota Rodoviaria - Campus'
WHERE dl.date = CURRENT_DATE - 3;

INSERT INTO reports (daily_list_id, generated_at, total_entries, snapshot_data)
SELECT dl.id, (dl.date + TIME '16:00'), 3,
  '[{"id":"seed-f","fullName":"Fernanda Costa","email":"fernanda@student.com","tripType":"ROUND_TRIP"},{"id":"seed-g","fullName":"Gabriel Martins","email":"gabriel@student.com","tripType":"TO_CAMPUS"},{"id":"seed-h","fullName":"Helena Dias","email":"helena@student.com","tripType":"FROM_CAMPUS"}]'
FROM daily_lists dl
JOIN routes r ON r.id = dl.route_id AND r.name = 'Rota Bairro Norte'
WHERE dl.date = CURRENT_DATE - 4;
