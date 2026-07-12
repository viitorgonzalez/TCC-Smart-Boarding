-- Seed de demonstracao: dados em todas as telas
-- (usuarios variados, rotas, lista do dia com inscritos, listas fechadas e relatorios).
-- Senha de todos os usuarios abaixo: sb@2026 (hash bcrypt reutilizado do admin).

-- ── Usuarios adicionais (para demonstrar filtro/hierarquia) ────────────────────
INSERT INTO users (email, password, role, full_name, birth_date, course, institution, phone, is_active) VALUES
  ('bruno@student.com',    '$2b$10$Hot5nGjLXrPmP772N4HTI.tViB4GCk3n/YW8778YUVIM4vNGFd56e', 'STUDENT', 'Bruno Almeida',     '2001-02-10', 'Engenharia Civil',    'UNIFOR-MG', '37990000001', TRUE),
  ('carla@student.com',    '$2b$10$Hot5nGjLXrPmP772N4HTI.tViB4GCk3n/YW8778YUVIM4vNGFd56e', 'STUDENT', 'Carla Souza',       '2002-06-22', 'Direito',             'UNIFOR-MG', '37990000002', TRUE),
  ('daniela@student.com',  '$2b$10$Hot5nGjLXrPmP772N4HTI.tViB4GCk3n/YW8778YUVIM4vNGFd56e', 'STUDENT', 'Daniela Rocha',     '2000-11-05', 'Medicina',            'UNIFOR-MG', '37990000003', TRUE),
  ('eduardo@student.com',  '$2b$10$Hot5nGjLXrPmP772N4HTI.tViB4GCk3n/YW8778YUVIM4vNGFd56e', 'STUDENT', 'Eduardo Lima',      '2001-09-14', 'Computacao',          'UNIFOR-MG', '37990000004', TRUE),
  ('fernanda@student.com', '$2b$10$Hot5nGjLXrPmP772N4HTI.tViB4GCk3n/YW8778YUVIM4vNGFd56e', 'STUDENT', 'Fernanda Costa',    '2003-03-30', 'Arquitetura',         'UNIFOR-MG', '37990000005', TRUE),
  ('gabriel@student.com',  '$2b$10$Hot5nGjLXrPmP772N4HTI.tViB4GCk3n/YW8778YUVIM4vNGFd56e', 'STUDENT', 'Gabriel Martins',   '2002-01-18', 'Administracao',       'UNIFOR-MG', '37990000006', TRUE),
  ('helena@student.com',   '$2b$10$Hot5nGjLXrPmP772N4HTI.tViB4GCk3n/YW8778YUVIM4vNGFd56e', 'STUDENT', 'Helena Dias',       '2000-07-27', 'Psicologia',          'UNIFOR-MG', '37990000007', TRUE),
  ('roberto@driver.com',   '$2b$10$Hot5nGjLXrPmP772N4HTI.tViB4GCk3n/YW8778YUVIM4vNGFd56e', 'DRIVER',  'Roberto Dias',      '1979-04-12', NULL,                  'Smart Boarding Inc', '37966666667', TRUE),
  ('marina@admin.com',     '$2b$10$Hot5nGjLXrPmP772N4HTI.tViB4GCk3n/YW8778YUVIM4vNGFd56e', 'ADMIN',   'Marina Gestora',    '1988-12-03', NULL,                  'Smart Boarding Inc', '37955555555', TRUE)
ON CONFLICT (email) DO NOTHING;

-- ── Rotas (2 ativas + 1 inativa) ──────────────────────────────────────────────
INSERT INTO routes (name, description, is_active) VALUES
  ('Rota Rodoviaria - Campus', 'Principal: da rodoviaria ate o campus universitario', TRUE),
  ('Rota Bairro Norte',        'Atende os bairros da zona norte',                      TRUE),
  ('Rota Centro',              'Rota antiga do centro (desativada)',                   FALSE);

-- ── Lista do dia ABERTA (hoje) para a rota principal ──────────────────────────
INSERT INTO daily_lists (route_id, date, status)
SELECT id, CURRENT_DATE, 'OPEN' FROM routes WHERE name = 'Rota Rodoviaria - Campus';

-- 6 alunos inscritos ativos na lista de hoje
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

-- ── Relatorios das listas fechadas (snapshot = array JSON de inscritos) ───────
INSERT INTO reports (daily_list_id, generated_at, total_entries, snapshot_data)
SELECT dl.id, (dl.date + TIME '16:00'), 5,
  '[{"id":"seed-a","fullName":"Ana Oliveira","email":"ana@student.com"},{"id":"seed-b","fullName":"Bruno Almeida","email":"bruno@student.com"},{"id":"seed-c","fullName":"Carla Souza","email":"carla@student.com"},{"id":"seed-d","fullName":"Daniela Rocha","email":"daniela@student.com"},{"id":"seed-e","fullName":"Eduardo Lima","email":"eduardo@student.com"}]'
FROM daily_lists dl
JOIN routes r ON r.id = dl.route_id AND r.name = 'Rota Rodoviaria - Campus'
WHERE dl.date = CURRENT_DATE - 3;

INSERT INTO reports (daily_list_id, generated_at, total_entries, snapshot_data)
SELECT dl.id, (dl.date + TIME '16:00'), 3,
  '[{"id":"seed-f","fullName":"Fernanda Costa","email":"fernanda@student.com"},{"id":"seed-g","fullName":"Gabriel Martins","email":"gabriel@student.com"},{"id":"seed-h","fullName":"Helena Dias","email":"helena@student.com"}]'
FROM daily_lists dl
JOIN routes r ON r.id = dl.route_id AND r.name = 'Rota Bairro Norte'
WHERE dl.date = CURRENT_DATE - 4;
