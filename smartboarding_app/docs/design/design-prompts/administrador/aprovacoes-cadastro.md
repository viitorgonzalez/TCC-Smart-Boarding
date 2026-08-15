# Prompt de design — Solicitações de cadastro (admin) (TCC-Smart-Boarding / smartboarding_app)
> Status: **rascunho** · Arquétipo: list (com ação de decisão por item) · Precedente: vocabulário de lista do app (sem tela irmã de aprovação existente)
> Tokens: `lib/core/theme/app_theme.dart` · Contrato: `smartboarding_app/docs/specs/administrador/registration-approvals.md` (planejado)
> Gaps ⛳: **100% especulativo** — sem `RegistrationController`, sem tabela de cadastros pendentes, sem `POST .../approve`/`reject`/`invite` no backend.
> Caracteres: 2429 (inclui espaços) · Limite: não confirmado (uxpilot free) — se precisar cortar, tire o bloco mais especulativo primeiro

## Prompt (colar na IA de layout)
```
Pagina — Smart Boarding — solicitacoes de cadastro pendentes — administrador decidindo quem entra no transporte — faixa de celular pequena a grande, retrato.

CONTEXTO & PROPOSITO:
- Fila de decisao: cada aluno que se cadastrou pelo convite espera aqui ate o administrador aprovar ou negar — a porta de entrada real do produto.

SENTIMENTO & EXPERIENCIA:
- Responsabilidade tranquila: decisoes claras, sem pressa forcada, com os dados necessarios visiveis antes de decidir.

TEMA & TOKENS:
- Hex reais: fundo claro #CAD2C5, verde geral #84A98C, verde principal/seed #52796F, apoio escuro #354F52, fundo escuro #2F3E46. Raio: 12 em cartoes, 10 em botoes/campos. Fonte: Montserrat.
- Paleta sage, Montserrat, mesmo vocabulario de lista do app.

ACAO PRINCIPAL:
- Aprovar ou negar cada solicitacao. Dois botoes claros por item, cada um pedindo confirmacao antes de agir (decisao nao e reversivel num toque so).
- Secundaria: gerar um convite novo, pra comecar o cadastro de outra pessoa.

CONSISTENCIA:
- Mesmo vocabulario de lista e confirmacao ja usados no app: cartao por item, dialogo de confirmacao antes de acao importante.

BLOCOS:
- Lista de pendentes: um cartao por solicitacao, com nome, e-mail, instituicao escolhida e data do pedido.
- Acoes por item: aprovar (positivo) e negar (neutro/cauteloso), lado a lado.
- Atalho: gerar convite novo, so pedindo o e-mail.

CONTEUDO & DADOS:
- Por solicitacao: nome completo, e-mail, instituicao, data do pedido.
- Exemplo pt-BR: "Maria Oliveira — maria@edu.unifor.br — Unifor Campus Central — pedido em 12/08". Contorno: fila vazia, muitas solicitacoes acumuladas.

ESTADOS:
- Carregando: contornos do conteudo. Vazia: mensagem tranquila, "nenhuma solicitação pendente".
- Aprovando/negando: confirmacao antes, depois some da fila com um retorno rapido de sucesso.
- Gerando convite: confirmacao de que o convite foi enviado pro e-mail informado.

INTERACAO & FLUXO:
- Alcancada pelo cartao "Solicitações de Cadastro" do painel do admin, com a contagem de pendentes visivel de la.
- Textos pt-BR: "Aprovar", "Negar", "Gerar convite", "Nenhuma solicitação pendente", "Convite enviado".

CUIDADO & EXPERIENCIA:
- Confirmacao sempre antes de aprovar ou negar; contraste bom; toques confortaveis.
- NAO: aprovar/negar num toque so sem confirmar; misturar a acao de gerar convite com a lista de pendentes (sao intencoes diferentes, mas podem dividir a mesma tela com clareza visual).
```

## Notas de decisão
- Ação primária: aprovar/negar pendências (+ gerar convite) · Estados: carregando, vazio, decidindo, convite enviado · Pendências ⛳: toda a feature.
- Contrato planejado (não implementado): `GET /api/registration/pending`, `POST /api/registration/{id}/approve`, `POST /api/registration/{id}/reject`, `POST /api/registration/invite {email}`.
- Esta tela é a origem do badge de contagem no `painel-admin.md` — os dois nascem juntos quando o backend existir.
