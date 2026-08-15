# Prompt de design — Recuperar/redefinir senha (TCC-Smart-Boarding / smartboarding_app)
> Status: **rascunho** · Arquétipo: form (fluxo de 2 passos: pedir e-mail → definir nova senha) · Precedente: tom do login
> Tokens: `lib/core/theme/app_theme.dart` · Contrato: `smartboarding_app/docs/specs/autenticacao/password-reset.md` (planejado)
> Gaps ⛳: **100% especulativo** — não existe `forgot-password`/`reset-password` no backend. Existe só a infraestrutura de e-mail (Resend) pronta e desconectada de qualquer fluxo real.
> Caracteres: 2637 (inclui espaços) · Limite: não confirmado (uxpilot free) — se precisar cortar, tire o bloco mais especulativo primeiro

## Prompt (colar na IA de layout)
```
Pagina — Smart Boarding — recuperar senha, dois passos (pedir e-mail, depois definir nova senha) — pessoa que esqueceu a senha e quer voltar a acessar — faixa de celular pequena a grande, retrato.

CONTEXTO & PROPOSITO:
- Quem chega aqui esta momentaneamente fora do app e um pouco frustrado — o objetivo e devolver o acesso rapido, sem burocracia, com clareza total do que fazer a seguir.

SENTIMENTO & EXPERIENCIA:
- Calma e clareza: cada passo mostra exatamente o que aconteceu e o que falta, sem deixar duvida se o pedido funcionou.

TEMA & TOKENS:
- Hex reais: fundo claro #CAD2C5, verde geral #84A98C, verde principal/seed #52796F, apoio escuro #354F52, fundo escuro #2F3E46. Raio: 12 em cartoes, 10 em botoes/campos. Fonte: Montserrat.
- Mesma paleta sage e Montserrat do resto do app; tom consistente com login, mesma linguagem de campo com contorno leve.

ACAO PRINCIPAL:
- Passo 1: pedir o link de redefinicao pelo e-mail. Passo 2 (a partir do link recebido): definir a nova senha. Um botao de destaque por passo.

CONSISTENCIA:
- Mesmo vocabulario de formulario do login: campo com icone, botao que vira carregamento, erro no rodape do campo.

PASSOS:
- Passo 1 — Pedir redefinicao: campo de e-mail, botao "Enviar link". Confirmacao visual de que o pedido foi enviado, mesmo que o e-mail nao exista no sistema (nao revelar se a conta existe, por seguranca).
- Passo 2 — Nova senha (aberta pelo link do e-mail): dois campos (nova senha, confirmar nova senha), botao "Redefinir senha".

CONTEUDO & DADOS:
- Passo 1: e-mail (obrigatorio). Passo 2: nova senha + confirmacao (obrigatorios, mesma regra de tamanho minimo do cadastro).
- Contorno: senha e confirmacao diferentes, link expirado ao abrir o passo 2.

ESTADOS:
- Passo 1 enviando: botao em carregamento. Enviado: mensagem calma "se o e-mail existir, voce vai receber o link em instantes" — nunca confirma se a conta existe.
- Passo 2, link invalido/expirado: tela dedicada explicando, com jeito de pedir um novo link.
- Passo 2 sucesso: confirmacao "senha redefinida" + convite a entrar de novo.

INTERACAO & FLUXO:
- Passo 1 e alcancado a partir do login (link "Esqueci minha senha"); passo 2 chega por e-mail. Depois de redefinir, volta pro login.
- Textos pt-BR: "Esqueci minha senha", "Enviar link", "Nova senha", "Confirmar nova senha", "Redefinir senha", "Senha redefinida com sucesso".

CUIDADO & EXPERIENCIA:
- Nunca revelar se um e-mail existe ou nao no sistema (mensagem sempre igual); contraste bom; toques confortaveis.
- NAO: confirmar existencia de conta pelo retorno da tela; pular a etapa de confirmar nova senha; inventar SMS/2FA que o produto nao tem.
```

## Notas de decisão
- Ação primária: recuperar acesso · Estados: passo 1 (form/enviando/enviado), passo 2 (form/link inválido/sucesso) · Pendências ⛳: toda a feature — sem endpoints reais.
- Infra parcial real: `EmailPort`/`ResendEmailAdapter` existem no backend (integração com Resend pronta), mas **nenhum use case os chama hoje** — é só o "cano", sem torneira.
- Não confundir com a tela de Login — é uma superfície separada, alcançada por um link a partir dela.
