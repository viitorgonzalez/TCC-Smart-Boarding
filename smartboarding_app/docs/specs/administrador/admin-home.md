# Spec — Painel do Admin

> Tela: `AdminHomeScreen` · Acesso: 🧑‍💼
> Base: [`../PAGES.md`](../../PAGES.md), [`../spec.md`](../../spec.md) §2.

## Objetivo

Dashboard com atalhos pras áreas de gestão do admin.

## Dados & contrato

- Números do "Resumo de Hoje" e a contagem do card de Solicitações: `GET /api/admin/stats`
  → `{activeStudents, enrolledToday, capacityToday, occupancyPercent, pendingProfileRequests, warningsToday}`.

## Layout / seções

Grid 2x4 de atalhos, em pares por propósito (operação do dia, comunicação, gestão de gente,
configuração):
1. Rotas e Listas · Códigos de acesso
2. Enviar Aviso · Avisos enviados
3. Advertências · Usuários
4. Relatórios · Instituições

"Códigos de acesso" empurra `InviteCodesScreen` direto (`Navigator.push`), não pelo helper
`_open` que as outras usam: essa tela já traz `Scaffold` e botão flutuante próprios, e passar
pelo `_open` acrescentaria uma segunda barra de título por cima. O cabeçalho mostra o avatar do
admin como atalho pro perfil (`ProfileScreen`) — é onde o usuário tende a procurar essa ação, e
evita mais um ícone solto no header.

### Códigos de acesso (`InviteCodesScreen`)

É tela própria, fora do detalhe de uma rota, porque o código é a porta de entrada da rota — essa
decisão não pertence ao dia a dia de uma rota específica, e dentro do detalhe ficava soterrada
sob lista de presença, veículos e paradas. Recebe as rotas do admin já carregadas (a tela não
refaz a busca que o painel já fez ao abrir).

- `InviteCode.usable` vem pronto do backend: "vale ou não vale" depende do relógio do servidor,
  não do aparelho. `uses` é quantos alunos já entraram por ele — o que diz se o código circulou
  ou se ninguém recebeu. `institutionId` nulo é o código **aberto** (vale pra qualquer aluno);
  `institutionName` vem resolvido pelo backend, senão a tela teria que cruzar cada código com o
  catálogo só pra escrever uma linha. `routeName` só vem preenchido nesta listagem agregada (que
  cruza rotas) — dentro do detalhe de uma rota só, repetir o nome em cada linha seria ruído.
- Ao gerar um código, a escolha "Qualquer instituição" manda string vazia pro backend, não nulo:
  nulo seria indistinguível de ter fechado a folha sem escolher nada. `expiresAt` nulo (sem
  escolher validade) deixa o backend aplicar a validade padrão dele.
- **Apagar** (`archiveInviteCodes`) e **cancelar/revogar** (`revokeInviteCode`) são operações
  diferentes: apagar só tira o código desta tela (quem já entrou continua na rota, e o relatório
  mantém por onde cada aluno chegou); cancelar impede uso futuro do código, mas também não afeta
  quem já entrou. "Selecionar expirados e cancelados" (`_marcarInutilizaveis`) é o caso de uso
  real de limpeza em lote.
- Seleção múltipla: segurar entra no modo (gesto já conhecido de qualquer lista de app); a barra
  de seleção substitui o título enquanto dura (o que importa ali é quantos foram marcados e o
  que fazer com eles); desmarcar o último item sai do modo automaticamente — manter a barra
  vazia na tela deixaria o admin num estado sem saída óbvia.
- O filtro por rota só aparece com mais de uma rota — com uma só, a lista inteira já é dela, e o
  chip seria um elemento a mais à toa.

Fora do grid, abaixo dele: card de alerta "Solicitações" (pedidos de alteração de perfil
aguardando revisão), com a contagem de `pendingProfileRequests`. Fica fora da grade 2x4 de
propósito — sozinho ele sobraria sem par, e um alerta com contagem chama mais atenção do que
mais um quadrado igual aos outros oito.

Depois do grid: seção "Resumo de Hoje", com `AdminStatsProvider`:
- Alunos Ativos
- Ocupação Hoje (`enrolledToday`/`capacityToday` + `occupancyPercent`%)
- Solicitações Pendentes
- Advertências Hoje

## Estados

- Contagem do card de Solicitações e a linha "Solicitações Pendentes" do resumo ficam em 0
  quando não há pedido pendente.

## Regras aplicáveis

`spec.md` §2.
