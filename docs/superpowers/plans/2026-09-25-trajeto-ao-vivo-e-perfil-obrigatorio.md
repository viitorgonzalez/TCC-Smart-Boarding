# Trajeto ao vivo e perfil obrigatório — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fechar o perfil como pré-requisito da lista (com endereço preenchido por CEP), entregar a carteirinha de estudante virtual, arrumar dois pontos de UI, e dar ao aluno o acompanhamento do trajeto ao vivo com tempo estimado **até a instituição dele**.

**Architecture:** O caminho por ruas já existe (`RoadRouteService` → OSRM) e o ciclo de trajeto já existe no backend (`start`/`checkpoint`/`finish`). O trabalho é: (a) estruturar o endereço e preenchê-lo por CEP, (b) exigir perfil completo no `AddEntryUseCase`, (c) ligar parada a instituição explicitamente (hoje é adivinhado por nome), (d) ler `duration` que o OSRM já devolve, (e) grudar a parada na via, (f) construir as telas.

**Tech Stack:** Java 21 · Spring Boot 4.0.5 · JPA/Hibernate · JUnit 5 + Mockito + AssertJ · Flutter/Dart 3.11 + Provider + Dio + flutter_map/OSRM

**Spec:** [`../specs/2026-09-25-trajeto-ao-vivo-e-perfil-obrigatorio-design.md`](../specs/2026-09-25-trajeto-ao-vivo-e-perfil-obrigatorio-design.md)

## Global Constraints

- Comentário em código explica **o porquê**, nunca o quê (CLAUDE.md do workspace).
- Nomes de variável, função e comentário em **inglês**; mensagens ao usuário em **PT-BR**.
- Todo teste novo precisa **reprovar antes do fix** — rode e veja falhar antes de implementar.
- Gates: `./mvnw verify` e `flutter test --coverage && ./scripts/coverage-gate.sh`.
- Nunca commitar sem o usuário pedir.
- **Migration nova = arquivo novo.** A última aplicada é a **`V30`** (conferido).
- **Serviço externo sem SLA não trava tela.** Vale pro OSRM e agora pro ViaCEP: falhou, o
  usuário preenche à mão e segue. O padrão já existe em `pathThrough` (devolve `null`, quem
  chama cai no plano B).

## Decisões que já vieram do usuário

Nada aqui está bloqueado. As duas perguntas em aberto foram respondidas:

- **Endereço** → estruturado, preenchido por **CEP** (Tasks 1–2).
- **"Parada principal"** no tempo estimado → **a instituição do aluno**, não a última parada.
  Isso arrastou uma dependência que não estava à vista: hoje a ligação parada↔instituição é
  adivinhada por nome. Vira **Task 9**, e as tasks de tempo dependem dela.

**Feature nova no meio do caminho:** carteirinha de estudante virtual (Task 5). Depende do
endereço estruturado, por isso o endereço subiu pra primeira posição.

> **⚠️ Bug encontrado ao investigar isso.** Nada no código de produção escreve `is_main_point`:
> só a migration V20 populou. Como o checkpoint exige ponto principal, **toda rota criada depois
> da V20 não consegue marcar parada nenhuma**. A Task 9 passa a ser conserto, e é
> **pré-requisito das Tasks 12–14** — fazer as telas antes seria entregar um botão que só dá
> erro. Detalhe na spec §7.

---

### Task 1: Endereço estruturado — backend

Base de tudo: a carteirinha mostra rua/bairro/número, e esses campos não existem ainda.

- [ ] Migration `V31__structured_address.sql`: adiciona `zip_code`, `street`, `neighborhood`,
      `city`, `state`, `street_number`, `complement` em `users`.
- [ ] **Renomeia** `address` → `address_legacy` em vez de dropar. Texto livre não dá pra quebrar
      com segurança, e adivinhar rua e número produz endereço errado com cara de certo — que é o
      motorista parando no lugar errado. Quem já tinha endereço preenche de novo.
- [ ] Campos novos no `User`, com `structuredAddressComplete()` no domínio (não no controller:
      a Task 3 vai precisar da mesma resposta).
