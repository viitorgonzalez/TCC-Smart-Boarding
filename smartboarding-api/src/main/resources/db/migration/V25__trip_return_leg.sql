-- O trajeto passa a ter duas pernas: ida ate o destino final e volta pelo mesmo
-- caminho invertido. Marcar a ultima parada da ida vira a volta; marcar a
-- ultima da volta encerra o dia.

-- CRITICO: a mesma parada e visitada NAS DUAS pernas. Com UNIQUE(daily_list_id,
-- stop_id) o primeiro checkpoint da volta batia na constraint e o admin ficava
-- sem conseguir marcar chegada nenhuma no retorno.
ALTER TABLE trip_checkpoints
    ADD COLUMN leg VARCHAR(10) NOT NULL DEFAULT 'OUTBOUND';

ALTER TABLE trip_checkpoints
    DROP CONSTRAINT IF EXISTS trip_checkpoints_daily_list_id_stop_id_key;

ALTER TABLE trip_checkpoints
    ADD CONSTRAINT trip_checkpoints_list_stop_leg_key
        UNIQUE (daily_list_id, stop_id, leg);

-- Quando a ida terminou. Nulo = ainda na ida (ou nem comecou).
-- trip_finished_at segue marcando o fim do dia inteiro, agora o fim da VOLTA.
ALTER TABLE daily_lists
    ADD COLUMN outbound_finished_at TIMESTAMP;

-- Trajeto que ja estava encerrado antes desta migration so teve ida; marcar a
-- ida como encerrada junto evita que ele apareca como "volta em andamento".
UPDATE daily_lists
   SET outbound_finished_at = trip_finished_at
 WHERE trip_finished_at IS NOT NULL;
