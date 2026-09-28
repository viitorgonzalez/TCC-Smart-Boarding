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

### Task 1: Endereço estruturado — backend ✅

Base de tudo: a carteirinha mostra rua/bairro/número, e esses campos não existem ainda.

> **Escopo ajustado durante a execução.** A Task 1 absorveu "o endereço sai da fila de
> aprovação", que estava na Task 3. Motivo: sem caminho de escrita as colunas novas nunca se
> preenchem, e o único caminho que existia era a fila do admin. Deixar os dois no ar faria uma
> aprovação escrever em `address_legacy` — coluna que nada lê. A Task 3 fica só com `phone`/
> `course` e a regra do `AddEntryUseCase`.

- [x] Migration `V31__structured_address.sql`: `zip_code`, `street`, `neighborhood`, `city`,
      `state`, `street_number`, `complement` em `users`.
- [x] **Renomeia** `address` → `address_legacy` em vez de dropar.
- [x] `Address` como `@Embeddable` em vez de 7 campos soltos no `User` — dá casa natural pro
      `isComplete()` e pro `shortForm()` da carteirinha, e evita duas versões da mesma linha
      (uma em Java, outra em Dart).
- [x] `shortForm()` (rua, número — bairro) e `fullForm()` (com cidade e CEP, pro admin).
      14 testes em `AddressTest`, incluindo o que prova que o CEP **não** vaza no `shortForm`.
- [x] `PUT /api/me/address` — salva direto, sem aprovação. É o que torna as colunas preenchíveis.
- [x] Endereço sai de `ProfileUpdateRequestDto` e do `approve()`. Pedido aberto **antes** disso
      ainda cai em `address_legacy` em vez de sumir calado.
- [x] `AddressResponse` em `MeResponse`, `UserResponse` e `StudentProfileResponse`.
- [x] Salvar incompleto é permitido de propósito: quem cobra completude é a entrada na lista,
      num lugar só.
- [x] Mutação: 5 mutações (checagem do CEP, `limpo()`, UF, formato do CEP, id do dono) mataram
      **exatamente** os testes certos.
- [x] `./mvnw verify` — 546 unit + 3 IT verdes, `ProductionMigrationsIT` incluso.

---

### Task 2: Endereço por CEP — app ✅

- [x] `CepService` consumindo `https://viacep.com.br/ws/{cep}/json/`. Sem chave.
- [x] **Cliente HTTP próprio, nunca o `DioClient`.** Aquele injeta o Bearer da sessão em toda
      requisição — reaproveitá-lo entregaria o token do aluno a um host de terceiro. Há teste
      pra isso, e ele morre se alguém trocar pelo cliente autenticado.
- [x] `null` em erro, timeout, corpo vazio **e** no `{"erro": true}` que vem com **HTTP 200**.
      Trata o campo como booleano **e** como string — já veio das duas formas.
- [x] CEP com menos de 8 dígitos nem chega a consultar: o campo consulta enquanto se digita, e
      seria um request por tecla.
- [x] `AddressCard` com card e botão próprios, fora do formulário de aprovação — duas semânticas
      de salvar num botão só fariam o aluno não saber o que já valeu.
- [x] Campos vindos do CEP continuam **editáveis**, e CEP que falha **não apaga** o que já foi
      digitado à mão (o teste que prova isso digita antes e consulta depois — a ordem é o ponto).
- [x] Foco pula pro "número" depois do preenchimento.
- [x] Aviso nomeando o que falta, e `AppTextField` ganhou `inputFormatters`/`focusNode`
      (máscara de CEP e o pulo de foco).
- [x] Mutação: 5 mutações no card + 4 no serviço. **Uma sobreviveu** e expôs teste vacuoso —
      `textContaining('Bairro')` casava com o rótulo do campo, não com o aviso. Corrigido pra
      asserção no key do aviso; agora mata.
- [x] 237 testes verdes, `coverage-gate.sh` exit 0, `flutter analyze` limpo.

---

### Task 3: Perfil completo como pré-requisito da lista ✅

Backend. A regra mora no use case porque só no app seria decorativa.

