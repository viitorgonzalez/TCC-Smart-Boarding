# CI e gate de cobertura — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Actions sem vermelho recorrente, só teste unitário bloqueando, e cobertura travando em 90% na regra de negócio e 70% no restante.

**Architecture:** Remover o e2e, incorporar o trabalho de gate que está solto, configurar o `check` do JaCoCo por pacote e um equivalente no Flutter — e, antes de ligar a trava, escrever os testes que faltam para o número ser alcançável.

**Tech Stack:** JaCoCo (API) · `flutter test --coverage` → lcov (app) · GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-08-hardening-pre-producao-design.md` (§4.5)

**Escopo desta PR:** a 5ª e última da spec §6. Vem depois das features por decisão do autor.

## Global Constraints

- Branch: `feature/hardening-pre-producao`. **Nenhuma migration.**
- Commit convencional, **sem** `Co-Authored-By` de IA.
- **Não** commitar, pushar ou abrir PR sem aprovação explícita do autor.
- O gate só é **ligado** quando os números já passam — subir uma trava que quebra o próprio CI é pior que não ter trava.

## Ponto de partida medido

Cobertura de linhas na `main`, por pacote (medida com `mvnw test jacoco:report`):

| Pacote | Cobertura | Linhas descobertas |
|---|---:|---:|
| `infrastructure.web` | **0,0%** | 491 |
| `infrastructure.persistence` | 0,0% | 105 |
| `infrastructure.config` | 0,0% | 94 |
| `application.list` | 62,4% | 77 |
| `application.notification` | 35,2% | 70 |
| `application.report` | 0,0% | 46 |
| `application.route` | 41,8% | 32 |
| `application.user` | 34,0% | 31 |
| `application.institution` | 75,0% | 9 |
| `application.vehicle` | 0,0% | 7 |
| `application.registration` | 97,9% | 3 |
| `application.warning` | 92,7% | 3 |
| `application.stop` | 94,3% | 2 |
| `application.stats` | 100% | 0 |

Total: **33,9%** na API (546/1611) e **35,1%** no app (115/328).

**Duas conclusões que mudam o plano:**

1. **`application.*` precisa de ~280 linhas cobertas** para chegar a 90%. É trabalho grande, mas é do tipo que a suíte já sabe fazer — mais testes de use case com Mockito, no formato dos que existem.
2. **`infrastructure.web` está zerado e é o maior bloco.** Não existe **nenhum** teste de controller: `@WebMvcTest` e `MockMvc` não aparecem em lugar nenhum. O único teste com contexto Spring é o `SmartboardingApiApplicationIT`, que só verifica se a aplicação sobe — não exercita endpoint. Chegar a 70% no "resto" exige introduzir um tipo de teste novo, não só escrever mais do mesmo. Isso é uma capacidade nova da suíte, e a Task 3 existe só por causa disso.

**Exclusões do gate** (decisão da spec §4.5): entidade, DTO e configuração ficam fora. São `record`/Lombok sem ramo — perseguir número ali produz teste que não protege nada e infla a métrica.

---

### Task 1: Limpar o CI

**Files:**
- Delete: `.github/workflows/e2e.yml`
- Delete: `smartboarding_app/integration_test/`
- Create: `.aiignore` (trabalho já pronto, hoje solto no worktree antigo)
- Modify: `.github/pull_request_template.md` (idem — seção "Cobertura" + 2 itens de checklist)
- Modify: `smartboarding_app/CLAUDE.md`, `smartboarding-api/CLAUDE.md`
- Modify: `smartboarding_app/pubspec.yaml` (remover `integration_test` de `dev_dependencies`)

**Interfaces:** nenhuma.

- [ ] **Step 1: Recuperar o trabalho solto antes de apagar qualquer coisa**

Os dois arquivos existem, não commitados, no worktree antigo `TCC-Smart-Boarding/` (57 commits atrás). Copiar para a branch de trabalho:

```bash
cd /home/viitorgonzalez/Documentos/personal-harness/TCC-Smart-Boarding
cp .aiignore .worktrees/cadastro-por-convite-aprovacao/.aiignore
cp .github/pull_request_template.md .worktrees/cadastro-por-convite-aprovacao/.github/pull_request_template.md
```

Conferir que o template ganhou a seção de cobertura:

```bash
grep -n "## Cobertura" .worktrees/cadastro-por-convite-aprovacao/.github/pull_request_template.md
```

- [ ] **Step 2: Remover o e2e**

```bash
cd .worktrees/cadastro-por-convite-aprovacao
git rm -r --cached smartboarding_app/integration_test 2>/dev/null; rm -rf smartboarding_app/integration_test
rm -f .github/workflows/e2e.yml
```

Tirar `integration_test` das `dev_dependencies` do `pubspec.yaml` e rodar `flutter pub get`.

- [ ] **Step 3: Tirar o e2e da documentação**

Nos dois `CLAUDE.md`, remover a linha do comando `flutter test integration_test/`. No `smartboarding_app/CLAUDE.md`, deixar registrado por que não há e2e hoje — sem isso alguém reintroduz o workflow em três meses.

- [ ] **Step 4: Confirmar que o Actions ficou limpo**

```bash
ls .github/workflows/
```

Esperado: só `ci.yml`.

- [ ] **Step 5: Commit (após aprovação do autor)**

```bash
git add -A .github .aiignore smartboarding_app/pubspec.yaml smartboarding_app/CLAUDE.md smartboarding-api/CLAUDE.md
git commit -m "ci: remove o e2e e incorpora o gate de tamanho

