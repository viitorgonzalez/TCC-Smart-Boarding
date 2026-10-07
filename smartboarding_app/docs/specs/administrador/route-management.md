# Spec — Gerenciar Rotas

> Telas: `RouteListScreen`, `RouteFormScreen` · Acesso: 🧑‍💼
> Providers: `RouteProvider`, `InstitutionProvider`, `VehicleProvider`
> Base: [`../PAGES.md`](../../PAGES.md), [`../spec.md`](../../spec.md) §3.2.

## Objetivo

CRUD de rota, com as sub-entidades vinculadas (instituições, veículos, paradas) editáveis no
mesmo formulário.

## Dados & contrato

- Lista: `GET /api/routes` (ativas + inativas pro admin).
- Criar: `POST /api/routes {name, description?}`.
- `admitsNoInstitution`: rota aceita aluno que não declarou instituição no perfil. Nasce
  **desligada** — é exceção que o admin liga de propósito, não comportamento padrão.
- Editar: `PATCH /api/routes/{id} {name?, description?, admitsNoInstitution?}`.
  `admitsNoInstitution` nulo mantém o que já está gravado — a tela de dados básicos da rota não
  conhece essa chave, e mandar `false` dali desligaria a admissão sem instituição sem querer.
- Horário da lista: `PATCH /api/routes/{id}/schedule {openTime, closeTime, reason}` — endpoint
  separado porque exige motivo e avisa a rota (RN18/RN24).
- Desativar: `DELETE /api/routes/{id}` (soft-delete).
- Sub-seções do form: `CRUD /api/institutions` (com `routeId`), `CRUD /api/routes/{id}/vehicles`,
  `CRUD /api/routes/{id}/stops`.
- Lista do dia da rota: `GET /api/lists?date=<hoje>` (filtrada pelo `routeId`), `POST /api/lists`,
  `PATCH /api/lists/{id} {status, reason}`, `DELETE /api/lists/{id}`.
- Avisos automáticos: `CRUD /api/notifications/scheduled` (`?routeId=` no GET).

## Layout / seções

- `RouteListScreen`: lista rotas ativas e inativas. Recarregar (`RouteProvider.load`) só mostra o
  spinner de tela cheia na **primeira** carga — depois de criar/editar/apagar, a lista atual
  continua visível até os dados novos chegarem; trocar pra "carregando" a cada reload fazia a
  tela perder a posição do scroll toda vez que o admin voltava de uma edição. Cada linha também
  traz o resumo da lista de hoje daquela rota (status + contagem) — é o resumo que uma tela
  separada de listas dava antes de ser incorporado aqui; o estado da lista mora no subtítulo, não
  numa pílula à direita, porque a pílula disputava largura com o nome da rota e quebrava nomes
  longos ("Rota Universitária de Formiga") em duas linhas.
