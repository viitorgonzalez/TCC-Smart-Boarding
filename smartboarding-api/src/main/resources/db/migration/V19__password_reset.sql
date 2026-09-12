-- Recuperacao de senha (RN22). Tabela propria em vez de colunas em users: o dado
-- e efemero e nao pertence ao perfil. Codigo fica hasheado -- 6 digitos tem pouca
-- entropia, entao a defesa e validade curta + limite de tentativas + uso unico.
CREATE TABLE password_reset_requests (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code_hash   VARCHAR(255) NOT NULL,
    expires_at  TIMESTAMP    NOT NULL,
    attempts    INT          NOT NULL DEFAULT 0,
    used_at     TIMESTAMP,
    created_at  TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_password_reset_user ON password_reset_requests(user_id);
