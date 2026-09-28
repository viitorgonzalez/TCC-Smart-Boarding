-- Tempo médio do início do trajeto até esta parada, já somando o embarque.
--
-- Por parada, e não por rota: o tempo que o aluno vê termina na instituição
-- DELE. A média do trajeto inteiro, mostrada pra quem desce na terceira de
-- sete paradas, seria um número que não é sobre a viagem dele.
--
-- Nulo é "não sei" -- o OSRM público não tem SLA, e a tela omite em vez de
-- mostrar um número inventado.
ALTER TABLE stops ADD COLUMN avg_minutes_from_start INTEGER;
