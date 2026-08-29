-- Sem isto a varredura de 5 min desfaz o que o admin fez na mão: reabrir uma
-- lista depois do close_time durava até o próximo tique.
ALTER TABLE daily_lists
    ADD COLUMN manual_override BOOLEAN NOT NULL DEFAULT FALSE;
