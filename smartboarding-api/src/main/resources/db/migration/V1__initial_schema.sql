-- Schema inicial consolidado.
--
-- Substitui as antigas V1..V11 (schema + seed espalhados em 11 arquivos), que
-- foram achatadas antes de existir qualquer ambiente publicado. Daqui pra
-- frente, mudança de schema é migration NOVA (V3+) — nunca edição desta.
--
-- Só DDL. Dado semente vive no V2__seed_data.sql.

-- role: ADMIN | STUDENT | DRIVER (VARCHAR sem CHECK — validado na aplicacao)
CREATE TABLE users (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email       VARCHAR(100) NOT NULL UNIQUE,
    password    VARCHAR(255) NOT NULL,
    role        VARCHAR(20)  NOT NULL,
    full_name   VARCHAR(150) NOT NULL,
    birth_date  DATE,
    course      VARCHAR(100),
    institution VARCHAR(100),
    phone       VARCHAR(20),
    address     TEXT,
    expiry_date DATE,
    is_active   BOOLEAN   DEFAULT TRUE,
    created_at  TIMESTAMP DEFAULT NOW(),
    updated_at  TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);

CREATE TABLE routes (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    is_active   BOOLEAN   NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

-- status: OPEN | CLOSED
CREATE TABLE daily_lists (
    id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id  UUID NOT NULL REFERENCES routes(id),
    date      DATE NOT NULL,
    status    VARCHAR(10) NOT NULL DEFAULT 'OPEN',
    closed_at TIMESTAMP,
    CONSTRAINT uq_route_date UNIQUE (route_id, date)
);

-- trip_type: ROUND_TRIP | TO_CAMPUS | FROM_CAMPUS
-- Saida da lista e soft-delete (is_active = FALSE), nunca DELETE.
CREATE TABLE list_entries (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(id),
    daily_list_id UUID NOT NULL REFERENCES daily_lists(id),
    created_at    TIMESTAMP   NOT NULL DEFAULT NOW(),
    is_active     BOOLEAN     NOT NULL DEFAULT TRUE,
    trip_type     VARCHAR(20) NOT NULL DEFAULT 'ROUND_TRIP',
    CONSTRAINT uq_user_list UNIQUE (user_id, daily_list_id)
);

-- snapshot_data: array JSON dos inscritos no momento do fechamento.
CREATE TABLE reports (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    daily_list_id UUID NOT NULL UNIQUE REFERENCES daily_lists(id),
    generated_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    total_entries INT       NOT NULL DEFAULT 0,
    snapshot_data TEXT
);

-- platform: ANDROID | IOS | WEB
CREATE TABLE device_tokens (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users(id),
    token      VARCHAR(500) NOT NULL UNIQUE,
    platform   VARCHAR(10)  NOT NULL,
    created_at TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_device_tokens_user ON device_tokens(user_id);
