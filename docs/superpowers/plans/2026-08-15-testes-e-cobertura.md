# Testes (unit/integration/e2e) e cobertura — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dar à API (Spring Boot) e ao app (Flutter) do TCC-Smart-Boarding uma camada de teste de
integração isolada (Testcontainers), um primeiro e2e de UI real (login + entrar na lista), e
relato informativo de cobertura nos dois lados — sem tornar nada disso bloqueante além do que já
é hoje (unit continua bloqueante por PR; integration API passa a ser bloqueante junto do unit,
por rodar rápido e sem infra externa; e2e de UI e cobertura ficam fora do caminho crítico do PR).

**Architecture:** API ganha `maven-failsafe-plugin` rodando classes `*IT.java` num `mvn verify`
que sobe seu próprio Postgres via Testcontainers (`@ServiceConnection`), substituindo o Postgres
manual que o CI sobe hoje. `jacoco-maven-plugin` gera relatório de cobertura unit, impresso (não
bloqueante) no CI. O app ganha o pacote `integration_test` do Flutter, com um teste de UI real
batendo numa API+Postgres reais — roda fora do `ci.yml` (workflow `workflow_dispatch` +
agendado), usando emulador Android. Cobertura do app via `flutter test --coverage` → `lcov.info`,
% impresso no CI.

**Tech Stack:** Java 21 · Spring Boot 4.0.5 · Maven · Testcontainers · JaCoCo · Flutter ·
`integration_test` (SDK do Flutter) · GitHub Actions (`reactivecircus/android-emulator-runner`).

**Spec:** `docs/superpowers/specs/2026-08-15-testes-e-cobertura-design.md`

## Global Constraints

- Nenhum segredo de alta entropia versionado — credencial de teste vai via
  `<environmentVariables>` do Failsafe (XML, não `chave: valor`), nunca como `String` Java/YAML
  atribuída com `=`/`:` (o hook `.githooks/pre-commit` bloqueia esse padrão).
- `mvn test` continua sem Docker e rápido — só `*Test.java` (Surefire). Integração (`*IT.java`,
  Failsafe) só roda em `mvn verify`.
- Cobertura é informativa nesta rodada — nenhum step de CI falha por % baixo.
- E2E de UI não entra em `pull_request`/`push` do `ci.yml` — só `workflow_dispatch`/`schedule`,
  em workflow separado.
- Seed usado no e2e: `vitor@student.com` / `sb@2026@123` (STUDENT) — já existe em
  `V2__seed_data.sql`, não criar seed novo.
- Formatação em commit isolado (regra do harness) — se algum `dart format`/reformat pintar no
  meio de uma task, isola num commit `style:` à parte, não mistura com o commit da task.

---

## Task 1: API — Testcontainers + Failsafe, migra o teste de contexto

**Files:**
- Modify: `smartboarding-api/pom.xml`
- Create: `smartboarding-api/src/test/java/com/smartboarding/smartboarding_api/SmartboardingApiApplicationIT.java`
- Delete: `smartboarding-api/src/test/java/com/smartboarding/smartboarding_api/SmartboardingApiApplicationTests.java`

**Interfaces:**
- Produces: comando `./mvnw verify` (roda `*Test.java` via Surefire + `*IT.java` via Failsafe,
  sobe Postgres 16 via Testcontainers automaticamente). Task 3 (CI) consome esse comando.

- [ ] **Step 1: Adicionar as dependências de teste no `pom.xml`**

Adicione logo após o bloco `mockito-junit-jupiter` (linhas 119-123 hoje), antes do `</dependencies>`:

```xml
			<dependency>
				<groupId>org.springframework.boot</groupId>
				<artifactId>spring-boot-testcontainers</artifactId>
				<scope>test</scope>
			</dependency>
			<dependency>
				<groupId>org.testcontainers</groupId>
				<artifactId>junit-jupiter</artifactId>
				<scope>test</scope>
			</dependency>
			<dependency>
				<groupId>org.testcontainers</groupId>
				<artifactId>postgresql</artifactId>
				<scope>test</scope>
			</dependency>
```

