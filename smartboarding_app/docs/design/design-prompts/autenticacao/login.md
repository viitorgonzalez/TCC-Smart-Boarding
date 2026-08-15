# Prompt de design — Login (TCC-Smart-Boarding / smartboarding_app)
> Status: **rascunho** · Arquétipo: form · Precedente: `lib/features/auth/screens/login_screen.dart` (redesign com design system novo, sem `.pen`)
> Tokens: `lib/core/theme/app_theme.dart` (paleta sage + Montserrat) · Contrato: `POST /api/auth/login` (real)
> Gaps ⛳: "lembrar de mim" é intenção documentada (`docs/spec.md` §3.7) mas o backend não tem refresh token nem esse campo — marcado no corpo. Sem aprovação-pendente/conta-expirada tratados no login real hoje (spec descreve, backend ainda não).
> Caracteres: 2832 (inclui espaços) · Limite: não confirmado (uxpilot free) — se precisar cortar, tire o bloco mais especulativo primeiro

## Prompt (colar na IA de layout)
```
Pagina — Smart Boarding (embarque universitario Unifor) — login, primeira tela sem sessao — aluno, ou administrador (papel motorista foi removido do produto) — faixa de celular pequena a grande, retrato.

CONTEXTO & PROPOSITO:
- Porta de entrada do app: email e senha pra comecar o dia, rapido, de manha, sem friccao.

SENTIMENTO & EXPERIENCIA:
- Confianca tranquila e agilidade de rotina matinal — abrir algo que ja faz parte do dia a dia, nao um cadastro burocratico.

TEMA & TOKENS:
- Hex reais: fundo claro #CAD2C5, verde geral #84A98C, verde principal/seed #52796F, apoio escuro #354F52, fundo escuro #2F3E46. Raio: 12 em cartoes, 10 em botoes/campos. Fonte: Montserrat.
- Paleta sage: fundo claro e arejado (ou escuro sereno, os dois modos existem); verde acinzentado como cor principal, um verde mais suave como acento. Tipografia Montserrat, humana e legivel.
- Cantos suavemente arredondados em cartoes/campos/botoes (a mesma escala em todo o app — dois raios, um pouco maior em cartoes, um pouco menor em botoes/campos).

ACAO PRINCIPAL:
- Entrar. Botao "Entrar" e o destaque absoluto, largura total. Olhar pousa no icone e nome do produto, depois desce aos campos.
- Secundaria: opcao "lembrar de mim" (a criar no back — hoje toda sessao expira em 1h sem renovar).

CONSISTENCIA:
- Usa o vocabulario ja padronizado do app: campo com contorno leve e icone, botao que vira indicador de carregamento ao confirmar, aviso de erro consistente (nunca "Colors.red" solto).

BLOCOS:
- Abertura: icone de onibus, nome do produto, frase curta de boas-vindas.
- Formulario: email (icone envelope) e senha (icone cadeado, com opcao de mostrar/ocultar) — direto ao ponto.
- Checkbox "Lembrar de mim" (a criar no back), discreto, abaixo dos campos.
- Acao: botao "Entrar", vira carregamento discreto ao confirmar.

CONTEUDO & DADOS:
- Campos reais: email (obrigatorio, formato email) e senha (obrigatoria). Exemplo: "joao.silva@edu.unifor.br". Contorno: campo vazio, email invalido.
- Erro real do backend hoje: credencial invalida (mensagem generica, nao aponta qual campo).

ESTADOS:
- Normal: pronto pra preencher. Enviando: botao vira carregamento, campos bloqueados.
- Erro: aviso gentil embaixo, sem travar a tela — "credenciais invalidas".

INTERACAO & FLUXO:
- Chega aqui sem sessao ativa; ao entrar, vai direto pra tela inicial do papel (aluno ou admin).
- Textos pt-BR: "Email", "Senha", "Lembrar de mim", "Entrar".

CUIDADO & EXPERIENCIA:
- Contraste bom nos dois modos; toques confortaveis; foco visivel no teclado; erro sempre com texto, nunca so cor.
- NAO: inventar "esqueci a senha" nesta tela (e uma tela separada, ja no MVP, nao um link aqui — a nao ser que o produto decida linkar); tratar "lembrar de mim" como se ja funcionasse de verdade (marcar visualmente como oferecido, sem prometer o que o back nao entrega).
```

## Notas de decisão
- Ação primária: entrar · Estados: normal, enviando, erro · Pendências ⛳: "lembrar de mim" (RN §3.7, sem refresh token no backend).
- Tema real: `_ashGrey #CAD2C5` / `_mutedTeal #84A98C` / `_deepTeal #52796F` (seed) / `_darkSlate #354F52` / `_charcoalBlue #2F3E46`, Montserrat via `google_fonts`, `AppRadius.card=12`/`control=10`.
- Backend real (`AuthController`): `POST /api/auth/login` só `email`+`password`, token expira em 1h fixo, sem refresh, sem checagem de `expiryDate`/conta pendente no fluxo de login hoje (apesar de existirem no `User`).
