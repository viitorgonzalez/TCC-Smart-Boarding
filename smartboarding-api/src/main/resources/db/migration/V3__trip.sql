CREATE TABLE trip_checkpoints (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    daily_list_id UUID        NOT NULL REFERENCES daily_lists(id) ON DELETE CASCADE,
    stop_id       UUID        NOT NULL REFERENCES stops(id) ON DELETE CASCADE,
    reached_at    TIMESTAMP   NOT NULL DEFAULT NOW(),
    leg           VARCHAR(10) NOT NULL DEFAULT 'OUTBOUND',
    CONSTRAINT trip_checkpoints_list_stop_leg_key
        UNIQUE (daily_list_id, stop_id, leg)
);

CREATE INDEX idx_trip_checkpoints_list ON trip_checkpoints(daily_list_id);
