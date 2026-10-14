# Spec — Trajeto

> Tela: `TripScreen` (dentro do painel do admin) · Acesso: 🧑‍💼 · Provider: `TripProvider`
> Base: [`../PAGES.md`](../../PAGES.md), [`../spec.md`](../../spec.md) §3.8.

## Objetivo

Admin conduz o trajeto do dia: inicia, passa por pontos principais, finaliza — cada ação avisa
os inscritos ativos por push.

## Dados & contrato

- Entrada pela tela da rota, na seção "Lista de hoje" (botão *Conduzir trajeto*).
- `GET /api/trip/{listId}` — estado atual, com os pontos principais e quais já foram marcados.
- `POST /api/trip/{listId}/start` — iniciar.
- `POST /api/trip/{listId}/checkpoint/{stopId}` — checkpoint (só aceito em pontos com
  `isMainPoint=true`).
- `POST /api/trip/{listId}/finish` — finalizar.

## Layout / seções

- Cartão com a rota do trajeto selecionado.
- Botão "Iniciar trajeto".
- Um botão de checkpoint por ponto principal da rota (rodoviária + instituições) — paradas
  comuns não aparecem aqui, só no mapa. Só o **primeiro ponto ainda não alcançado**
  (`TripStatus.current`) ganha botão ativo, um "Marcar" por vez, como no desenho — os demais
  ficam sem ação até a vez deles chegar.
- `TripStatus.leg` (`OUTBOUND`/`RETURN`) só rotula: a API já manda as paradas na ordem certa de
  cada perna, o app não reordena.
- Botão "Finalizar".

## Estados

- Iniciar e finalizar pedem confirmação, porque disparam aviso pra rota inteira e não têm
  volta. **Marcar chegada não pede** — uma confirmação por parada transformaria o uso normal
  numa sequência de diálogos; o risco de toque acidental é resolvido pelo desenho (botão grande
  e único na tela, não um link pequeno no meio de uma lista), não por confirmação.
- A **última** parada continua usando o botão de marcar chegada ("Cheguei aqui"), nunca um botão
  de "Encerrar" no lugar: ela é uma chegada como as outras, e trocar o botão ali perderia o
  registro de que o ônibus de fato chegou nesse ponto. Encerrar o trajeto é o passo seguinte,
  separado, não o mesmo gesto.
- Enquanto uma ação está em voo (`TripProvider.busy`), novas ações ficam bloqueadas: sem a trava,
  um duplo toque em "Marcar" virava dois checkpoints, e o segundo morria em erro na cara de quem
  está dirigindo.
- Em andamento sem parada atual (todas marcadas) mostra aviso explícito — sem ele, o botão
  "sumindo" pareceria trava em vez de trajeto completo.
- Finalizar **não bloqueia** por paradas pendentes: o ônibus pode legitimamente pular uma parada
  (ninguém esperando), e travar o encerramento deixaria o admin preso no fim do dia. Mas a
  confirmação lista as paradas não marcadas antes de decidir — pode ter sido esquecimento, e elas
  ficam registradas como "não visitadas".
- Na volta (`TripStatus.onReturn`), a lista de paradas abaixo do progresso aparece na ordem da
  perna de volta — o rótulo do cabeçalho ("Volta em andamento" vs. "Ida em andamento") existe
  pra evitar a dúvida de "por que as paradas inverteram?".
- A lista de paradas é só leitura — a única ação (marcar chegada) mora no card de próxima parada,
  um alvo só na tela. O horário de cada parada já marcada fica visível pra permitir conferir o
  ritmo do trajeto depois.
- Feedback pós-ação: "Notificação enviada para N alunos".
- Funciona com a lista `OPEN` ou `CLOSED` — o trajeto acontece depois do fechamento.

## Regras aplicáveis

`spec.md` §3.4, §3.8. Backend: RN20, RN23.
