-- Entrar com Google. A conta pode ter os DOIS caminhos: quem entrou pelo Google
-- define uma senha depois e passa a poder entrar das duas formas.
--
-- Nao ha coluna de "provedor": um enum forcaria escolher um so, e o requisito e
-- justamente acumular. O que a conta aceita e derivado -- tem google_id, entra
-- pelo Google; tem password, entra por senha.

ALTER TABLE users ADD COLUMN google_id VARCHAR(64);

-- Um Google por conta e uma conta por Google: sem isto, dois cadastros
-- poderiam apontar pro mesmo login social e o "entrar com Google" ficaria
-- ambiguo sobre em qual conta entrar.
CREATE UNIQUE INDEX idx_users_google_id ON users(google_id) WHERE google_id IS NOT NULL;

-- Conta criada pelo Google nao tem senha local ate o usuario definir uma.
-- Guardar hash de string vazia ou placeholder seria pior: viraria uma senha
-- real que alguem poderia adivinhar.
ALTER TABLE users ALTER COLUMN password DROP NOT NULL;
