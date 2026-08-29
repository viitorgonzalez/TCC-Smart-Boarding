# Testes (unit/integration/e2e) e cobertura — design

> **Status: aprovado, aguardando plano de implementação.**
> Data: 2026-08-15 · Origem: sessão de validação/fechamento da PR #4

## 1. Problema

`docs/CONVENTIONS.md` §8 (harness) já pede delta de cobertura por tipo no corpo de todo PR, e
o `/pr-description` já sabe descobrir o comando de coverage lendo o `CLAUDE.md` do repo — mas
nenhum dos dois apps do TCC tem esse comando pra descobrir. A API só tem um teste de contexto
inteiro (`SmartboardingApiApplicationTests`, `@SpringBootTest`) acoplado ao Postgres que o CI
sobe manualmente em `:5433`; o app tem 2 testes unitários (`mocktail`) e nenhum e2e.

Faltam três coisas concretas: ferramenta de teste de integração pra API (algo que não dependa
do CI subir Postgres na mão), escopo e ferramenta de e2e do app, e ferramenta+convenção de
cobertura nos dois lados.

## 2. Escopo

Montar o pipeline (dependências, camadas, CI, convenções) e converter o teste de contexto
existente pra provar que funciona ponta a ponta. **Não é** reescrever suíte de teste completa
pra cada tela/endpoint hoje — mesmo raciocínio do gate de 300 linhas: ratchet, não sweep
retroativo.

## 3. Decisões

| Decisão | Escolha | Motivo |
|---|---|---|
| Integração API — banco de teste | Testcontainers (`postgresql` module) | Container efêmero gerenciado pelo próprio teste (`@DynamicPropertySource`), igual local e CI, sem exigir Postgres de pé antes. Runners do GitHub Actions já têm Docker disponível. |
| Separação unit/integration na API | Maven Failsafe, convenção `*IT.java` | `mvn test` (Surefire, `*Test.java`) continua rápido e sem Docker; `mvn verify` (Failsafe, `*IT.java`) roda os que precisam de container. Padrão de mercado, zero config além do plugin. |
| Escopo do e2e | UI real via `integration_test`, só login + primeiro formulário do aluno (entrar na lista do dia) | Prova o pipeline completo (emulador + API + banco) antes de expandir. Fluxo de admin/trajeto/relatório fica pra rodada seguinte. |
| E2E no CI | Fora do caminho bloqueante do PR — `workflow_dispatch` + agendado, workflow separado | Emulador Android soma ~3-8min + risco de flakiness; não vale pagar isso em todo push de PR ainda. Mesmo raciocínio do `dart format` que nasceu não-bloqueante. |
| Cobertura — enforcement | Informativo no PR, sem threshold bloqueante | Bloquear por cobertura exige parsear relatório por arquivo tocado e comparar com a base — escopo de uma PR futura, depois que a baseline existir. |
| Cobertura — ferramenta | JaCoCo (API) / `flutter test --coverage` → lcov (app) | Padrão de cada stack, sem dependência nova além do plugin Maven. |
| Onde documentar o comando de coverage | `CLAUDE.md` de cada app | `/pr-description` (harness) já foi atualizado pra descobrir o comando lendo o `CLAUDE.md` do repo-alvo em vez de assumir — fecha esse contrato. |

## 4. Arquitetura

### 4.1 API (`smartboarding-api/`)

- **Unit** (já existe, sem mudança): JUnit 5 + Mockito, sem contexto Spring — padrão de
  `ResendEmailAdapterTest`/`R2StorageAdapterTest`. Roda em `mvn test`.
- **Integration**: novo `maven-failsafe-plugin` + deps de teste `testcontainers`,
  `testcontainers-junit-jupiter`, `testcontainers-postgresql`. `SmartboardingApiApplicationTests`
  migra pra `SmartboardingApiApplicationIT` (pacote raiz), sobe Postgres via
  `@Container static PostgreSQLContainer<>` e registra a URL via `@DynamicPropertySource` —
  deixa de depender do `:5433` fixo que hoje só existe pro ambiente de CI/dev. Roda em
  `mvn verify`.
- **Cobertura**: `jacoco-maven-plugin`, `prepare-agent` + `report` no phase `test` (cobertura
  unit). Relatório em `target/site/jacoco/`.
