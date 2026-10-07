# CLAUDE.md — `TCC-Smart-Boarding`

Sistema de gestão de embarque no ônibus universitário da Unifor: o aluno cria a própria conta, entra numa rota com o código que o admin distribui e entra/sai da lista diária pelo app, o admin gerencia rotas/instituições/veículos e dispara push, e conduz o trajeto do ônibus (não há papel de motorista separado). Projeto de TCC (entrega oficial: início de novembro/2026).

> ℹ️ **A `main` é a fonte da verdade.** Alinhada em 08/09/2026 (PR #9) — o app Flutter e a API
> completa estão nela. Branches de feature saem da `main` e voltam pra ela.

## Duas aplicações, um repo

**Não é monorepo** — não há workspace tooling nem pacote compartilhado. São dois projetos independentes lado a lado, com toolchains distintos:

| Path | O que é | Toolchain |
|---|---|---|
| `smartboarding-api/` | Backend REST + scheduler + push | Java 21 · Spring Boot 4.0.5 · Maven |
| `smartboarding_app/` | App mobile (consome a API) | Flutter · Dart `^3.11.4` |

⚠️ O diretório do app é `smartboarding_app` com **underscore** (exigência de nome de package Dart), não hífen.

## Comandos

**API** — tudo roda de dentro de `smartboarding-api/` (⚠️ **o `pom.xml` não está na raiz do repo**):

```bash
docker compose up -d    # Postgres :5433 + pgAdmin :5050
./run-local.sh          # sobe a API em :8080  ← NÃO use ./mvnw spring-boot:run direto
./mvnw test              # unit
./mvnw verify             # unit + integration (Testcontainers, precisa de Docker)
```

**App** — de dentro de `smartboarding_app/`:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://<ip-da-lan>:8080 \
            --dart-define=GOOGLE_WEB_CLIENT_ID=<id>.apps.googleusercontent.com
flutter build apk --release --dart-define=API_BASE_URL=... --dart-define=GOOGLE_WEB_CLIENT_ID=...
flutter test --coverage && ./scripts/coverage-gate.sh                    # unit + gate (catraca)
flutter test integration_test/ --dart-define=API_BASE_URL=http://10.0.2.2:8080  # e2e (API+Postgres locais, emulador rodando)
```

## Onde ficam as docs

| Arquivo | O quê |
|---|---|
| `smartboarding_app/docs/spec.md` | **Spec do Flutter** — arquitetura, papéis, regras de negócio. Leia antes de mexer no app. |
| `smartboarding_app/docs/PAGES.md` + `docs/specs/<categoria>/<tela>.md` | Índice de telas + uma spec por tela (contrato de API e regras específicas daquela tela), agrupadas por categoria (autenticacao/aluno/notificacoes/relatorios/administrador). |
| `smartboarding_app/docs/design/` | `design-system.md` (tokens) + `design-prompts/<categoria>/` (prompts de layout) + `figma-screens/` (referência visual do Figma). |
| `smartboarding-api/docs/spec.md` | **Spec do backend** — papéis, regras de negócio (RN1…), arquitetura hexagonal, entidades, contratos de API. Leia antes de mexer na API. |
| `smartboarding-api/CONTEXT.md` | Contexto de domínio do backend (problema, entidades, papéis) |
| `smartboarding-api/CLAUDE.md` | Convenções detalhadas de backend e Flutter |
| `smartboarding_app/docs/firebase-setup.md` | Ativação do FCM (passo manual, feito pelo usuário) |
| `docs/README.md` | **Índice da documentação** — o que está em qual pasta e o que vale como fonte da verdade. |
| `docs/superpowers/plans/` | Planos de implementação (app e backend), um por frente, com data. Histórico — a spec vence em caso de divergência. |

Spec nova vai **neste repo**, não no harness — contrato em `../personal-harness/docs/README.md`, template em `../personal-harness/templates/spec.md`.

## Serviços externos sem SLA

Dois, e ambos seguem a mesma postura: **falha devolve nulo e a tela segue**. Nenhum dos dois pode
impedir alguém de terminar o cadastro ou pegar o ônibus.

| Serviço | Pra quê | Onde |
|---|---|---|
| **OSRM** (demo público) | Caminho por ruas, grudar parada na via, tempo entre paradas | `RoadRouteService` (app), `OsrmRoutePlannerAdapter` (API, `osrm.base-url`) |
| **ViaCEP** | Preencher o endereço a partir do CEP | `CepService` (app) |

⚠️ **O ViaCEP responde HTTP 200 com `{"erro": true}` pra CEP inexistente** — e o campo já veio
como booleano e como string. Tratar só o status deixa passar resposta vazia como endereço bom.

⚠️ **O `CepService` usa Dio próprio, nunca o `DioClient`.** Aquele injeta o Bearer da sessão em
toda requisição; reaproveitá-lo entregaria o token do aluno a um host de terceiro.

⚠️ **O OSRM espera `longitude,latitude`** — invertido em relação ao `LatLng`. E os separadores
(`,` e `;`) não podem ser URL-encoded: `%2C`/`%3B` no path quebram contra o serviço real.

## Armadilhas conhecidas

- **`./mvnw spring-boot:run` direto não funciona.** O `docker compose` lê o `.env` sozinho; o Maven **não**. Sem exportar as vars, o Spring recebe `${DB_USER}`/`${JWT_SECRET}` literais e quebra no boot. Use `./run-local.sh`.
- **`JWT_SECRET` precisa de ≥32 chars.** Secret curto falha no **boot**, e o stacktrace não aponta pro `.env`.
- **Postgres em `:5433`, não `:5432`** — hardcoded na URL do `application.properties`. Se a porta já estiver ocupada por outro projeto, o compose sobe mas a API não conecta (`docker stop postgres_gelo pgadmin_gelo` resolve o caso conhecido).
- **Pacotes seguem arquitetura hexagonal** (`domain/`, `application/`, `infrastructure/`, `shared/`) — não a flat capitalizada (`Models/`, `Controllers/`...) de versões antigas do projeto. Detalhe em `smartboarding-api/docs/spec.md` §4.1.
- **Nunca edite migration já aplicada.** Mudança de schema = `V3__...` nova. Editar quebra o checksum do Flyway e o boot falha.
- **`V1__core_schema.sql` já é a segunda consolidação.** O schema atual achatou as antigas `V1..V35` num `V1` novo — mesmo espírito de uma consolidação que o `V1` original já tinha feito uma vez antes. Squash de migrations só é seguro **antes de existir qualquer ambiente publicado** (nenhum banco real rodou a cadeia antiga pra quebrar o checksum do Flyway); depois do primeiro deploy, essa porta se fecha — a partir daí, mudança de schema é sempre migration nova.
- **Lombok `@Builder.Default` tem duas pegadinhas.** (1) Esquecer a anotação faz o Lombok ignorar o inicializador do campo no builder — um booleano que deveria nascer `true` (ex: `isActive`) nasce `false` em silêncio. (2) Mesmo anotado, ela não protege contra um `null` **explícito** vindo de fora (ex: campo de um DTO de request): o builder recebe o `null` e grava assim mesmo, violando `NOT NULL` — o código que usa o valor precisa aplicar o default manualmente quando o campo vier nulo (ver `RouteUseCaseImpl.execute`).
- **Sem `ORDER BY` explícito, o Postgres não garante a ordem das linhas** — ela pode mudar depois de um `UPDATE` ou `VACUUM`. Qualquer regra que dependa de "a primeira linha" (ex: instituição principal do aluno, derivada da primeira de `user_institutions`) precisa de `ORDER BY` explícito na query, senão a "primeira" muda sozinha sem nenhuma escrita do domínio.
- **Hibernate devolve um `@Embedded` como `null` quando todas as colunas dele estão nulas.** Código que lê o campo embutido sem reconstruí-lo primeiro (ver `User.getAddress()`) toma NPE; sempre que ler, garanta um valor não nulo antes.
- **Com Jackson 2 e 3 no mesmo classpath, pedir `JsonNode` direto a um `RestClient` cai no conversor errado.** O sintoma só aparece depois que o serviço remoto já respondeu 200 (`GoogleTokenVerifierAdapter` contorna lendo `String` e fazendo o parse manual com um `ObjectMapper` próprio) — nada nos testes simples pega isso, só uma chamada de rede de verdade.
- **O `tokeninfo` do Google devolve `"true"`/`"false"` como STRING, não booleano.** Ler `email_verified` como bool direto do JSON dá sempre `false`.
- **Mensagens de erro que viajam no cabeçalho `WWW-Authenticate` precisam ser ASCII.** `BearerTokenError` (resource server OAuth2) recusa qualquer caractere fora do RFC 6750 — acento quebra a resposta. É a única exceção à regra de mensagem em PT-BR do resto da API (ver `SecurityConfig.currentAuthorities`).
- **Contador de tentativas (rate-limit) nunca fica na mesma `@Transactional` que lança a exceção de limite excedido.** O rollback da transação desfaria o próprio incremento que deveria travar a próxima tentativa, e a força bruta ficaria livre pra sempre tentar de novo — foi exatamente o bug do fluxo de convite deste repo. Ver `PasswordResetUseCaseImpl`/`EmailChangeUseCaseImpl` (sem `@Transactional` de propósito nesses métodos). Consequência: qualquer `@Modifying` do repositório JPA chamado por eles (ex. `invalidateAllForUser`) precisa da própria `@Transactional` no adapter — sem transação ambiente nenhuma por perto, a query `@Modifying` simplesmente não executa.
- **A `UNIQUE (route_id, sequence)` de `stops` é `DEFERRABLE INITIALLY DEFERRED`.** Inserir uma parada no meio do trajeto empurra as seguintes pra `sequence + 1` uma a uma, dentro da mesma transação (`StopUseCaseImpl.add`); sem `DEFERRABLE`, o primeiro `UPDATE` do lote já colidiria com a linha que ainda não foi movida, mesmo a constraint acabando satisfeita no fim da transação.
- **Migration removida continua no `target/`.** O Maven não limpa resources órfãos: se você apagar/renomear um `V*.sql`, a cópia velha fica em `target/classes/db/migration/` e o Flyway aborta com `Found more than one migration with version N`. Rode `./mvnw clean test` — não é problema da migration nova.
- **`localhost` não resolve em device físico.** O `API_BASE_URL` precisa do IP da máquina na LAN.
- **Mudança de contrato é trabalho nos dois lados.** Alterar um DTO na API quase sempre exige mexer no `lib/features/<x>/` correspondente. Trate como uma unidade lógica só.

## Convenções

- **Branch default / base de PR:** `main`
- **Papéis:** `ADMIN`, `STUDENT` (ações de trajeto são do `ADMIN` — sem papel de motorista separado)
- **Estado no app:** Provider exclusivamente — sem BLoC, sem Riverpod
- **Segredos:** `.env` a partir de `.env.example` — nunca commitados. Override pessoal de config: `application-local.properties` (gitignored por convenção do repo). Hook local anti-hardcode: `git config core.hooksPath .githooks` (bloqueia commit com secret/token/senha literal — motivo em `.githooks/pre-commit`).
- **Perfis Spring:** `local` (default, override pessoal gitignored), `dev` (config de
  desenvolvimento compartilhada e versionada — traz o dado de demonstração de `db/seed`) e `prod`
  (`SPRING_PROFILES_ACTIVE=prod` — desliga SQL no log, `ddl-auto=validate`, esconde stacktrace,
  limita o pool). O `run-local.sh` ativa `local,dev`.
- **A configuração base é segura por omissão.** `application.properties` carrega só
  `db/migration`; o seed entra apenas pelo perfil `dev`. Isso é de propósito: as contas do seed
  têm a senha publicada no próprio arquivo, e um deploy que esqueça `SPRING_PROFILES_ACTIVE` não
  pode ganhar administrador de credencial conhecida por descuido. Banco sem o perfil `dev` sobe
  vazio — que é exatamente o que produção faz.
- **Deploy:** ainda não há ambiente publicado, mas a API já está preparada: `Dockerfile` multi-stage (JRE + usuário sem privilégio), host/porta do banco externalizados (`DB_HOST`/`DB_PORT`, ou `SPRING_DATASOURCE_URL` inteiro) e `PORT` respeitado. Variáveis necessárias em `.env.prod.example`.
- Commit/branch/PR: ver `../personal-harness/docs/CONVENTIONS.md`
