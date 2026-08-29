-- Fechamento é por rota, não global (spec §3.5 / RN18): cada rota tem seu
-- próprio horário, editável pelo admin. Antes disso o único fechamento era um
-- cron fixo das 16h, que só valia se a API estivesse no ar naquele instante.
ALTER TABLE routes
    ADD COLUMN close_time TIME NOT NULL DEFAULT '16:00:00';