Sem `<version>` — gerenciadas pelo BOM do `spring-boot-starter-parent`, mesmo padrão das outras
dependências deste `pom.xml`.

- [ ] **Step 2: Adicionar o `maven-failsafe-plugin` no `<build><plugins>`**

No mesmo bloco `<plugins>` onde já está o `spring-boot-maven-plugin` (linhas 128-131), adicione
depois dele:

```xml
			<plugin>
				<groupId>org.apache.maven.plugins</groupId>
				<artifactId>maven-failsafe-plugin</artifactId>
				<configuration>
					<!-- Chave de teste fixa, só pra passar validação de tamanho no boot do
					     contexto. Não é segredo real, nunca sai da JVM do teste. -->
					<environmentVariables>
						<JWT_SECRET>integracao-teste-chave-fixa-de-32-caracteres-no-minimo</JWT_SECRET>
					</environmentVariables>
				</configuration>
				<executions>
					<execution>
						<goals>
							<goal>integration-test</goal>
							<goal>verify</goal>
						</goals>
					</execution>
				</executions>
			</plugin>
```

Sem `<version>` — se o Maven reclamar de não resolver a versão do plugin, adicione
`<version>3.5.2</version>` (mesma versão do Surefire que o parent já usa).

- [ ] **Step 3: Rodar `./mvnw test` pra confirmar que nada quebrou (unit continua sem Docker)**

Run: `cd smartboarding-api && ./mvnw -B test`
Expected: `BUILD SUCCESS`, 5 testes (os 2 de `ResendEmailAdapterTest`, os 2 de
`R2StorageAdapterTest` — confirme o nome real rodando `find src/test -name '*Test.java'` — e o
`contextLoads` de `SmartboardingApiApplicationTests`, que ainda existe nesse passo).

- [ ] **Step 4: Criar `SmartboardingApiApplicationIT.java`**

```java
package com.smartboarding.smartboarding_api;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * Sobe o contexto Spring inteiro contra um Postgres real e efêmero — também valida
 * que as migrations Flyway aplicam num banco vazio. Precisa de Docker disponível
 * (local ou runner de CI); roda via `mvn verify`, não via `mvn test`.
 */
@Testcontainers
@SpringBootTest
class SmartboardingApiApplicationIT {

	@Container
	@ServiceConnection
	static final PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16");

	@Test
	void contextLoads() {
	}

}
```

- [ ] **Step 5: Apagar o arquivo antigo**

```bash
rm smartboarding-api/src/test/java/com/smartboarding/smartboarding_api/SmartboardingApiApplicationTests.java
```

- [ ] **Step 6: Rodar `./mvnw test` de novo — confirmar que o `*IT` NÃO roda aqui**

Run: `cd smartboarding-api && ./mvnw -B test`
Expected: `BUILD SUCCESS`, 4 testes (os 2 adapters de email/storage; o `SmartboardingApiApplicationIT`
não aparece — Surefire por padrão ignora `*IT.java`). Sem Docker envolvido, sem `JWT_SECRET`
no ambiente (nenhum teste unit sobe contexto Spring).

- [ ] **Step 7: Rodar `./mvnw verify` — precisa de Docker rodando localmente**

Run: `cd smartboarding-api && ./mvnw -B verify`
Expected: `BUILD SUCCESS`. Sobe um container `postgres:16` (verifique com `docker ps` durante a
run), roda o `SmartboardingApiApplicationIT`, Flyway aplica `V1`/`V2`/`V3` num banco vazio.

- [ ] **Step 8: Commit**

```bash
cd smartboarding-api
git add pom.xml src/test/java/com/smartboarding/smartboarding_api/SmartboardingApiApplicationIT.java
git rm src/test/java/com/smartboarding/smartboarding_api/SmartboardingApiApplicationTests.java
git commit -m "test(api): migra teste de contexto pra Testcontainers via Failsafe"
```

