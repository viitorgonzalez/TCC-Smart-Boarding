-- O aluno pode estudar em mais de uma instituicao. Ate aqui users.institution_id
-- guardava uma so, o que obrigava quem faz dois cursos a escolher qual declarar.

CREATE TABLE user_institutions (
    id             UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    institution_id UUID      NOT NULL REFERENCES institutions(id) ON DELETE CASCADE,
    created_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    -- Declarar a mesma instituicao duas vezes duplicaria o aluno em toda
    -- contagem por instituicao da lista.
    UNIQUE (user_id, institution_id)
);

CREATE INDEX idx_user_institutions_user        ON user_institutions(user_id);
CREATE INDEX idx_user_institutions_institution ON user_institutions(institution_id);

-- CRITICO: carrega o vinculo unico que ja existe. Sem isto, todo aluno cadastrado
-- perde a instituicao no deploy e some da contagem por instituicao da lista.
INSERT INTO user_institutions (user_id, institution_id)
SELECT id, institution_id
  FROM users
 WHERE institution_id IS NOT NULL
ON CONFLICT (user_id, institution_id) DO NOTHING;

-- users.institution_id fica como esta por enquanto: dropar agora exigiria mexer
-- em tudo que le o campo no mesmo commit. A V26 so passa a ser a fonte da
-- verdade; a coluna sai depois que nada mais a ler.
