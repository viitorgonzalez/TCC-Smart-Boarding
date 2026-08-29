# Prompt de design — Inbox de notificações (TCC-Smart-Boarding / smartboarding_app)
> Status: **rascunho** · Arquétipo: list · Precedente: arquétipo genérico (tela nova, sem precedente de código)
> Tokens: `lib/core/theme/app_theme.dart` · Contrato: `smartboarding_app/docs/specs/notificacoes/notifications.md` (planejado)
> Gaps ⛳: **100% especulativo** — não existe entidade `Notification` persistida nem `GET /api/notifications` no backend. Notificações hoje são "dispara e esquece" via FCM, sem histórico.
> Caracteres: 2112 (inclui espaços) · Limite: não confirmado (uxpilot free) — se precisar cortar, tire o bloco mais especulativo primeiro

## Prompt (colar na IA de layout)
```
Pagina — Smart Boarding — inbox de notificacoes, historico do que ja foi avisado — aluno ou administrador conferindo os avisos recentes — faixa de celular pequena a grande, retrato.

CONTEXTO & PROPOSITO:
- Lugar pra rever o que ja foi avisado: lista aberta, lista fechada, aviso do administrador — tudo num so lugar, em ordem cronologica.

SENTIMENTO & EXPERIENCIA:
- Organizacao tranquila: uma linha do tempo simples de acompanhar, sem ansiedade de perder um aviso importante.

TEMA & TOKENS:
- Hex reais: fundo claro #CAD2C5, verde geral #84A98C, verde principal/seed #52796F, apoio escuro #354F52, fundo escuro #2F3E46. Raio: 12 em cartoes, 10 em botoes/campos. Fonte: Montserrat.
- Paleta sage, Montserrat, mesmo vocabulario de lista do app.

ACAO PRINCIPAL:
- Rever os avisos recentes. Pro administrador, um botao flutuante leva pra compor um aviso novo (tela separada).

CONSISTENCIA:
- Mesmo vocabulario de lista do app: linha com icone, titulo em destaque, data como referencia temporal.

BLOCOS:
- Lista cronologica: cada aviso com titulo, corpo resumido, imagem quando houver, e a rota especifica quando o aviso nao for geral.
- Botao de compor (so admin): flutuante, sempre alcancavel, leva pra tela de envio.

CONTEUDO & DADOS:
- Por aviso: titulo, corpo, imagem opcional, escopo (geral ou uma rota especifica), data/hora.
- Exemplo pt-BR: "Lista fechada — Embarque confirmado, as listas de hoje foram fechadas." Contorno: aviso sem imagem, aviso geral vs. de uma rota so, texto de corpo longo.

ESTADOS:
- Carregando: contornos do conteudo. Vazio: mensagem tranquila, sem alarme, "nenhuma notificacao ainda".
- Erro ao carregar: aviso gentil com tentar de novo.

INTERACAO & FLUXO:
- Acessivel tanto pro aluno quanto pro admin, cada um ve o que se aplica a ele. Admin tem o botao extra de compor.
- Textos pt-BR: "Notificações", "Nenhuma notificação ainda".

CUIDADO & EXPERIENCIA:
- Imagens com proporcao consistente, nunca distorcidas; contraste bom; toques confortaveis.
- NAO: misturar o botao de compor na visao do aluno; inventar contador de nao-lidas (o produto nao tem esse conceito hoje).
```

## Notas de decisão
- Ação primária: consultar histórico (+ compor, admin) · Estados: carregando, vazio, erro · Pendências ⛳: toda a feature — sem persistência de notificação no backend.
- Único gatilho automático real hoje é "lista fechada" (`SchedulerUseCaseImpl.close()`, broadcast fixo pra todos); "lista aberta" e "regra de rota mudou" estão documentados mas não disparam no código atual — o histórico mostrado aqui seria, hoje, quase vazio na prática.
