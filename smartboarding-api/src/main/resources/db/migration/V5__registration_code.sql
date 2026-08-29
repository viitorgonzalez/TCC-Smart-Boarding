-- Cadastro por convite passa a usar codigo de 6 digitos por e-mail em vez de
-- link (App Link exige dominio publicado+verificado, indisponivel ate o
-- deploy). O token de 64 chars continua existindo e sendo usado internamente
-- pelo submit -- so deixa de ser exposto na URL. Codigo fica hasheado
-- (nunca texto puro), validade curta (15min) e tentativas limitadas, dado
-- que 6 digitos tem muito menos entropia que o token original.
ALTER TABLE registration_requests
    ADD COLUMN code_hash VARCHAR(255),
    ADD COLUMN code_expires_at TIMESTAMP,
    ADD COLUMN code_attempts INT NOT NULL DEFAULT 0;
