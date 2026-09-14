-- O cadastro por convite saiu: o aluno cria a propria conta e o convite virou
-- codigo de ROTA (V22). A tabela guardava o fluxo antigo -- convite por e-mail,
-- codigo de verificacao e fila de aprovacao -- e nada mais le dela.
--
-- Os alunos aprovados por esse fluxo ja estao em `users`, e o vinculo com a
-- rota foi carregado pra `route_members` na V22. Nenhum dado vivo depende daqui.
DROP TABLE IF EXISTS registration_requests;
