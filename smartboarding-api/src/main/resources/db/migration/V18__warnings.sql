-- Advertência ao aluno que não se inscreveu no horário e precisou do admin.
-- Emitir é escolha do admin: nem toda inclusão tardia é falta do aluno.
CREATE TABLE warnings (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    daily_list_id UUID REFERENCES daily_lists(id) ON DELETE SET NULL,
    reason        TEXT NOT NULL,
    issued_by     UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_warnings_user ON warnings(user_id);
