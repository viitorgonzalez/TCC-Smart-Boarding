# Consumo dos Gaps 2/3/4 (Backend) + Quality Gate de Cobertura (Flutter) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ligar o app aos três gaps de backend que estão em implementação em paralelo
(`smartboarding-api/docs/superpowers/plans/2026-08-14-gaps-2-3-4-e-quality-gate.md`): motorista
enviando notificação de saída de verdade, campos de perfil estendido no cadastro de usuário e
tratamento de conta expirada — e ligar o mesmo mecanismo de quality gate de cobertura usado no
backend.

**Architecture:** Sem mudança — `Provider` por feature, services manuais em cima do `Dio`
(`DioClient`), `Navigator` 1.0. Ver `docs/spec.md` §4.

**Tech Stack:** Flutter 3.44 / Dart 3.12, `provider`, `dio`, `mocktail` (já em uso nos testes
existentes).

## Global Constraints

- **Depende do backend estar de pé.** Tasks 1 e 3 fazem chamada real aos endpoints novos — só
  testáveis ponta a ponta depois que o plano do backend mergear. A UI pode ser construída e
  testada com mock antes disso (mesma lógica que já valeu para o `DriverHomeScreen` original).
- **Sem `go_router`/BLoC/Riverpod** — manter `Provider`.
- **`expiryDate = null` → nunca expira** — replicar a mesma regra no client (não assumir expirado
  quando o campo vier ausente/null do `UserResponse`).

---

### Task 1: Motorista — notificação de saída real

**Files:**
- Modify: `lib/features/driver/services/driver_service.dart` (já existe, hoje aponta pro endpoint que não existia)
- Modify: `lib/features/driver/providers/driver_provider.dart`
- Modify: `lib/features/driver/screens/driver_home_screen.dart` (confirmar mensagens de feedback já implementadas batem com `notified: N` real)
- Modify: `test/unit/driver_provider_test.dart` (já existe — atualizar mocks pro contrato real)

- [ ] **Step 1: Confirmar `driver_service.dart` contra o contrato final**
  - `POST /api/lists/{id}/notifications/departure`, body opcional `{title?, body?}`, resposta
    `{ data: { success: true, notified: N } }`. Já era o contrato assumido — só validar que nada
    mudou durante a implementação do backend (checar `smartboarding-api/docs/spec.md` §6 na hora).

- [ ] **Step 2: Teste de integração manual**
  - Com backend local rodando (`./run-local.sh`) e um usuário `DRIVER` de seed: login → selecionar
    lista → enviar notificação → confirmar `notified: N` bate com inscritos ativos reais.

---

### Task 2: Formulário de usuário — campos de perfil estendido

**Files:**
- Modify: `lib/features/admin/screens/user_management_screen.dart` (ou o form widget correspondente)
- Modify: `lib/features/admin/providers/user_provider.dart`
- Modify: model de request de registro (onde hoje monta o payload de `POST /api/auth/register`)
- Modify: `test/unit/user_provider_test.dart`

- [ ] **Step 1: Campos novos no formulário, condicionais a `role == STUDENT`**
  - `course`, `institution`, `phone`, `address` — `TextFormField` simples, sem validação de
    formato (não decidido — ver `docs/spec.md` §0).
  - `birthDate`, `expiryDate` — `DatePicker`, ambos opcionais.
  - Campos somem/reaparecem ao trocar o `role` selecionado no mesmo formulário (sem submeter valor
    quando o role não for `STUDENT`).

- [ ] **Step 2: Payload do registro**
  - Enviar os campos preenchidos (omitir os vazios, não enviar string vazia como se fosse valor).

- [ ] **Step 3: Widget/unit test**
  - Selecionar role `STUDENT` → campos aparecem; trocar pra `DRIVER`/`ADMIN` → campos escondem e
    não vão no payload.

---

### Task 3: Tratamento de `ACCOUNT_EXPIRED`

**Files:**
- Modify: `lib/features/auth/providers/auth_provider.dart` (ou onde o login já trata erro de credencial)
- Modify: `lib/features/auth/screens/login_screen.dart`
- Modify: `lib/features/student/providers/list_provider.dart` (entrar na lista)
- Create/modify: teste unitário do `AuthProvider` e do `ListProvider` cobrindo o novo erro

- [ ] **Step 1: Mapear `code: "ACCOUNT_EXPIRED"` no cliente HTTP/provider de auth**
  - Erro de login (`401`) com `code=ACCOUNT_EXPIRED` → mensagem "Sua carteirinha de transporte
    expirou — procure o administrador", distinta da mensagem genérica de credencial inválida.

- [ ] **Step 2: Mesmo tratamento no `ListProvider` (entrar na lista, `403`)**

- [ ] **Step 3: Unit tests**
  - Login: erro `401` com `code=ACCOUNT_EXPIRED` → mensagem dedicada; `401` sem esse code →
    mensagem genérica de credencial (não regredir o caminho existente).
  - Entrar na lista: erro `403 ACCOUNT_EXPIRED` → mesma mensagem dedicada.

---

### Task 4: Quality gate de cobertura (Flutter)

**Files:**
- Create: `smartboarding_app/.coverage-baseline`
- Modify: `../.github/workflows/ci.yml` — job `app`

- [ ] **Step 1: Medir baseline local**
  - `flutter test --coverage` → `coverage/lcov.info`.
  - Somar `LF`/`LH` de todas as entradas do `lcov.info` (`grep -E '^(LF|LH):' coverage/lcov.info`)
    e calcular `%` = `soma(LH) / soma(LF) * 100`.
  - Fazer isso **depois** das Tasks 1–3 (baseline já reflete os testes novos).
  - Commitar o número em `smartboarding_app/.coverage-baseline`.

- [ ] **Step 2: Step de CI**
  - Depois do step "Testes" no job `app` do `ci.yml`:
    ```yaml
    - name: Testes com cobertura
      run: flutter test --coverage

    - name: Quality gate de cobertura
      run: |
        lf=$(grep -oE '^LF:[0-9]+' coverage/lcov.info | cut -d: -f2 | awk '{s+=$1} END {print s}')
        lh=$(grep -oE '^LH:[0-9]+' coverage/lcov.info | cut -d: -f2 | awk '{s+=$1} END {print s}')
        actual=$(awk -v lh="$lh" -v lf="$lf" 'BEGIN { printf "%.1f", lh*100/lf }')
        baseline=$(cat .coverage-baseline)
        echo "cobertura atual: ${actual}% · baseline: ${baseline}%"
        awk -v a="$actual" -v b="$baseline" 'BEGIN { if (a+0 < b+0) { print "regressão de cobertura"; exit 1 } }'
        awk -v a="$actual" -v b="$baseline" 'BEGIN { if (a+0 > b+0.5) { print "cobertura subiu mas .coverage-baseline não foi atualizado — setar para " a; exit 1 } }'
    ```
    - Substitui o step "Testes" existente do job `app` (mesmo comando, só com `--coverage`).

- [ ] **Step 3: Confirmar simetria com o gate do backend**
  - Mesma lógica de ratchet (regressão falha; ganho não commitado no arquivo também falha) —
    documentado em `docs/spec.md` §9. Se o mecanismo divergir na prática, atualizar a spec.

---

## Ordem recomendada

Tasks 1–3 dependem do plano do backend estar mergeado pra teste ponta a ponta, mas a UI/lógica de
cliente pode ser escrita e testada com mock em paralelo. **Task 4 por último**, pelo mesmo motivo
do plano do backend: a baseline deve refletir os testes novos das Tasks 1–3.
