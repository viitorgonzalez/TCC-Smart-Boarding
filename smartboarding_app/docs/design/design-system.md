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

## 3. Forma

| Token | Valor | Uso |
|---|---|---|
| `AppRadius.card` | `12` | Cartões, painéis, grades |
| `AppRadius.control` | `10` | Botões, campos, botão de ícone do header |
| `AppRadius.pill` | `20` | Selos de status e badges |

`AppSpacing` expõe `4/8/12/16/24` — a escala observada no desenho.

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
- **"Lembrar de mim"** no login: não há suporte de sessão persistente no backend, então o checkbox
  do desenho não foi incluído.
- **Tema escuro.** O Figma só desenhou o claro; o app roda travado em `ThemeMode.light`.