- [x] `PUT /me/profile` salva `phone` e `course` **direto**. Com o endereço (Task 1), a fila de
      aprovação ficou só com o que decide em qual transporte a pessoa entra: nome e instituição.
- [x] `User.missingForList()` no domínio, devolvendo a lista **toda de uma vez** — a mensagem
      genérica faria o aluno descobrir por tentativa, um campo por viagem perdida.
- [x] `AppException` ganhou `details`, e o handler o despeja no mesmo nível de `code`/`error`.
      Mecanismo geral, não gambiarra pra um erro só.
- [x] A regra em `ListUseCaseImpl.add`, **só pra quem ainda não está na lista**: quem já entrou o
      fez quando era permitido, e barrar ali expulsaria quem só troca ida por volta.
- [x] Admin não passa pela trava (ele não entra em lista).
- [x] Teste em `WarningUseCaseImplTest` travando que `/entries/admin` **não** herda a regra —
      inclusão tardia é justamente pra quem tem cadastro pela metade.
- [x] App: `OwnDataCard` (telefone + curso) com botão próprio; o formulário de aprovação ficou
      só com o nome.
- [x] Mutação: 4 no use case + 4 no card. **Uma sobreviveu** — admin com `course` herdado de
      quando era aluno reenviaria o campo. Teste novo, e agora mata.
- [x] `./mvnw verify` (572 unit + 3 IT) e 244 testes no app, gate exit 0, analyze limpo.

**Descoberto ao rodar:** o `stubList` do `ListUseCaseImplTest` montava um aluno sem perfil
nenhum, então a regra nova quebrou dois testes de **horário**. Dei perfil completo ao aluno do
stub — sem isso, todo teste de horário passaria a falhar por um motivo que não é o dele.

---

### Task 4: O app avisa antes de esbarrar ✅

App. Nunca deixe o aluno descobrir o bloqueio só ao tocar no botão.

- [x] `/me` passou a devolver `missingForList`. O app **não** refaz a conta: quem recusa a
      entrada é o backend, e duas versões da regra divergiriam na primeira mudança.
- [x] `MeProvider` compartilhado — o card da lista e a tela de perfil leem o mesmo dado.
- [x] Perfil incompleto → o botão "Entrar na lista" dá lugar a um bloco nomeando o que falta,
      com atalho pro perfil que recarrega o `/me` na volta.
- [x] **Quem já está na lista mantém o "Sair"**: entrou quando era permitido, e escondê-lo por
      um campo em branco o prenderia numa viagem que ele não vai fazer.
- [x] `ProfileScreen` passou a ler do `MeProvider` em vez de um `/me` próprio. Com duas cópias,
      salvar pelo cabeçalho deixaria o aviso do card mentindo até a próxima abertura da tela.
- [x] `my_route_screen` mostrava `e.toString()` cru — um `DioException` aparecia como
      "DioException [bad response]..." na cara do aluno. Agora usa `AppException.fromError`.
- [x] Mutação: 4 mutações, 4 alvos certos.
- [x] 249 testes no app, gate exit 0, analyze limpo; API 573 unit + 3 IT.

**Teste meu que estava errado:** o primeiro montava a lista com `closeTime: '16:00'`. Como
`acceptsChanges` compara com o relógio, o card sumia inteiro depois das 16h — o teste passaria de
manhã e falharia à noite. Agora monta sem `closeTime`.

---

### Task 5: Carteirinha de estudante virtual ✅

Feature nova. Depende da Task 1 (rua/bairro/número).

- [x] Tela nova, alcançável do perfil — **só pro aluno**: quem administra não tem vínculo de estudante a atestar.
- [x] Mostra: nome completo, instituição, curso, e **só rua, bairro e número** do endereço.
      Sem CEP, sem cidade/UF — não identificam ninguém numa conferência e CEP é dado que não
      precisa circular numa tela que se mostra pra outra pessoa.
- [x] Avatar por iniciais (padrão já usado no app). **Sem foto** — não há campo em `users`, e
      adicionar significa upload, storage e moderação: é outra frente.
- [x] Validade = estar ativo e vinculado a uma rota. **Não** usar `users.expiry_date`: ela
      alimenta `isAccountNonExpired()` do Spring Security, e preenchê-la com validade de
      carteirinha faria o aluno **perder o login** no dia em que ela vencesse.
