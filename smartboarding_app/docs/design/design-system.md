# SmartBoarding App — Design System

> **Fonte da verdade: o Figma** (`rPf69MjkPX0DtpK1QPS6Hm`, screenshots em
> [`figma-screens/`](./figma-screens/)). Os tokens vivem em
> `lib/core/theme/app_theme.dart` (`AppColors`, `AppRadius`, `AppSpacing`).
>
> ⚠️ **Isso inverteu em 2026-08-28.** Até então este documento tratava o código como fonte da
> verdade e listava vários valores do Figma como "não adotar". A decisão mudou: o app passou a
> replicar o desenho, e as divergências antes recusadas (fundo `#F4F6F4`, tamanhos 13/15px) agora
> são o padrão. O que o Figma pede e ainda não existe está em §6.
>
> Sem `.pen`/Pencil: este repo é Flutter (sem Tailwind), então o design system vive em código +
> este `.md`.

---

## 1. Cor

`AppColors` em `app_theme.dart`. Os tons de apoio **não** saem do `ColorScheme`: o Material deriva
outros valores a partir do seed, e o desenho depende destes exatos.

| Token | Hex | Uso |
|---|---|---|
| `ashGrey` | `#CAD2C5` | Fundo das telas de autenticação (login, convite, cadastro) |
| `background` | `#F4F6F4` | Fundo do app autenticado |
| `surface` | `#FFFFFF` | Cartões e campos |
| `mutedTeal` | `#84A98C` | Avatares, apoios secundários |
| `deepTeal` | `#52796F` | **Primária** — botões, ícones de destaque, valores em evidência |
| `darkSlate` | `#354F52` | Ícones sobre círculo claro |
| `charcoal` | `#2F3E46` | Header escuro, cartão de resumo e texto principal |
| `stroke` | `#D1DCD6` | Contorno de cartões e grades |
| `textSecondary` | `#4F6566` | Texto de apoio, rótulos |
| `positiveBg` / `positiveFg` | `#E8F5E9` / `#2E7D32` | Selo de status positivo, painel de trajeto |
| `dangerBg` / `danger` | `#FDECEC` / `#D32F2F` | Badge de pendências, negar, sair |

## 2. Tipografia

- **Fonte:** Montserrat via `google_fonts` — bate 100% com o Figma.
- **Escala customizada.** O desenho usa 13 e 15px, que não existem na escala do Material 3; sem
  sobrescrever o `TextTheme` esses tamanhos não são reproduzíveis. `AppTheme._textTheme` define:
  `displaySmall` 32/w800, `headlineSmall` 22/w700, `titleLarge` 20/w700, `titleMedium` 16/w700,
  `bodyLarge` 15, `bodyMedium` 14, `bodySmall` 13, `labelLarge` 15/w600, `labelMedium` 13/w600.
- Pesos usados: 400/500/600/700/800.
- **Helpers de texto** (`lib/core/text/`): `contagem()` flexiona o substantivo junto do número
  (`7 paradas`, `1 inscrito`) — "0 inscrito(s)" espalhado pelas telas era atalho de programador
  aparecendo pro usuário, e o parêntese não é português. O parâmetro `zero` troca a frase inteira
  quando não há nenhum ("Ninguém inscrito hoje" em vez de "0 inscritos hoje"), que quase sempre
  lê melhor. `primeiroNome()` reduz o nome completo pra saudações no cabeçalho — "Vítor Silva
  Pastor Gonzalez" ocupa duas linhas e empurra as ações pra fora; o cabeçalho é saudação, não
  documento.

## 3. Forma

| Token | Valor | Uso |
|---|---|---|
| `AppRadius.card` | `12` | Cartões, painéis, grades |
| `AppRadius.control` | `10` | Botões, campos, botão de ícone do header |
| `AppRadius.pill` | `20` | Selos de status e badges |

`AppSpacing` expõe `4/8/12/16/24` — a escala observada no desenho.

**`AppSurface`** (`lib/core/theme/app_theme.dart`) nomeia três níveis de superfície por
intenção, não por gosto — quando tudo era caixa branca com fio, um card de rota, um item de
menu e um bloco de estatística tinham o mesmo peso e nada liderava a tela:
- `grouped`: itens de uma lista. Sem fio; fundo e divisores separam.
- `card`: conteúdo solto que precisa se destacar do fundo. Fio de 1px.
- `floating`: o que de fato paira sobre o conteúdo (folha, botão). Sombra (`AppShadow.floating`,
  difusa e quase sem deslocamento — o objetivo é destacar do fundo, não simular objeto suspenso).

**`AppGrid.featureAspectRatio`** (`1.9`) é token porque a proporção das grades de navegação
(painel do admin, início do aluno) estava cravada em duas telas e já tinha divergido — mexer
numa deixava a outra com cartão oco. Essas grades usam `GridView.count` sem `padding` explícito
(`EdgeInsets.zero`): uma grade aninhada sem isso consome o padding do `MediaQuery` por conta
própria e abre um vão antes da primeira linha.

