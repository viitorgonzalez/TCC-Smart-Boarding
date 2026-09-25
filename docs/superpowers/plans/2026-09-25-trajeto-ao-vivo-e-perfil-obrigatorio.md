# Trajeto ao vivo e perfil obrigatório — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fechar o perfil como pré-requisito da lista, arrumar dois pontos de UI, e dar ao aluno o acompanhamento do trajeto ao vivo com tempo estimado real.

**Architecture:** O caminho por ruas já existe (`RoadRouteService` → OSRM) e o ciclo de trajeto já existe no backend (`start`/`checkpoint`/`finish`). O trabalho é: (a) exigir perfil completo no `AddEntryUseCase`, (b) ler `duration`/`distance` que o OSRM já devolve, (c) grudar a parada na via, (d) construir a tela do aluno e simplificar a do admin.

**Tech Stack:** Java 21 · Spring Boot 4.0.5 · JPA/Hibernate · JUnit 5 + Mockito + AssertJ · Flutter/Dart 3.11 + Provider + Dio + flutter_map/OSRM

**Spec:** [`../specs/2026-09-25-trajeto-ao-vivo-e-perfil-obrigatorio-design.md`](../specs/2026-09-25-trajeto-ao-vivo-e-perfil-obrigatorio-design.md)

## Global Constraints

- Comentário em código explica **o porquê**, nunca o quê (CLAUDE.md do workspace).
- Nomes de variável, função e comentário em **inglês**; mensagens ao usuário em **PT-BR**.
- Todo teste novo precisa **reprovar antes do fix** — rode e veja falhar antes de implementar.
- Gates: `./mvnw verify` e `flutter test --coverage && ./scripts/coverage-gate.sh`.
- Nunca commitar sem o usuário pedir.
- **Migration nova = arquivo novo.** A última aplicada é a `V30`.
- O OSRM público não tem SLA. Toda chamada precisa de caminho de falha que **não trave a tela** — o padrão já usado em `pathThrough` (devolve `null`, quem chama cai no plano B).

## ⚠️ Bloqueios antes de começar

Duas decisões do usuário. **Task 1 e Task 7 não começam sem elas.**

- [ ] **Endereço:** texto livre (só exigir preenchido) ou estruturado em logradouro/número/bairro? Estruturado = migration + formulário novo. → afeta Task 1
- [ ] **"Parada principal"** no tempo estimado: a última parada do trajeto, ou a instituição do aluno? → afeta Task 7

---

### Task 1: Perfil completo como pré-requisito da lista

Backend. A regra mora no use case porque só no app seria decorativa.

- [ ] Escrever teste em `AddEntryUseCaseImplTest`: aluno sem `phone` é recusado com `PROFILE_INCOMPLETE_FOR_LIST`. **Rode e veja falhar.**
- [ ] Testes irmãos: sem `address` recusa; sem instituição recusa; sem `fullName` recusa; com tudo preenchido **entra**.
- [ ] Teste do conteúdo: o erro lista **quais** campos faltam, não só que falta algo.
- [ ] Teste de não-regressão: `birthDate` e `course` vazios **não** impedem — são opcionais por decisão de design.
- [ ] Implementar a checagem em `AddEntryUseCaseImpl`.
- [ ] `ForbiddenException` não serve aqui (é permissão). Usar `BadRequestException` com o código novo, e estender o corpo de erro pra carregar `missing`.
- [ ] Mutação: comente a checagem e confirme que **exatamente** os testes novos falham.
- [ ] `./mvnw test`

**Verificação:** o admin que inscreve aluno pela folha (`/entries/admin`) **não** passa por esta trava — inclusão tardia é decisão dele, com o aluno na frente. Confirme com um teste.

---

### Task 2: O app avisa antes de esbarrar

App. Nunca deixe o aluno descobrir o bloqueio só ao tocar no botão.

- [ ] `Me` (perfil) já é carregado na tela do aluno. Estender com os campos que faltam, se necessário.
- [ ] Widget: quando o perfil está incompleto, o botão "Entrar na lista" dá lugar a um bloco com **o que falta** e atalho pro perfil.
- [ ] Teste de widget: perfil incompleto → não há botão de entrar, há o aviso e o atalho.
- [ ] Teste de widget: perfil completo → botão normal, sem aviso.
- [ ] Teste: o texto nomeia os campos que faltam (não "complete seu perfil" genérico).
- [ ] `flutter test`

---

### Task 3: Cabeçalho do aluno

App, só visual. Independente de tudo.

- [ ] `AppHeader`: mostrar só o primeiro nome. Cuidado com nome de uma palavra só e com espaços extras.
- [ ] Teste: "Vítor Silva Pastor Gonzalez" → "Vítor"; "Ana" → "Ana"; `"  Ana  Maria "` → "Ana".
- [ ] Trocar os três botões sólidos por: um botão de ação (entrar com código) + menu de excesso (⋮) com perfil e sair.
- [ ] Teste: as três ações continuam alcançáveis (a de sair, dentro do menu).
- [ ] `flutter test` + `flutter analyze`

---

### Task 4: Ordem dos cards do admin

App, só visual. Independente.

- [ ] Reordenar o grid conforme a spec §3.
- [ ] Nenhum teste novo — é ordem visual. Confirme que os testes existentes do painel seguem verdes.

**Verificação no aparelho:** os 8 cards continuam cabendo sem rolar, com o "Resumo de Hoje" visível.

---

### Task 5: Parada grudada na via

App. Base pro bloco do trajeto — sem isso, o tempo estimado parte de um ponto que não é onde o ônibus encosta.

