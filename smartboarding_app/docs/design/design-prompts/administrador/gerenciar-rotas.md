# Prompt de design — Gerenciar rotas (admin) (TCC-Smart-Boarding / smartboarding_app)
> Status: **rascunho** · Arquétipo: list (+ form ao criar/editar) · Precedente: `lib/features/routes/screens/{routes_screen,route_form_screen}.dart` (redesign — lista já real, form ganha seções novas especulativas)
> Tokens: `lib/core/theme/app_theme.dart` · Contrato: `GET/POST/PATCH/DELETE /api/routes` (real, só `name`+`description`)
> Gaps ⛳: `closeTime` (horário de fechamento por rota) — não existe no `Route` real. Seções de instituições/veículos/paradas no formulário — nenhuma das 3 entidades existe no backend, é 100% especulativo.
> Caracteres: 3045 (inclui espaços) · Limite: não confirmado (uxpilot free) — se precisar cortar, tire o bloco mais especulativo primeiro

## Prompt (colar na IA de layout)
```
Pagina — Smart Boarding — gestao de rotas do administrador, com as sub-areas vinculadas — admin organizando rotas, instituicoes, veiculos e paradas — faixa de celular pequena a grande, retrato.

CONTEXTO & PROPOSITO:
- Tela onde o administrador mantem as rotas que alimentam as listas diarias, e tudo que esta vinculado a elas — trabalho de manutencao, feito com calma.

SENTIMENTO & EXPERIENCIA:
- Ordem e controle tranquilo: lista limpa, facil de escanear; ao entrar numa rota, tudo que pertence a ela aparece organizado, nao espalhado.

TEMA & TOKENS:
- Hex reais: fundo claro #CAD2C5, verde geral #84A98C, verde principal/seed #52796F, apoio escuro #354F52, fundo escuro #2F3E46. Raio: 12 em cartoes, 10 em botoes/campos. Fonte: Montserrat.
- Paleta sage, Montserrat. Tom neutro predominante, verde reservado pra criar e confirmar.

ACAO PRINCIPAL:
- Criar uma rota nova. Botao flutuante de destaque, sempre alcancavel.
- Secundarias: editar rota (abre o formulario completo com as sub-secoes), desativar rota.

CONSISTENCIA:
- Mesmo vocabulario ja padronizado do app: cartao de item, selo ativa/inativa, dialogo de confirmacao antes de desativar.

BLOCOS:
- Lista de rotas: nome, descricao curta, selo ativa/inativa, acoes de editar/desativar.
- Formulario de rota (criar/editar): nome, descricao, horario de fechamento (a criar no back — hoje o fechamento e fixo, nao por rota).
- Secao instituicoes vinculadas: adicionar/remover instituicoes cadastradas (a criar no back — instituicao nao existe como entidade hoje).
- Secao veiculos disponiveis: tipo e capacidade (a criar no back — nao existe entidade de veiculo).
- Secao paradas no mapa: nome e posicao de cada parada, com indicacao de "ponto principal" (a criar no back — sem coordenadas nem entidade de parada hoje).

CONTEUDO & DADOS:
- Reais hoje: nome (obrigatorio), descricao (opcional), ativa/inativa.
- Exemplo pt-BR: "Rota Principal". Contorno: nome duplicado (erro de conflito), rota sem nenhuma sub-secao preenchida ainda.

ESTADOS:
- Carregando: contornos do conteudo. Vazia: convite a criar a primeira rota.
- Nome duplicado ao salvar: aviso claro apontando o conflito. Desativando: confirmacao antes.
- Sub-secoes vazias (instituicao/veiculo/parada): convite gentil a adicionar o primeiro item de cada uma, sem parecer erro.

INTERACAO & FLUXO:
- Alcancada pelo cartao "Gerenciar Rotas" do painel do admin. Editar uma rota abre um formulario mais rico que so nome/descricao, com as sub-secoes abaixo.
- Textos pt-BR: "Nova rota", "Editar", "Desativar", "Horário de fechamento", "Instituições vinculadas", "Veículos", "Paradas".

CUIDADO & EXPERIENCIA:
- Sub-secoes claramente separadas visualmente (nao misturar com os campos basicos da rota); contraste bom; desativar sempre pede confirmacao.
- NAO: inventar coordenadas reais de parada; prometer que editar a rota dispara notificacao automatica sem isso existir no back ainda; misturar os dados reais (nome/descricao) com os especulativos sem alguma diferenciacao visual sutil pro time de dev saber o que ja funciona.
```

## Notas de decisão
- Ação primária: criar/editar rota · Estados: vazio, conflito de nome, desativando, sub-seções vazias · Pendências ⛳: `closeTime`, instituições, veículos, paradas — todas ausentes do backend real.
- Dados reais confirmados: `Route{id, name, description, isActive, createdAt, updatedAt}` — `POST/GET/GET{id}/PATCH/DELETE /api/routes` funcionam; `DELETE` é soft-delete (`isActive=false`).
- A notificação automática "regra de rota mudou" ao editar (spec §3.4) também é gap — `RouteUseCaseImpl` não dispara nenhum broadcast hoje.
