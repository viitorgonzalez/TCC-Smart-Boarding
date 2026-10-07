INSERT INTO routes (id, name, description, is_active, open_time, close_time)
VALUES ('aaaaaaaa-0000-0000-0000-000000000001', 'Rota Universitária de Formiga',
        'Sai de Pimenta, passa pelo centro e segue pra Formiga, atendendo UNIFOR-MG e IFMG',
        TRUE, '00:00:00', '16:00:00');

INSERT INTO institutions (id, name, address, route_id) VALUES
  ('aaaaaaaa-0000-0000-0000-000000000011', 'UNIFOR-MG', 'Av. Dr. Arnaldo de Senna, 328 - Formiga/MG', 'aaaaaaaa-0000-0000-0000-000000000001'),
  ('aaaaaaaa-0000-0000-0000-000000000012', 'IFMG',      'R. Padre Alberico, 440 - Formiga/MG',         'aaaaaaaa-0000-0000-0000-000000000001');

INSERT INTO vehicles (route_id, label, capacity) VALUES
  ('aaaaaaaa-0000-0000-0000-000000000001', 'Ônibus', 45),
  ('aaaaaaaa-0000-0000-0000-000000000001', 'Van',    15);

INSERT INTO stops (route_id, name, latitude, longitude, sequence, is_main_point, institution_id) VALUES
  ('aaaaaaaa-0000-0000-0000-000000000001', 'Rodoviária de Pimenta',     -20.4841262, -45.8067703, 1, TRUE,  NULL),
  ('aaaaaaaa-0000-0000-0000-000000000001', 'Av. Aristides Garcia Leão', -20.4860499, -45.8075674, 2, FALSE, NULL),
  ('aaaaaaaa-0000-0000-0000-000000000001', 'Av. Jair Leite',            -20.4829497, -45.8055229, 3, FALSE, NULL),
  ('aaaaaaaa-0000-0000-0000-000000000001', 'Av. Juscelino Kubitschek',  -20.4798253, -45.7991373, 4, FALSE, NULL),
  ('aaaaaaaa-0000-0000-0000-000000000001', 'Distrimed (MG-050)',        -20.4713033, -45.7983842, 5, FALSE, NULL),
  ('aaaaaaaa-0000-0000-0000-000000000001', 'UNIFOR-MG — Formiga',       -20.4567147, -45.4512983, 6, TRUE,  'aaaaaaaa-0000-0000-0000-000000000011'),
  ('aaaaaaaa-0000-0000-0000-000000000001', 'IFMG — Campus Formiga',     -20.4527670, -45.4385239, 7, TRUE,  'aaaaaaaa-0000-0000-0000-000000000012');