---

## Task 2: API — cobertura com JaCoCo

**Files:**
- Modify: `smartboarding-api/pom.xml`

**Interfaces:**
- Consumes: nenhuma (independente da Task 1).
- Produces: `smartboarding-api/target/site/jacoco/jacoco.csv` depois de `mvn test`. Task 3 (CI)
  consome esse caminho pra imprimir o resumo.

- [ ] **Step 1: Adicionar o `jacoco-maven-plugin`**

No `<build><plugins>` do `smartboarding-api/pom.xml`, junto dos outros plugins:

```xml
			<plugin>
				<groupId>org.jacoco</groupId>
				<artifactId>jacoco-maven-plugin</artifactId>
				<version>0.8.12</version>
				<executions>
					<execution>
						<goals>
							<goal>prepare-agent</goal>
						</goals>
					</execution>
					<execution>
						<id>report</id>
						<phase>test</phase>
						<goals>
							<goal>report</goal>
						</goals>
					</execution>
				</executions>
			</plugin>
```

- [ ] **Step 2: Rodar `./mvnw test` e conferir o relatório**

Run: `cd smartboarding-api && ./mvnw -B test && ls target/site/jacoco/`
Expected: `BUILD SUCCESS`, e a pasta lista `jacoco.csv`, `jacoco.xml`, `index.html`.

- [ ] **Step 3: Conferir que o CSV tem conteúdo de verdade**

Run: `head -3 smartboarding-api/target/site/jacoco/jacoco.csv`
Expected: cabeçalho `GROUP,PACKAGE,CLASS,INSTRUCTION_MISSED,INSTRUCTION_COVERED,BRANCH_MISSED,BRANCH_COVERED,LINE_MISSED,LINE_COVERED,COMPLEXITY_MISSED,COMPLEXITY_COVERED,METHOD_MISSED,METHOD_COVERED`
seguido de pelo menos uma linha de dado.

- [ ] **Step 4: Commit**

```bash
cd smartboarding-api
git add pom.xml
git commit -m "build(api): adiciona JaCoCo pra relatório de cobertura unit"
```

---

## Task 3: CI — job `api` roda `verify` e imprime cobertura

**Files:**
- Modify: `.github/workflows/ci.yml:14-88`

**Interfaces:**
- Consumes: `./mvnw verify` (Task 1), `target/site/jacoco/jacoco.csv` (Task 2).

- [ ] **Step 1: Substituir o bloco do job `api` (comentário + steps de credencial/Postgres/Testes)**

Troque as linhas 14 a 88 (do `api:` até o fim do step `Testes`, mantendo o step
`Quality gate de tamanho de arquivo` como está) por:

```yaml
  api:
    name: API (Java 21 · Spring Boot)
    runs-on: ubuntu-latest

    # mvn verify sobe seu próprio Postgres via Testcontainers (docker já vem pronto no
    # runner) — não precisa mais subir Postgres manualmente aqui. Ver
    # SmartboardingApiApplicationIT.

    defaults:
      run:
        working-directory: smartboarding-api

    steps:
      # fetch-depth: 0 -- o gate de tamanho de arquivo (abaixo) precisa do commit
      # base da PR disponível localmente pra calcular o diff.
      - uses: actions/checkout@v5
        with:
          fetch-depth: 0

      - name: Setup JDK 21
        uses: actions/setup-java@v5
        with:
          java-version: '21'
          distribution: temurin
          cache: maven

      - name: Testes (unit + integration)
        # Failsafe (*IT.java) sobe Postgres via Testcontainers; Surefire (*Test.java)
        # não precisa de infra nenhuma. Um verify só roda os dois.
        run: |
          chmod +x ./mvnw
          ./mvnw -B --no-transfer-progress verify

      - name: Cobertura (informativo)
        working-directory: .
        run: |
          csv="smartboarding-api/target/site/jacoco/jacoco.csv"
          if [ -f "$csv" ]; then
            awk -F',' 'NR>1{missed+=$8; covered+=$9} END{
              if (covered+missed>0) printf "**Cobertura de linhas (unit, API):** %.1f%%\n", 100*covered/(covered+missed);
              else print "**Cobertura de linhas (unit, API):** sem dados"
            }' "$csv" >> "$GITHUB_STEP_SUMMARY"
          else
            echo "**Cobertura de linhas (unit, API):** relatório não encontrado" >> "$GITHUB_STEP_SUMMARY"
          fi
```