- **Efeito colateral no CI**: o step atual de `docker run postgres` + espera de `pg_isready` no
  job `api` do `ci.yml` deixa de ser necessário pro `mvn verify` — Testcontainers cuida do
  próprio ciclo de vida do container. `JWT_SECRET` continua gerado via `openssl rand` (não é
  concern de banco, é config de boot da app).

### 4.2 App (`smartboarding_app/`)

- **Unit** (já existe, sem mudança): `flutter_test` + `mocktail` — padrão de
  `user_provider_test.dart`. Roda em `flutter test`.
- Não há camada de "integração com banco" separada no app — ele não fala com o banco direto.
  Isso cai inteiramente no e2e.
- **E2E**: pacote `integration_test` (SDK do Flutter, adicionar em `dev_dependencies`). Primeiro
  arquivo: `integration_test/auth_e_lista_test.dart`, cobrindo:
  1. Login com credencial válida (semente `vitor@student.com` / `sb@2026@123`) → chega na home
     do aluno.
  2. Login com credencial inválida → mensagem de erro, sem navegar.
  3. Aluno entra na lista do dia (escolhe direção no bottom sheet) → item aparece como inscrito.
  - Roda contra API real: `flutter test integration_test/ --dart-define=API_BASE_URL=http://10.0.2.2:8080`
    (`10.0.2.2` é o alias do host no emulador Android).
- **Cobertura**: `flutter test --coverage` (só `test/`, não `integration_test/`) → `coverage/lcov.info`.

### 4.3 CI

- **`ci.yml`** (bloqueante em todo PR/push):
  - Job `api`: troca o step manual de Postgres por `./mvnw -B --no-transfer-progress verify`
    (roda unit + integration); adiciona step que imprime o resumo do JaCoCo no
    `$GITHUB_STEP_SUMMARY`. Quality gate de 300 linhas inalterado.
  - Job `app`: troca `flutter test` por `flutter test --coverage`; adiciona step que calcula e
    imprime o % do `lcov.info` no `$GITHUB_STEP_SUMMARY`. `dart format`/`analyze`/quality gate
    de 300 linhas inalterados.
- **`e2e.yml`** (novo, não-bloqueante): `workflow_dispatch` + `schedule` (nightly). Sobe Postgres
  efêmero (mesmo padrão de credencial gerada em runtime do job `api` hoje), builda e roda o jar
  da API em background, aguarda ficar pronto, sobe emulador Android via
  `reactivecircus/android-emulator-runner`, roda `flutter test integration_test/`.

### 4.4 Documentação

- `smartboarding-api/CLAUDE.md`: adiciona `./mvnw verify` (integration) e o comando de cobertura
  (`./mvnw test` + caminho do relatório JaCoCo) na seção de comandos.
- `smartboarding_app/CLAUDE.md` (ou o `CLAUDE.md` raiz, onde já vive o mapa das duas apps):
  adiciona `flutter test --coverage` e o comando do e2e (`flutter test integration_test/`).

## 5. Critérios de aceite

- [ ] `mvn test` continua rápido, sem Docker, só roda `*Test.java`.
- [ ] `mvn verify` sobe Testcontainers e roda `SmartboardingApiApplicationIT` com sucesso, local
      e no CI.
- [ ] `ci.yml` job `api` não tem mais o step manual de `docker run postgres` pro job de teste.
- [ ] `flutter test --coverage` gera `coverage/lcov.info` e o CI imprime o % no job summary.
- [ ] `mvn test` gera relatório JaCoCo e o CI imprime o % no job summary.
- [ ] Nenhum dos dois é bloqueante — falha de leitura/parse do relatório não derruba o job.
- [ ] `integration_test/auth_e_lista_test.dart` passa localmente contra API+Postgres reais.
- [ ] `e2e.yml` roda via `workflow_dispatch` e via agendamento, não dispara em `pull_request`.
- [ ] `CLAUDE.md` da API e do app documentam os comandos novos.

## 6. Fora de escopo

- Cobertura como gate bloqueante (PR futura, quando existir baseline pra comparar).
- E2E cobrindo fluxo de admin/trajeto/relatório.
- E2E em iOS (custo de runner macOS).
- Merge de cobertura unit+integration num relatório só (JaCoCo `merge` goal).
- Escrever testes novos pra cobertura ampla de telas/endpoints existentes — só o necessário pra
  provar cada camada nova.
