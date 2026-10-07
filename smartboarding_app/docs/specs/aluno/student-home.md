# Spec — Início do Aluno

> Tela: `StudentHomeScreen` · Acesso: 🎓 · Provider: `ListProvider`
> Base: [`../PAGES.md`](../../PAGES.md), [`../spec.md`](../../spec.md) §3.2, §3.3.

## Objetivo

Tela principal do aluno: lista do dia da própria rota, mapa, entrar/sair.

## Dados & contrato

- Carrega `GET /api/lists/today` ao abrir + pull-to-refresh — já filtrado pela rota derivada da
  instituição do aluno (o aluno nunca escolhe rota).
- `POST /api/lists/{id}/entries {tripType?}` — entrar (default `ROUND_TRIP`).
- `DELETE /api/lists/{id}/entries` — sair.

## Layout / seções

- Card da rota: nome, contagem de inscritos, status, mapa (`google_maps_flutter`, pontos da
  rota — paradas e pontos principais, com ícone).
- Botão "Entrar na Lista" (não inscrito, lista `OPEN`) ou "Sair da Lista" + badge "Você está na
  lista" (inscrito).
- Acesso à tela de notificações e à tela de relatórios (últimos 7 dias).

## Estados

- Sem lista `OPEN` → mensagem explicativa com o horário real de fechamento **daquela rota**.
- Loading, erro de fetch, sucesso.
- `403 ACCOUNT_EXPIRED` ao entrar na lista → mensagem dedicada de carteirinha expirada.
- Sem rota nenhuma (`MembershipProvider.hasNoRoute`): mostra `NoRouteCard` em vez do status do
  dia — sem rota não há lista, aviso nem trajeto, então mostrar o status aqui seria anunciar
  vazio sem dizer por quê.
- No painel de status (`_TodayStatus`), o caso "lista fechada e sem inscrição" precisa vir
  **antes** do caso genérico "ainda não entrou" no `switch`: sem inscrição e lista fechada não há
  ação possível, então "ainda não entrou" sugeriria uma ação que não existe mais — e, por ser
  genérico, o caso teria casado primeiro se viesse antes.

## Minhas rotas (`MyRoutesScreen`) e lista do dia (`MyRouteScreen`)

- O gesto de "entrar com código" é o do Google Classroom: as rotas de que o aluno já participa,
  com a porta pra entrar em mais uma sempre visível junto delas (tanto na tela "Minhas rotas"
  quanto fixa no cabeçalho da home) — entrar em mais uma rota é ação normal, não estado de
  excessão, e por isso a ação mora onde a pessoa já vem procurar, não escondida noutro canto.
- Ao abrir a lista do dia de uma rota específica, `MembershipProvider.select(routeId)` é chamado
  antes de navegar — sem isso, quem está em mais de uma rota abriria a lista da rota errada.
  Com várias rotas, a home mostra uma por vez em foco (`selectedId`); `RouteSelector` (os chips
  pra trocar entre elas) só aparece com duas ou mais — com uma só, um seletor de um item é
  ruído: ocupa espaço e não oferece escolha nenhuma. A porta pra entrar em outra rota
  (`student_home_join_route`, no cabeçalho) é separada do `RouteSelector` e do `NoRouteCard` de
  propósito: já foi bug real ter só essas duas portas, porque com exatamente **uma** rota nem o
  `NoRouteCard` aparece (ele é só do estado vazio) nem o chip "Outra rota" do seletor (ele pede
  duas ou mais) — o aluno com uma única rota ficava sem nenhuma porta pro código. Se a rota em foco sumir (o aluno saiu dela)
  o foco não pode continuar nela, senão a home ficaria pedindo dado de uma rota que ele não tem
  mais — `MembershipProvider.load` zera `selectedId` nesse caso. Entrar com código
  (`MembershipProvider.join`) também põe a rota nova em foco — entrar é um ato deliberado, e
  deixar o foco na rota antiga faria o aluno achar que o código não funcionou. Falha ao carregar
  as rotas não é reportada como "sem rota" (`hasNoRoute` continua `false` no erro): mostrar
  "entre com código" quando na verdade a rede caiu mandaria o aluno resolver o problema errado.
- Ao voltar da tela de perfil (fluxo "complete o perfil pra entrar na lista"), `MyRouteScreen`
  recarrega `/me`: quem foi preencher o que faltava precisa ver o botão de entrar liberado sem
  fechar e reabrir a tela.
- Card de veículo (`ProposedVehicle`, dentro de `StudentListCard`): com a lista `OPEN`, o
  veículo exibido é **previsão** ("TRANSPORTE PREVISTO") e muda conforme entra e sai gente;
  só com a lista fechada (RN16) ele vira **definido** ("TRANSPORTE DEFINIDO") — dizer
  "definido" antes da hora seria uma promessa que o app não pode cumprir. Com zero veículo
  confirmado mas também zero passageiro (`shortfall == 0`), o texto é "ainda sem passageiros
  confirmados", não "nenhum veículo disponível": a frota não falta, simplesmente não foi
  necessária ainda.
- `StudentListCard.missingProfile` chega pronto (já em português) de fora do widget: quem decide
  o que falta no perfil é o backend — ele é que recusa a entrada na lista, e refazer essa conta
  no app criaria duas versões da mesma regra. O aviso de perfil incompleto (`_ProfileWarning`)
  aparece no lugar do botão de entrar, não como erro depois do toque — descobrir o bloqueio
  batendo de cara com ele é o que esse aviso existe pra evitar. Quem já está inscrito não vê
  esse aviso mesmo com perfil incompleto: ele entrou quando era permitido, e esconder o botão
  "Sair" por um campo em branco o prenderia numa viagem que não vai fazer.
- "Quem está na lista" (`showListMembers`) é visível a qualquer aluno da lista, mas
  `ListEntry.email` vem nulo quando quem pediu a lista não é admin: o aluno vê quem embarca
  junto, mas não o contato de ninguém. Pedir a lista enquanto o provider ainda não carregou o
  e-mail do usuário (`StudentListProvider.load`) devolve erro explícito em vez de ficar calado —
  sair em silêncio deixava a tela girando pra sempre.
- `onFollowTrip` (botão "Acompanhar trajeto") só aparece com o ônibus de fato na rua
  (`list.tripInProgress`) — oferecer sempre levaria a uma tela que só diz "não começou".
- O rótulo de horário vira "Fechou às" (não "Fecha às") quando a lista já não aceita mudanças —
  com a lista fechada, "fecha às" descreveria um futuro que não existe mais.
- O veículo recomendado (`ProposedVehicle`) mostra sempre o veículo certo pro total atual de
  confirmados, nunca a frota inteira disponível na rota: listar "Ônibus (45)" e "Van (15)" lado
  a lado faria o aluno adivinhar em qual dos dois ele realmente vai.
- O tempo estimado de viagem (`_TempoDeViagem`) fica logo abaixo da prévia do trajeto, de
  propósito: o mapa mostra o caminho, e a pergunta seguinte de quem olha é sempre "quanto tempo
  isso leva pra mim". O destino vem nomeado no texto porque dois alunos do mesmo ônibus veem
  números diferentes (cada um até a própria instituição) — sem dizer até onde, quem compara com
  o colega concluiria que o app está errado. `myTripTime` vem nulo pro admin (o cálculo é por
  aluno) e também enquanto o tempo ainda não foi calculado.

## Regras aplicáveis

`spec.md` §3.2, §3.3, §3.6. Backend: RN1-RN7, RN12, RN15.
