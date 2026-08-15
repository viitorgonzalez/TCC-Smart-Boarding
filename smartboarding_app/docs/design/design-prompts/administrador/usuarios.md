# Prompt de design — Usuários (admin) (TCC-Smart-Boarding / smartboarding_app)
> Status: **rascunho** · Arquétipo: list (só visualização — sem formulário de criação) · Precedente: `lib/features/users/screens/user_management_screen.dart` (redesign — **remove** a criação manual, ver nota)
> Tokens: `lib/core/theme/app_theme.dart` · Contrato: `GET /api/users` / `GET /api/users/{id}` (real)
> Gaps ⛳: nenhum campo inventado — todos os campos abaixo já existem em `UserResponse`.
> Caracteres: 2148 (inclui espaços) · Limite: não confirmado (uxpilot free) — se precisar cortar, tire o bloco mais especulativo primeiro

## Prompt (colar na IA de layout)
```
Pagina — Smart Boarding — listagem de contas do sistema — administrador consultando quem tem acesso — faixa de celular pequena a grande, retrato.

CONTEXTO & PROPOSITO:
- Visao geral de todas as contas ativas — aluno, administrador — pra consulta, nao pra criar conta (aluno nasce so pelo convite).

SENTIMENTO & EXPERIENCIA:
- Organizacao tranquila: uma lista clara, agrupada por papel, facil de escanear e filtrar.

TEMA & TOKENS:
- Hex reais: fundo claro #CAD2C5, verde geral #84A98C, verde principal/seed #52796F, apoio escuro #354F52, fundo escuro #2F3E46. Raio: 12 em cartoes, 10 em botoes/campos. Fonte: Montserrat.
- Paleta sage, Montserrat, mesmo vocabulario de lista do app.

ACAO PRINCIPAL:
- Consultar e filtrar por papel. Sem acao de criar conta nesta tela.
- Secundaria: filtrar por papel (todos, administradores, alunos).

CONSISTENCIA:
- Mesmo vocabulario ja padronizado do app: filtro em chips roláveis com contagem, cabecalho de secao por grupo, linha com selo de papel.

BLOCOS:
- Barra de filtro: chips por papel, cada um com a contagem.
- Lista agrupada por papel: cabecalho de secao (icone + nome do papel + contagem), depois as contas daquele grupo.
- Cada conta: nome, e-mail, selo do papel.

CONTEUDO & DADOS:
- Por conta: nome completo, e-mail, papel (administrador ou aluno).
- Exemplo pt-BR: "Maria Oliveira — maria@edu.unifor.br — Aluno". Contorno: nenhuma conta cadastrada, filtro sem resultado, nome bem longo.

ESTADOS:
- Carregando: contornos do conteudo. Vazio geral: mensagem tranquila. Vazio por filtro: mensagem distinta, convidando a limpar o filtro.
- Erro ao carregar: aviso gentil com tentar de novo.

INTERACAO & FLUXO:
- Alcancada pelo cartao "Usuários" do painel do admin. Pura consulta — sem navegacao de saida alem de voltar.
- Textos pt-BR: "Todos", "Administradores", "Alunos", "Nenhum usuário cadastrado", "Nenhum usuário neste filtro".

CUIDADO & EXPERIENCIA:
- Contraste bom; toques confortaveis mesmo com lista densa; selo de papel sempre com texto, nunca so cor.
- NAO: incluir botao ou formulario de criar aluno manualmente — contraria a regra do produto (conta de aluno nasce só por convite).
```

## Notas de decisão
- Ação primária: consultar/filtrar por papel · Estados: carregando, vazio, vazio-por-filtro, erro · Pendências ⛳: nenhuma — dados 100% reais.
- Dados reais confirmados: `UserResponse{id, email, fullName, role, course, institution, phone, address, birthDate, expiryDate, isActive}` — bem mais rico que o exibido hoje; este redesign usa só o essencial pra lista (nome/email/papel), o resto fica pra uma eventual tela de detalhe (fora do MVP atual).
- **Divergência importante com o código atual**: `smartboarding_app/docs/specs/administrador/users-list.md` é explícito — "sem formulário de criação". A tela real hoje (`user_management_screen.dart`) ainda tem um FAB "Novo usuário" + formulário completo de criação (nome/email/senha/papel). Esse redesign reflete o alvo da spec (só listagem) — remover o FAB/formulário é uma mudança de regra de negócio, fora do escopo de design, mas vale registrar pro time de dev antes de implementar este prompt.
