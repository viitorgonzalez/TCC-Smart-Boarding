# Prompt de design — Enviar notificação (admin) (TCC-Smart-Boarding / smartboarding_app)
> Status: **rascunho** · Arquétipo: form · Precedente: `lib/features/notifications/screens/broadcast_screen.dart` (redesign — já usa `LoadingFilledButton`/`showErrorSnackBar` da Fase A)
> Tokens: `lib/core/theme/app_theme.dart` · Contrato: `POST /api/notifications/broadcast` (real, só título+corpo)
> Gaps ⛳: imagem — infraestrutura R2 existe mas não está conectada a nenhum endpoint. Escopo (geral vs. rota específica) — hoje é **sempre geral**, não existe seleção real.
> Caracteres: 2290 (inclui espaços) · Limite: não confirmado (uxpilot free) — se precisar cortar, tire o bloco mais especulativo primeiro

## Prompt (colar na IA de layout)
```
Pagina — Smart Boarding — compor e enviar uma notificacao manual — administrador avisando algo importante pra todo mundo (ou uma rota especifica) — faixa de celular pequena a grande, retrato.

CONTEXTO & PROPOSITO:
- Ferramenta direta do administrador pra avisar algo que nao se encaixa nos avisos automaticos — um recado pontual, com controle de pra quem vai.

SENTIMENTO & EXPERIENCIA:
- Confianca e controle: a pessoa precisa sentir que sabe exatamente quem vai receber antes de apertar enviar.

TEMA & TOKENS:
- Hex reais: fundo claro #CAD2C5, verde geral #84A98C, verde principal/seed #52796F, apoio escuro #354F52, fundo escuro #2F3E46. Raio: 12 em cartoes, 10 em botoes/campos. Fonte: Montserrat.
- Paleta sage, Montserrat, mesmo vocabulario de formulario do app.

ACAO PRINCIPAL:
- Enviar a notificacao. Botao de destaque com icone de enviar, ao final do formulario, sempre visivel.

CONSISTENCIA:
- Mesmo vocabulario de formulario ja padronizado: campo com contorno leve, botao que troca o icone por um carregamento discreto ao confirmar.

BLOCOS:
- Cabecalho: titulo curto da acao, "a mensagem sera enviada pra quem voce escolher".
- Conteudo: titulo e corpo da mensagem, obrigatorios.
- Imagem opcional (a criar no back — hoje o envio e so texto).
- Escopo: geral (todos) ou uma rota especifica (a criar no back — hoje todo envio e sempre geral).
- Acao: enviar, com um resumo rapido de pra quem vai antes de confirmar.

CONTEUDO & DADOS:
- Campos reais: titulo (obrigatorio), corpo (obrigatorio, texto livre). Exemplo pt-BR: titulo "Aviso importante", corpo "O onibus de amanha sai 10 minutos mais cedo."
- Contorno: titulo vazio, corpo bem longo.

ESTADOS:
- Enviando: botao em carregamento. Sucesso: confirmacao "notificacao enviada" e os campos limpam.
- Erro ao enviar: aviso gentil, convite a tentar de novo.

INTERACAO & FLUXO:
- Alcancada pelo botao de compor da tela de notificacoes. Ao enviar com sucesso, volta pro historico (inbox) atualizado.
- Textos pt-BR: "Enviar Notificação", "Título", "Mensagem", "Enviar para todos".

CUIDADO & EXPERIENCIA:
- Contraste bom; toques confortaveis; nunca enviar sem o titulo/corpo preenchidos.
- NAO: prometer selecao de rota especifica ou imagem como se ja funcionassem de verdade — sao intencao de produto, nao dado real hoje.
```

## Notas de decisão
- Ação primária: enviar notificação · Estados: enviando, sucesso, erro · Pendências ⛳: imagem (upload não conectado), escopo por rota (sempre geral hoje).
- Contrato real confirmado: `POST /api/notifications/broadcast` `{title, body}` → dispara FCM pra **todos** os device tokens cadastrados, sem filtro de escopo/rota.
- Infra parcial real: `StoragePort`/`R2StorageAdapter` (Cloudflare R2) existe no backend, mas nenhum endpoint de upload de imagem a usa hoje — mesma situação do `EmailPort` (cano pronto, torneira não instalada).