O workflow rodava so em cron, falhava todo dia no emulador e nao bloqueava nada
-- ruido sem sinal. Volta quando houver suite de verdade."
```

---

### Task 2: Cobrir a regra de negócio (`application.*` a 90%)

O maior bloco de escrita desta PR. Prioridade pela ordem da tabela acima — quem tem mais linha descoberta primeiro, porque é onde o número se move.

**Files:**
- Test: `src/test/.../application/list/DailyListAdminUseCaseImplTest.java` *(criar)*
- Test: `src/test/.../application/notification/NotificationUseCaseImplTest.java` *(ampliar)*
- Test: `src/test/.../application/report/ReportUseCaseImplTest.java` *(criar)*
- Test: `src/test/.../application/route/RouteUseCaseImplTest.java` *(criar)*
- Test: `src/test/.../application/user/AuthUseCaseImplTest.java` *(ampliar)*
- Test: `src/test/.../application/vehicle/VehicleUseCaseImplTest.java` *(criar)*
- Test: `src/test/.../application/institution/InstitutionUseCaseImplTest.java` *(ampliar)*

**Interfaces:** nenhuma nova — só testes sobre o que já existe.

- [ ] **Step 1: Medir antes**

```bash
cd smartboarding-api && ./mvnw -B --no-transfer-progress test jacoco:report
python3 - target/site/jacoco/jacoco.csv <<'PY'
import csv, sys, collections
pk = collections.defaultdict(lambda: [0, 0])
for r in csv.DictReader(open(sys.argv[1])):
    p = r['PACKAGE'].replace('com.smartboarding.smartboarding_api.', '')
    if not p.startswith('application'):
        continue
    pk[p][0] += int(r['LINE_MISSED']); pk[p][1] += int(r['LINE_COVERED'])
for k, (m, c) in sorted(pk.items(), key=lambda kv: -kv[1][0]):
    print(f"{k:34} {100*c/(m+c):5.1f}%  faltam {m}")
