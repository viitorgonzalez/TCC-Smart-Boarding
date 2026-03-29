CREATE TYPE perfil_usuario AS ENUM ('ALUNO', 'ADM');

CREATE TABLE usuario (
                         id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                         nome          VARCHAR(255) NOT NULL,
                         email         VARCHAR(255) NOT NULL UNIQUE,
                         senha_hash    VARCHAR(255) NOT NULL,
                         perfil        perfil_usuario NOT NULL,
                         ativo         BOOLEAN DEFAULT TRUE,
                         criado_em     TIMESTAMP DEFAULT NOW(),
                         atualizado_em TIMESTAMP DEFAULT NOW()
);

CREATE TABLE dados_aluno (
                             usuario_id    UUID PRIMARY KEY REFERENCES usuario(id) ON DELETE CASCADE,
                             curso         VARCHAR(255) NOT NULL,
                             instituicao   VARCHAR(255) NOT NULL,
                             celular       VARCHAR(20) NOT NULL,
                             endereco      VARCHAR(500) NOT NULL,
                             data_inicio   DATE NOT NULL,
                             data_validade DATE NOT NULL
);

CREATE INDEX idx_usuario_email ON usuario(email);
CREATE INDEX idx_aluno_validade ON dados_aluno(data_validade);