- [ ] Teste: falta `streetNumber` → incompleto; tudo menos `complement` → completo
      (`complement` é opcional, nem todo endereço tem).
- [ ] Expor em `StudentProfileResponse` e no `/me`.
- [ ] `./mvnw test`

---

### Task 2: Endereço por CEP — app

- [ ] `CepService` consumindo `https://viacep.com.br/ws/{cep}/json/`. Sem chave.
- [ ] Devolve `null` em erro, timeout **e** no `{"erro": true}` que o ViaCEP responde com
      **HTTP 200** pra CEP inexistente — tratar só o status deixaria passar resposta vazia como
      se fosse endereço bom.
- [ ] Teste com HTTP falso: CEP válido → campos preenchidos; CEP inexistente (200 + `erro`) →
      `null`; timeout → `null`.
- [ ] No formulário de perfil: digitou 8 dígitos → busca e preenche rua/bairro/cidade/UF.
- [ ] Os campos preenchidos ficam **editáveis**. CEP genérico de cidade pequena erra, e ninguém
      deve ficar preso a um endereço errado que o app escolheu.
- [ ] Teste de widget: ViaCEP fora do ar → o formulário continua preenchível e envia.
- [ ] Foco pula pro campo "número" depois do preenchimento — é o único que falta.
- [ ] `flutter test`

---

### Task 3: Perfil completo como pré-requisito da lista

Backend. A regra mora no use case porque só no app seria decorativa.

- [ ] **Antes de tudo:** `phone`, endereço e `course` passam a salvar **direto**, sem aprovação
      do admin. Ver spec §1 "beco sem saída" — sem isso a regra nova vira parede: o aluno
      preenche e fica esperando aprovação enquanto perde a viagem.
- [ ] Teste: aluno altera `phone` → aplica na hora, **sem** criar `ProfileUpdateRequest`.
- [ ] Teste de não-regressão: aluno altera `fullName` → **continua** criando solicitação.
      O que decide em qual transporte a pessoa entra segue passando pelo admin.
- [ ] Escrever teste em `AddEntryUseCaseImplTest`: aluno sem `phone` é recusado com
      `PROFILE_INCOMPLETE_FOR_LIST`. **Rode e veja falhar.**
- [ ] Testes irmãos: endereço incompleto recusa; sem instituição recusa; sem `fullName` recusa;
      com tudo preenchido **entra**.
- [ ] Teste do conteúdo: o erro lista **quais** campos faltam, não só que falta algo.
- [ ] Teste de não-regressão: `birthDate` e `course` vazios **não** impedem — opcionais por
      decisão de design.
- [ ] Implementar em `AddEntryUseCaseImpl`, reusando `structuredAddressComplete()` da Task 1.
- [ ] `ForbiddenException` não serve (é permissão). `BadRequestException` com o código novo, e
      estender o corpo de erro pra carregar `missing`.
- [ ] Mutação: comente a checagem e confirme que **exatamente** os testes novos falham.
- [ ] `./mvnw test`

**Verificação:** o admin que inscreve aluno pela folha (`/entries/admin`) **não** passa por esta
trava — inclusão tardia é decisão dele, com o aluno na frente. Confirme com um teste.

---

### Task 4: O app avisa antes de esbarrar

App. Nunca deixe o aluno descobrir o bloqueio só ao tocar no botão.

- [ ] Widget: perfil incompleto → o botão "Entrar na lista" dá lugar a um bloco com **o que
      falta** e atalho pro perfil.
- [ ] Teste de widget: perfil incompleto → não há botão de entrar, há o aviso e o atalho.
- [ ] Teste: perfil completo → botão normal, sem aviso.
- [ ] Teste: o texto **nomeia** os campos que faltam (não "complete seu perfil" genérico).
- [ ] `flutter test`

---

### Task 5: Carteirinha de estudante virtual

Feature nova. Depende da Task 1 (rua/bairro/número).

- [ ] Tela nova, alcançável do perfil do aluno.
- [ ] Mostra: nome completo, instituição, curso, e **só rua, bairro e número** do endereço.
      Sem CEP, sem cidade/UF — não identificam ninguém numa conferência e CEP é dado que não
      precisa circular numa tela que se mostra pra outra pessoa.