PY
```

Guardar a saída — ela é o baseline do "antes" na tabela do PR.

- [ ] **Step 2: `application.report` (0% → 90%), 46 linhas**

Escrever `ReportUseCaseImplTest` cobrindo o que é regra e não encanamento: relatório é imutável e único por lista (RN8) — fechar duas vezes devolve o existente e não gera segundo; o veículo proposto sai do total de confirmados (RN16); `capacityShortfall` é zero quando a frota cobre todo mundo e positivo quando não cobre. Usar `Clock` fixo e mocks de repositório, no formato de `WarningUseCaseImplTest`.

- [ ] **Step 3: `application.list` (62% → 90%), 77 linhas**

O que falta aqui é o admin: `DailyListAdminUseCaseImpl` (criar lista, uma por rota e data, apagar com guarda de relatório, `setStatus` exigindo motivo e publicando aviso) e os ramos ainda descobertos de `SchedulerUseCaseImpl`.

- [ ] **Step 4: `application.notification` (35% → 90%), 70 linhas**

`NotificationUseCaseImpl`: aviso é gravado antes do push; falha de FCM não desfaz o registro; listagem do aluno traz os da rota dele dentro da validade e o admin vê tudo; exclusão em lote. E `ScheduledNotificationUseCaseImpl`: `lastSentAt` só é marcado depois do envio bem-sucedido.

- [ ] **Step 5: `application.route`, `application.user`, `application.vehicle`, `application.institution`**

Route: nome duplicado gera conflito, horários nulos caem no default, desativar desvincula instituições. User: `AuthUseCaseImpl` já tem teste — ampliar para os ramos descobertos, e cobrir `UserUseCaseImpl` (filtro por rota). Vehicle e Institution são pequenos: 7 e 9 linhas.

- [ ] **Step 6: Medir depois e confirmar**

Repetir o Step 1. Esperado: todo pacote `application.*` **≥ 90%**. Onde não chegar, decidir conscientemente entre escrever mais teste ou excluir o trecho com justificativa escrita — nunca baixar o alvo em silêncio.

- [ ] **Step 7: Commit (após aprovação do autor)**

```bash
git commit -m "test(api): cobre a regra de negocio dos use cases"
```

---

### Task 3: Cobrir os controllers (`infrastructure.web` a 70%)

Capacidade nova: hoje não existe teste de controller no repo. Introduzir `@WebMvcTest` com `MockMvc`, começando pelos controllers que carregam regra de acesso — que é o que dá risco real.

**Files:**
- Modify: `smartboarding-api/pom.xml` (se faltar `spring-security-test`)
- Test: `src/test/.../infrastructure/web/list/ListControllerTest.java`
- Test: `src/test/.../infrastructure/web/user/AuthControllerTest.java`
- Test: `src/test/.../infrastructure/web/trip/TripControllerTest.java`
- Test: `src/test/.../infrastructure/web/route/RouteControllerTest.java`

**Interfaces:** nenhuma nova.

- [ ] **Step 1: Conferir a dependência de teste de segurança**

```bash
grep -n "spring-security-test" smartboarding-api/pom.xml || echo "  falta — acrescentar em <dependencies> com <scope>test</scope>"
```

- [ ] **Step 2: Escrever o primeiro teste de slice como referência**

Começar pelo `AuthController`, que é o mais simples e estabelece o padrão que os outros seguem: `@WebMvcTest(AuthController.class)`, use cases mockados com `@MockitoBean`, e asserções sobre status e corpo. Cobrir o caminho feliz do login e o `401` de credencial inválida.

- [ ] **Step 3: Cobrir o que protege acesso**

Os três casos que mais importam, porque erro neles é falha de segurança e não de funcionalidade:
- `POST /api/lists/{id}/entries/admin` recusa quem não é ADMIN.
- `GET /api/warnings` recusa aluno (o aluno só pode `/me`).
- `/api/trip/**` recusa aluno.

- [ ] **Step 4: Medir**

Repetir a medição, agora filtrando `infrastructure`. Esperado: `infrastructure.web` **≥ 70%**.

Se ficar perto mas não passar, a decisão honesta é escolher entre cobrir mais um controller ou excluir explicitamente os DTOs do cálculo — a exclusão de DTO já está prevista na spec e é legítima; baixar o alvo não é.

- [ ] **Step 5: Commit (após aprovação do autor)**

```bash
git commit -m "test(api): testes de slice dos controllers, com foco em regra de acesso"
```

---

### Task 4: Ligar o gate na API

Só agora, com os números já passando.

**Files:**
- Modify: `smartboarding-api/pom.xml`

- [ ] **Step 1: Configurar o `check` do JaCoCo**

Acrescentar uma execução `check` ligada ao `verify`, com duas regras e as exclusões da spec:

```xml
<execution>
    <id>check-coverage</id>
    <phase>verify</phase>
    <goals><goal>check</goal></goals>
    <configuration>
        <!-- Entidade, DTO e config sao record/Lombok sem ramo: perseguir numero
             ali produz teste que nao protege nada e infla a metrica. -->
        <excludes>
            <exclude>**/entity/**</exclude>
            <exclude>**/dto/**</exclude>
            <exclude>**/infrastructure/config/**</exclude>
            <exclude>**/SmartboardingApiApplication.class</exclude>
        </excludes>
        <rules>
            <rule>
                <element>PACKAGE</element>
                <includes>
                    <include>com.smartboarding.smartboarding_api.application.*</include>
                    <include>com.smartboarding.smartboarding_api.domain.*</include>
                </includes>
                <limits>
                    <limit>
                        <counter>LINE</counter>
                        <value>COVEREDRATIO</value>
                        <minimum>0.90</minimum>
                    </limit>
                </limits>
            </rule>
            <rule>
                <element>BUNDLE</element>
                <limits>
                    <limit>
                        <counter>LINE</counter>
                        <value>COVEREDRATIO</value>
                        <minimum>0.70</minimum>
                    </limit>
                </limits>
            </rule>
        </rules>
    </configuration>
