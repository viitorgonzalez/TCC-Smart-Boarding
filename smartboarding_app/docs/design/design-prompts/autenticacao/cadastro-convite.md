# Prompt de design — Cadastro por convite (TCC-Smart-Boarding / smartboarding_app)
> Status: **rascunho** · Arquétipo: form · Precedente: arquétipo genérico (tela nova, sem precedente de código — usa vocabulário do login como referência de tom)
> Tokens: `lib/core/theme/app_theme.dart` · Contrato: `smartboarding_app/docs/specs/autenticacao/register.md` (planejado)
> Gaps ⛳: **100% especulativo** — `RegistrationController` não existe no backend (zero endpoint, zero tabela). `Institution` também não existe como entidade (só um campo texto livre em `User`) — o dropdown de instituição do spec não tem de onde vir hoje. Esta tela é só visualização de intenção, não pronta pra implementar.
> Caracteres: 2872 (inclui espaços) · Limite: não confirmado (uxpilot free) — se precisar cortar, tire o bloco mais especulativo primeiro

## Prompt (colar na IA de layout)
```
Pagina — Smart Boarding — cadastro por convite, aberta a partir de um link de e-mail — aluno novo que ainda nunca usou o app — faixa de celular pequena a grande, retrato.

CONTEXTO & PROPOSITO:
- E o primeiro contato do aluno com o produto: ele recebeu um link no e-mail (gerado pelo admin) e abre direto nesta tela pra terminar o proprio cadastro, sem precisar do admin digitar nada por ele.

SENTIMENTO & EXPERIENCIA:
- Acolhimento e simplicidade: a pessoa ja foi convidada, entao a tela deve parecer o ultimo passo facil, nao um formulario burocratico longo.

TEMA & TOKENS:
- Hex reais: fundo claro #CAD2C5, verde geral #84A98C, verde principal/seed #52796F, apoio escuro #354F52, fundo escuro #2F3E46. Raio: 12 em cartoes, 10 em botoes/campos. Fonte: Montserrat.
- Mesma paleta sage e Montserrat do resto do app; tom consistente com a tela de login (mesmo icone de onibus, mesmo respiro).

ACAO PRINCIPAL:
- Completar o cadastro. Botao "Enviar cadastro" em destaque, largura total, ao final do formulario.

CONSISTENCIA:
- Mesmo vocabulario da tela de login: campos com contorno leve e icone, botao que vira carregamento ao confirmar, mensagens de erro no rodape do campo.

BLOCOS:
- Abertura: confirmacao de quem foi convidado — o email vem pronto, so pra leitura, dando confianca de que o link e legitimo.
- Dados pessoais: nome completo e senha, obrigatorios.
- Instituicao: selecao numa lista (a criar no back — hoje nao existe cadastro de instituicoes).
- Dados complementares (opcionais, podem ficar recolhidos/expansiveis): curso, telefone, endereco, data de nascimento.
- Acao final: enviar, com aviso claro de que depois disso o cadastro fica esperando aprovacao.

CONTEUDO & DADOS:
- Campos obrigatorios: nome completo, senha, instituicao. Opcionais: curso, telefone, endereco, data de nascimento.
- Exemplo pt-BR: "Maria Oliveira", instituicao "Unifor — Campus Central" (a criar no back).

ESTADOS:
- Link invalido ou expirado: tela dedicada, sem formulario nenhum, so a explicacao e um jeito de pedir um novo convite.
- Enviando: botao em carregamento. Sucesso: tela de confirmacao acolhedora — "cadastro enviado, aguardando aprovacao do administrador".
- Campo obrigatorio vazio: aviso no proprio campo antes de tentar enviar.

INTERACAO & FLUXO:
- Chega por um link, sem navegacao anterior no app. Ao enviar com sucesso, mostra a confirmacao — nao entra direto no app (precisa de aprovacao antes).
- Textos pt-BR: "Seu convite", "Nome completo", "Senha", "Instituicao", "Enviar cadastro", "Cadastro enviado — aguardando aprovacao do administrador".

CUIDADO & EXPERIENCIA:
- Campos opcionais claramente diferenciados dos obrigatorios; contraste bom; toques confortaveis; foco visivel.
- NAO: pedir mais dados do que o listado; deixar a pessoa achar que ja pode usar o app antes da aprovacao; inventar logica de instituicao/endereco que nao existe hoje.
```

## Notas de decisão
- Ação primária: enviar cadastro · Estados: link inválido, formulário, enviando, sucesso (aguardando aprovação) · Pendências ⛳: toda a feature (endpoint, `Institution`, aprovação) é gap.
- Contrato planejado (não implementado): `GET /api/registration/invite/{token}`, `POST /api/registration/{token}/submit` `{fullName, password, institutionId, course?, phone?, address?, birthDate?}`, `GET /api/institutions` — nenhum existe no código hoje (`smartboarding_app/docs/specs/autenticacao/register.md`).
- Campos opcionais (`course/phone/address/birthDate`) já existem em `User`/`UserResponse` no backend real — só o endpoint de submissão via convite que falta.