- [ ] **Step 2: Confirmar que o step do quality gate de tamanho de arquivo continua logo depois, intacto**

Confira que as linhas seguintes do arquivo (o comentário "Reforma 2026-08-14..." e o step
`Quality gate de tamanho de arquivo`) não mudaram — só o bloco acima delas foi substituído.

- [ ] **Step 3: Validar o YAML**

Run: `cd /home/viitorgonzalez/Documentos/personal-harness/TCC-Smart-Boarding && python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))" && echo OK`
Expected: `OK` (sem erro de parsing).

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci(api): troca Postgres manual por Testcontainers (mvn verify) + resumo de cobertura"
```

- [ ] **Step 5: Push e conferir a run no GitHub Actions**

Run: `git push origin fix/project-setup` (ou a branch em uso) e acompanhe:
`gh run list -R viitorgonzalez/TCC-Smart-Boarding --workflow=ci.yml --limit 1`
Expected: job `api` verde, com "Cobertura de linhas (unit, API): NN.N%" no Job Summary.

---

## Task 4: App — dependência `integration_test` + keys no login

**Files:**
- Modify: `smartboarding_app/pubspec.yaml`
- Modify: `smartboarding_app/lib/features/auth/screens/login_screen.dart`

**Interfaces:**
- Produces: `Key('login_email_field')`, `Key('login_password_field')`,
  `Key('login_submit_button')` — a Task 5 consome esses keys pra dirigir o e2e.

- [ ] **Step 1: Adicionar `integration_test` em `dev_dependencies`**

No `smartboarding_app/pubspec.yaml`, dentro de `dev_dependencies:`, junto do `flutter_test`:

```yaml
  integration_test:
    sdk: flutter
