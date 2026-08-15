# Prompt de design — Relatórios (aluno e admin) (TCC-Smart-Boarding / smartboarding_app)
> Status: **rascunho** · Arquétipo: list (+ detail ao tocar um item, admin) · Precedente: `lib/features/reports/screens/{reports_screen,report_detail_screen}.dart` (redesign)
> Tokens: `lib/core/theme/app_theme.dart` · Contrato: `GET /api/reports` (real, paginado), `GET /api/reports/{id}` (real)
> Gaps ⛳: "veículo proposto" — sem `Vehicle` no backend, é campo inexistente. Filtro de 7 dias pro aluno vs. completo pro admin — a spec descreve isso como feito pelo backend, mas o `ReportController` real **não filtra por papel nem data** hoje — é um gap de enforcement, não só de dado.
> Caracteres: 2495 (inclui espaços) · Limite: não confirmado (uxpilot free) — se precisar cortar, tire o bloco mais especulativo primeiro

## Prompt (colar na IA de layout)
```
Pagina — Smart Boarding — historico de relatorios de fechamento das listas — aluno conferindo os ultimos dias, ou administrador revisando o historico completo — faixa de celular pequena a grande, retrato.

CONTEXTO & PROPOSITO:
- Cada relatorio e o retrato de um fechamento de lista: quem embarcou naquele dia. O aluno usa pra conferir seus ultimos dias; o administrador, pra acompanhar tudo.

SENTIMENTO & EXPERIENCIA:
- Confianca em dados organizados: uma linha do tempo clara, sem excesso de numeros, facil de escanear por data.

TEMA & TOKENS:
- Hex reais: fundo claro #CAD2C5, verde geral #84A98C, verde principal/seed #52796F, apoio escuro #354F52, fundo escuro #2F3E46. Raio: 12 em cartoes, 10 em botoes/campos. Fonte: Montserrat.
- Paleta sage, Montserrat, mesmo vocabulario de lista do resto do app.

ACAO PRINCIPAL:
- Ver o historico. Pro admin, tocar um item abre o detalhe completo (quem embarcou + veiculo proposto). Pro aluno, a lista e so consulta.
- Secundaria: rolar pra carregar mais (admin, paginado).

CONSISTENCIA:
- Mesmo vocabulario de lista ja usado no app: linha com icone, nome da rota em destaque, data e contagem como subtitulo.

BLOCOS:
- Lista: uma linha por relatorio — rota, data, quantos embarcaram naquele dia.
- Detalhe (so admin, ao tocar): cabecalho com data/rota, lista de quem estava inscrito (nome + direcao), e o veiculo proposto pra aquele volume (a criar no back).

CONTEUDO & DADOS:
- Por relatorio: rota, data, total de inscritos, gerado em (data/hora). No detalhe: nome/e-mail de cada inscrito + direcao.
- Exemplo pt-BR: "Rota Principal — 12/08/2026 — 18 inscritos". Contorno: nenhum relatorio ainda, rota nova sem historico.
- Veiculo proposto: "(a criar no back)".

ESTADOS:
- Carregando: contornos do conteudo. Vazio: mensagem tranquila (aluno sem relatorios recentes, ou rota nova).
- Erro ao carregar: aviso gentil com tentar de novo. Carregando mais (scroll, admin): indicador discreto no fim da lista.

INTERACAO & FLUXO:
- Aluno chega pelo atalho da tela inicial; ve so os ultimos dias. Admin chega pelo painel; ve tudo, paginado, e pode abrir o detalhe.
- Textos pt-BR: "Nenhum relatório disponível", "inscrito(s)", "Gerado em".

CUIDADO & EXPERIENCIA:
- Datas sempre por extenso e claras; contraste bom; toques confortaveis na lista densa.
- NAO: mostrar veiculo como se fosse dado real; deixar o aluno pensar que tem acesso ao historico completo (a visao dele e só os ultimos dias, mesmo que hoje o backend nao imponha isso de verdade).
```

## Notas de decisão
- Ação primária: consultar histórico (+ ver detalhe, admin) · Estados: carregando, vazio, erro, paginação · Pendências ⛳: veículo proposto (dado), filtro de 7-dias-vs-completo (enforcement de backend).
- Dados reais confirmados: `ReportSummaryResponse{id, dailyListId, listDate, routeName, totalEntries, generatedAt}`, `ReportDetailResponse` + `snapshotData` (JSON com nome/email/tripType de cada inscrito).
- **Divergência spec × código**: `docs/specs/relatorios/reports.md` diz que o backend filtra 7 dias pro `STUDENT` — o `ReportController` real não tem esse filtro (nem por papel, nem por data). O app precisa aplicar esse corte no cliente até o backend implementar, ou tratar como gap de segurança (aluno hoje consegue ver `GET /api/reports/{id}` de qualquer relatório se souber o id).
