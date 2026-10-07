# db/seed

Dado de demonstracao. **Nao e schema** — o schema mora em `db/migration`.

## Por que separado

As contas criadas aqui tem a senha publicada no proprio `.sql`. Se o seed
estivesse em `db/migration`, bastaria esquecer uma configuracao no deploy pra
producao subir com administradores de credencial conhecida. Separando os
diretorios, o default e seguro: quem quiser o seed precisa pedir por ele.

Quem carrega: `application-dev.properties` (`spring.flyway.locations` inclui
`classpath:db/seed`), ativado pelo `run-local.sh`. Producao resolve so
`db/migration`.

## Credenciais

Senha de todas as contas do seed: `sb@2026` (hash Argon2id+pepper compartilhado entre elas).
Excecao: `vitor@student.com` usa `sb@2026@123` (hash proprio). Os hashes gravados no `.sql` so
batem com o `PASSWORD_PEPPER` usado pra gera-los — pepper diferente faz o login do seed falhar.
Se o seu `PASSWORD_PEPPER` local for outro, use o fluxo de "esqueci minha senha" pra redefinir, ou
gere os hashes de novo com o seu pepper.

## Nao edite o `.sql` depois de aplicado

O Flyway guarda o checksum do **conteudo** de cada migration ja aplicada e
recusa o boot se ele mudar — inclusive por causa de comentario. Como este
arquivo ja rodou em bancos de desenvolvimento por ai, mexer nele quebra o
ambiente de quem ja o aplicou, com:

```
Migration checksum mismatch for migration version 2
```

Por isso esta explicacao esta aqui e nao no cabecalho do `.sql`.

Se precisar mudar o dado de demonstracao, prefira **adicionar** um arquivo novo
(`V<n>__...sql`) em vez de editar este. Se nao houver jeito, quem ja aplicou
roda `mvn flyway:repair` ou recria a base (`docker compose down -v`).

> Excecao registrada: este arquivo foi reescrito junto com a squash de
> `db/migration` (V1..V35 -> V1..V9), antes de existir qualquer banco
> compartilhado -- mesmo motivo que já valia pra squash do schema. Quem tinha
> banco local de antes precisa `docker compose down -v`.

## Se um banco de producao recusar o boot

O Flyway reclamando de migration aplicada que nao existe localmente
("applied migration not resolved locally") num ambiente prod e o
comportamento desejado, nao um obstaculo a contornar: significa que aquela base
carrega as contas de demonstracao e nao deveria virar producao.
