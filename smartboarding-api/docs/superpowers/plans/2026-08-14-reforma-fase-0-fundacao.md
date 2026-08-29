# Reforma — Fase 0: Fundação (backend) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preparar a base pra toda a reforma de regras de negócio (`docs/spec.md` §4-§6, RN13-RN23):
remover o papel `DRIVER` do domínio, subir os clients de e-mail (Resend) e storage
(Cloudflare R2) que as fases seguintes vão consumir, e ligar o quality gate de tamanho de
arquivo na CI. Nenhuma regra de negócio nova (RN13+) é implementada nesta fase — só a fundação.

**Architecture:** Arquitetura hexagonal já existente (`domain/application/infrastructure`, ver
`docs/spec.md` §4.1). `EmailPort`/`StoragePort` novos entram como ports "de kernel
compartilhado" em `domain/shared/port/out/` (não pertencem a um contexto de negócio específico —
serão consumidos por `registration`/`user` e `notification` respectivamente nas fases 2-4) — é
uma inferência de onde encaixar na convenção existente, não uma decisão do usuário; ajustar se o
padrão do repo já tiver um lugar mais natural quando a Fase 2/4 forem implementar quem consome.

**Tech Stack:** Java 21, Spring Boot 4.0.5 (`spring-boot-starter-webmvc` já traz `RestClient` —
sem dependência HTTP nova pro client Resend), `software.amazon.awssdk:s3` (novo — R2 é
S3-compatible, é o cliente recomendado pela própria Cloudflare em vez de assinar requests
manualmente).

## Global Constraints

- **Não editar `V1__initial_schema.sql`/`V2__seed_data.sql`.** Mudança de dado/schema é migration
  nova (`V3__...`).
- **Quality gate de tamanho de arquivo é por diff, não full-sweep.** `student_home_screen.dart`
  (497 linhas) e `user_management_screen.dart` (387 linhas) no Flutter **já excedem 300 linhas
  hoje** — um gate de sweep completo quebraria a CI imediatamente nesta fase, bloqueando todo PR
  futuro até um refactor não planejado. O gate só falha se um arquivo **tocado no diff do PR**
  passar de 300 linhas — arquivos antigos intocados não bloqueiam (mesmo raciocínio do ratchet de
  cobertura: não travar em cima de débito pré-existente, só evitar piorar).
- **Sem comentários no código**, exceto pra explicar correção de bug muito específico.
- **`main` é prod** (`docs/spec.md` §8) — não é relevante nesta fase (sem deploy ainda, Fase 6),
  mas os clients Resend/R2 desta fase precisam ser testados contra os serviços reais (conta de
  teste), não só mockados, antes de considerar a fase pronta — `docs/spec.md` reforça isso.

---

### Task 1: Remover papel `DRIVER` do domínio

**Files:**
- Modify: `domain/user/entity/Role.java`
- Create: `src/main/resources/db/migration/V3__migrate_driver_users_to_admin.sql`
- Modify: `docs/spec.md` (riscar RN11 já foi feito na spec; nada a fazer aqui além de conferir)

- [ ] **Step 1: Migration pra realinhar seed data existente**
  - `V2__seed_data.sql` (já aplicada, não editar) criou dois usuários com `role='DRIVER'`
    (`motorista@smartboarding.com`, `roberto@driver.com`). Como a coluna `role` é `VARCHAR(20)`
    **sem `CHECK`** (validada só na aplicação — `smartboarding-api/CLAUDE.md`), remover `DRIVER`
    do enum Java sem migrar esses dois registros quebra o boot: Hibernate tenta desserializar
    `role='DRIVER'` pro enum `Role` e não encontra o valor.
  - `V3__migrate_driver_users_to_admin.sql`:
    ```sql
    UPDATE users SET role = 'ADMIN' WHERE role = 'DRIVER';
    ```
  - Decisão de negócio já tomada (`docs/spec.md` §4.7): "motorista é adm mesmo" — os dois usuários
    viram `ADMIN` de fato, não são deletados (mantêm login/senha/histórico).