- `RouteFormScreen`: nome e descrição — formulário mínimo, só pra **criar** rota. Editar abre a
  tela completa (`RouteDetailScreen`), com paradas, frota e instituições. Cada seção secundária
  do detalhe (lista de hoje, avisos automáticos, instituições, veículos, paradas) vive na própria
  tela (`RouteSectionScreen` é a moldura comum) — empilhar as sete num scroll só fazia uma
  operação do dia a dia (a lista de hoje) ficar do mesmo tamanho visual que algo que só se mexe
  uma vez por semestre. Cada linha só constrói o conteúdo da seção **ao abrir** (não as seis de
  uma vez) — isso evitaria que a tela buscasse tudo de novo a cada volta. A seção some a própria
  barra de título quando já é uma tela inteira (`telaPropria`, ex.: Códigos de acesso); senão
  entra na moldura comum `RouteSectionScreen`, pra não empilhar dois títulos. No toggle "aceita
  aluno sem instituição" (dentro de Instituições atendidas), o switch salva direto, sem botão
  próprio — mas se a chamada falhar, o estado volta pro valor anterior (`rethrow` depois de
  reverter o `setState`): quem desenha o switch é quem precisa devolvê-lo, senão a tela mentiria
  sobre o que o servidor realmente guardou. A lista de alunos no detalhe é escopada por rota
  (`UserService.getUsers(routeId: ...)`), não a base inteira — ela cresce sem teto, e o detalhe
  só precisa de quem está ali. `GET /api/users` responde **paginado** (formato de página do
  Spring — `{content, number, totalPages}`), diferente de `/stops` e `/vehicles`, que respondem
  lista simples; tratar `/users` como lista simples também estoura um `TypeError` em runtime que
  cai no fallback genérico de erro, escondendo a causa real — já foi bug real neste repo. Sub-seções:
  - **Lista de hoje** — a rota tem no máximo uma lista por dia, então ela é gerenciada aqui e não
    numa tela separada: horário de abertura/fechamento (alterar exige motivo e avisa a rota),
    status, total de inscritos, divisão por instituição, atalho pros inscritos, abrir/fechar
    manualmente e apagar. O agendador cria a lista automaticamente no horário de abertura; o
    botão manual de criar existe pro admin cobrir data extra ou corrigir uma lista que não foi
    criada. Recarregar essa seção (depois de fechar/reabrir, mudar horário etc.) não troca o
    card por um esqueleto de novo, só na primeira carga — trocar a cada reload faria a seção
    piscar sem necessidade; o card novo substitui o atual em silêncio.
  - **Avisos automáticos** — aviso recorrente por rota (frequência `DAILY`/`WEEKDAYS`/`WEEKLY`,
    `dayOfWeek` 1=segunda…7=domingo só para `WEEKLY`, horário, validade), disparado pelo backend;
    pode ser pausado ou removido. O formulário de criação (`ScheduledNotificationForm`) vive em
    arquivo próprio porque a seção que lista só lista e alterna — criar é outro assunto, com seis
    campos e teclado — e abre num bottom sheet, não `AlertDialog`: o diálogo estourava a altura
    disponível com esse tanto de campo. No card de cada aviso, o título fica num `Expanded`
    porque texto longo sem isso empurrava as ações pra fora do cartão (bug já visto antes).
  - **Instituições vinculadas** (`RouteInstitutionsCard`) — só **escolhe** entre instituições já
    cadastradas no catálogo (`InstitutionProvider.unlinked`); cadastrar e editar é na tela de
    Instituições. Antes o caminho primário era cadastrar direto dentro da rota, o que espalhava o
    cadastro por dentro de cada rota e escondia a lista real do catálogo. Desvincular
    (`linkRoute(id, null)`) não apaga a instituição — ela volta pro catálogo, disponível pra
    outra rota. Junto da lista mora o switch "Aceitar aluno sem instituição"
    (`admitsNoInstitution`): a instituição é o que diz onde o aluno desce e em que contagem ele
    entra, então abrir mão disso é escolha deliberada do admin, e por isso a chave fica aqui, ao
    lado de quem a rota atende. O estado desse switch mora no próprio card (`_RouteInstitutionsCardState`),
    não na tela de detalhe: a seção é construída uma vez no push, então se o detalhe guardasse a
    chave e chamasse `setState`, esta subárvore não reconstruiria — a chave ficaria mostrando o
    valor de antes do próprio toque, mentindo sobre o que o servidor guardou. Se salvar falhar,
    o card devolve a chave pro valor anterior.
  - **Veículos disponíveis** — tipo + capacidade. A capacidade cadastrada é informação pro
    admin planejar, não um teto que o app aplica — o backend não bloqueia inscrição além da
    capacidade somada, só reporta o `capacityShortfall` (quantos ficam sem lugar) pro card
    avisar.
  - **Paradas/pontos no mapa** — nome + posição, com toggle "é ponto principal". Uma parada pode
    vincular uma instituição (`StopModel.institutionId`) — é dali que sai o "tempo até a sua
    instituição" de cada aluno (`MyTripTime`, ver spec de Início do Aluno). `sequence` posiciona
    a parada no trajeto empurrando as seguintes; nulo acrescenta no fim. Mover a parada
    (`updateStop`, coordenadas) e vincular/desvincular instituição (`setStopInstitution`) são
    chamadas **separadas** de propósito: o backend distingue "mover a parada" de "mexer no
    vínculo", porque mandar `institutionId: null` junto das coordenadas desvincularia a
    instituição só por arrastar o pino no mapa. Ao tocar o mapa pra criar uma parada,
    `RoadRouteService.snapToRoad` gruda o ponto na via mais próxima via OSRM (ver gotchas do
    OSRM no `CLAUDE.md` da raiz do repo) — o toque cai no meio do quarteirão ou no lado errado da
    rua, e sem o snap o **pino** ficava onde o dedo encostou enquanto o cálculo de trajeto (que já
    gruda internamente) seguia outro ponto: desenho e realidade divergiam, e o aluno via uma
    parada que não é onde o ônibus de fato encosta. Falha do OSRM aqui mantém o ponto do toque —
    parada no lugar aproximado é melhor que nenhuma parada.