- [ ] Avatar por iniciais (padrão já usado no app). **Sem foto** — não há campo em `users`, e
      adicionar significa upload, storage e moderação: é outra frente.
- [ ] Validade = estar ativo e vinculado a uma rota. **Não** usar `users.expiry_date`: ela
      alimenta `isAccountNonExpired()` do Spring Security, e preenchê-la com validade de
      carteirinha faria o aluno **perder o login** no dia em que ela vencesse.
- [ ] Rodapé dizendo que **não é documento oficial** nem prova de matrícula — o app sabe o que o
      aluno declarou, não valida vínculo com a instituição. Sem isso vira documento com aparência
      de oficial que ninguém auditou.
- [ ] Teste de widget: perfil incompleto → a carteirinha mostra o que falta em vez de campos
      vazios. Carteirinha com lacuna não serve pra conferência nenhuma.
- [ ] Teste: aluno sem rota → estado "sem vínculo ativo", não carteirinha em branco.
- [ ] Teste: o CEP **não** aparece na tela.
- [ ] Registrar em `docs/PAGES.md` e criar a spec da tela em `docs/specs/aluno/`.
- [ ] `flutter test`

---

### Task 6: Cabeçalho do aluno

App, só visual. Independente.

- [ ] `AppHeader`: mostrar só o primeiro nome. Cuidado com nome de uma palavra só e espaços extras.
- [ ] Teste: "Vítor Silva Pastor Gonzalez" → "Vítor"; "Ana" → "Ana"; `"  Ana  Maria "` → "Ana".
- [ ] Trocar os três botões sólidos por: um botão de ação (entrar com código) + menu de excesso
      (⋮) com perfil e sair.
- [ ] Teste: as três ações continuam alcançáveis (a de sair, dentro do menu).
- [ ] `flutter test` + `flutter analyze`

---

### Task 7: Ordem dos cards do admin

App, só visual. Independente.

- [ ] Reordenar o grid conforme a spec §3.
- [ ] Nenhum teste novo — é ordem visual. Confirme que os testes existentes do painel seguem verdes.

**Verificação no aparelho:** os 8 cards continuam cabendo sem rolar, com o "Resumo de Hoje" visível.

---

### Task 8: Parada grudada na via

App. Base pro bloco do trajeto — sem isso o tempo parte de um ponto que não é onde o ônibus encosta.

- [ ] `RoadRouteService.snapToRoad(LatLng)` usando `/nearest/v1/driving/{lon},{lat}` do OSRM.
- [ ] Devolve `null` quando o serviço não responde — quem chama **usa o ponto original**. Uma
      parada no lugar aproximado é melhor que nenhuma parada.
- [ ] Teste com HTTP falso: resposta boa → coordenada grudada; erro/timeout → `null`.
- [ ] Ligar em `RouteStopsEditor`, ao criar e ao mover parada.
- [ ] Teste de widget: criar parada manda a coordenada **corrigida**, não a do toque.
- [ ] Teste: OSRM fora do ar → a parada ainda é criada, com a coordenada do toque.

---

### Task 9: Parada ↔ instituição — **corrige um bug vivo**

Backend. Não é só o que destrava "tempo até a sua instituição": é conserto.

> **O bug.** Nada em `src/main/java` escreve `is_main_point` — `CreateStopRequest` não tem o
> campo, `add()` deixa no default `false`, `update()` não o toca, e
> `grep -rn "setMainPoint" src/main/java` não devolve nada. Só a migration V20 populou, uma vez.
> Como `TripUseCaseImpl.checkpoint` recusa parada que não seja ponto principal, **toda rota
> criada depois da V20 não consegue marcar parada nenhuma** — o trajeto inicia e todo toque
> devolve `STOP_NOT_MAIN_POINT`. Fazer as telas novas (Tasks 12–14) sem isto seria entregar um
> botão que só dá erro.

- [ ] **Primeiro reproduza:** crie uma rota nova com paradas pela API, inicie o trajeto, tente o
      checkpoint. Espere `STOP_NOT_MAIN_POINT`. Não implemente antes de ver o erro.