INSERT INTO users (id, email, password, role, full_name, birth_date, course, institution_id, phone, is_active) VALUES
  ('aaaaaaaa-0000-0000-0000-000000000101', 'admin@smartboarding.com',     '$argon2id$v=19$m=16384,t=2,p=1$Dbh9QDoCbk5sXcTCOMEN7g$whClh9dWJn7R3wJsa0zMmpWUhuY7K/cDTehxp55szro', 'ADMIN',   'System Administrator', '1990-01-01', NULL,               NULL,                                   '37999999999', TRUE),
  ('aaaaaaaa-0000-0000-0000-000000000102', 'marina@admin.com',            '$argon2id$v=19$m=16384,t=2,p=1$Dbh9QDoCbk5sXcTCOMEN7g$whClh9dWJn7R3wJsa0zMmpWUhuY7K/cDTehxp55szro', 'ADMIN',   'Marina Gestora',       '1988-12-03', NULL,               NULL,                                   '37955555555', TRUE),
  ('aaaaaaaa-0000-0000-0000-000000000103', 'motorista@smartboarding.com', '$argon2id$v=19$m=16384,t=2,p=1$Dbh9QDoCbk5sXcTCOMEN7g$whClh9dWJn7R3wJsa0zMmpWUhuY7K/cDTehxp55szro', 'ADMIN',   'Carlos Motorista',     '1985-08-10', NULL,               NULL,                                   '37966666666', TRUE),
  ('aaaaaaaa-0000-0000-0000-000000000104', 'roberto@driver.com',          '$argon2id$v=19$m=16384,t=2,p=1$Dbh9QDoCbk5sXcTCOMEN7g$whClh9dWJn7R3wJsa0zMmpWUhuY7K/cDTehxp55szro', 'ADMIN',   'Roberto Dias',         '1979-04-12', NULL,               NULL,                                   '37966666667', TRUE),
  ('aaaaaaaa-0000-0000-0000-000000000201', 'vitor@student.com',           '$argon2id$v=19$m=16384,t=2,p=1$S7T5teEEXPXTjhGwkn8Cdg$1UeehCZjST2T8++a50HdihifQLuhRmm2MQxcAhACrb8', 'STUDENT', 'Vítor Silva Pastor Gonzalez', '2000-05-15', 'Computer Science', 'aaaaaaaa-0000-0000-0000-000000000011', '37988888888', TRUE),
  ('aaaaaaaa-0000-0000-0000-000000000202', 'ana@student.com',             '$argon2id$v=19$m=16384,t=2,p=1$Dbh9QDoCbk5sXcTCOMEN7g$whClh9dWJn7R3wJsa0zMmpWUhuY7K/cDTehxp55szro', 'STUDENT', 'Ana Oliveira',         '2002-03-20', 'Civil Engineering', 'aaaaaaaa-0000-0000-0000-000000000011', '37977777777', TRUE),
  ('aaaaaaaa-0000-0000-0000-000000000203', 'bruno@student.com',           '$argon2id$v=19$m=16384,t=2,p=1$Dbh9QDoCbk5sXcTCOMEN7g$whClh9dWJn7R3wJsa0zMmpWUhuY7K/cDTehxp55szro', 'STUDENT', 'Bruno Almeida',        '2001-02-10', 'Engenharia Civil',  'aaaaaaaa-0000-0000-0000-000000000012', '37990000001', TRUE),
  ('aaaaaaaa-0000-0000-0000-000000000204', 'carla@student.com',           '$argon2id$v=19$m=16384,t=2,p=1$Dbh9QDoCbk5sXcTCOMEN7g$whClh9dWJn7R3wJsa0zMmpWUhuY7K/cDTehxp55szro', 'STUDENT', 'Carla Souza',          '2002-06-22', 'Direito',           'aaaaaaaa-0000-0000-0000-000000000012', '37990000002', TRUE),
  ('aaaaaaaa-0000-0000-0000-000000000205', 'daniela@student.com',         '$argon2id$v=19$m=16384,t=2,p=1$Dbh9QDoCbk5sXcTCOMEN7g$whClh9dWJn7R3wJsa0zMmpWUhuY7K/cDTehxp55szro', 'STUDENT', 'Daniela Rocha',        '2000-11-05', 'Medicina',          'aaaaaaaa-0000-0000-0000-000000000012', '37990000003', TRUE),
  ('aaaaaaaa-0000-0000-0000-000000000206', 'eduardo@student.com',         '$argon2id$v=19$m=16384,t=2,p=1$Dbh9QDoCbk5sXcTCOMEN7g$whClh9dWJn7R3wJsa0zMmpWUhuY7K/cDTehxp55szro', 'STUDENT', 'Eduardo Lima',         '2001-09-14', 'Computacao',        'aaaaaaaa-0000-0000-0000-000000000011', '37990000004', TRUE),
  ('aaaaaaaa-0000-0000-0000-000000000207', 'fernanda@student.com',        '$argon2id$v=19$m=16384,t=2,p=1$Dbh9QDoCbk5sXcTCOMEN7g$whClh9dWJn7R3wJsa0zMmpWUhuY7K/cDTehxp55szro', 'STUDENT', 'Fernanda Costa',       '2003-03-30', 'Arquitetura',       'aaaaaaaa-0000-0000-0000-000000000011', '37990000005', TRUE),
  ('aaaaaaaa-0000-0000-0000-000000000208', 'gabriel@student.com',         '$argon2id$v=19$m=16384,t=2,p=1$Dbh9QDoCbk5sXcTCOMEN7g$whClh9dWJn7R3wJsa0zMmpWUhuY7K/cDTehxp55szro', 'STUDENT', 'Gabriel Martins',      '2002-01-18', 'Administracao',     'aaaaaaaa-0000-0000-0000-000000000011', '37990000006', TRUE),
  ('aaaaaaaa-0000-0000-0000-000000000209', 'helena@student.com',          '$argon2id$v=19$m=16384,t=2,p=1$Dbh9QDoCbk5sXcTCOMEN7g$whClh9dWJn7R3wJsa0zMmpWUhuY7K/cDTehxp55szro', 'STUDENT', 'Helena Dias',          '2000-07-27', 'Psicologia',        'aaaaaaaa-0000-0000-0000-000000000011', '37990000007', TRUE);

INSERT INTO user_institutions (user_id, institution_id)
SELECT id, institution_id FROM users WHERE institution_id IS NOT NULL;

INSERT INTO user_institutions (user_id, institution_id)
SELECT u.id, i.id
FROM users u
CROSS JOIN institutions i
WHERE u.role = 'ADMIN';

INSERT INTO route_members (user_id, route_id)
SELECT id, 'aaaaaaaa-0000-0000-0000-000000000001' FROM users WHERE role = 'STUDENT';

INSERT INTO daily_lists (id, route_id, date, status)
VALUES ('aaaaaaaa-0000-0000-0000-000000000301', 'aaaaaaaa-0000-0000-0000-000000000001', CURRENT_DATE, 'OPEN');

INSERT INTO list_entries (user_id, daily_list_id)
SELECT u.id, 'aaaaaaaa-0000-0000-0000-000000000301'
FROM users u
WHERE u.email IN (
  'vitor@student.com','ana@student.com','bruno@student.com',
  'carla@student.com','daniela@student.com','eduardo@student.com'
);

INSERT INTO daily_lists (id, route_id, date, status, closed_at)
VALUES ('aaaaaaaa-0000-0000-0000-000000000302', 'aaaaaaaa-0000-0000-0000-000000000001',
        CURRENT_DATE - 3, 'CLOSED', (CURRENT_DATE - 3 + TIME '16:00'));

INSERT INTO reports (daily_list_id, generated_at, total_entries, snapshot_data)
VALUES ('aaaaaaaa-0000-0000-0000-000000000302', (CURRENT_DATE - 3 + TIME '16:00'), 5,
  '[{"id":"seed-a","fullName":"Ana Oliveira","email":"ana@student.com","tripType":"ROUND_TRIP","addedByAdmin":"false"},{"id":"seed-b","fullName":"Bruno Almeida","email":"bruno@student.com","tripType":"ROUND_TRIP","addedByAdmin":"false"},{"id":"seed-c","fullName":"Carla Souza","email":"carla@student.com","tripType":"TO_CAMPUS","addedByAdmin":"false"},{"id":"seed-d","fullName":"Daniela Rocha","email":"daniela@student.com","tripType":"FROM_CAMPUS","addedByAdmin":"false"},{"id":"seed-e","fullName":"Eduardo Lima","email":"eduardo@student.com","tripType":"ROUND_TRIP","addedByAdmin":"true"}]');
