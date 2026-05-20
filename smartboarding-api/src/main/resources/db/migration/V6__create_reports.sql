CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    daily_list_id UUID NOT NULL UNIQUE REFERENCES daily_lists(id),
    generated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    total_entries INT NOT NULL DEFAULT 0,
    snapshot_data TEXT
);
