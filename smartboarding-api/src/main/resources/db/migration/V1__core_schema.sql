CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(100) NOT NULL UNIQUE,
    password        VARCHAR(255),
    role            VARCHAR(20)  NOT NULL,
    full_name       VARCHAR(150) NOT NULL,
    birth_date      DATE,
    course          VARCHAR(100),
    phone           VARCHAR(20),
    address_legacy  TEXT,
    zip_code        VARCHAR(9),
    street          VARCHAR(150),
    neighborhood    VARCHAR(100),
    city            VARCHAR(100),
    state           VARCHAR(2),
    street_number   VARCHAR(20),
    complement      VARCHAR(100),
    expiry_date     DATE,
    is_active       BOOLEAN   DEFAULT TRUE,
    institution_id  UUID,
    google_id       VARCHAR(64),
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_institution ON users(institution_id);
CREATE UNIQUE INDEX idx_users_google_id ON users(google_id) WHERE google_id IS NOT NULL;

CREATE TABLE routes (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                   VARCHAR(100) NOT NULL,
    description            VARCHAR(255),
    is_active              BOOLEAN   NOT NULL DEFAULT TRUE,
    open_time              TIME      NOT NULL DEFAULT '00:00:00',
    close_time             TIME      NOT NULL DEFAULT '16:00:00',
    admits_no_institution  BOOLEAN   NOT NULL DEFAULT FALSE,
    created_at             TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE institutions (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name       VARCHAR(150) NOT NULL,
    address    VARCHAR(255),
    latitude   DOUBLE PRECISION,
    longitude  DOUBLE PRECISION,
    route_id   UUID REFERENCES routes(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_institutions_route ON institutions(route_id);

ALTER TABLE users ADD CONSTRAINT users_institution_id_fkey
    FOREIGN KEY (institution_id) REFERENCES institutions(id);

CREATE TABLE vehicles (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id   UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    label      VARCHAR(100) NOT NULL,
    capacity   INT NOT NULL CHECK (capacity > 0),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_vehicles_route ON vehicles(route_id);

CREATE TABLE stops (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id                UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    name                    VARCHAR(150) NOT NULL,
    latitude                DOUBLE PRECISION,
    longitude               DOUBLE PRECISION,
    sequence                INT NOT NULL,
    is_main_point           BOOLEAN NOT NULL DEFAULT FALSE,
    institution_id          UUID REFERENCES institutions(id),
    avg_minutes_from_start  INTEGER,
    created_at              TIMESTAMP DEFAULT NOW(),
    updated_at              TIMESTAMP DEFAULT NOW(),
    CONSTRAINT stops_route_id_sequence_key
        UNIQUE (route_id, sequence) DEFERRABLE INITIALLY DEFERRED
);

CREATE INDEX idx_stops_route ON stops(route_id);

CREATE TABLE route_invite_codes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id        UUID        NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    code            VARCHAR(16) NOT NULL UNIQUE,
    expires_at      TIMESTAMP   NOT NULL,
    revoked_at      TIMESTAMP,
    institution_id  UUID        REFERENCES institutions(id) ON DELETE SET NULL,
    archived_at     TIMESTAMP,
    created_by      UUID        REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_route_invite_codes_route ON route_invite_codes(route_id);
CREATE INDEX idx_route_invite_codes_institution ON route_invite_codes(institution_id);
CREATE INDEX idx_route_invite_codes_archived ON route_invite_codes(route_id, archived_at);

CREATE TABLE route_members (
    id             UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    route_id       UUID      NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    invite_code_id UUID      REFERENCES route_invite_codes(id) ON DELETE SET NULL,
    joined_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, route_id)
);

CREATE INDEX idx_route_members_user  ON route_members(user_id);
CREATE INDEX idx_route_members_route ON route_members(route_id);

CREATE TABLE user_institutions (
    id             UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    institution_id UUID      NOT NULL REFERENCES institutions(id) ON DELETE CASCADE,
    created_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, institution_id)
);

CREATE INDEX idx_user_institutions_user        ON user_institutions(user_id);
CREATE INDEX idx_user_institutions_institution ON user_institutions(institution_id);

CREATE TABLE daily_lists (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id               UUID NOT NULL REFERENCES routes(id),
    date                   DATE NOT NULL,
    status                 VARCHAR(10) NOT NULL DEFAULT 'OPEN',
    closed_at              TIMESTAMP,
    manual_override        BOOLEAN NOT NULL DEFAULT FALSE,
    trip_started_at        TIMESTAMP,
    outbound_finished_at   TIMESTAMP,
    trip_finished_at       TIMESTAMP,
    CONSTRAINT uq_route_date UNIQUE (route_id, date)
);

CREATE TABLE list_entries (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id),
    daily_list_id   UUID NOT NULL REFERENCES daily_lists(id),
    created_at      TIMESTAMP   NOT NULL DEFAULT NOW(),
    is_active       BOOLEAN     NOT NULL DEFAULT TRUE,
    trip_type       VARCHAR(20) NOT NULL DEFAULT 'ROUND_TRIP',
    added_by_admin  BOOLEAN     NOT NULL DEFAULT FALSE,
    CONSTRAINT uq_user_list UNIQUE (user_id, daily_list_id)
);

CREATE TABLE reports (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    daily_list_id        UUID NOT NULL UNIQUE REFERENCES daily_lists(id),
    generated_at         TIMESTAMP NOT NULL DEFAULT NOW(),
    total_entries        INT       NOT NULL DEFAULT 0,
    snapshot_data        TEXT,
    proposed_vehicles    TEXT,
    capacity_shortfall   INT       NOT NULL DEFAULT 0
);

CREATE TABLE device_tokens (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users(id),
    token      VARCHAR(500) NOT NULL UNIQUE,
    platform   VARCHAR(10)  NOT NULL,
    created_at TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_device_tokens_user ON device_tokens(user_id);
