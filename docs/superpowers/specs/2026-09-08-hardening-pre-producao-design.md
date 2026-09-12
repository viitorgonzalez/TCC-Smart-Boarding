# Hardening pré-produção — design

> Origem: `/do` → brainstorming · Intake e overview em
> `../../../../docs/work/2026-09-08-hardening-pre-producao-smartboarding/`
> Base: `main` (alinhada em 08/09/2026 pela PR #9).

## 1. Problema

O projeto saiu do modo "fechar funcionalidade" e entrou no modo entrega — defesa em novembro/2026.
O que falta não é feature solta: é o que separa protótipo de sistema que aguenta uso e revisão.

Cinco lacunas concretas, todas verificadas no código antes deste design:

1. Quem esquece a senha **fica fora do sistema** — RN22 tem spec nos dois lados e zero código.
2. O trajeto (RN23) tem spec e mockup, e **nenhuma linha** — sem `/api/trip`, sem use case, sem tela.
3. O admin **vê** aluno mas não age sobre ele — `UserController` só expõe `GET`.
4. Push não sai: FCM sem credencial configurada.
5. Cobertura em **~34%** nos dois projetos, sem gate — e o `e2e.yml` falha todo dia sem bloquear nada,
   poluindo o Actions.

Nível exigido pelo autor: **quase pronto pra produção**, não MVP.

## 2. Escopo

**Dentro:** RN22 (recuperação de senha) · RN23 (trajeto) · perfil e status do aluno com auditoria ·
reativação de rota · configuração do FCM · regime de CI e cobertura · correção do aviso de branch
desatualizado nos `CLAUDE.md`.

**Fora:** redesenho das telas internas restantes contra os mockups (segue aberto, é outro assunto) ·
suíte e2e (removida, ver §3) · deploy/publicação (não há ambiente).

## 3. Decisões

| Decisão | Escolha | Porquê |
|---|---|---|
| Ordem das frentes | Features primeiro, CI/cobertura por último | Decisão do autor. Mitigação: cada feature nasce com teste mesmo sem o gate cobrando, pra o gate final ser confirmação e não retrofit. |
| Entrega da autorização de reset | **Código de 6 dígitos** por e-mail | A spec pedia link com token na URL, mas App Link `https://` exige domínio publicado e verificado — pendência de deploy. O convite já abandonou o link pelo mesmo motivo; repetir o padrão mantém coerência e funciona hoje. |
| Passos do reset | **Uma tela**: código + nova senha juntos | Mantém os 2 endpoints que a spec já descreve, sem ticket intermediário circulando. O mockup ganha um campo, não uma tela. |
| Trajetos por dia | **Um**, com estado na `daily_lists` | `tripType` da inscrição é a intenção do aluno (ida/volta/ambos), não dois percursos conduzidos. Relação estritamente 1:1 com a lista — entidade `Trip` própria não compraria nada. |
| Auditoria | **Só** ativar/desativar aluno | Escopo fechado pedido pelo autor. Outras ações sensíveis (fechar lista, mudar horário, apagar aviso) seguem sem rastro — dívida conhecida, registrada em §8. |
| E2E | **Removido** — workflow e teste | ⚠️ **Substitui** a decisão de `2026-08-15-testes-e-cobertura-design.md`, que o manteve como job agendado não-bloqueante. Falha diariamente no emulador, não bloqueia nada e não entrega sinal. Manter o arquivo de teste sem workflow só deixaria código morto. |
| Cobertura | Gate **90%** em regra de negócio, **70%** no resto | ⚠️ **Substitui** a decisão de `2026-08-15`, que deixou cobertura informativa "até a baseline existir". A baseline existe agora (~34%) e o autor pediu enforcement. |

## 4. Arquitetura

### 4.1 Recuperação de senha (RN22)

**Migration `V19__password_reset.sql`** — tabela `password_reset_requests`:
`id`, `user_id` (FK), `code_hash`, `expires_at`, `attempts`, `used_at`, `created_at`.
Tabela própria, espelhando `registration_requests`: o dado é efêmero e não pertence ao perfil do usuário.

**Domínio** — `PasswordResetRequest` (entidade) · `RequestPasswordResetUseCase` e
`ResetPasswordUseCase` (portas in) · `PasswordResetRepositoryPort` (porta out).

**`PasswordResetUseCaseImpl`** — replica o que `RegistrationUseCaseImpl` já provou em produção aqui:

- `request(email)`: responde igual havendo conta ou não. Existindo: invalida requisições anteriores
  do mesmo usuário, gera 6 dígitos com `SecureRandom`, persiste **apenas o hash**
  (`PasswordEncoder`), envia por e-mail em best-effort (falha de envio não desfaz a transação).
  Cooldown de reenvio silencioso — recusar em voz alta transformaria o endpoint em detector de e-mail.
- `reset(email, code, newPassword)`: **sem `@Transactional`** no caminho que incrementa tentativas.
  Esta é a armadilha que já causou força bruta livre neste repo: numa transação única o rollback da
  exceção descarta o incremento e o limite nunca é atingido. Valida código, expiração e tentativas;
  troca a senha; marca `used_at`; invalida as demais requisições do usuário.
- Senha nova respeita RN10 (mínimo 6 caracteres).

**Configuração** — `app.password-reset.code-ttl-minutes`, `.max-attempts`,
`.resend-cooldown-seconds` em `application.properties`. Nenhum literal no código.

**E-mail** — `PasswordResetEmails`, no mesmo padrão de `RegistrationEmails` (corpo fora do use case).

**Web** — `POST /api/auth/forgot-password` e `POST /api/auth/reset-password`, ambos públicos no
`SecurityConfig`.

**App** — `ForgotPasswordScreen` e `ResetPasswordScreen` conforme os mockups
`figma-screens/recuperar-senha.png` e `redefinir-senha.png`, com duas adaptações: o botão vira
**"Enviar código"** e a tela de redefinir ganha um campo de código acima dos dois de senha.
`AuthService.forgotPassword/resetPassword`; entrada pelo link "Esqueci minha senha" no login.

### 4.2 Trajeto (RN23)

**Migration `V20__trip.sql`**:
- `stops.is_main_point BOOLEAN NOT NULL DEFAULT FALSE`, com as paradas atuais de rodoviária e
  instituições marcadas como principais no mesmo script.
- `daily_lists.trip_started_at`, `daily_lists.trip_finished_at` (ambos nulos).
- Tabela `trip_checkpoints`: `id`, `daily_list_id` (FK), `stop_id` (FK), `reached_at`,
  `UNIQUE (daily_list_id, stop_id)` — a unicidade é o que torna o checkpoint idempotente.

**`TripUseCaseImpl`** — máquina de estado explícita:

| Ação | Pré-condição | Efeito |
|---|---|---|
| `start` | trajeto não iniciado | grava `trip_started_at`; notifica |
| `checkpoint(stopId)` | iniciado, não finalizado, parada com `isMainPoint` e pertencente à rota | grava checkpoint (idempotente); notifica |
| `finish` | iniciado, não finalizado | grava `trip_finished_at`; notifica |

Violação de pré-condição devolve `400` com código próprio (`TRIP_NOT_STARTED`,
`TRIP_ALREADY_STARTED`, `TRIP_ALREADY_FINISHED`, `STOP_NOT_MAIN_POINT`).

Cada ação **notifica os inscritos ativos e persiste o aviso** via `PublishNotificationUseCase`.
Persistir não é opcional: com o FCM desligado o push não deixa registro nenhum, e o aluno não saberia
de nada — é a mesma lição do fechamento automático da lista. Funciona com a lista `OPEN` ou `CLOSED`
(RN23) — o embarque físico acontece depois do fechamento.

**Web** — `TripController` com os três endpoints da spec, restrito a `ADMIN` no `SecurityConfig`.

**App** — `TripScreen` reproduzindo o stepper de `figma-screens/trajeto-admin.png`: cartão da rota
selecionada, passos numerados (início concluído → parada atual com "Marcar" → próximas esmaecidas),
confirmação antes de cada ação, rodapé com o retorno do envio e "Finalizar Trajeto" liberado só com
o trajeto em curso. `TripProvider`; entrada pela tela da rota.

### 4.3 Perfil e status do aluno

**Migration `V21__user_status_log.sql`** — `user_status_log`: `id`, `user_id` (FK), `admin_id` (FK),
`action` (`ACTIVATED`/`DEACTIVATED`), `created_at`.

**Web** — `PATCH /api/users/{id}/status {active}` (ADMIN): muda `isActive` e grava o log com o admin
autenticado e o instante da ação. `GET /api/users/{id}` passa a devolver também o histórico de status.

**App** — tocar num aluno (na lista da rota ou nos inscritos) abre um **card de perfil breve**: nome,
curso, instituição, status atual e presenças recentes. **Sem e-mail, telefone ou qualquer dado
credencial** — o card é para conferência rápida, não para gestão de cadastro. Traz o switch
ativo/inativo e, abaixo, o histórico "quem mudou e quando".

**Reativação de rota** — `PATCH /api/routes/{id}` passa a aceitar `isActive`. Hoje o `DELETE` desativa
por soft-delete e não existe caminho de volta.

### 4.4 FCM

Completar `smartboarding_app/docs/firebase-setup.md` com o passo a passo real.
`google-services.json` entra no `.gitignore` com um `.example` ao lado; `FIREBASE_CREDENTIALS_PATH`
documentado no `.env.example`. A API precisa **degradar sem a credencial** — subir e operar com push
desligado, nunca falhar no boot. O repo tem hook anti-segredo local e GitGuardian no CI: nenhuma
credencial é versionada.

### 4.5 CI e cobertura

- **Remover** `.github/workflows/e2e.yml` e `smartboarding_app/integration_test/`.
- **Incorporar** o trabalho hoje solto e não publicado: `.aiignore` (consumido pelo gate de tamanho)
  e a seção "Cobertura" + 2 itens de checklist já editados em `.github/pull_request_template.md`.
- **API** — `jacoco-maven-plugin` ganha `check` ligado ao `verify`, com duas regras:
  90% de linhas em `com.smartboarding.smartboarding_api.application.*` e `...domain.*`;
  70% no restante. Exclui DTO, entidade e configuração — código sem ramo não deve inflar nem
  penalizar o número.
- **App** — passo que lê `coverage/lcov.info` e falha abaixo dos mesmos limiares, tratando
  `lib/features/**/providers/` e `lib/core/utils/` como regra de negócio.
- `CLAUDE.md` dos dois projetos: remover o comando de e2e e registrar os limiares.

### 4.6 Verdade sobre a branch

`TCC-Smart-Boarding/CLAUDE.md` e `smartboarding-api/CLAUDE.md` afirmam que a `main` está desatualizada
e que o código vive em `fix/project-setup`. Virou falso em 08/09/2026. Corrigir os dois, mais o
ponteiro em `personal-harness/docs/repos.md`, e varrer outras referências à `fix/project-setup` como
fonte da verdade. Entra de carona na primeira PR.

## 5. Estratégia de teste

Cada frente nasce testada, mesmo antes do gate existir — é o que evita o paredão de retrofit no fim.

- **RN22**: código nunca persistido em texto puro · expirado é recusado · limite de tentativas é
  atingido de fato (o teste que teria pego o bug de força bruta) · uso único · resposta idêntica para
  e-mail existente e inexistente · falha de e-mail não desfaz a operação.
- **RN23**: cada pré-condição da máquina de estado · checkpoint em parada comum recusado · checkpoint
  repetido é idempotente · notificação persistida a cada ação.
- **Status do aluno**: log gravado com admin e instante corretos · desativar e reativar acumulam
  entradas · aluno não consegue chamar o endpoint.
- **App**: providers com `mocktail`; telas novas com teste de widget cobrindo render, validação e
  estado de erro.

Tempo determinístico continua saindo do `Clock` injetável — regra de horário não se testa com
`LocalDateTime.now()`.

## 6. Divisão em PRs

Uma por frente, todas bem abaixo do limite de 100 arquivos do CodeRabbit:

1. `feat(api,app)`: recuperação de senha + correção dos `CLAUDE.md`
2. `feat(api,app)`: trajeto
3. `feat(api,app)`: perfil e status do aluno + reativação de rota
4. `chore`: FCM configurável e documentado
5. `ci`: remoção do e2e, `.aiignore`, template e gate de cobertura

Mudança de contrato é trabalho simultâneo em API e app — cada PR fecha os dois lados, nunca deixa o
app quebrado em runtime.

## 7. Critérios de aceite

- [ ] Aluno que esqueceu a senha recupera o acesso ponta a ponta pelo app.
- [ ] `forgot-password` responde igual para e-mail cadastrado e não cadastrado.
- [ ] Código de reset é de uso único, expira e trava após o limite de tentativas.
- [ ] Nenhum TTL, cooldown ou limite literal no código.
- [ ] Admin inicia, marca pontos principais e finaliza o trajeto; cada ação vira aviso persistido.
- [ ] Checkpoint em parada comum é recusado; repetido não duplica.
- [ ] Admin ativa/desativa aluno pelo card de perfil, e o log mostra qual admin e quando.
- [ ] Card de perfil não exibe e-mail nem dado credencial.
- [ ] Rota desativada volta a ficar ativa.
- [ ] API sobe sem credencial de FCM, com push desligado e sem erro no boot.
- [ ] `e2e.yml` e `integration_test/` não existem mais; Actions sem falha recorrente.
- [ ] `./mvnw verify` falha se a cobertura cair abaixo de 90% em regra de negócio ou 70% no resto.
- [ ] O job do app falha nos mesmos limiares.
- [ ] Nenhum `CLAUDE.md` afirma que a `main` está desatualizada.

## 8. Riscos e dívidas assumidas

- **A cobertura é a maior fatia.** Sair de ~34% para 90/70 é praticamente dobrar a suíte, e vem por
  último por decisão do autor. O risco é a última PR virar um bloco enorme; a mitigação é escrever
  teste junto de cada feature desde a primeira.
- **Auditoria parcial.** Fechar lista, mudar horário e apagar aviso continuam sem registro de autoria.
  Ficou fora por escolha explícita de escopo.
- **Entropia do código de 6 dígitos** é menor que a de um token de URL. Compensada por TTL curto,
  limite de tentativas e uso único — mesmo trade-off já aceito no convite.
- **`expiry_date` segue dormente** na tabela `users`: existe desde a V1, é devolvido pela API e nunca
  é preenchido nem verificado. Não entra neste escopo; fica registrado para não ser confundido com
  funcionalidade ativa.
