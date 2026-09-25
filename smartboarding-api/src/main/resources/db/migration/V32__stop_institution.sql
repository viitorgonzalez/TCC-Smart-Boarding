-- O vínculo parada↔instituição era adivinhado por comparação de nome, dentro
-- da V20. Adivinhar aqui tinha dois custos: renomear a parada desfazia o
-- vínculo em silêncio, e nada no código da aplicação sabia recriá-lo.
ALTER TABLE stops ADD COLUMN institution_id UUID REFERENCES institutions(id);

-- Popula com o MESMO LIKE que a V20 usou -- mas aqui ele roda uma vez, como
-- dado. Dali pra frente o vínculo é explícito e o admin o declara na tela.
UPDATE stops s SET institution_id = i.id
  FROM institutions i
 WHERE i.route_id = s.route_id
   AND s.name LIKE i.name || '%';

-- Toda parada que serve uma instituição é ponto principal (RN23).
UPDATE stops SET is_main_point = TRUE WHERE institution_id IS NOT NULL;

-- ⚠️ O que o LIKE errou continua errado, e de propósito: "Campus Unifor" não
-- casa com "UNIFOR-MG — Formiga", e adivinhar qual parada serve qual
-- instituição é exatamente o que esta migration existe pra parar de fazer.
-- O admin corrige na tela de paradas, onde agora há o campo.
