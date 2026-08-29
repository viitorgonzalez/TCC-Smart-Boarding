-- RN16: no fechamento o relatório precisa registrar qual transporte atende os
-- inscritos daquele dia. Sem isso a capacidade cadastrada não servia pra nada
-- além de exibição, e a decisão de veículo ficava fora do sistema.
ALTER TABLE reports
    ADD COLUMN proposed_vehicles TEXT,
    -- Frota insuficiente é resultado válido do algoritmo, não erro: o admin
    -- precisa ver que faltou lugar em vez de receber uma proposta silenciosa.
    ADD COLUMN capacity_shortfall INT NOT NULL DEFAULT 0;
