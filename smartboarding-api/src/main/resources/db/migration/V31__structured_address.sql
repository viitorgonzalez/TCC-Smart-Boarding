-- O endereço deixa de ser texto livre: é dele que sai o ponto de embarque do
-- aluno, e "rua tal, perto do mercado" não vira parada nenhuma. O CEP preenche
-- quase tudo, e sobra o número pro aluno digitar.
ALTER TABLE users
    ADD COLUMN zip_code      VARCHAR(9),
    ADD COLUMN street        VARCHAR(150),
    ADD COLUMN neighborhood  VARCHAR(100),
    ADD COLUMN city          VARCHAR(100),
    ADD COLUMN state         VARCHAR(2),
    ADD COLUMN street_number VARCHAR(20),
    ADD COLUMN complement    VARCHAR(100);

-- O texto antigo fica guardado em vez de ser quebrado nos campos novos: dele
-- não dá pra separar rua de número com segurança, e um chute aqui produz
-- endereço errado com cara de certo -- que é o motorista parando no lugar
-- errado. Quem já tinha endereço preenche de novo, uma vez.
ALTER TABLE users RENAME COLUMN address TO address_legacy;