### Editor de trajeto (`RouteStopsEditor`)

Mapa mais lista, com três ações por parada tocada no mapa: mover, inserir depois, ou (num menu
separado) renomear/vincular instituição/remover. O "modo pendente" (o que o próximo toque no
mapa significa) é estado só desta interação — fica no editor, não na tela da rota. O rótulo do
modo aparece sobreposto ao mapa (ex.: `Toque no novo local de "<parada>"`).

- O snap-to-road (`RoadRouteService.snapToRoad`) é aplicado **antes** de decidir qual das três
  ações (criar, mover, inserir) está em curso — as três nascem do mesmo ponto tocado, então
  corrigir o ponto uma vez só, nesse lugar único, cobre as três.
- O menu de ações de uma parada (bottom sheet) é rolável: numa tela baixa, sem rolagem a última
  ação cortaria — e a última é "Remover". "Instituição atendida" só aparece no menu quando a
  rota tem instituições vinculadas (`widget.institutions`); oferecer essa escolha sem opção
  nenhuma seria um beco. Remover a parada não tem botão na lista principal (só o menu que abre
  no toque) — repetir ali poria uma ação destrutiva em vermelho no meio da lista.
- Vincular instituição (`_escolherInstituicao`) é o que faz a parada aceitar checkpoint no
  trajeto (RN23) e o que permite calcular o tempo até ela pra cada aluno. **Histórico:** até uma
  versão anterior (V32) esse vínculo era adivinhado pelo **nome** da parada — renomear a parada
  quebrava o vínculo em silêncio, e uma parada criada pelo app nunca virava ponto principal —
o trajeto recusava todo checkpoint nela com `STOP_NOT_MAIN_POINT`. A
  resposta desse seletor embrulha o id (`_EscolhaInstituicao`) porque `null` também é resposta
  válida (é como se desfaz o vínculo) — devolver `null` puro do bottom sheet confundiria
  "escolheu nenhuma" com "fechou sem escolher".

## Estados

- Nome de rota duplicado → erro de conflito.
- Segunda lista pra mesma rota e data → `409 LIST_ALREADY_EXISTS`.
- Abrir/fechar a lista na mão exige confirmação com motivo (`400 REASON_REQUIRED` sem ele); o texto
  vira o aviso enviado a todos da rota.
- Apagar lista que já tem relatório → recusado (RN8).
- Instituição já vinculada a outra rota ativa → erro de conflito.
- Editar qualquer campo da rota dispara a notificação automática de mudança de regra (§3.4 do
  `spec.md`) — sem passo extra na UI, é automático ao salvar.

## Catálogo de instituições (`InstitutionsScreen`, `InstitutionProvider`)

Instituição não pertence a rota nenhuma por natureza — ela é cadastrada uma vez (separado do
form de rota) e só depois é atendida por uma rota, ou por nenhuma enquanto não houver transporte
pra lá:

- `InstitutionProvider.unlinked` (instituições sem `routeId`) é a lista que a tela de rota
  oferece pra vincular — mostrar as que já estão vinculadas convidaria a tirar uma instituição de
  outra rota sem que ninguém percebesse.
- Desvincular (`linkRoute` com `routeId: null`) e vincular de novo são operações separadas: o
  backend recusa trocar de rota ativa direto, sem desvincular antes (RN15).
- Remover uma instituição é recusado pelo backend se houver aluno vinculado a ela (a rota dele
  sai de onde vem). No catálogo, "Sem rota atendendo" aparece em vermelho com um indicador: sem
  rota, o aluno dessa instituição não enxerga lista nenhuma, e dizer isso evita o mistério de
  "por que não aparece nada pra mim".
- No formulário de instituição, endereço vazio é salvo como `null`, nunca string vazia — `""` no
  banco apareceria como campo em branco na tela, indistinguível de "não informado".

## Regras aplicáveis

`spec.md` §3.2. Backend: RN9, RN15, RN16, RN18, RN19, RN23 (paradas/pontos principais).
