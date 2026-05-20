CREATE TABLE daily_lists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id UUID NOT NULL REFERENCES routes(id),
    date DATE NOT NULL,
    status VARCHAR(10) NOT NULL DEFAULT 'OPEN',
    closed_at TIMESTAMP,
    CONSTRAINT uq_route_date UNIQUE (route_id, date)
);