- [x] Rodapé dizendo que **não é documento oficial** nem prova de matrícula — o app sabe o que o
      aluno declarou, não valida vínculo com a instituição. Sem isso vira documento com aparência
      de oficial que ninguém auditou.
- [x] Perfil incompleto → mostra o que falta em vez de campos vazios.
- [x] Aluno sem rota → "sem vínculo ativo", não carteirinha em branco.
- [x] Teste provando que CEP, cidade **e e-mail** não aparecem.
- [x] `/me` passou a devolver o **nome** da instituição — resolver o id no app obrigaria a tela
      a baixar o catálogo inteiro pra escrever uma linha.
- [x] Mutação: 5 mutações, 5 alvos certos (inclusive a que vaza o CEP).
- [x] `docs/PAGES.md` + `docs/specs/aluno/student-card.md`.
- [x] 257 testes no app, gate exit 0; API 573 unit + 3 IT.

---

### Task 6: Cabeçalho do aluno ✅

App, só visual. Independente.

- [x] `primeiroNome()` em `core/text/names.dart`, com os casos que quebram: nome de uma palavra,
      espaço sobrando nas pontas e no meio, vazio e nulo.
- [x] `HeaderOverflowMenu` (⋮) com perfil e sair; só "entrar com código" fica à vista — é a
      única ação do dia a dia.
- [x] Teste: as ações ficam escondidas até abrir o menu, e as duas são alcançáveis lá dentro.
- [x] `flutter test` + `flutter analyze` limpos.

---

### Task 7: Ordem dos cards do admin ✅

App, só visual. Independente.

- [x] Ordem nova: Rotas/Enviar Aviso · Relatórios/Advertências · Usuários/Avisos enviados ·
      Códigos/Instituições. Faixas de propósito: operação do dia, acompanhamento, gestão de
      gente, configuração.
- [x] Comentário no código registrando **por que** essa ordem — a anterior nasceu por acaso, na
      sequência em que as telas foram surgindo.
- [x] Sem teste novo (é ordem visual); os 265 testes existentes seguem verdes.

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

### Task 9: Parada ↔ instituição — **corrige um bug vivo** ✅

Backend. Não é só o que destrava "tempo até a sua instituição": é conserto.

> **O bug.** Nada em `src/main/java` escreve `is_main_point` — `CreateStopRequest` não tem o
> campo, `add()` deixa no default `false`, `update()` não o toca, e
> `grep -rn "setMainPoint" src/main/java` não devolve nada. Só a migration V20 populou, uma vez.
> Como `TripUseCaseImpl.checkpoint` recusa parada que não seja ponto principal, **toda rota
> criada depois da V20 não consegue marcar parada nenhuma** — o trajeto inicia e todo toque
> devolve `STOP_NOT_MAIN_POINT`. Fazer as telas novas (Tasks 12–14) sem isto seria entregar um
> botão que só dá erro.

- [x] **Reproduzido primeiro:** teste em `StopUseCaseImplTest` que falhava — parada criada com
      instituição não virava ponto principal (o método nem existia).
- [x] `StopControllerTest`: o `institutionId` do corpo chega no use case e volta na resposta.
- [x] Migration `V32__stop_institution.sql`:
- [x] Populada pelo mesmo `LIKE` da V20
- [x] `Stop.refreshMainPoint()`: quem serve instituição é sempre principal; o resto depende do
      que o admin marcou — a rodoviária é ponto principal sem ser instituição nenhuma.
- [x] `CreateStopRequest`/`UpdateStopRequest` ganham `institutionId` e `mainPoint`; `add()` e a
      sobrecarga de `update()` gravam. **É a linha que conserta o bug.**
- [x] Teste: renomear **não** desfaz o vínculo.
- [x] Teste: parada comum segue sem virar ponto principal — a RN23 continua valendo.
- [x] "Instituição atendida" no menu da parada, no app. Some quando a rota não tem instituição:
      oferecer escolha sem opção é um beco.
