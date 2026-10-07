CREATE TABLE profile_update_requests (
    id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    full_name         VARCHAR(150),
    phone             VARCHAR(20),
    address           TEXT,
    course            VARCHAR(100),
    institution_id    UUID        REFERENCES institutions(id) ON DELETE SET NULL,
    birth_date        DATE,
    zip_code          VARCHAR(9),
    street            VARCHAR(150),
    neighborhood      VARCHAR(100),
    city              VARCHAR(100),
    state             VARCHAR(2),
    street_number     VARCHAR(20),
    complement        VARCHAR(100),
    status            VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    rejection_reason  TEXT,
    reviewed_by       UUID        REFERENCES users(id) ON DELETE SET NULL,
    reviewed_at       TIMESTAMP,
    created_at        TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profile_update_user   ON profile_update_requests(user_id);
CREATE INDEX idx_profile_update_status ON profile_update_requests(status);

CREATE UNIQUE INDEX idx_profile_update_one_pending
    ON profile_update_requests(user_id) WHERE status = 'PENDING';