**Borda dos campos** (`AppTheme._build`, `inputDecorationTheme`): o contorno é fixo em todos os
estados (não só ao focar) — sem ele o campo só ganhava borda ao focar e sumia contra o cartão
branco no resto do tempo.

## 4. Componentes (`lib/core/widgets/`)

| Widget | Papel |
|---|---|
| `AppHeader` | Barra escura do topo: linha de apoio + título forte + ação. **Substitui a AppBar** nas telas raiz — no desenho ela não existe como AppBar |
| `HeaderIconButton` | Botão quadrado teal dentro do header |
| `AppCard` | Cartão branco, canto 12, contorno `stroke` — a unidade de conteúdo |
| `SectionTitle` | Título de seção ("Funcionalidades", "Resumo de Hoje") |
| `StatBlock` | Rótulo em caixa alta sobre valor grande, com sufixo opcional (`18 / 45`) |
| `FeatureCard` | Ícone em círculo claro sobre rótulo — grade do painel do admin |
| `AlertCard` | Destaque com ícone colorido, apoio e contador (Solicitações) |
| `AppTextField` | Rótulo em negrito **acima** da caixa (não flutuante), ícone à esquerda |
| `StatusPill` | Selo de status nos três tons |

**`FeatureCard`**: ícone alinhado à esquerda, acima do rótulo — não centralizado num disco. Um
disco grande sobre rótulo centralizado gastava quase o dobro da altura pra dizer a mesma coisa,
e os itens de navegação do painel não cabiam numa dobra só.

**`LoadingCard`**: usa a mesma moldura (`AppCard`) dos cartões de conteúdo, pra a seção não
mudar de forma quando os dados chegam.

**`showStudentProfile`** (`lib/core/widgets/student_sheet.dart`): abre o perfil breve do aluno
numa folha modal. Vive no `core` porque três telas diferentes precisam do mesmo gesto (lista de
usuários, lista de alunos da rota, inscritos do dia). Devolve `true` quando a folha mudou o
status ou o papel da conta — ela só atualiza o próprio estado, então sem esse aviso a lista de
trás continuaria mostrando o aluno recém-promovido no grupo antigo até um pull-to-refresh.
Fechar arrastando ou tocando fora não passa valor nenhum pro `pop`, então a mudança é registrada
por callback em vez do resultado da rota; durante uma gravação a própria folha bloqueia o
fechamento (`PopScope`), pra não devolver um resultado que a requisição em voo ainda vai
contradizer.

**Banner de SnackBar** (`showErrorSnackBar`/`showSuccessSnackBar`, `lib/core/widgets/
snackbar_utils.dart`): só um banner por vez — um segundo erro enquanto o primeiro ainda está na
tela substitui, não empilha por cima. Usa `rootOverlay: true` porque o banner precisa aparecer
por cima de tudo, inclusive de telas empurradas sobre a que disparou o aviso. Deslizar pra cima
também descarta, além do toque: é o gesto natural pra quem já leu e quer tirar o banner do
caminho antes dos 4s do auto-dismiss.

**`AppCard`**: usa `Material` em vez de `Container` pintado — com a cor num `DecoratedBox`
solto, o ink de qualquer `ListTile`/`InkWell` com `onTap` dentro do card era pintado *atrás* do
fundo (toque sem retorno visual, e o Flutter reclamando em debug). No `surface: floating`, a
sombra vai num `DecoratedBox` **por fora** do `Material`: dentro dele, a sombra sai junto com o
recorte (`clipBehavior`) e vaza por cima do próprio conteúdo.

**`AppHeader`**: o título trunca em 2 linhas (`maxLines: 2` + ellipsis) — nome longo virava 3
linhas e empurrava as ações pra fora do alinhamento. `HeaderOverflowMenu`/`HeaderMenuItem`
existem porque três botões sólidos lado a lado no cabeçalho escuro competiam entre si com o
mesmo peso visual; abrir o perfil e sair são ações ocasionais — não precisam de alvo
permanente, só o que se usa todo dia fica à vista. O ícone do menu é contorno, não preenchido:
o cabeçalho já tem um botão sólido (a ação do dia), e dois blocos cheios voltariam a disputar a
atenção.

**`AppListGroup`/`AppListItem`**: agrupa itens relacionados numa superfície só (`AppSurface.
grouped`), separados por divisor, substituindo um `Card` por item — com um cartão por linha,
cada linha pesava o mesmo que um bloco de conteúdo solto e a tela virava uma pilha de caixas do
mesmo tamanho, sem hierarquia. `dividerIndent` alinha o divisor ao texto quando os itens têm
ícone à esquerda — de ponta a ponta ele corta o ícone ao meio. Em `AppListItem`, `trailing` é só
pra informação/navegação; ação destrutiva nunca vai ali — em vermelho cheio, ao lado do
conteúdo, ela viraria o elemento mais saturado da tela sendo o mais raro, então vai pro `menu`
(três pontos) via `destructiveMenuItem`. `StatusDot` substitui a `StatusPill` quando ela competia
por largura com o título: o ponto diz a mesma coisa com um oitavo do espaço.