- [ ] **Step 2: Remover `DRIVER` do enum**
  ```java
  public enum Role {
      ADMIN, STUDENT
  }
  ```
  - Rodar `./mvnw clean test` depois — `SmartboardingApiApplicationTests` (smoke test) vai pegar
    qualquer lugar que ainda referencie `Role.DRIVER` em código (não deveria haver nenhum —
    `SecurityConfig.java` não tem `hasRole("DRIVER")` hoje, confirmado antes de escrever este
    plano).

- [ ] **Step 3: Confirmar que a migration roda antes do boot tentar ler os dois usuários**
  - Ordem Flyway é por número de versão (`V3` depois de `V2`) — não precisa de ação extra, só
    confirmar no log do `./run-local.sh` que `V3` aplicou antes de qualquer teste que carregue
    `motorista@smartboarding.com`.

---

### Task 2: Client de e-mail (Resend)

**Files:**
- Create: `domain/shared/port/out/EmailPort.java`
- Create: `infrastructure/email/ResendEmailAdapter.java`
- Create: `infrastructure/email/ResendProperties.java` (`@ConfigurationProperties`, le
  `RESEND_API_KEY`)
- Modify: `.env.example` (adicionar `RESEND_API_KEY`)
- Create: `src/test/java/.../infrastructure/email/ResendEmailAdapterTest.java`

- [ ] **Step 1: Port**
  ```java
  public interface EmailPort {
      void send(String to, String subject, String htmlBody);
  }
  ```
  - Interface mínima — RN13 (convite) e RN22 (reset de senha) chamam com HTML pronto (o
    template do e-mail é responsabilidade de quem chama, não do port).

- [ ] **Step 2: Adapter via `RestClient`**
  - `POST https://api.resend.com/emails`, header `Authorization: Bearer ${RESEND_API_KEY}`,
    body `{"from": "...", "to": [to], "subject": subject, "html": htmlBody}`.
  - `from` precisa de um domínio verificado no Resend — **bloqueio conhecido**: sem domínio
    próprio configurado no Resend, só é possível enviar pro e-mail cadastrado na conta de teste
    (limitação da conta grátis do Resend, não do código). Documentar isso na task, não é
    resolvível só com código.
  - Falha HTTP (4xx/5xx) → lançar exceção (`shared/exception`, `BadRequestException` ou nova
    `EmailDeliveryException` — decidir na implementação, seguindo o padrão de
    `GlobalExceptionHandler` existente).

- [ ] **Step 3: `RESEND_API_KEY` no `.env.example`**
  ```
  # ── E-mail (Resend) — convite de cadastro (RN13) e recuperação de senha (RN22) ──
  RESEND_API_KEY=CHANGE_ME_resend_api_key
  ```

- [ ] **Step 4: Teste de integração manual (não mockado)**
  - Com conta Resend real (mesmo que sandbox), enviar um e-mail de teste e confirmar recebimento
    — antes de dar a task por pronta (`docs/spec.md` §8: "main é prod", integração testada de
    ponta a ponta).

- [ ] **Step 5: Unit test do adapter**
  - Mock do `RestClient` (ou `MockRestServiceServer`), cobrindo: sucesso (200) e falha (4xx/5xx
    propaga exceção).

---

### Task 3: Client de storage (Cloudflare R2)

**Files:**
- Modify: `pom.xml` (dependência `software.amazon.awssdk:s3`)
- Create: `domain/shared/port/out/StoragePort.java`
- Create: `infrastructure/storage/R2StorageAdapter.java`
- Create: `infrastructure/storage/R2Properties.java`
- Modify: `.env.example`
- Create: `src/test/java/.../infrastructure/storage/R2StorageAdapterTest.java`

- [ ] **Step 1: Dependência**
  ```xml
  <dependency>
    <groupId>software.amazon.awssdk</groupId>
    <artifactId>s3</artifactId>
  </dependency>
  ```
  - Adicionar o BOM `software.amazon.awssdk:bom` em `<dependencyManagement>` pra travar a versão
    (padrão do SDK v2) — checar versão estável mais recente na hora de implementar.

- [ ] **Step 2: Port**
  ```java
  public interface StoragePort {
      String upload(byte[] content, String contentType, String fileName); // retorna URL pública
  }
  ```