- [ ] `RoadRouteService.snapToRoad(LatLng)` usando `/nearest/v1/driving/{lon},{lat}` do OSRM.
- [ ] Devolve `null` quando o serviço não responde — quem chama **usa o ponto original**. Uma parada no lugar aproximado é melhor que nenhuma parada.
- [ ] Teste com HTTP falso: resposta boa → devolve a coordenada grudada; erro/timeout → `null`.
- [ ] Ligar em `RouteStopsEditor`, ao criar e ao mover parada.
- [ ] Teste de widget: criar parada manda a coordenada **corrigida** pro backend, não a do toque.
- [ ] Teste: OSRM fora do ar → a parada ainda é criada, com a coordenada do toque.

---

### Task 6: Tempo médio da rota

Backend. O número é estável — calcular no app faria cada aparelho bater no OSRM pro mesmo resultado.

- [ ] Migration `V31`: `routes.avg_trip_minutes INTEGER NULL`.
- [ ] Porta de saída nova pro OSRM no backend (`RoutePlannerPort`), com adapter HTTP. Porta, não chamada direta: o serviço troca (spec §4c), e o use case não pode saber disso.
- [ ] `duration` do OSRM + **1 min por parada** (tempo de embarque).
- [ ] Recalcular quando as paradas mudarem (criar/mover/remover). Não recalcular na leitura.
- [ ] Teste do cálculo com a porta mockada: 3 paradas, 600s de OSRM → 10 + 3 = 13 min.
- [ ] Teste: OSRM indisponível → `avg_trip_minutes` fica **nulo** e nada quebra. Nulo é "não sei", e a tela omite — melhor que um número inventado.
- [ ] Expor em `RouteResponse` e mostrar na lista do aluno.
- [ ] `./mvnw test`

---

### Task 7: Trajeto ao vivo — backend

O ciclo já existe. Falta o que o aluno precisa ler.

> **Não começar sem a resposta sobre "parada principal"** (bloqueio no topo).

- [ ] `GET /api/trip/{listId}` já devolve o estado. Conferir se traz: parada atual, paradas alcançadas, e se o trajeto está em andamento.
- [ ] Estender com o que faltar pro aluno montar a tela.
- [ ] **Escopo:** o aluno só lê o trajeto de uma rota em que ele está. Teste: aluno de outra rota toma 403.
- [ ] Teste: trajeto não iniciado → estado "não começou", não erro.
- [ ] `./mvnw test`

---

### Task 8: Trajeto ao vivo — tela do admin

- [ ] Simplificar `trip_screen.dart`: próxima parada em destaque, um botão "Cheguei nesta parada", quantas faltam, encerrar.
- [ ] Sai da tela: mapa de edição, lista de inscritos, qualquer coisa que não seja a decisão do momento.
- [ ] Teste de widget: tocar no botão chama o checkpoint da **parada certa** (a atual, não a primeira).
- [ ] Teste: última parada → o botão vira "Encerrar trajeto".

---

### Task 9: Trajeto ao vivo — tela do aluno

- [ ] Botão "Acompanhar trajeto" no card da lista, **só quando o trajeto está em andamento**.
- [ ] Tela nova reaproveitando `RouteMap`: paradas como checklist (alcançadas marcadas, atual destacada) + polilinha real.
- [ ] Polling a cada 20s **enquanto a tela está aberta**. Cancelar no `dispose` — timer vivo depois de sair é vazamento e gasta bateria.
- [ ] Teste: trajeto parado → sem botão. Em andamento → com botão.
- [ ] Teste: a tela pede o estado ao abrir e de novo depois do intervalo.
- [ ] Teste: sair da tela **cancela** o polling. (Use `tester.pumpWidget` com outra tela e confirme que não há mais requisições.)

---

### Task 10: Tempo estimado na tela do aluno

Fecha o bloco.

- [ ] `RoadRouteService` passa a ler `duration` além da geometria — **já vem na mesma resposta**.
- [ ] Estimado = duração(parada atual → principal) + (paradas restantes × 1 min).
- [ ] Teste do cálculo, com o serviço mockado.
- [ ] Teste: OSRM sem resposta → a tela **omite** o tempo em vez de mostrar zero ou "—" enganoso.
- [ ] Mostrar na tela de acompanhamento.
- [ ] `flutter test --coverage && ./scripts/coverage-gate.sh`

---

### Task 11: Verificação no aparelho

Os testes não pegam layout nem fluxo. Esta task é olhar.

- [ ] Subir ambiente (`docker compose up -d`, `./run-local.sh`, emulador).
- [ ] **Perfil incompleto:** criar aluno sem telefone → o card mostra o que falta, sem botão de entrar. Preencher → botão volta.
- [ ] **Cabeçalho:** logar como `vitor@student.com` (nome longo) → só "Vítor", uma linha, ações alinhadas.
- [ ] **Painel do admin:** 8 cards na ordem nova, sem rolar, "Resumo de Hoje" à vista.
- [ ] **Parada:** criar uma tocando entre dois quarteirões → o pino se ajusta pra via.
- [ ] **Trajeto:** iniciar como admin, marcar uma parada; como aluno, abrir "Acompanhar trajeto" e ver a parada marcada e o tempo estimado.
- [ ] Tirar print de cada tela mexida e comparar com o estado anterior.

---

### Task 12: Documentação

- [ ] Atualizar `smartboarding-api/docs/spec.md` com a regra de perfil obrigatório (é RN nova).
- [ ] Atualizar a spec de tela do aluno em `smartboarding_app/docs/specs/aluno/`.
- [ ] `smartboarding_app/docs/PAGES.md`: registrar a tela de acompanhamento.
- [ ] Se o endereço virar estruturado, registrar a migration no spec do backend.
