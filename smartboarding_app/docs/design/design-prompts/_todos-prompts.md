# Todos os prompts de design — Smart Boarding (colar direto no uxpilot)

> Gerado a partir dos 12 arquivos individuais em `docs/design-prompts/`. Cada bloco abaixo é autocontido — copie só o conteúdo entre as crases de cada tela e cole no uxpilot. Detalhe de gaps/contrato/notas de decisão fica nos arquivos individuais, não repetido aqui.

---

## Login

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

---

## Cadastro por convite

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

---

## Recuperar/redefinir senha

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

---

## Início do aluno

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

---

## Relatórios (aluno + admin)

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

---

## Inbox de notificações

```
Pagina — Smart Boarding — inbox de notificacoes, historico do que ja foi avisado — aluno ou administrador conferindo os avisos recentes — faixa de celular pequena a grande, retrato.

CONTEXTO & PROPOSITO:
- Lugar pra rever o que ja foi avisado: lista aberta, lista fechada, aviso do administrador — tudo num so lugar, em ordem cronologica.

SENTIMENTO & EXPERIENCIA:
- Organizacao tranquila: uma linha do tempo simples de acompanhar, sem ansiedade de perder um aviso importante.

TEMA & TOKENS:
- Hex reais: fundo claro #CAD2C5, verde geral #84A98C, verde principal/seed #52796F, apoio escuro #354F52, fundo escuro #2F3E46. Raio: 12 em cartoes, 10 em botoes/campos. Fonte: Montserrat.
- Paleta sage, Montserrat, mesmo vocabulario de lista do app.

ACAO PRINCIPAL:
- Rever os avisos recentes. Pro administrador, um botao flutuante leva pra compor um aviso novo (tela separada).

CONSISTENCIA:
- Mesmo vocabulario de lista do app: linha com icone, titulo em destaque, data como referencia temporal.

BLOCOS:
- Lista cronologica: cada aviso com titulo, corpo resumido, imagem quando houver, e a rota especifica quando o aviso nao for geral.
- Botao de compor (so admin): flutuante, sempre alcancavel, leva pra tela de envio.

CONTEUDO & DADOS:
- Por aviso: titulo, corpo, imagem opcional, escopo (geral ou uma rota especifica), data/hora.
- Exemplo pt-BR: "Lista fechada — Embarque confirmado, as listas de hoje foram fechadas." Contorno: aviso sem imagem, aviso geral vs. de uma rota so, texto de corpo longo.

ESTADOS:
- Carregando: contornos do conteudo. Vazio: mensagem tranquila, sem alarme, "nenhuma notificacao ainda".
- Erro ao carregar: aviso gentil com tentar de novo.

INTERACAO & FLUXO:
- Acessivel tanto pro aluno quanto pro admin, cada um ve o que se aplica a ele. Admin tem o botao extra de compor.
- Textos pt-BR: "Notificações", "Nenhuma notificação ainda".

CUIDADO & EXPERIENCIA:
- Imagens com proporcao consistente, nunca distorcidas; contraste bom; toques confortaveis.
- NAO: misturar o botao de compor na visao do aluno; inventar contador de nao-lidas (o produto nao tem esse conceito hoje).
```

---

## Enviar notificação (admin)

```
Pagina — Smart Boarding — compor e enviar uma notificacao manual — administrador avisando algo importante pra todo mundo (ou uma rota especifica) — faixa de celular pequena a grande, retrato.

CONTEXTO & PROPOSITO:
- Ferramenta direta do administrador pra avisar algo que nao se encaixa nos avisos automaticos — um recado pontual, com controle de pra quem vai.

SENTIMENTO & EXPERIENCIA:
- Confianca e controle: a pessoa precisa sentir que sabe exatamente quem vai receber antes de apertar enviar.

TEMA & TOKENS:
- Hex reais: fundo claro #CAD2C5, verde geral #84A98C, verde principal/seed #52796F, apoio escuro #354F52, fundo escuro #2F3E46. Raio: 12 em cartoes, 10 em botoes/campos. Fonte: Montserrat.
- Paleta sage, Montserrat, mesmo vocabulario de formulario do app.

ACAO PRINCIPAL:
- Enviar a notificacao. Botao de destaque com icone de enviar, ao final do formulario, sempre visivel.

CONSISTENCIA:
- Mesmo vocabulario de formulario ja padronizado: campo com contorno leve, botao que troca o icone por um carregamento discreto ao confirmar.

BLOCOS:
- Cabecalho: titulo curto da acao, "a mensagem sera enviada pra quem voce escolher".
- Conteudo: titulo e corpo da mensagem, obrigatorios.
- Imagem opcional (a criar no back — hoje o envio e so texto).
- Escopo: geral (todos) ou uma rota especifica (a criar no back — hoje todo envio e sempre geral).
- Acao: enviar, com um resumo rapido de pra quem vai antes de confirmar.

CONTEUDO & DADOS:
- Campos reais: titulo (obrigatorio), corpo (obrigatorio, texto livre). Exemplo pt-BR: titulo "Aviso importante", corpo "O onibus de amanha sai 10 minutos mais cedo."
- Contorno: titulo vazio, corpo bem longo.

ESTADOS:
- Enviando: botao em carregamento. Sucesso: confirmacao "notificacao enviada" e os campos limpam.
- Erro ao enviar: aviso gentil, convite a tentar de novo.

INTERACAO & FLUXO:
- Alcancada pelo botao de compor da tela de notificacoes. Ao enviar com sucesso, volta pro historico (inbox) atualizado.
- Textos pt-BR: "Enviar Notificação", "Título", "Mensagem", "Enviar para todos".

CUIDADO & EXPERIENCIA:
- Contraste bom; toques confortaveis; nunca enviar sem o titulo/corpo preenchidos.
- NAO: prometer selecao de rota especifica ou imagem como se ja funcionassem de verdade — sao intencao de produto, nao dado real hoje.
```