- [ ] **Step 3: Adapter — `S3Client` apontando pro endpoint do R2**
  - R2 é S3-compatible: `endpointOverride` = `https://<account_id>.r2.cloudflarestorage.com`,
    `region` = `auto` (convenção R2), credenciais = `R2_ACCESS_KEY_ID`/`R2_SECRET_ACCESS_KEY`.
  - Upload via `putObject` no bucket `R2_BUCKET_NAME`; URL pública retornada depende de o bucket
    ter **acesso público habilitado** ou um domínio customizado configurado no painel do
    Cloudflare — **bloqueio conhecido, fora de código**: precisa ser configurado manualmente no
    painel R2 antes do adapter funcionar de ponta a ponta (mesma natureza do bloqueio do Resend).

- [ ] **Step 4: Variáveis no `.env.example`**
  ```
  # ── Storage (Cloudflare R2) — imagem de notificação (RN20) ──
  R2_ACCOUNT_ID=CHANGE_ME
  R2_ACCESS_KEY_ID=CHANGE_ME
  R2_SECRET_ACCESS_KEY=CHANGE_ME
  R2_BUCKET_NAME=CHANGE_ME
  ```

- [ ] **Step 5: Teste de integração manual (não mockado)**
  - Upload real de uma imagem de teste pro bucket R2, confirmar que a URL retornada abre a
    imagem num navegador — antes de dar a task por pronta.

- [ ] **Step 6: Unit test do adapter**
  - Mock do `S3Client` (AWS SDK v2 tem `S3Client` fácil de mockar via Mockito/`S3Mock` se
    disponível) — cobre sucesso e falha de upload.

---

### Task 4: Quality gate de tamanho de arquivo (CI)

**Files:**
- Modify: `.github/workflows/ci.yml` — jobs `api` e `app`

- [ ] **Step 1: Step no job `api`, depois de "Testes"**
  ```yaml
  - name: Quality gate de tamanho de arquivo
    run: |
      base="${{ github.event.pull_request.base.sha }}"
      head="${{ github.sha }}"
      changed=$(git diff --name-only --diff-filter=ACMR "$base" "$head" -- '*.java' | grep '^smartboarding-api/src/main/' || true)
      violations=""
      for f in $changed; do
        lines=$(wc -l < "../$f" 2>/dev/null || wc -l < "$f")
        [ "$lines" -gt 300 ] && violations="$violations\n$f: $lines linhas"
      done
      if [ -n "$violations" ]; then
        echo -e "Arquivos no diff acima de 300 linhas:$violations"
        exit 1
      fi
  ```
  - ⚠️ Esqueleto, não copiar sem validar: confirmar se `git diff` no runner do GitHub Actions
    enxerga `base.sha`/`sha` direto (pode precisar de `actions/checkout@v5` com
    `fetch-depth: 0` pra ter o histórico completo — checkout raso hoje pode não ter o commit
    base disponível localmente). Validar rodando o step numa PR de teste antes de confiar.
  - Path do `wc -l` depende do `working-directory: smartboarding-api` já configurado no job —
    ajustar o path relativo do `git diff` (que roda na raiz do repo) contra os arquivos do step
    (que roda dentro de `smartboarding-api/`) na hora de implementar.

- [ ] **Step 2: Step equivalente no job `app`, mesmo padrão mas filtrando `*.dart` em `lib/`**

- [ ] **Step 3: Confirmar que não quebra nos 2 arquivos Flutter já acima de 300 linhas**
  - `student_home_screen.dart` (497) e `user_management_screen.dart` (387) só devem falhar o
    gate **se aparecerem no diff de uma PR** (mesmo raciocínio do Global Constraint) — validar
    isso numa PR de teste que NÃO toca nesses dois arquivos (deve passar) e outra que toca
    (deve falhar, comportamento esperado — força quem tocar neles a começar a reduzir).

---

## Ordem recomendada

Task 1 (remoção do `DRIVER`) é independente das outras e pode ir primeiro — é a única com risco
de quebrar o boot se a migration não rodar certo. Tasks 2 e 3 (clients externos) são
independentes entre si, podem ser paralelas. Task 4 (CI) por último, depois que os arquivos que
ela vai varrer (os novos adapters/tests das Tasks 2/3) já existirem — evita a CI falhar num PR
que ainda está sendo construído.
