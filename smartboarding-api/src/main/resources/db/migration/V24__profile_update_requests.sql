-- O aluno edita o proprio perfil, mas a mudanca passa pelo admin: nome e
-- instituicao decidem em que lista ele aparece e em que contagem entra, entao
-- alterar sozinho abriria caminho pra entrar em transporte que nao e o dele.
--
-- Guarda os campos pedidos, nao um diff: o valor atual muda entre o pedido e a
-- aprovacao, e aplicar um diff velho sobrescreveria o que mudou no meio.
CREATE TABLE profile_update_requests (
    id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    full_name      VARCHAR(150),
    phone          VARCHAR(20),
    address        TEXT,
    course         VARCHAR(100),
    institution_id UUID        REFERENCES institutions(id) ON DELETE SET NULL,
    birth_date     DATE,
    status         VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    -- Preenchido na recusa: sem o motivo o aluno refaz o mesmo pedido.
    rejection_reason TEXT,
    reviewed_by    UUID        REFERENCES users(id) ON DELETE SET NULL,
    reviewed_at    TIMESTAMP,
    created_at     TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profile_update_user   ON profile_update_requests(user_id);
CREATE INDEX idx_profile_update_status ON profile_update_requests(status);

-- Um pedido pendente por aluno. Sem isso, tocar "enviar" duas vezes criaria
-- dois pedidos e o admin aprovaria o mais velho sem saber do outro.
CREATE UNIQUE INDEX idx_profile_update_one_pending
    ON profile_update_requests(user_id) WHERE status = 'PENDING';
