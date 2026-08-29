-- Cadastro por convite (RN13/RN14) precisa de instituição real pro dropdown
-- (User.institution era só string solta) e de um lugar pra guardar o pedido
-- pendente sem virar conta antes da aprovação.
CREATE TABLE institutions (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name       VARCHAR(150) NOT NULL,
    address    VARCHAR(255),
    latitude   DOUBLE PRECISION,
    longitude  DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE registration_requests (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email             VARCHAR(100) NOT NULL,
    token             VARCHAR(64)  NOT NULL UNIQUE,
    token_expires_at  TIMESTAMP    NOT NULL,
    status            VARCHAR(20)  NOT NULL DEFAULT 'INVITED',
    full_name         VARCHAR(150),
    password_hash     VARCHAR(255),
    institution_id    UUID REFERENCES institutions(id),
    course            VARCHAR(100),
    phone             VARCHAR(20),
    address           TEXT,
    birth_date        DATE,
    created_at        TIMESTAMP DEFAULT NOW(),
    updated_at        TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_registration_requests_token ON registration_requests(token);
CREATE INDEX idx_registration_requests_status ON registration_requests(status);
