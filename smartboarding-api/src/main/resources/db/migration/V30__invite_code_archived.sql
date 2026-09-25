-- Codigo arquivado: some da tela do admin sem apagar o registro.
--
-- Codigo expirado e cancelado se acumulam e viram ruido -- a lista fica cheia
-- de coisa morta e o admin perde de vista o que ainda vale. Mas apagar a linha
-- levaria junto a origem de quem entrou por ela (route_members.invite_code_id
-- vira NULL), e o relatorio deixaria de saber por onde cada aluno chegou.
--
-- Arquivar resolve os dois: a tela limpa, o historico intacto.
ALTER TABLE route_invite_codes
    ADD COLUMN archived_at TIMESTAMP;

-- A listagem filtra por isto em toda consulta.
CREATE INDEX idx_route_invite_codes_archived
    ON route_invite_codes(route_id, archived_at);
