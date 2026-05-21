-- Hashes: Argon2id + pepper (m=19456, t=2, p=1)
-- pepper definido em auth.pepper (env var AUTH_PEPPER)
--
-- admin@smartboarding.com : sb@2026
-- vitor@student.com       : sb@2026@123
-- ana@student.com         : sb@2026

INSERT INTO users (email, password, role, full_name, birth_date, course, institution, phone, is_active)
VALUES
    ('admin@smartboarding.com',
     '$argon2id$v=16$m=19456,t=2,p=1$ol5txORrFd0J2FkPSBaPIbgcAB1SvfD7Rh8BqYa7VHlOS0faw29sbUf8f1MKqWMU3VUmQ8WUeOllL3+XvuJ6ag$YIZ8+etplBM3ltvvzQiq/sWMRGQPBBF7sg17RuBcHd8',
     'ADMIN', 'System Administrator', '1990-01-01', NULL, 'Smart Boarding Inc', '37999999999', TRUE),

    ('vitor@student.com',
     '$argon2id$v=16$m=19456,t=2,p=1$Od0S/lA6YvplDvxHe6yKD5GtYW2vl5xFEOkfHvIsYpj92r6eP+6Xd3PGKtNAtVSNCKj806OAfGXW1JxsrkN31w$cd92TfLolZibX9zSZPtr7nsWf5bpjtUqIKHMyO6tYZs',
     'STUDENT', 'Vítor Silva Pastor Gonzalez', '2000-05-15', 'Computer Science', 'UNIFOR-MG', '37988888888', TRUE),

    ('ana@student.com',
     '$argon2id$v=16$m=19456,t=2,p=1$pikZZhdiybU1pnSQUXSG/RQrzXRxdQiIYFOgQv7ErhVaZQR8iXydCxo3Wr8/unAzRHvffxNbu0KKNT+6VKGw/A$hmtso6rnBzCAIFG9mKLyHLXwCPflNBy3owjOVRPhWu0',
     'STUDENT', 'Ana Oliveira', '2002-03-20', 'Civil Engineering', 'UNIFOR-MG', '37977777777', TRUE);