- [ ] Teste de integração que falha hoje: parada criada pela API → checkpoint aceito.
- [ ] Migration `V32__stop_institution.sql`: `stops.institution_id UUID NULL REFERENCES institutions(id)`.
- [ ] Popular pelo mesmo `LIKE` da V20 — uma vez, **como dado**, não como regra viva.
- [ ] `is_main_point` passa a ser derivado: tem `institution_id`, ou é a rodoviária.
- [ ] `CreateStopRequest`/`UpdateStopRequest` ganham `institutionId`; `add()` e `update()` gravam.
      **Esta é a linha que conserta o bug** — sem ela a parada nova continua nascendo comum.
- [ ] Teste: renomear a parada **não** desfaz o vínculo. (É o que prova que saímos do `LIKE`.)
- [ ] Teste: parada sem instituição e sem ser rodoviária → segue recusando checkpoint. A RN23
      continua valendo; o que muda é existir um jeito de marcar a parada como principal.
- [ ] Campo opcional no editor de paradas do admin — parada comum não tem instituição.
- [ ] Expor `institutionId` em `StopResponse`.
- [ ] **Dado existente:** "Campus Unifor" está `is_main_point = f` no banco local porque não
      casou com "UNIFOR-MG — Formiga". A migration deve corrigir o que o `LIKE` errou, ou o admin
      corrige na tela. Decida ao implementar, mas não deixe passar em silêncio.
- [ ] `./mvnw verify`

---

### Task 10: Tempo médio por parada principal

Backend. O número é estável — calcular no app faria cada aparelho bater no OSRM pro mesmo resultado.

- [ ] Migration `V33__stop_avg_minutes.sql`: `stops.avg_minutes_from_start INTEGER NULL`.
      **Por parada**, não por rota: se o tempo ao vivo é até a instituição do aluno, a média
      também precisa ser. A média do trajeto inteiro pra quem desce na terceira de sete paradas
      é um número que não é sobre a viagem dele.
- [ ] Porta de saída nova pro OSRM (`RoutePlannerPort`) + adapter HTTP. Porta, não chamada
      direta: o serviço troca (spec §4c) e o use case não pode saber disso.
- [ ] `duration` do OSRM + **1 min por parada** até ali (tempo de embarque).
- [ ] Recalcular quando as paradas mudarem (criar/mover/remover/reordenar). Não na leitura.
- [ ] Teste com a porta mockada: 3 paradas, 600s de OSRM até a terceira → 10 + 3 = 13 min.
- [ ] Teste: OSRM indisponível → fica **nulo** e nada quebra. Nulo é "não sei", e a tela omite —
      melhor que um número inventado.
- [ ] `./mvnw test`

---

### Task 11: Trajeto ao vivo — backend

O ciclo já existe. Falta o que o aluno precisa ler.

- [ ] `GET /api/trip/{listId}` já devolve o estado. Conferir se traz parada atual, paradas
      alcançadas e se está em andamento; estender com o que faltar.
- [ ] Resolver **a parada do aluno**: a que tem `institution_id` = instituição declarada dele.
- [ ] Aluno com duas instituições na mesma rota → vale a **primeira declarada**, que já é a
      "principal" hoje (decide em que contagem ele entra, ver `my_institutions_card.dart`).
      Uma regra só no app inteiro.
- [ ] Aluno cuja instituição não tem parada → devolve a **última** parada e diz qual é. Omitir
      seria pior: ele fica sem nenhuma noção de quando chega.
- [ ] Testes dos três casos acima.
- [ ] **Escopo:** o aluno só lê o trajeto de rota em que ele está. Teste: aluno de outra rota
      toma 403.
- [ ] Teste: trajeto não iniciado → estado "não começou", não erro.
- [ ] `./mvnw test`

---

### Task 12: Trajeto ao vivo — tela do admin

- [ ] Simplificar `trip_screen.dart`: próxima parada em destaque, um botão "Cheguei nesta
      parada", quantas faltam, encerrar.
- [ ] Sai da tela: mapa de edição, lista de inscritos, qualquer coisa que não seja a decisão do
      momento. Quem conduz não navega o app — toca uma vez por parada.
- [ ] Teste de widget: tocar no botão chama o checkpoint da **parada certa** (a atual, não a
      primeira).
