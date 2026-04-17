CREATE TABLE users (
                       id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                       email       VARCHAR(100) NOT NULL UNIQUE,
                       password    VARCHAR(255) NOT NULL,
                       role        VARCHAR(20) NOT NULL,
                       full_name   VARCHAR(150) NOT NULL,
                       birth_date  DATE,
                       course      VARCHAR(100),
                       institution VARCHAR(100),
                       phone       VARCHAR(20),
                       address     TEXT,
                       expiry_date DATE,
                       is_active   BOOLEAN DEFAULT TRUE,
                       created_at  TIMESTAMP DEFAULT NOW(),
                       updated_at  TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
