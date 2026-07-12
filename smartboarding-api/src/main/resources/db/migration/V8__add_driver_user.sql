-- Papel DRIVER (Gap 1). A coluna role é VARCHAR(20) sem CHECK — aceita o novo valor.
-- Usuário motorista semente:
-- motorista@smartboarding.com : sb@2026
-- (reutiliza o mesmo hash bcrypt do admin, que corresponde à senha sb@2026)

INSERT INTO users (email, password, role, full_name, birth_date, course, institution, phone, is_active)
VALUES
    ('motorista@smartboarding.com', '$2b$10$Hot5nGjLXrPmP772N4HTI.tViB4GCk3n/YW8778YUVIM4vNGFd56e', 'DRIVER', 'Carlos Motorista', '1985-08-10', NULL, 'Smart Boarding Inc', '37966666666', TRUE);