```

- [ ] **Step 2: Rodar `flutter pub get`**

Run: `cd smartboarding_app && flutter pub get`
Expected: `Got dependencies!` sem erro.

- [ ] **Step 3: Adicionar `key` no campo de e-mail**

Em `smartboarding_app/lib/features/auth/screens/login_screen.dart`, troque:

```dart
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
```

por:

```dart
                TextFormField(
                  key: const Key('login_email_field'),
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
```

- [ ] **Step 4: Adicionar `key` no campo de senha**

Troque:

```dart
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
```

por:

```dart
                TextFormField(
                  key: const Key('login_password_field'),
                  controller: _passCtrl,
                  obscureText: _obscure,
```

- [ ] **Step 5: Adicionar `key` no botão de entrar**

Troque:

```dart
                LoadingFilledButton(
                  loading: _loading,
                  onPressed: _submit,
                  label: 'Entrar',
                ),
```

por:

```dart
                LoadingFilledButton(
                  key: const Key('login_submit_button'),
                  loading: _loading,
                  onPressed: _submit,
                  label: 'Entrar',
                ),
```

- [ ] **Step 6: Rodar analyze e os testes unit existentes — confirmar que nada quebrou**

Run: `cd smartboarding_app && flutter analyze && flutter test`
Expected: `No issues found!`, todos os testes existentes passando.

- [ ] **Step 7: Commit**

```bash
cd smartboarding_app
git add pubspec.yaml pubspec.lock lib/features/auth/screens/login_screen.dart
git commit -m "test(app): adiciona integration_test e keys no login pra e2e"
```

---

## Task 5: App — e2e de login + entrar na lista

**Files:**
- Create: `smartboarding_app/integration_test/auth_e_lista_test.dart`

**Interfaces:**
- Consumes: `Key('login_email_field')`, `Key('login_password_field')`,
  `Key('login_submit_button')` (Task 4); `API_BASE_URL` via `--dart-define` (já existe,
  `lib/core/constants/api_constants.dart`); seed `vitor@student.com` / `sb@2026@123`.

- [ ] **Step 1: Criar `integration_test/auth_e_lista_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smartboarding_app/main.dart' as app;

const _studentEmail = 'vitor@student.com';
const _studentPassword = 'sb@2026@123';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Autenticação e primeiro formulário do aluno', () {
    testWidgets('credencial inválida mostra erro e não sai do login', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        _studentEmail,
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'senha-errada-de-proposito',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.textContaining('Falha no login'), findsOneWidget);
      expect(find.byKey(const Key('login_email_field')), findsOneWidget);
    });

    testWidgets(
      'credencial válida entra na home do aluno e abre o formulário de direção',
      (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('login_email_field')),
          _studentEmail,
        );
        await tester.enterText(
          find.byKey(const Key('login_password_field')),
          _studentPassword,
        );
        await tester.tap(find.byKey(const Key('login_submit_button')));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Saiu da tela de login.
        expect(find.byKey(const Key('login_email_field')), findsNothing);
        expect(find.text('Smart Boarding'), findsOneWidget);

        // Estado do seed pode variar (já inscrito ou não) — cobre os dois.
        final entrarNaLista = find.widgetWithText(
          FilledButton,
          'Entrar na lista',
        );
        final jaInscrito = find.text('Você está na lista');

        expect(
          tester.any(entrarNaLista) || tester.any(jaInscrito),
          isTrue,
          reason: 'esperava ver o card da lista de hoje em algum dos dois estados',
        );

        if (tester.any(entrarNaLista)) {
          await tester.tap(entrarNaLista.first);
          await tester.pumpAndSettle();

          // Bottom sheet de direção — abre pelo menos uma opção (ida/volta/ida e volta).
          expect(find.text('Escolha a direção'), findsOneWidget);
          await tester.tap(find.byType(ListTile).first);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          expect(find.text('Você está na lista'), findsOneWidget);
        }
      },
    );
  });
}
```

- [ ] **Step 2: Preparar API + Postgres locais pro e2e (fora do jar de teste, é infra manual aqui)**

Run (num terminal separado, de dentro de `smartboarding-api/`):
```bash
docker compose up -d
./run-local.sh
```
Expected: API respondendo em `http://localhost:8080` (confira com
`curl -i http://localhost:8080/api/routes` — é `GET` público, não precisa de token).

- [ ] **Step 3: Rodar o e2e contra um device/emulador Android**

Run: `cd smartboarding_app && flutter test integration_test/auth_e_lista_test.dart --dart-define=API_BASE_URL=http://10.0.2.2:8080`

> Precisa de um emulador Android **rodando** (ou device físico com `adb reverse tcp:8080 tcp:8080`
> e `API_BASE_URL=http://localhost:8080` nesse caso). Não roda em ambiente sem emulador/device —
> se não houver um disponível agora, deixe marcado como pendente de verificação na review desta
> task e valide antes de mergear.

Expected: `2 tests passed` (ou os 2 no describe acima).

- [ ] **Step 4: Commit**

```bash
cd smartboarding_app
git add integration_test/auth_e_lista_test.dart
git commit -m "test(app): e2e de login + primeiro formulário do aluno"
```

---

## Task 6: CI — job `app` reporta cobertura unit

**Files:**
- Modify: `.github/workflows/ci.yml:142-143`

**Interfaces:**
- Independente das outras tasks de CI (Task 3), pode ser feita em paralelo.

