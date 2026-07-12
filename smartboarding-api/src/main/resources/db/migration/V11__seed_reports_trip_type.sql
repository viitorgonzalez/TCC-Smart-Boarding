-- Os relatórios semente (V9) foram criados antes da direção (trip_type) existir,
-- então o snapshot não tinha essa informação. Atualiza para incluir a direção,
-- de modo que os totais de ida/volta apareçam no relatório.

UPDATE reports SET snapshot_data =
  '[{"id":"seed-a","fullName":"Ana Oliveira","email":"ana@student.com","tripType":"ROUND_TRIP"},{"id":"seed-b","fullName":"Bruno Almeida","email":"bruno@student.com","tripType":"ROUND_TRIP"},{"id":"seed-c","fullName":"Carla Souza","email":"carla@student.com","tripType":"TO_CAMPUS"},{"id":"seed-d","fullName":"Daniela Rocha","email":"daniela@student.com","tripType":"FROM_CAMPUS"},{"id":"seed-e","fullName":"Eduardo Lima","email":"eduardo@student.com","tripType":"ROUND_TRIP"}]'
WHERE daily_list_id IN (
  SELECT dl.id FROM daily_lists dl JOIN routes r ON r.id = dl.route_id
  WHERE r.name = 'Rota Rodoviaria - Campus' AND dl.status = 'CLOSED'
);

UPDATE reports SET snapshot_data =
  '[{"id":"seed-f","fullName":"Fernanda Costa","email":"fernanda@student.com","tripType":"ROUND_TRIP"},{"id":"seed-g","fullName":"Gabriel Martins","email":"gabriel@student.com","tripType":"TO_CAMPUS"},{"id":"seed-h","fullName":"Helena Dias","email":"helena@student.com","tripType":"FROM_CAMPUS"}]'
WHERE daily_list_id IN (
  SELECT dl.id FROM daily_lists dl JOIN routes r ON r.id = dl.route_id
  WHERE r.name = 'Rota Bairro Norte' AND dl.status = 'CLOSED'
);
