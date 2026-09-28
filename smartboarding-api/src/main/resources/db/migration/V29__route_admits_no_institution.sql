-- A rota passa a decidir se aceita aluno SEM instituicao declarada.
--
-- Ate aqui o perfil incompleto era barreira absoluta: sem instituicao, ninguem
-- entrava em rota nenhuma. A instituicao e o que diz onde o aluno desce e em
-- que contagem ele entra, entao a barreira existe por um motivo -- mas ha rota
-- que atende quem nao se encaixa em instituicao alguma, e isso nao cabia.
--
-- Nasce FALSE: abrir a porta e decisao consciente do admin daquela rota, nao
-- estado padrao de quem criou a rota sem pensar nisso.
ALTER TABLE routes
    ADD COLUMN admits_no_institution BOOLEAN NOT NULL DEFAULT FALSE;