- [x] `institutionId` e `isMainPoint` em `StopResponse` e no `StopModel` do app.
- [x] **Dado existente:** a migration **não** tenta adivinhar o que o `LIKE` errou ("Campus
      Unifor" × "UNIFOR-MG — Formiga") — adivinhar é exatamente o que ela existe pra parar de
      fazer. Está comentado no SQL e entra na verificação no aparelho.
- [x] `./mvnw verify` — 582 unit + 3 IT; app com 275 testes e gate exit 0.
- [x] Migration `V33__stop_avg_minutes.sql`: `stops.avg_minutes_from_start`, **por parada**
- [x] `RoutePlannerPort` + `OsrmRoutePlannerAdapter` (RestClient), com `GeoPoint` no domínio pra
      a porta não falar em `Stop`.
- [x] `duration` do OSRM + **1 min por parada** (embarque). 3 paradas, 600s → 13 min.
- [x] Recalcula a cada escrita de parada, em `try/catch`: o OSRM não tem SLA, e o admin criou a
      parada — serviço externo fora não pode desfazer isso.
- [x] 6 testes do cálculo + 5 do adapter. Mutação: 5 mutações, 5 alvos certos.
- [x] OSRM indisponível **ou resposta truncada** → nulo. Completar com zero daria um tempo que
      parece certo e não é.
- [x] `./mvnw verify` — 595 unit + 3 IT.
- [x] **`/api/trip/**` inteiro era `hasRole("ADMIN")`** — o aluno não lia nada. O GET passou a
      aceitar qualquer autenticado; conduzir (start/checkpoint/finish) segue do admin (RN23).
- [x] `myStop` na resposta: a parada com `institution_id` = a instituição declarada dele.
- [x] Aluno com duas instituições → vale a **principal** (`user.institutionId`), a mesma que já
      decide em que contagem ele entra. Uma regra só no app inteiro.
- [x] Instituição sem parada → devolve a última **com `fallback: true`**, pra tela avisar.
- [x] **O ETA não chama o OSRM.** Sai da diferença entre os `avg_minutes_from_start` já
      calculados: parada dele menos a última alcançada. Bater no OSRM por consulta seria uma
      requisição por aluno a cada 20s, e o resultado seria o mesmo número.
- [x] **Escopo:** aluno de outra rota toma 403 — sem isso, abrir a leitura deixaria qualquer um
      ler o trajeto de qualquer rota.
- [x] Admin não tem `myStop`: quem conduz o ônibus não viaja nele.
- [x] Mutação: 6 mutações. **Uma sobreviveu** — faltava o caso do admin pular um checkpoint,
      que dava `-7 min` na tela. Teste novo, e agora mata.
- [x] `./mvnw verify` — 596 unit + 3 IT.
> **Já estava feito.** A task #63 ("Simplificar o modo conduzir trajeto") entregou isto antes:
> próxima parada em `headlineSmall`, um botão `Cheguei aqui` de 56px, quantas faltam no
> `TripProgressCard`, e nem mapa de edição nem lista de inscritos na tela. Só faltavam os testes.
>
> **Não fiz** "última parada → o botão vira Encerrar": ela é uma chegada como as outras, e trocar
> o botão perderia o registro de que o ônibus chegou lá. Encerrar é o passo seguinte, não o mesmo.

- [x] Simplificar `trip_screen.dart`: próxima parada em destaque, um botão "Cheguei nesta
      parada", quantas faltam, encerrar.
- [x] Sai da tela: mapa de edição, lista de inscritos, qualquer coisa que não seja a decisão do
      momento. Quem conduz não navega o app — toca uma vez por parada.
- [x] Teste: `trip.current` é a primeira **não alcançada** — se fosse a primeira da lista, o admin
      marcaria a rodoviária de novo a cada toque e o trajeto nunca sairia dela. (a atual, não a
      primeira).
- [x] Teste: a última parada **mantém** o botão de marcar.

---

### Task 13: Trajeto ao vivo — tela do aluno ✅

- [x] Botão "Acompanhar trajeto" no card, só com `tripInProgress` — que passou a vir no
      `ListResponse` (oferecer sempre levaria a uma tela que só diz "não começou").
- [x] `TripFollowScreen` com as paradas como checklist e a **parada dele destacada**.
- [x] `TripStepTile` ganhou `highlighted`.
- [x] Polling de 20s cancelado no `dispose` — timer vivo depois de sair gasta bateria de quem
      está no ônibus justamente quando ela importa. Falha de polling **não** apaga o que já está
      na tela.
- [x] Testes: sem botão parado, com botão em andamento, e o botão leva pra tela.
- [x] Testes: pede ao abrir e de novo depois do intervalo.
- [x] Teste: sair cancela o polling.
- [x] 290 testes no app, gate exit 0, analyze limpo.
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

### Task 15: Verificação no aparelho ✅

Feita no emulador Pixel 9, com a API local, **em debug e em release**.

- [x] **CEP:** digitar `35574-018` preencheu rua, bairro, cidade e UF, e o foco pulou pro número.
- [x] **CEP inexistente:** `35570-000` **não** preencheu nada e **não** apagou nada — o ViaCEP
      devolve `{"erro": "true"}` com HTTP 200, e a string (não o booleano) é o caso tratado.
      Confirmado contra o serviço real.
- [x] **Perfil incompleto:** o aviso nomeia os campos e encolhe conforme se preenche.
- [x] **Carteirinha:** "Rua Newton Garcia Cunha, 4328 — Novo Santo Antônio". Sem CEP, sem
      cidade, com o rodapé de "não é documento oficial".
- [x] **Cabeçalho:** "Fernanda" (só o primeiro nome), um botão de ação e o menu ⋮ com perfil e
      sair.
- [x] **Login com Google** presente (com o `--dart-define`; sem ele o botão se esconde, que é o
      certo — um botão de Google sem client id só daria erro).
- [x] **Trajeto e ETA:** verificados pela API (ver Task 11/14) — dois alunos, 42 e 47 min.

**Bug encontrado aqui, e corrigido:** o aviso do endereço só reconstruía no listener do CEP.
Quem digitava o número à mão continuava vendo "Falta preencher: Número" em vermelho e concluía
que o app estava quebrado. Os campos que alimentam o aviso ganharam listener; dois testes novos,
e a mutação que remove os listeners os mata.

> ### ⚠️ A borda verde-limão — eu estava errado
>
> Em sessão anterior afirmei que era "ferramenta de debug do Flutter, não defeito". **Não é.**
> Medido agora, no mesmo aparelho:
>
> - Cor `#A9D32A`, ~2px, nos **quatro** lados (em cima fica escurecida pelo header)
> - **Presente também no build de release** — logo, não é debug tooling
> - **Ausente** na home do Android e em Ajustes → é a janela do app, não o sistema
> - **Intermitente**: aparece e some entre capturas com segundos de diferença, sem relação com
>   a tela, com scroll, com acessibilidade ou com número de sessões de debug
> - **Não existe no código Dart**: nada em `lib/` pinta essa cor nem desenha borda de tela cheia
>
> Fica em aberto, com os dados acima. O que eu tinha como conclusão era hipótese não verificada.

---

### Task 16: Documentação ✅

- [x] `smartboarding-api/docs/spec.md`: **RN29–RN35** — perfil completo pra entrar na lista,
      `stops.institution_id`, `avg_minutes_from_start`, o aluno lendo o trajeto, endereço
      estruturado, o que sai da fila de aprovação, e a carteirinha.
- [x] **RN12 reconciliada:** ela diz que `users.expiry_date` é a validade da carteirinha física.
      Eu havia documentado essa coluna como "expiração de conta, não validade de carteirinha" —
      impreciso. O efeito que descrevi como risco (bloquear o login) é o comportamento
      **pretendido** pela RN12. A decisão prática não muda: a carteirinha virtual não escreve
      nela, e não carrega data própria, porque uma segunda validade criaria duas verdades.
- [x] `smartboarding_app/docs/specs/aluno/trip-follow.md` + `student-card.md`, e `PAGES.md`.
- [x] `smartboarding_app/docs/spec.md`: perfil, CEP e onde cada campo salva.
- [x] `TCC-Smart-Boarding/CLAUDE.md`: seção de serviços externos sem SLA, com as três armadilhas
      (o `erro` string do ViaCEP, o Dio próprio, e o `longitude,latitude` não-encodado do OSRM).
