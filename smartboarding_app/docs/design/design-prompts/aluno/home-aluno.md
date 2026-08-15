# Prompt de design — Início do aluno (TCC-Smart-Boarding / smartboarding_app)
> Status: **rascunho** · Arquétipo: detail (uma rota só, resolvida automaticamente — não é mais lista de várias) · Precedente: `lib/features/home/student_home_screen.dart` (redesign — reforma simplifica pra rota única por instituição)
> Tokens: `lib/core/theme/app_theme.dart` · Contrato: `GET /api/lists/today` (real, mas hoje não filtra por instituição), `POST`/`DELETE /api/lists/{id}/entries` (real)
> Gaps ⛳: mapa da rota — sem `Institution`/`Stop` reais, não há trajeto/coordenadas pra plotar. Resolução automática de rota pela instituição do aluno — `Route` não tem vínculo com instituição hoje, é regra só de spec. `403 ACCOUNT_EXPIRED` ao entrar — backend não valida `expiryDate` no fluxo real ainda.
> Caracteres: 2933 (inclui espaços) · Limite: não confirmado (uxpilot free) — se precisar cortar, tire o bloco mais especulativo primeiro

## Prompt (colar na IA de layout)
```
Pagina — Smart Boarding — tela inicial do aluno, aberta ao logar todo dia — aluno decidindo se vai pegar o onibus hoje, ja sabendo qual e sua rota — faixa de celular pequena a grande, retrato.

CONTEXTO & PROPOSITO:
- Tela que o aluno abre toda manha pra saber se a lista do onibus de hoje esta aberta e garantir a vaga com um toque — a rota ja e a dele, resolvida automaticamente, sem escolher nada.

SENTIMENTO & EXPERIENCIA:
- Clareza e alivio: numa olhada so, sabe se ainda da tempo de entrar. Sensacao de controle, sem duvida se "foi contado".

TEMA & TOKENS:
- Hex reais: fundo claro #CAD2C5, verde geral #84A98C, verde principal/seed #52796F, apoio escuro #354F52, fundo escuro #2F3E46. Raio: 12 em cartoes, 10 em botoes/campos. Fonte: Montserrat.
- Paleta sage, Montserrat. Status aberto em verde vivo e seguro; fechado esfria pro tom neutro, sem alarme.

ACAO PRINCIPAL:
- Entrar (ou sair) da lista de hoje. Botao largura total, na cor de acao quando a lista esta aberta — inconfundivel.
- Secundarias: ver notificacoes, ver relatorios dos ultimos dias.

CONSISTENCIA:
- Mesmo vocabulario ja padronizado do app: selo de status colorido, aviso vazio com icone quando nao ha lista, botao de acao que confirma com carregamento.

BLOCOS:
- Cabecalho: nome do produto + saudacao com o nome do aluno.
- Cartao da rota: nome da rota, selo aberta/fechada, quantas pessoas confirmaram, direcao escolhida se ja inscrito.
- Mapa da rota: previa visual do trajeto com os pontos principais, contexto de onde o onibus passa (a criar no back).
- Contagem regressiva ate o fechamento, leve, sem alarmar.
- Atalhos: ver notificacoes, ver meus relatorios.

CONTEUDO & DADOS:
- Rota: nome, status aberta/fechada, quantidade de inscritos, horario real de fechamento daquela rota. Direcao: ida e volta, so ida, ou so volta.
- Exemplo pt-BR: "Rota Principal", "fecha as 16h". Contorno: nenhuma lista aberta hoje (mostrar o horario real de fechamento mesmo assim), muitos inscritos.
- Trajeto no mapa: "(a criar no back)".

ESTADOS:
- Carregando: contornos do conteudo. Sem lista aberta: mensagem tranquila explicando quando fecha/abre, sem alarme.
- Erro ao carregar: aviso gentil com tentar de novo. Entrando/saindo: botao em carregamento.
- Carteirinha expirada ao tentar entrar: mensagem dedicada e gentil — "sua carteirinha de transporte expirou, procure o administrador" — nao um erro generico.

INTERACAO & FLUXO:
- Abre logo apos o login do aluno. Atalhos levam pra notificacoes e relatorios sem perder o contexto desta tela.
- Textos pt-BR: "Entrar na lista", "Sair da lista", "Você está na lista", "Fecha às 16h", "Sua carteirinha de transporte expirou — procure o administrador".

CUIDADO & EXPERIENCIA:
- Status sempre com icone e texto, nunca so cor; toques confortaveis; contraste bom nos dois modos.
- NAO: deixar o aluno escolher a rota (ela ja e resolvida); inventar pontos de parada reais no mapa; contagem regressiva alarmante.
```

## Notas de decisão
- Ação primária: entrar/sair da lista de hoje · Estados: carregando, sem lista aberta, erro, entrando/saindo, carteirinha expirada · Pendências ⛳: mapa, resolução por instituição, validação de expiração.
- Simplificação real da reforma: a spec (`docs/specs/aluno/student-home.md`) já não fala mais em "cartões de múltiplas listas" — é uma rota só, resolvida automaticamente. Redesign deste prompt reflete essa simplificação, diferente da versão anterior (que mostrava N cartões).
- `GET /api/lists/today` já existe e funciona — só não filtra por instituição hoje (porque `Route` não tem esse vínculo); o filtro "rota do aluno" precisa ser resolvido antes deste redesign virar código.