- [ ] **Step 1: Trocar o step `Testes` do job `app`**

Troque:

```yaml
      - name: Testes
        run: flutter test
```

por:

```yaml
      - name: Testes
        run: flutter test --coverage

      - name: Cobertura (informativo)
        working-directory: .
        run: |
          lcov="smartboarding_app/coverage/lcov.info"
          if [ -f "$lcov" ]; then
            awk -F: '/^LF:/{lf+=$2} /^LH:/{lh+=$2} END{
              if (lf>0) printf "**Cobertura de linhas (unit, App):** %.1f%%\n", 100*lh/lf;
              else print "**Cobertura de linhas (unit, App):** sem dados"
            }' "$lcov" >> "$GITHUB_STEP_SUMMARY"
          else
            echo "**Cobertura de linhas (unit, App):** relatório não encontrado" >> "$GITHUB_STEP_SUMMARY"
          fi
```

- [ ] **Step 2: Rodar localmente pra conferir o parsing**

Run: `cd smartboarding_app && flutter test --coverage && awk -F: '/^LF:/{lf+=$2} /^LH:/{lh+=$2} END{if (lf>0) printf "%.1f%%\n", 100*lh/lf}' coverage/lcov.info`
Expected: um número tipo `42.3%` impresso, sem erro.

- [ ] **Step 3: Validar o YAML**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))" && echo OK`
Expected: `OK`.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci(app): flutter test --coverage + resumo de cobertura no job summary"
```

---

## Task 7: CI — workflow de e2e separado (não bloqueante)

**Files:**
- Create: `.github/workflows/e2e.yml`

**Interfaces:**
- Consumes: `integration_test/auth_e_lista_test.dart` (Task 5), seed `V2__seed_data.sql`
  (já existe).

- [ ] **Step 1: Criar `.github/workflows/e2e.yml`**

```yaml
name: e2e

on:
  workflow_dispatch:
  schedule:
    # 06:00 UTC = 03:00 em Fortaleza — fora do horário de uso.
    - cron: '0 6 * * *'

