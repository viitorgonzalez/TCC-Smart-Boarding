-- O convite deixa de ser o portao pra CRIAR CONTA e vira a chave pra ENTRAR
-- NUMA ROTA (modelo Classroom). Ate aqui a rota do aluno era derivada:
-- users.institution_id -> institutions.route_id. Agora ela e concedida, e o
-- aluno pode estar em mais de uma.

CREATE TABLE route_invite_codes (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id   UUID        NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    code       VARCHAR(16) NOT NULL UNIQUE,
    expires_at TIMESTAMP   NOT NULL,
    -- Preenchido revoga na hora, sem esperar a expiracao.
    revoked_at TIMESTAMP,
    created_by UUID        REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_route_invite_codes_route ON route_invite_codes(route_id);

CREATE TABLE route_members (
    id             UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    route_id       UUID      NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    -- Nulo = vinculo que nao veio de codigo: a migracao abaixo, ou o admin
    -- adicionando a mao. Guardar a origem e o que permite contar quantos
    -- alunos entraram por cada codigo.
    invite_code_id UUID      REFERENCES route_invite_codes(id) ON DELETE SET NULL,
    joined_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    -- Entrar duas vezes na mesma rota nao faz sentido e duplicaria o aluno em
    -- toda contagem da lista.
    UNIQUE (user_id, route_id)
);

CREATE INDEX idx_route_members_user  ON route_members(user_id);
CREATE INDEX idx_route_members_route ON route_members(route_id);

-- CRITICO: carrega o vinculo que hoje existe so como derivacao. Sem este passo
-- todo aluno ja cadastrado perde a rota no deploy, e nao ha outro lugar de onde
-- reconstruir quem estava em qual rota.
INSERT INTO route_members (user_id, route_id, joined_at)
SELECT u.id, i.route_id, COALESCE(u.created_at, NOW())
  FROM users u
  JOIN institutions i ON i.id = u.institution_id
 WHERE u.role = 'STUDENT'
   AND i.route_id IS NOT NULL
ON CONFLICT (user_id, route_id) DO NOTHING;
