-- Ativar/desativar aluno deixa rastro: quem fez e quando. Sem isso, conta
-- desativada vira misterio -- ninguem sabe se foi engano ou decisao.
CREATE TABLE user_status_log (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    admin_id   UUID        REFERENCES users(id) ON DELETE SET NULL,
    action     VARCHAR(20) NOT NULL,
    created_at TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_status_log_user ON user_status_log(user_id);