**`AppTextField`**: `textCapitalization` em caixa alta é só pra campo de código — o código é
normalizado no backend de qualquer jeito, mas ver o que se digita igual ao que está no quadro
evita a dúvida "será que precisa ser maiúscula?". `autofocus` no primeiro campo do formulário
poupa um toque extra só pra começar a digitar. `autofillHints` liga o gerenciador de senhas do
aparelho — sem ele a pessoa digita e-mail e senha na mão em todo login. No cadastro, o hint
precisa ser `newPassword`, não `password`: com `password` o gerenciador ofereceria uma senha
**antiga** salva (de outra conta) em vez de sugerir uma nova forte. `textInputAction`
(`next`/`done`) evita que o teclado mostre só "return" sem navegar, o que custaria um toque a
mais por campo num formulário longo; `onSubmitted` é o que faz o `done` enviar o formulário em
vez de só fechar o teclado. `inputFormatters` aplica máscara (CEP, telefone) — sem isso o campo
mostra `35570000` em vez de `35570-000`. `focusNode` deixa outra tela empurrar o foco pra lá — é
o que permite ao CEP, depois de preencher rua e bairro sozinho, pular direto pro único campo que
sobrou. O contador (`counterText`) só aparece quando `maxLength` é passado (bio, motivo); em CEP
e UF ele seria ruído, porque o formato já diz quanto cabe. Campo `readOnly` (e-mail do convite)
usa `AppColors.background` como fill pra parecer visualmente não-editável.

## 5. Navegação — desvio consciente do Figma

O Figma desenha **3 abas** pro aluno (Início/Avisos/Perfil) e **6 cards** pro admin, incluindo
telas que não existem. O app adapta:

- **Aluno:** sem barra inferior. Só há um destino — Avisos (inbox, fase 2) e Perfil não foram
  construídos, e aba que não leva a lugar nenhum é pior que aba ausente. A barra entra quando
  essas telas existirem.
- **Admin:** o dashboard substituiu o `NavigationBar` de 6 abas. A grade lista só o que tem tela:
  Rotas e Listas, Enviar Aviso, Avisos enviados, Relatórios e Usuários. A lista do dia saiu da
  grade: uma rota tem no máximo uma lista por dia, então ela mora dentro da rota. "Conduzir Trajeto" (fase 3)
  e "Configurações" ficam de fora até existirem.

## 6. O que o Figma pede e ainda não existe

- **Fotos de usuário.** O desenho usa retratos; o app usa iniciais em `CircleAvatar`, porque nenhum
  contrato de API tem campo de foto.
- **Mapa.** O desenho mostra um mapa no início do aluno. Hoje "Ver trajeto completo" abre a lista
  ordenada de paradas (`RouteStopsScreen`) — os dados de parada existem (`stops`), o mapa não.
  Essa tela já inclui `RouteMap` acima da lista (saber por onde o ônibus passa é a informação
  principal ali, além da ordem), mesmo sem o mapa estar no início do aluno ainda. Atenção ao
  importar `latlong2` perto de código que desenha (`CustomPainter`, pino de mapa): o pacote
  exporta sua própria classe `Path`, que sombreia a `Path` de `dart:ui` usada no desenho. Em
  `StopPin`, origem e destino ganham cor própria (verde/bandeira) em vez da cor padrão das
  paradas comuns: num trajeto, início e fim são o que se lê primeiro. O pino é ancorado pela
  ponta (`Marker.alignment: topCenter`), não pelo centro, senão apontaria pro lado errado da
  parada. O traçado entre paradas (`routePolyline`) fica pontilhado quando é só a ligação reta
  (sem caminho por ruas do OSRM) e sólido quando é o caminho real: a diferença visual deixa claro
  que a linha pontilhada não é o trajeto de verdade. As camadas do mapa (tile, traçado, pinos)
  ficam fora do widget principal (`route_map_layers.dart`) porque desenhá-las é assunto separado
  de reagir a toque e enquadrar a câmera (`RouteMap`). No card compacto (`compact: true`), o mapa
  é ilustração, não ferramenta: câmera fixa no enquadramento de todas as paradas
  (`CameraFit.bounds` — centralizar só na primeira parada com zoom fixo escondia o resto do
  trajeto) e gestos desligados (`InteractiveFlag.none`), porque um gesto ali deve rolar a página,
  não mexer no mapa. Em tela cheia, o zoom pela roda do mouse é habilitado explicitamente: é o
  único gesto de zoom disponível sem tela sensível.
- **"Lembrar de mim"** no login: não há suporte de sessão persistente no backend, então o checkbox
  do desenho não foi incluído.
- **Tema escuro.** O Figma só desenhou o claro; o app roda travado em `ThemeMode.light`.
  `AppTheme.dark` continua existindo (espelha o `light`) só pra não quebrar
  `MaterialApp.darkTheme`, que exige o getter.