jobs:
  app-e2e:
    name: E2E (Android · login + lista)
    runs-on: ubuntu-latest
    timeout-minutes: 30

    steps:
      - uses: actions/checkout@v5

      - name: Setup JDK 21
        uses: actions/setup-java@v5
        with:
          java-version: '21'
          distribution: temurin
          cache: maven

      # Mesmo padrão de credencial efêmera do job `api` do ci.yml.
      - name: Gera credenciais efêmeras
        run: |
          {
            echo "DB_NAME=smartboarding_e2e"
            echo "DB_USER=e2e_$(openssl rand -hex 6)"
            echo "DB_PASSWORD=$(openssl rand -hex 24)"
            echo "JWT_SECRET=$(openssl rand -hex 32)"
          } >> "$GITHUB_ENV"

      - name: Sobe Postgres 16
        run: |
          docker run -d --name e2e-postgres \
            -e POSTGRES_DB="$DB_NAME" \
            -e POSTGRES_USER="$DB_USER" \
            -e POSTGRES_PASSWORD="$DB_PASSWORD" \
            -p 5433:5432 \
            postgres:16
          for _ in $(seq 1 30); do
            if docker exec e2e-postgres pg_isready -U "$DB_USER" -d "$DB_NAME" >/dev/null 2>&1; then
              echo "Postgres pronto"
              exit 0
            fi
            sleep 2
          done
          echo "Postgres não ficou pronto em 60s" >&2
          docker logs e2e-postgres >&2
          exit 1

      - name: Builda e sobe a API em background
        working-directory: smartboarding-api
        run: |
          chmod +x ./mvnw
          ./mvnw -B -DskipTests package
          nohup java -jar target/*.jar \
            --spring.profiles.active=local \
            > ../api.log 2>&1 &
          # /api/routes é GET público (SecurityConfig permitAll) — não precisa de token
          # nem de Actuator (não está no pom.xml) só pra saber que a API subiu.
          for _ in $(seq 1 30); do
            if curl -sf http://localhost:8080/api/routes >/dev/null 2>&1; then
              echo "API pronta"
              exit 0
            fi
            sleep 2
          done
          echo "API não respondeu em 60s" >&2
          cat ../api.log >&2
          exit 1

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: Dependências
        working-directory: smartboarding_app
        run: flutter pub get

      - name: E2E no emulador Android
        uses: reactivecircus/android-emulator-runner@v2
        with:
          api-level: 34
          working-directory: smartboarding_app
          script: |
            flutter test integration_test/ --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

- [ ] **Step 2: Validar o YAML**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/e2e.yml'))" && echo OK`
Expected: `OK`.

- [ ] **Step 3: Disparar manualmente e conferir**

Run: `gh workflow run e2e.yml -R viitorgonzalez/TCC-Smart-Boarding` e depois
`gh run list -R viitorgonzalez/TCC-Smart-Boarding --workflow=e2e.yml --limit 1`
Expected: run verde (ou o motivo específico da falha, pra ajustar antes de fechar a task —
emulador é a peça mais sujeita a flakiness na primeira tentativa).

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/e2e.yml
git commit -m "ci: adiciona workflow de e2e (Android, manual + agendado, não bloqueante)"
```

---

## Task 8: Docs — comandos novos no CLAUDE.md

**Files:**
- Modify: `smartboarding-api/CLAUDE.md`
- Modify: `CLAUDE.md` (raiz do repo)

**Interfaces:**
- Nenhuma — task de documentação, consumida pelo `/pr-description` do harness (descobre o
  comando de coverage lendo esses arquivos, ver `docs/CONVENTIONS.md` §8).

- [ ] **Step 1: Atualizar `smartboarding-api/CLAUDE.md`**

Na seção "Como Rodar o Backend", troque:

```
# 4. Rodar testes
./mvnw test
```

por:

```
# 4. Rodar testes
./mvnw test      # unit — rápido, sem Docker
./mvnw verify     # unit + integration — sobe Postgres via Testcontainers, precisa de Docker

# 5. Cobertura (unit)
./mvnw test && open target/site/jacoco/index.html   # (ou xdg-open no Linux)
```

- [ ] **Step 2: Atualizar o `CLAUDE.md` raiz — bloco de comandos da API**

Troque:

```bash
docker compose up -d    # Postgres :5433 + pgAdmin :5050
./run-local.sh          # sobe a API em :8080  ← NÃO use ./mvnw spring-boot:run direto
./mvnw test
```

por:

```bash
docker compose up -d    # Postgres :5433 + pgAdmin :5050
./run-local.sh          # sobe a API em :8080  ← NÃO use ./mvnw spring-boot:run direto
./mvnw test              # unit
./mvnw verify             # unit + integration (Testcontainers, precisa de Docker)
```

- [ ] **Step 3: Atualizar o `CLAUDE.md` raiz — bloco de comandos do App**

Troque:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://<ip-da-lan>:8080
flutter build apk --release
```

por:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://<ip-da-lan>:8080
flutter build apk --release
flutter test --coverage                                                  # unit + cobertura
flutter test integration_test/ --dart-define=API_BASE_URL=http://10.0.2.2:8080  # e2e (API+Postgres locais, emulador rodando)
```

- [ ] **Step 4: Commit**

```bash
git add smartboarding-api/CLAUDE.md CLAUDE.md
git commit -m "docs: documenta comandos de integration/e2e/cobertura nos CLAUDE.md"
```

---

## Ordem sugerida

Tasks 1→2→3 (API) e 4→5 (App e2e) e 6 (App cobertura CI) podem rodar em paralelo entre si — só
respeitam a ordem interna de cada grupo. Task 7 depende de Task 5 existir. Task 8 fecha por
último, depois que os comandos reais de todas as outras estiverem confirmados.
