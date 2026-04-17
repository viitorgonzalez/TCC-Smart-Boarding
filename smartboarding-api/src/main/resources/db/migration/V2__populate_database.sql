-- admin@smartboarding.com : sb@2026
-- vitor@student.com       : sb@2026@123
-- ana@student.com         : sb@2026

INSERT INTO users (email, password, role, full_name, birth_date, course, institution, phone, is_active)
VALUES
    ('admin@smartboarding.com', '$2b$10$Hot5nGjLXrPmP772N4HTI.tViB4GCk3n/YW8778YUVIM4vNGFd56e', 'ADMIN', 'System Administrator', '1990-01-01', NULL, 'Smart Boarding Inc', '37999999999', TRUE),
    ('vitor@student.com', '$2b$10$gO.uV8wE1xvKImI.IMVl5.tVdo4OJ6OAJf1qtZ2LlAxo0XXM8L6M6', 'STUDENT', 'Vítor Silva Pastor Gonzalez', '2000-05-15', 'Computer Science', 'UNIFOR-MG', '37988888888', TRUE),
    ('ana@student.com', '$2b$10$ms4D9e/PWi16v05AQzKE8OY7xra/JAi8zNeMvszN7Uaxa1ObMB.Ju', 'STUDENT', 'Ana Oliveira', '2002-03-20', 'Civil Engineering', 'UNIFOR-MG', '37977777777', TRUE);
