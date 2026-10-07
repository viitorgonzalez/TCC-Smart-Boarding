CREATE TABLE notifications (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title      VARCHAR(150) NOT NULL,
    body       TEXT NOT NULL,
    route_id   UUID REFERENCES routes(id) ON DELETE CASCADE,
    created_by UUID REFERENCES users(id),
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_notifications_route ON notifications(route_id);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);

CREATE TABLE scheduled_notifications (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id       UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    title          VARCHAR(150) NOT NULL,
    body           TEXT NOT NULL,
    frequency      VARCHAR(20) NOT NULL,
    send_at        TIME NOT NULL,
    day_of_week    INT,
    duration_hours INT,
    active         BOOLEAN NOT NULL DEFAULT TRUE,
    last_sent_at   TIMESTAMP,
    created_at     TIMESTAMP DEFAULT NOW(),
    updated_at     TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_scheduled_notifications_route ON scheduled_notifications(route_id);
