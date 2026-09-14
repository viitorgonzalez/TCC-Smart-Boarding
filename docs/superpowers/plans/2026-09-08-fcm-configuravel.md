# FCM configurável — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deixar o push pronto para ligar — configuração documentada e verificada nos dois lados — sem versionar credencial e sem que a ausência dela quebre a aplicação.

**Architecture:** Nada de código novo de domínio. O trabalho é de configuração, documentação e uma verificação honesta de que o caminho degradado funciona: a API sobe e opera com push desligado, e o app não trava sem `google-services.json`.

**Tech Stack:** Firebase Admin SDK (API) · `firebase_messaging` (app).

**Spec:** `docs/superpowers/specs/2026-09-08-hardening-pre-producao-design.md` (§4.4)

**Escopo desta PR:** a 4ª das 5 da spec §6. É a menor do pacote.

## Global Constraints

- Branch: `feature/hardening-pre-producao`. **Nenhuma migration.**
- **Nenhuma credencial versionada.** O repo tem hook anti-segredo local (`.githooks/pre-commit`) e GitGuardian no CI — os dois vão barrar, e com razão.
- Commit convencional, **sem** `Co-Authored-By` de IA.
- **Não** commitar, pushar ou abrir PR sem aprovação explícita do autor.

## Ponto de partida verificado

- `application.properties` já tem `firebase.credentials.path=${FIREBASE_CREDENTIALS_PATH:}` — default vazio.
- `FcmAdapter` já guarda a inicialização com `if (FirebaseApp.getApps().isEmpty())` e tem um `catch (Exception)` no envio.
- `smartboarding_app/docs/firebase-setup.md` existe com 48 linhas.
- `google-services.json` **não** está no app.

Ou seja: a base existe. O que falta é **provar** que o caminho degradado funciona e documentar o caminho feliz.

---

### Task 1: Provar que a ausência de credencial não quebra nada

Antes de documentar como ligar, confirmar que estar desligado é seguro. Esta é a parte que vale mais do que a documentação.

**Files:** nenhum ainda — é investigação com resultado registrado.

- [ ] **Step 1: Subir a API sem credencial**

```bash
cd smartboarding-api
grep -n "FIREBASE_CREDENTIALS_PATH" .env || echo "  não definido — é o cenário que queremos"
docker compose up -d && ./run-local.sh
```

Esperado: a aplicação **sobe** e loga o início normalmente. Se falhar no boot, esta task vira correção de código no `FcmAdapter` antes de qualquer documentação.

- [ ] **Step 2: Exercitar um caminho que dispara push**

Com um token de admin, publicar um aviso — que é o caminho mais curto até o FCM:

```bash
curl -s -X POST localhost:8080/api/notifications/broadcast -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{\"title\":\"Teste sem FCM\",\"body\":\"Deve gravar mesmo sem push\",\"routeId\":\"$RID\"}" \
  -w " | %{http_code}\n"
```

Esperado: `200`. O aviso precisa **existir na caixa** mesmo sem push:

```bash
curl -s localhost:8080/api/notifications -H "Authorization: Bearer $TOKEN" | head -c 200
```

Esperado: "Teste sem FCM" no topo. Se o endpoint devolver erro, o `publish` está deixando a falha do FCM subir — corrigir para best-effort antes de seguir.

- [ ] **Step 3: Registrar o resultado**

Anotar no corpo da PR o que foi observado. Se algo precisou de correção no `FcmAdapter` ou no `NotificationUseCaseImpl`, essa correção é o commit desta task:

```bash
git commit -m "fix(api): push desligado nao impede o aviso de ser gravado"
```

Se nada precisou mudar, esta task não gera commit — e isso é resultado, não ausência de trabalho.

---

### Task 2: Configuração do lado da API

**Files:**
- Modify: `smartboarding-api/.env.example`
- Modify: `smartboarding-api/.env.prod.example`
- Modify: `smartboarding-api/CLAUDE.md`
- Modify: `.gitignore`

- [ ] **Step 1: Documentar a variável no `.env.example`**

Substituir a linha vazia por algo que explique o efeito de deixá-la vazia:

```bash
# Caminho do service account JSON do Firebase Admin SDK.
# Vazio = push desligado: os avisos continuam sendo gravados e aparecem no app,
# só não chegam como notificação do sistema. Nunca commite o arquivo apontado.
FIREBASE_CREDENTIALS_PATH=
```

- [ ] **Step 2: Garantir que a credencial não entra no git**

Conferir e, se faltar, acrescentar ao `.gitignore` da raiz:

```gitignore
# Credenciais do Firebase — nunca versionadas
**/google-services.json
**/GoogleService-Info.plist
**/firebase-service-account*.json
```

Verificar que a regra pega:

```bash
git check-ignore -v smartboarding_app/android/app/google-services.json
```

Esperado: a linha do `.gitignore` que casou. Sem saída = a regra não pegou, corrigir antes de seguir.

- [ ] **Step 3: Atualizar o `CLAUDE.md` da API**

Na seção de variáveis de ambiente, deixar explícito que `FIREBASE_CREDENTIALS_PATH` é opcional e o que acontece sem ela.

- [ ] **Step 4: Commit (após aprovação do autor)**

```bash
git add smartboarding-api/.env.example smartboarding-api/.env.prod.example \
        smartboarding-api/CLAUDE.md .gitignore
git commit -m "chore: documenta credencial do FCM como opcional e a mantem fora do git"
```

---

### Task 3: Configuração do lado do app

**Files:**
- Create: `smartboarding_app/android/app/google-services.json.example`
- Modify: `smartboarding_app/docs/firebase-setup.md`
- Modify: `smartboarding_app/CLAUDE.md` (se mencionar FCM)

- [ ] **Step 1: Criar o exemplo**

Um `google-services.json.example` com a estrutura e valores obviamente falsos, para quem for configurar saber o formato sem precisar caçar na documentação do Firebase. Os campos ficam com `SUBSTITUA-*` no lugar dos valores — nada que pareça uma chave real.

- [ ] **Step 2: Completar o `firebase-setup.md`**

O arquivo já tem 48 linhas. Acrescentar o que falta para alguém executar sozinho: criar o projeto no console, registrar o app Android com o `applicationId` correto (`com.smartboarding.smartboarding_app`), baixar o `google-services.json` para `android/app/`, gerar a chave de service account e apontar `FIREBASE_CREDENTIALS_PATH`. E deixar registrado, no topo, que **nada disso é obrigatório para desenvolver** — o app e a API funcionam sem push, com os avisos na caixa.

- [ ] **Step 3: Confirmar que o app roda sem o arquivo**

```bash
cd smartboarding_app && flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Esperado: o app abre, loga e mostra o mural. Se travar por falta do `google-services.json`, o registro de token precisa virar best-effort — e essa correção entra aqui.

- [ ] **Step 4: Gate e commit (após aprovação do autor)**

```bash
cd smartboarding_app && dart format . && flutter analyze && flutter test
git add smartboarding_app/docs/firebase-setup.md smartboarding_app/android/app/google-services.json.example
git commit -m "docs(app): passo a passo do FCM, opcional para desenvolver"
```

---

## Fechamento da PR

- [ ] API sobe e opera sem credencial, com aviso gravado.
- [ ] App abre e funciona sem `google-services.json`.
- [ ] `git check-ignore` confirma que as credenciais estão fora do versionamento.
- [ ] Nenhum valor que pareça chave real foi commitado — o hook e o GitGuardian passam.
- [ ] PR aberta **somente após aprovação do autor**.
