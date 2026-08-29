-- Aviso era só push: saía pelo FCM e desaparecia. Quem estava sem o app aberto,
-- sem token registrado ou trocou de aparelho nunca ficava sabendo, e não havia
-- onde consultar depois. Agora fica registrado e o aluno tem caixa de entrada.
CREATE TABLE notifications (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title      VARCHAR(150) NOT NULL,
    body       TEXT NOT NULL,
    -- Nulo = aviso geral. Preenchido = só quem pega aquela rota (spec §3.7).
    route_id   UUID REFERENCES routes(id) ON DELETE CASCADE,
    created_by UUID REFERENCES users(id),
    -- Nulo = sem prazo. O admin define quanto tempo o aviso continua valendo.
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_notifications_route ON notifications(route_id);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);