</execution>
```

- [ ] **Step 2: Provar que o gate morde**

```bash
cd smartboarding-api && ./mvnw -B --no-transfer-progress clean verify
```

Esperado: `BUILD SUCCESS`. Então provar que a trava funciona de verdade — comentar um teste de use case e rodar de novo:

Esperado: **falha** com `Rule violated for package ...: lines covered ratio is 0.xx, but expected minimum is 0.90`. Descomentar depois. Gate que não foi visto falhando não está provado.

- [ ] **Step 3: Commit (após aprovação do autor)**

```bash
git commit -m "ci: gate de cobertura em 90% na regra de negocio e 70% no resto"
```

---

### Task 5: Ligar o gate no app

**Files:**
- Modify: `.github/workflows/ci.yml`
- Create: `smartboarding_app/tool/check_coverage.dart` *(ou script shell equivalente)*
- Test: os que faltarem para o app chegar aos limiares

- [ ] **Step 1: Medir o app por diretório**

```bash
cd smartboarding_app && flutter test --coverage
python3 - coverage/lcov.info <<'PY'
import sys, collections
pk = collections.defaultdict(lambda: [0, 0])
cur = None
for line in open(sys.argv[1]):
    if line.startswith('SF:'):
        p = line[3:].strip()
        parts = p.split('/')
        cur = '/'.join(parts[1:4]) if len(parts) > 3 else p
    elif line.startswith('LH:'): pk[cur][1] += int(line[3:])
    elif line.startswith('LF:'): pk[cur][0] += int(line[3:])
for k, (f, h) in sorted(pk.items(), key=lambda kv: -(kv[1][0] - kv[1][1])):
    if f: print(f"{k:46} {100*h/f:5.1f}%  faltam {f-h}")
PY
```

- [ ] **Step 2: Cobrir os providers**

No app, "regra de negócio" são os `providers/` (estado e decisão) e `core/utils/` (formatação de data e horário, que já causou bug real). Escrever teste de provider no formato dos que existem (`registration_provider_test.dart`, `user_provider_test.dart`), com `mocktail`.

- [ ] **Step 3: Escrever o verificador**

Script que lê `coverage/lcov.info` e falha se `lib/features/**/providers/` ou `lib/core/utils/` ficarem abaixo de 90%, ou se o total ficar abaixo de 70%. Excluir `*.g.dart` e `*.freezed.dart` (já listados no `.aiignore`).

- [ ] **Step 4: Ligar no `ci.yml`**

Trocar o passo "Cobertura (informativo)" do job do app por uma chamada ao verificador, que **falha** o job.

- [ ] **Step 5: Provar que morde**

Mesmo procedimento da Task 4: quebrar um teste de propósito, ver o job falhar, restaurar.

- [ ] **Step 6: Commit (após aprovação do autor)**

```bash
git commit -m "ci: gate de cobertura no app"
```

---

## Dívida registrada, fora do escopo desta PR

**`JWT_SECRET` fixo no `pom.xml`.** Os testes de integração usam `integracao-teste-chave-fixa-de-32-caracteres-no-minimo`, em texto, no `pom.xml`. É fixture óbvia e não protege nada, mas contraria a convenção do harness ("credencial de CI se gera em runtime, nunca em texto no repo") e é o tipo de coisa que um scanner aponta. Gerar em runtime no Failsafe resolveria. Fica registrado aqui em vez de corrigido junto: é mudança na infraestrutura de teste, e misturar isso com o gate de cobertura confunde a revisão.

## Fechamento da PR

- [ ] `./mvnw clean verify` verde **com** o gate ligado.
- [ ] Job do app verde **com** o verificador ligado.
- [ ] Os dois gates vistos falhando de propósito ao menos uma vez.
- [ ] Actions sem workflow vermelho recorrente.
- [ ] Tabela de cobertura do template preenchida com antes e depois reais.
- [ ] PR aberta **somente após aprovação do autor**.
