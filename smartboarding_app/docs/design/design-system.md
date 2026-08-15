# SmartBoarding App — Design System

> Fonte de verdade dos tokens: [`spec.md`](./spec.md) §4.5 + `lib/core/theme/app_theme.dart`.
> Este arquivo espelha o que já está **implementado no código** e audita contra as 14 telas do
> Figma de referência (`rPf69MjkPX0DtpK1QPS6Hm`, screenshots em
> [`figma-screens/`](./figma-screens/), extraídas em 2026-08-14). Onde o Figma diverge do código,
> está marcado ⚠️ com a decisão em aberto — **nada aqui foi implementado a partir do Figma**, é só
> auditoria.
>
> Sem `.pen`/Pencil: este repo é Flutter (sem Tailwind), então o design system vive só em código +
> este `.md` — ver nota em `../../CLAUDE.md` (harness).

---

## Cor

### Paleta oficial — fonte de verdade, tem prioridade sobre o Figma

`ColorScheme` derivado via `ColorScheme.fromSeed(seedColor: DeepTeal)` — 5 tons fecham a paleta
(reforma 2026-08-14, `spec.md` §4.5). Onde o Figma bater, ótimo; onde divergir, **o código manda**:

| Tom | Hex | Uso no código | No Figma |
|---|---|---|---|
| Ash Grey | `#CAD2C5` | Fundo do tema light | ✓ usado — mas só nas 4 telas de auth (`login`, `cadastro-convite`, `recuperar-senha`, `redefinir-senha`) |
| Muted Teal | `#84A98C` | Verde de uso geral | ✓ usado (ícones/backgrounds secundários) |
| Deep Teal | `#52796F` | Verde geral / seed do scheme | ✓ usado — botões primários, FAB |
| Dark Slate Grey | `#354F52` | Tom escuro de apoio (dark theme) | não aparece — Figma só desenhou o tema light, esperado |
| Charcoal Blue | `#2F3E46` | Fundo do tema **dark** | ✓ usado no Figma, mas como cor de **header/appbar e texto principal no tema light** (barra superior de todas as telas, títulos) — reaproveitado fora do papel original |

**Não válido — Figma diverge da paleta oficial, não adotar:** fundo `#F4F6F4` (10 das 14 telas,
deveria ser `Ash Grey #CAD2C5`), stroke `#D1DCD6`, texto secundário `#4F6566`/`#6B7A75`. Esses
valores não entram no design system; se aparecerem numa implementação, é o Figma que está errado,
não o código.

### Tokens semânticos novos — validados, a formalizar no código

Diferente dos acima, esses dois pares de cor (erro e confirmação) aparecem de forma consistente
em várias telas do Figma e **passam a valer como padrão oficial**, mesmo não estando implementados
ainda em `app_theme.dart`:

| Papel | Tom | Hex | Uso observado |
|---|---|---|---|
| Positivo / confirmação | claro (fundo) | `#E8F5E9` | fundo do `StatusPill` (`ABERTA`, `ATIVA`, `IDA`) |
| Positivo / confirmação | forte (texto/ícone) | `#2E7D32` | texto do `StatusPill` positivo |
| Erro / perigo | forte | `#D32F2F` | badge de pendências, botão `Recusar`, link `Sair do Painel` |

**Pendente de implementação:** hoje `spec.md` §4.5 diz que `StatusPill` mapeia só pro `ColorScheme`
existente (`primary`/`surfaceContainerHighest`/`error`), sem cor nova — esses 3 hex formalizam a
exceção. Falta trazer isso pro `app_theme.dart` (`StatusPill.positive`/`.danger`) e atualizar a
spec pra registrar os tokens novos.

---

## Tipografia

- **Fonte:** Montserrat via `google_fonts` — bate 100% com o Figma (única família usada nas 14
  telas) ✓
- **Escala:** `spec.md` §4.5 diz "sem `TextTheme` customizado além da fonte — a escala é a do
  Material 3" (tamanhos padrão: 11, 12, 14, 16, 22, 24, 28, 32...).
- **⚠️ Divergência:** o Figma usa também `13px` e `15px`, que **não existem** na escala padrão do
  Material 3 — não dá pra reproduzir esses dois tamanhos exatos sem customizar o `TextTheme`, o
  que a spec proíbe hoje. Pesos usados: 400/500/600/700/800 (todos suportados pelo Montserrat).

---

## Raio — `AppRadius`

| Token | Valor | Uso | No Figma |
|---|---|---|---|
| `card` | `12.0` | Cards, list tiles | ✓ bate exatamente |
| `control` | `10.0` | Botões, campos | ✓ bate exatamente |

**⚠️ Sem token:** Figma também usa `100px` (FAB circular — não precisa de token, é o padrão de
círculo), `20px` (pills de status/chip grande) e `4–8px` (badges/chips pequenos). Se o padrão se
confirmar em mais telas, vale nomear algo como `AppRadius.pill`.

---

## Spacing

Não existe uma escala nomeada em código hoje (cada tela usa valor solto no `EdgeInsets`). Valores
observados nas 14 telas do Figma: `4, 8, 10, 12, 14, 16, 20, 24, 28` — quase todos múltiplos de 4.
Não é bloqueante, só uma lacuna: se o time quiser consistência, dá pra nomear uma escala em
`AppSpacing` (mirror do `AppRadius`) usando esses valores.

---

## Componentes do produto (`lib/core/widgets/`) — código × Figma

| Widget | No Figma | Nota |
|---|---|---|
| `StatusPill` | ✓ visível (`ABERTA`/`ATIVA`/`INATIVA`, `IDA`/`VOLTA`, badges numéricos) | usa cores literais fora do `ColorScheme` — ver seção Cor |
| `EntityListTile` | ✓ usado nas listas (rotas, solicitações, alunos do relatório) | consistente |
| `TripTypeChip` | ✓ visível em `relatorios-admin` (`IDA`/`VOLTA`) | consistente |
| `InitialsAvatar` | ⚠️ Figma usa fotos reais, não iniciais | nenhum contrato de API (`users`/`students`) documenta campo de foto — provável placeholder de mockup, não mudança de escopo real |
| `EmptyState` / `ErrorState` / `LoadingFilledButton` | não aparecem | esperado — os 14 frames são todos estado "com dados", nenhum captura loading/erro/vazio |

---

## Fora do escopo de design system (arquitetura)

O Figma introduz uma **bottom navigation bar persistente** (aluno: `Início/Avisos/Perfil` · admin:
`Início/Rotas/Alunos`) em várias telas. `spec.md` §4.4 descreve `Navigator` 1.0 com rotas nomeadas
simples, sem shell de tabs — isso é decisão de **navegação**, não de tokens visuais, mas afeta
diretamente como os componentes acima seriam usados. Ver conversa/decisão antes de implementar
qualquer tela a partir do Figma.
