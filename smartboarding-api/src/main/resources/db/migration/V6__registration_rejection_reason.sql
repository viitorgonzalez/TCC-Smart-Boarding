-- Negar um cadastro sem dizer o porquê deixa o aluno sem saber o que corrigir,
-- e o reenvio (RN14) vira tentativa às cegas. O motivo é escrito pelo admin na
-- negação e viaja no e-mail de aviso + na tela de cadastro quando o aluno volta.
ALTER TABLE registration_requests
    ADD COLUMN rejection_reason TEXT;
