-- A abertura era um cron fixo à meia-noite, igual pra todas as rotas, enquanto
-- o fechamento já era por rota (RN18). Agora as duas pontas são configuráveis
-- pelo admin, e a varredura abre pelo horário de cada rota.
ALTER TABLE routes
    ADD COLUMN open_time TIME NOT NULL DEFAULT '00:00:00';