---

## Painel do admin

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

---

## Solicitações de cadastro (admin)

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

---

## Gerenciar rotas (admin)

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

---

## Trajeto (admin)

```
Pagina — Smart Boarding — conducao do trajeto do dia — administrador avisando os inscritos em cada etapa da viagem, do inicio ao fim — faixa de celular pequena a grande, retrato.

CONTEXTO & PROPOSITO:
- Ferramenta do administrador pra avisar em tempo real cada etapa do trajeto: saiu, passou por um ponto principal, terminou — sem depender de motorista com conta propria.

SENTIMENTO & EXPERIENCIA:
- Praticidade e confianca: um gesto simples por etapa, com certeza de que o aviso chega — quem esta usando pode estar com pressa, perto do veiculo.

TEMA & TOKENS:
- Hex reais: fundo claro #CAD2C5, verde geral #84A98C, verde principal/seed #52796F, apoio escuro #354F52, fundo escuro #2F3E46. Raio: 12 em cartoes, 10 em botoes/campos. Fonte: Montserrat.
- Paleta sage, Montserrat. Botao de acao em destaque, o resto da tela calmo, sem competir.

ACAO PRINCIPAL:
- Avancar o trajeto: iniciar, depois um botao por ponto principal (checkpoint), depois finalizar. Um botao de destaque por vez, na ordem certa.

CONSISTENCIA:
- Mesmo vocabulario de acao com confirmacao ja usado no app: dialogo antes de agir, botao que vira carregamento, retorno de "notificacao enviada pra N alunos".

BLOCOS:
- Selecao da rota/lista do dia.
- Botao "Iniciar trajeto" — disponivel antes de comecar.
- Um botao por ponto principal (rodoviaria + instituicoes da rota) — aparecem na ordem do trajeto, cada um vira "concluido" apos o checkpoint.
- Botao "Finalizar trajeto" — disponivel so depois do ultimo checkpoint.

CONTEUDO & DADOS:
- Por rota: nome, lista de pontos principais (nome de cada um — a criar no back, sem entidade de parada hoje).
- Exemplo pt-BR: "Rodoviária", "Unifor — Campus Central". Contorno: rota sem pontos principais cadastrados ainda.

ESTADOS:
- Antes de iniciar: so o botao de iniciar disponivel. Em andamento: pontos ja passados ficam marcados, o proximo em destaque.
- Cada acao pede confirmacao antes de disparar. Sucesso: "notificação enviada para N aluno(s)".
- Funciona com a lista aberta ou ja fechada — o trajeto acontece depois do fechamento tambem.

INTERACAO & FLUXO:
- Alcancada pelo cartao "Trajeto" do painel do admin. Sequencia linear: iniciar, checkpoints em ordem, finalizar.
- Textos pt-BR: "Iniciar trajeto", "Finalizar trajeto", "Notificação enviada para N aluno(s)".

CUIDADO & EXPERIENCIA:
- Toques bem confortaveis (quem usa pode estar com pressa ou em movimento); confirmacao sempre antes de cada etapa.
- NAO: permitir checkpoint fora de ordem sem deixar claro visualmente; inventar rastreamento de GPS ao vivo (fora de escopo do produto — so pontos fixos avisados manualmente).
```

---

## Usuários (admin)

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

---

