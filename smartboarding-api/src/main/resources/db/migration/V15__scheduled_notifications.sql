-- Avisos que se repetem (saída do ônibus, lembrete de entrar na lista) eram
-- digitados à mão todo dia. Aqui o admin configura uma vez e a varredura
-- dispara, reusando a publicação normal — então cai na caixa de entrada e no
-- push como qualquer outro aviso.
CREATE TABLE scheduled_notifications (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id       UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    title          VARCHAR(150) NOT NULL,
    body           TEXT NOT NULL,
    -- DAILY | WEEKDAYS | WEEKLY
    frequency      VARCHAR(20) NOT NULL,
    -- A varredura roda a cada 5 min, então o envio sai no primeiro tique após
    -- este horário.
    send_at        TIME NOT NULL,
    -- Só para WEEKLY: 1=segunda ... 7=domingo (java.time.DayOfWeek).
    day_of_week    INT,
    -- Validade do aviso gerado, em horas. Nulo = sem prazo.
    duration_hours INT,
    active         BOOLEAN NOT NULL DEFAULT TRUE,
    -- Último disparo, pra não repetir no mesmo dia.
    last_sent_at   TIMESTAMP,
    created_at     TIMESTAMP DEFAULT NOW(),
    updated_at     TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_scheduled_notifications_route ON scheduled_notifications(route_id);
