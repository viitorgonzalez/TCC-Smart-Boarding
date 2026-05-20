CREATE TABLE list_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    daily_list_id UUID NOT NULL REFERENCES daily_lists(id),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_user_list UNIQUE (user_id, daily_list_id)
);
