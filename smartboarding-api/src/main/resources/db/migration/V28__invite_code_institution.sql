-- O codigo de convite passa a poder exigir uma instituicao: o admin gera um
-- codigo "da UNIFOR" e so quem declarou a UNIFOR no perfil consegue usar.
--
-- Nulo continua significando "qualquer instituicao" -- e o que mantem validos
-- os codigos ja distribuidos e o que permite gerar um codigo aberto de
-- proposito, quando a rota atende mais de uma instituicao.
ALTER TABLE route_invite_codes
    ADD COLUMN institution_id UUID REFERENCES institutions(id) ON DELETE SET NULL;

-- Instituicao apagada nao pode invalidar codigo em circulacao sem aviso: o
-- ON DELETE SET NULL devolve o codigo ao estado aberto, que e recuperavel.
CREATE INDEX idx_route_invite_codes_institution
    ON route_invite_codes(institution_id);
