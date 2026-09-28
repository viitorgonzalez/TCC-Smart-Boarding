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

## Se um banco de producao recusar o boot

O Flyway reclamando de migration aplicada que nao existe localmente
("applied migration not resolved locally") num ambiente prod e o
comportamento desejado, nao um obstaculo a contornar: significa que aquela base
carrega as contas de demonstracao e nao deveria virar producao.
