# Spec — Notificações (Inbox + Envio)

> Telas: `NotificationsInboxScreen`, `SendNotificationScreen` · Acesso: inbox 🎓🧑‍💼, envio 🧑‍💼
> Provider: `NotificationProvider` · Base: [`../PAGES.md`](../../PAGES.md), [`../spec.md`](../../spec.md) §3.4.

## Objetivo

Histórico de notificações (aluno e admin) + envio manual pelo admin, com imagem opcional.

## Dados & contrato

- Inbox: `GET /api/notifications?page&size` — filtrado por escopo/rota do usuário logado.
- Envio: `POST /api/notifications/upload-image` (multipart, se houver imagem) →
  `{imageUrl}`, depois `POST /api/notifications {title, body, imageUrl?, scope, routeId?}`.

## Layout / seções

- Inbox: lista cronológica, cada item com título, corpo, imagem (se houver), rota (se
  `scope=ROUTE`), data.
- FAB estilo "compor" do Gmail (só visível pro `ADMIN`) → abre `SendNotificationScreen`: título,
  corpo, picker de imagem, seletor de escopo (geral ou uma rota específica), confirmação antes
  de enviar.

## Estados

- Inbox vazia, loading, erro de fetch.
- Envio: validação de campos obrigatórios, confirmação antes de disparar, feedback de sucesso.

## Regras aplicáveis

`spec.md` §3.4. Backend: RN19, RN20.

## Mural de avisos (visão do aluno)

O aluno vê a caixa como um **mural**: painel recuado em `AppColors.ashGrey` (a mesma superfície das
telas de autenticação) com uma malha de pontos desenhada em `CustomPainter`, e cada aviso num
cartão do design system preso por um alfinete — disco em `deepTeal` com anel branco. A metáfora
vem da malha e do alfinete; **cor, raio e tipografia saem dos tokens**, sem skin próprio.
A inclinação do bilhete é mínima (≈0,5°) e derivada do id do aviso, então o mesmo bilhete cai
sempre no mesmo ângulo. Avisos expirados usam fundo `background` e texto secundário.

**Admin e aluno veem o mesmo mural.** A diferença está no cartão: o admin ganha um ícone de apagar
no próprio bilhete (confirmação antes de sumir da caixa dos alunos) e o toque longo entra na
seleção múltipla, que é como se apaga em lote — o bilhete marcado fica com borda `deepTeal` e o
alfinete vira `danger`.

⚠️ Borda com cores diferentes por lado **não aceita `borderRadius`** no Flutter — descoberto quando
o mural ainda tinha moldura biselada, e pego pelo teste de widget antes de chegar na tela.
`test/widget/notice_board_test.dart` cobre render, texto longo, tela estreita e **a paleta**: se
alguém trouxer cor de fora do design system, o teste quebra.
