# Prompt de design — Painel do admin (TCC-Smart-Boarding / smartboarding_app)
> Status: **rascunho** · Arquétipo: dashboard (novo — a tela atual é abas na base, a spec pede cartões de atalho) · Precedente: nenhum no app (arquétipo inédito); componentes reaproveitados do resto do design system
> Tokens: `lib/core/theme/app_theme.dart` · Contrato: `smartboarding_app/docs/specs/administrador/admin-home.md`
> Gaps ⛳: contagem de pendências (`GET /api/profile-requests`) depende da feature de aprovação de cadastro, que não existe no backend — o badge não tem de onde vir hoje.
> Caracteres: 2359 (inclui espaços) · Limite: não confirmado (uxpilot free) — se precisar cortar, tire o bloco mais especulativo primeiro

## Prompt (colar na IA de layout)
```
Pagina — Smart Boarding — painel inicial do administrador, ponto de partida pra tudo que ele gerencia — administrador organizando o dia a dia do transporte — faixa de celular pequena a grande, retrato.

CONTEXTO & PROPOSITO:
- E o hub do administrador: em vez de abas escondendo tudo, um painel com cartoes claros pra cada area — rotas, solicitacoes, trajeto, notificacoes, relatorios, usuarios.

SENTIMENTO & EXPERIENCIA:
- Sensacao de comando tranquilo: tudo visivel de uma vez, prioridades claras (o que precisa de atencao aparece em destaque), nada escondido atras de abas.

TEMA & TOKENS:
- Hex reais: fundo claro #CAD2C5, verde geral #84A98C, verde principal/seed #52796F, apoio escuro #354F52, fundo escuro #2F3E46. Raio: 12 em cartoes, 10 em botoes/campos. Fonte: Montserrat.
- Paleta sage, Montserrat. Cartoes com respiro generoso entre eles, icones grandes e claros por area.

ACAO PRINCIPAL:
- Ir pra area que precisa de atencao. O cartao de solicitacoes de cadastro ganha destaque visual quando ha pendencias (contagem em selo).

CONSISTENCIA:
- Reusa os componentes ja padronizados do app: selo de contagem, cartoes com cantos suaves, mesmo tom das outras telas do admin.

BLOCOS:
- Cabecalho: saudacao ao administrador.
- Grade de cartoes de atalho, um por area: Solicitacoes de Cadastro (com selo de quantos pendentes), Gerenciar Rotas, Trajeto, Notificacoes, Relatorios, Usuarios — cada um com icone proprio e nome claro.

CONTEUDO & DADOS:
- Por cartao: nome da area, icone, e (so no de solicitacoes) a contagem de pendentes.
- Exemplo pt-BR: "Solicitações de Cadastro — 3 pendentes". Contorno: zero pendencias (selo some ou fica neutro, sem alarmar).

ESTADOS:
- Carregando a contagem de pendencias: espaco reservado discreto, sem travar o resto do painel.
- Sem pendencias: o cartao de solicitacoes fica no tom normal, sem destaque extra.

INTERACAO & FLUXO:
- E a primeira tela do administrador apos o login. Cada cartao leva pra sua area; ao voltar, retorna aqui.
- Textos pt-BR: "Solicitações de Cadastro", "Gerenciar Rotas", "Trajeto", "Notificações", "Relatórios", "Usuários".

CUIDADO & EXPERIENCIA:
- Toques confortaveis nos cartoes; contraste bom; selo de contagem sempre com numero visivel, nunca so uma bolinha colorida.
- NAO: esconder areas atras de mais de um nivel de navegacao; inventar mais atalhos do que os seis listados.
```

## Notas de decisão
- Ação primária: navegar pra uma área de gestão · Estados: contagem carregando, sem pendências · Pendências ⛳: contagem de pendências depende da feature de aprovação (gap total).
- **Mudança estrutural real**: a tela atual (`admin_home_screen.dart`, já com o design system da Fase A) usa `NavigationBar` com 5 abas na base (Listas/Rotas/Relatórios/Broadcast/Usuários) — a spec da reforma pede um dashboard de cartões com 6 áreas (troca Listas por Trajeto+Solicitações, unifica Notificações). Este prompt já reflete o alvo novo, não o padrão atual de abas.
