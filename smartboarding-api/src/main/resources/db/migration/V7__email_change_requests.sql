CREATE TABLE email_change_requests (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    new_email  VARCHAR(100) NOT NULL,
    code_hash  VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    attempts   INT NOT NULL DEFAULT 0,
    used_at    TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_email_change_requests_user ON email_change_requests(user_id);
