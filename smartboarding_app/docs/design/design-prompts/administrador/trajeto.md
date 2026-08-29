# Prompt de design — Trajeto (admin) (TCC-Smart-Boarding / smartboarding_app)
> Status: **rascunho** · Arquétipo: form (ação sequencial) · Precedente: vocabulário do app (tela nova, substitui o antigo papel de motorista — hoje removido)
> Tokens: `lib/core/theme/app_theme.dart` · Contrato: `smartboarding_app/docs/specs/administrador/trip.md` (planejado)
> Gaps ⛳: **100% especulativo** — não existe `TripController`, nem estado de trajeto na `DailyList`, nem `Stop`/pontos principais no backend. Nada disso tem schema hoje.
> Caracteres: 2610 (inclui espaços) · Limite: não confirmado (uxpilot free) — se precisar cortar, tire o bloco mais especulativo primeiro

## Prompt (colar na IA de layout)
```
Pagina — Smart Boarding — conducao do trajeto do dia — administrador avisando os inscritos em cada etapa da viagem, do inicio ao fim — faixa de celular pequena a grande, retrato.

CONTEXTO & PROPOSITO:
- Ferramenta do administrador pra avisar em tempo real cada etapa do trajeto: saiu, passou por um ponto principal, terminou — sem depender de motorista com conta propria.

SENTIMENTO & EXPERIENCIA:
- Praticidade e confianca: um gesto simples por etapa, com certeza de que o aviso chega — quem esta usando pode estar com pressa, perto do veiculo.

TEMA & TOKENS:
- Hex reais: fundo claro #CAD2C5, verde geral #84A98C, verde principal/seed #52796F, apoio escuro #354F52, fundo escuro #2F3E46. Raio: 12 em cartoes, 10 em botoes/campos. Fonte: Montserrat.
- Paleta sage, Montserrat. Botao de acao em destaque, o resto da tela calmo, sem competir.

ACAO PRINCIPAL:
- Avancar o trajeto: iniciar, depois um botao por ponto principal (checkpoint), depois finalizar. Um botao de destaque por vez, na ordem certa.

CONSISTENCIA:
- Mesmo vocabulario de acao com confirmacao ja usado no app: dialogo antes de agir, botao que vira carregamento, retorno de "notificacao enviada pra N alunos".

BLOCOS:
- Selecao da rota/lista do dia.
- Botao "Iniciar trajeto" — disponivel antes de comecar.
- Um botao por ponto principal (rodoviaria + instituicoes da rota) — aparecem na ordem do trajeto, cada um vira "concluido" apos o checkpoint.
- Botao "Finalizar trajeto" — disponivel so depois do ultimo checkpoint.

CONTEUDO & DADOS:
- Por rota: nome, lista de pontos principais (nome de cada um — a criar no back, sem entidade de parada hoje).
- Exemplo pt-BR: "Rodoviária", "Unifor — Campus Central". Contorno: rota sem pontos principais cadastrados ainda.

ESTADOS:
- Antes de iniciar: so o botao de iniciar disponivel. Em andamento: pontos ja passados ficam marcados, o proximo em destaque.
- Cada acao pede confirmacao antes de disparar. Sucesso: "notificação enviada para N aluno(s)".
- Funciona com a lista aberta ou ja fechada — o trajeto acontece depois do fechamento tambem.

INTERACAO & FLUXO:
- Alcancada pelo cartao "Trajeto" do painel do admin. Sequencia linear: iniciar, checkpoints em ordem, finalizar.
- Textos pt-BR: "Iniciar trajeto", "Finalizar trajeto", "Notificação enviada para N aluno(s)".

CUIDADO & EXPERIENCIA:
- Toques bem confortaveis (quem usa pode estar com pressa ou em movimento); confirmacao sempre antes de cada etapa.
- NAO: permitir checkpoint fora de ordem sem deixar claro visualmente; inventar rastreamento de GPS ao vivo (fora de escopo do produto — so pontos fixos avisados manualmente).
```

## Notas de decisão
- Ação primária: avançar o trajeto (iniciar/checkpoint/finalizar) · Estados: antes de iniciar, em andamento, finalizado · Pendências ⛳: toda a feature — zero código no backend.
- Contrato planejado (não implementado): `POST /api/trip/{listId}/start`, `POST /api/trip/{listId}/checkpoint/{stopId}` (só aceito em `isMainPoint=true`), `POST /api/trip/{listId}/finish`.
- Depende diretamente de `Stop` existir (`gerenciar-rotas.md`) — sem paradas cadastradas, não há o que listar aqui.