- [ ] Teste: última parada → o botão vira "Encerrar trajeto".

---

### Task 13: Trajeto ao vivo — tela do aluno

- [ ] Botão "Acompanhar trajeto" no card da lista, **só quando o trajeto está em andamento**.
- [ ] Tela nova reaproveitando `RouteMap`: paradas como checklist (alcançadas marcadas, atual
      destacada) + polilinha real.
- [ ] A parada da instituição do aluno fica **destacada** — é o ponto que interessa a ele.
- [ ] Polling a cada 20s **enquanto a tela está aberta**. Cancelar no `dispose` — timer vivo
      depois de sair é vazamento e gasta bateria.
- [ ] Teste: trajeto parado → sem botão. Em andamento → com botão.
- [ ] Teste: a tela pede o estado ao abrir e de novo depois do intervalo.
- [ ] Teste: sair da tela **cancela** o polling.

---

### Task 14: Tempo estimado até a instituição do aluno

Fecha o bloco.

- [ ] `RoadRouteService` passa a ler `duration` além da geometria — **já vem na mesma resposta**.
- [ ] Estimado = duração(parada atual → parada da instituição dele) + (paradas no meio × 1 min).
- [ ] O rótulo **nomeia o destino** ("até a UNIFOR"), não "até o destino". Dois alunos no mesmo
      ônibus veem números diferentes — sem o nome, um deles acha que o app está errado.
- [ ] Teste do cálculo, com o serviço mockado.
- [ ] Teste: dois alunos de instituições diferentes na mesma lista → tempos diferentes, cada um
      com o rótulo certo.
- [ ] Teste: ônibus **já passou** da instituição do aluno → não mostra tempo negativo; mostra
      "você já desceu" / trajeto concluído pra ele.
- [ ] Teste: OSRM sem resposta → a tela **omite** o tempo em vez de mostrar zero ou "—" enganoso.
- [ ] Tempo médio (Task 10) na lista, também até a instituição dele.
- [ ] `flutter test --coverage && ./scripts/coverage-gate.sh`

---

### Task 15: Verificação no aparelho

Os testes não pegam layout nem fluxo. Esta task é olhar.

- [ ] Subir ambiente (`docker compose up -d`, `./run-local.sh`, emulador).
- [ ] **CEP:** digitar um CEP de Formiga → rua e bairro preenchem sozinhos; só falta o número.
- [ ] **Perfil incompleto:** aluno sem telefone → o card mostra o que falta, sem botão de entrar.
      Preencher → botão volta **na hora**, sem passar por aprovação.
- [ ] **Carteirinha:** abrir → nome, instituição, curso, rua/bairro/número. Sem CEP à vista.
- [ ] **Cabeçalho:** logar como `vitor@student.com` (nome longo) → só "Vítor", uma linha.
- [ ] **Painel do admin:** 8 cards na ordem nova, sem rolar, "Resumo de Hoje" à vista.
- [ ] **Parada:** criar uma tocando entre dois quarteirões → o pino se ajusta pra via.
- [ ] **Trajeto:** iniciar como admin, marcar uma parada; como aluno, abrir "Acompanhar trajeto"
      e ver a parada marcada e o tempo **nomeando a instituição dele**.
- [ ] **O caso que mais importa:** dois alunos de instituições diferentes, mesma lista → cada um
      vê o seu tempo. É a resposta da decisão do usuário; se falhar aqui, falhou inteiro.
- [ ] Tirar print de cada tela mexida e comparar com o estado anterior.

---

### Task 16: Documentação

- [ ] `smartboarding-api/docs/spec.md`: RN nova de perfil obrigatório; endereço estruturado e as
      migrations V31–V33; `stops.institution_id` substituindo o `LIKE` da V20 na RN23.
- [ ] Registrar que `phone`/endereço/`course` saem do fluxo de aprovação, e **por quê**.
- [ ] `smartboarding_app/docs/specs/aluno/`: tela de acompanhamento e carteirinha.
- [ ] `smartboarding_app/docs/PAGES.md`: as duas telas novas.
- [ ] `CLAUDE.md` do app: ViaCEP como dependência externa nova, junto do aviso do OSRM.
