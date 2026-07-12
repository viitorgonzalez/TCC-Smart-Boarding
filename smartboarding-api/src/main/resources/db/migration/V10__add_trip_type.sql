-- Direção do transporte por inscrição (ida e volta / só ida / só volta).
-- Inscrições existentes assumem ida e volta.
ALTER TABLE list_entries
    ADD COLUMN trip_type VARCHAR(20) NOT NULL DEFAULT 'ROUND_TRIP';
