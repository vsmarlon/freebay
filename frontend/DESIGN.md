# The Digital Brutalist

The FreeBay design system. This file is the source of truth for tokens. Every value
below exists as a named constant in `libs/freebay_design_system/lib/tokens/` — when
they disagree, the code wins and this file is wrong. Do not copy hex values into
other documents; link here instead.

## Axioms

1. **Square corners, everywhere.** No `BorderRadius.circular`, `StadiumBorder`,
   `CircleBorder`, `CircleAvatar`, `ClipOval`. Avatars are squares. 0px is the
   framework default and the theme squares every Material widget that would
   otherwise round itself — so you never write `BorderRadius.zero`. If a corner is
   round, something is overriding the theme.
2. **No blurred shadows.** Depth comes from two things: tonal layering (step the
   surface) and the hard offset shadow (`AppDepth`). A `blurRadius` anywhere is a bug.
3. **No divider lines.** Separate content by putting adjacent surfaces on different
   tonal steps. `Divider` is themed to zero height and transparent; a visible
   hairline border used as a separator is the same anti-pattern wearing a hat.
4. **Two families, real weights.** Space Grotesk for display, Inter for everything
   read as text. Both are variable fonts — weight is applied through
   `fontVariations`, never `fontWeight` alone (see Type).
5. **Magenta is a laser.** `#8A1083` marks the primary action, the focus ring, the
   active tab, the one thing that matters on screen. It is the only saturated colour
   in the system besides the four status colours. There is no secondary accent.
6. **Motion answers the finger.** Named roles only (see Motion). No bouncy or
   symmetric easing — `elasticOut`, `easeOutBack` and `easeInOut` are banned.
7. **Dark mode is not a variant.** Read colours from the theme, never from a
   brightness check. If you are writing `isDark ? a : b` for a colour, the token
   you want already exists.

## Colour

Colours reach widgets through the theme. Three ways to read one, in order of preference:

```dart
context.textPrimary                    // the semantic getters — prefer these
context.colors.surfaceContainerHigh    // the full ColorScheme
AppColors.primaryContainer             // raw palette; brand marks that never adapt
```

`AppColors` is the palette. `AppTheme` maps it into a `ColorScheme` per brightness.
`AppThemeContext` (the `context.*` getters) reads that `ColorScheme`. Because all
three now agree, `isDark` ternaries for colour are always redundant.

### Surface ladder

Depth is a step on this ladder, never a shadow. Put child content one step above its
parent.

| Role | Light | Dark | Getter |
|---|---|---|---|
| Lowest | `#FFFEF8` | `#0A0A0A` | `colors.surfaceContainerLowest` |
| Base canvas | `#FCF9EE` | `#121212` | `context.bgColor` |
| Card / tile | `#F7F3E7` | `#1C1C1C` | `context.surfaceColor` |
| Elevated | `#F1ECDE` | `#242424` | `context.surfaceMidColor` |
| High | `#EAE4D5` | `#2E2E2E` | `context.surfaceHighColor` |
| Highest | `#E3DCCB` | `#383838` | `colors.surfaceContainerHighest` |

The dark ladder is neutral on purpose. Any hue in the greys competes with the
magenta and makes it read as decoration rather than signal.

### Ink and edges

| Role | Light | Dark | Getter |
|---|---|---|---|
| Primary text | `#11100E` | `#F1F1F1` | `context.textPrimary` |
| Muted text | `#403C34` | `#A0A0A0` | `context.textSecondary` |
| Hard border | `#11100E` | `#FF9DEE` | `context.borderColor` |
| Soft border | `#C9C1B2` | `#3A3A3A` | `context.borderSoftColor` |

The hard border is ink, not grey. A brutalist outline that apologises is just a box.

### Brand and status

| Token | Value | Use |
|---|---|---|
| `AppColors.primary` | `#660062` | Gradient start, hard shadow under primary buttons |
| `AppColors.primaryForeground` | `#FF9DEE` | Dark-mode foreground accent and hard border |
| `AppColors.primaryContainer` | `#8A1083` | The magenta. Primary action fills, focus surfaces |
| `AppColors.brutalistGradient` | `#660062 → #8A1083` | Primary button fill only |
| `AppColors.success` | `#10B981` | Escrow released, verified |
| `AppColors.warning` | `#F59E0B` | Escrow held, pending |
| `AppColors.error` | `#BA1A1A` | Disputes, destructive actions, validation |
| `AppColors.info` | `#3B82F6` | Neutral informational state |

In dark mode, `ColorScheme.primary` is the accessible `#FF9DEE` foreground/accent;
`primaryContainer` remains the `#8A1083` action fill and `onPrimaryContainer` remains
white on that fill. `AppColors.primaryForeground` names the contrast foreground token;
the palette `primary` remains the darker `#660062` gradient stop.

## Type

Both faces ship as variable fonts (`SpaceGrotesk[wght].ttf`, `Inter[opsz,wght].ttf`)
declared with a single asset and no per-weight entries. Flutter therefore cannot
resolve a weight from `fontWeight` alone — it falls back to synthetic bold, which
collapses w500 through w900 into one rendered weight. **Every style must carry
`fontVariations`.** `AppTypography` does this for you; if you need a different weight
at a call site, use the extension rather than `copyWith(fontWeight:)`:

```dart
Text('SOLD', style: AppTypography.h2.weight(900))
```

| Token | Family | Size | Weight | Tracking | Leading |
|---|---|---|---|---|---|
| `displayHero` | Grotesk | 56 | 800 | −2.0 | 0.95 |
| `h1` | Grotesk | 34 | 700 | −1.0 | 1.15 |
| `h2` | Grotesk | 24 | 700 | −0.5 | 1.20 |
| `h3` | Grotesk | 18 | 700 | −0.2 | 1.30 |
| `bodyLarge` | Inter | 16 | 400 | 0 | 1.55 |
| `bodyMedium` | Inter | 14 | 400 | 0 | 1.50 |
| `bodySmall` | Inter | 12 | 400 | 0.1 | 1.40 |
| `labelLarge` | Inter | 13 | 600 | 0.2 | 1.20 |
| `labelSmall` | Inter | 11 | 600 | 0.3 | 1.20 |
| `brutalistTag` | Grotesk | 11 | 700 | 0.6 | 1.00 |
| `button` | Grotesk | 15 | 700 | 0.3 | 1.00 |

Styles carry no colour. They inherit from the theme so they adapt; pass a colour only
when the text sits on a non-surface background (a magenta button, an image overlay).

`AppTypography` is also wired into `ThemeData.textTheme`, so `context.textTheme.titleLarge`
and `AppTypography.h2` are the same style. Prefer the `AppTypography` name — it says
which step of the scale you meant.

Body copy wraps below 80 characters. ALL CAPS is the nav and label vernacular
(`EXPLORAR`, `CONFIRMAR ENTREGA`); do not extend it to sentences.

Secondary copy sitting directly on the backdrop (empty states, hints) uses
`context.textSecondary` — never a hardcoded `mediumGray`/`outline`, which
loses contrast in one of the two modes. `EmptyState` already follows this.

## Background

Every screen shows the aurora. Pushed pages wrap `body:` in `AppBackground`
(with a transparent `Scaffold`); tab pages stay transparent and inherit the
shell's. `AppBackground` honors the user's "Fundo animado" setting: animated
shader when on, one frozen aurora frame (`staticAurora`) when off. Flat
`bgColor` scaffolds covering the aurora are a bug — as is navigating anywhere
with a raw string literal (see `AppRoutes`; enforced by `make routes-check`).

## Motion

Roles, not milliseconds. `AppMotion`:

| Token | Duration | Curve | Use |
|---|---|---|---|
| `tap` | 120ms | `tapCurve` (linear) | Press, displace, toggle — anything under a finger |
| `base` | 180ms | `baseCurve` (linear) | State changes, tab switches, expand/collapse |
| `enter` | 240ms | `enterCurve` (easeOut) | Something arriving: routes, sheets, first paint |
| `shimmer` | 1000ms | linear | Skeleton loop |
| `ambient` | 8000ms | linear | The auth backdrop drift |

Linear for anything the finger drives — easing a press makes it feel laggy. `easeOut`
only for arrivals, because things entering decelerate. Nothing eases in, and nothing
overshoots.

When the platform requests reduced motion, `AppMotion.forContext` returns zero for
route and shell-page transitions; skeleton scopes stop their repeating clock. Keep
state changes and haptic feedback functional.

## Depth

One tactile idiom, `AppDepth`. A pressable surface carries a hard offset shadow and
displaces by the same distance when pressed, so the shadow collapses under it.

| Token | Value |
|---|---|
| `pressOffset` | `3.0` |
| `shadowOffset` | `Offset(3, 3)` |
| `shadowOffsetSmall` | `Offset(2, 2)` — text shadows, small chrome |
| `borderThin` | `1.5` |
| `borderThick` | `2.0` |
| `hard(color)` | The shadow list. Never has a blur. |

```dart
AnimatedContainer(
  duration: AppMotion.tap,
  curve: AppMotion.tapCurve,
  transform: Matrix4.translationValues(
    pressed ? AppDepth.pressOffset : 0.0,
    pressed ? AppDepth.pressOffset : 0.0,
    0.0,
  ),
  child: DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: context.borderColor, width: AppDepth.borderThick),
      boxShadow: pressed ? null : AppDepth.hard(context.borderColor),
    ),
    ...
```

## Spacing

`Spacing` — an 8px grid: `xs 4`, `sm 8`, `md 16`, `lg 24`, `xl 32`, `xxl 48`.
Prebuilt gaps avoid a `SizedBox` literal: `Spacing.vMd` (vertical), `Spacing.hSm`
(horizontal). Screen horizontal padding is `Spacing.md`. There is one spacing scale;
if you find another, delete it.

## Components

Import everything through `package:freebay/core/ui.dart`. It re-exports the design
system package plus the app-level components. Do not import
`package:freebay_design_system/...` directly from a feature.

Before building a UI primitive, check whether it exists. The common ones:

| Need | Use | Not |
|---|---|---|
| Button | `AppButton(label:, variant:, size:)` — `primary`, `secondary`, `ghost`, `danger` | `ElevatedButton`, `OutlinedButton`, `TextButton`, `GestureDetector` + `Container` |
| Icon button | `BrutalistIconButton` | `IconButton` |
| Bordered surface | `BrutalistBox` (takes `onTap:`) | `Container` + `BoxDecoration` + `Border.all` |
| Text input | `AppTextField` | `TextField`, `TextFormField` |
| Filter chip | `BrutalistFilterChip` | `FilterChip`, `ChoiceChip` |
| Bottom sheet | `showBrutalistSheet<T>()` / `BrutalistSheetScaffold` | `showModalBottomSheet` |
| Snackbar | `AppSnackbar` | `ScaffoldMessenger.showSnackBar` |
| Empty state | `EmptyState` | An inline `Column` with an icon and two `Text`s |
| Loading | `ShimmerBlock`, `SkeletonList`, `SkeletonPage` | `CircularProgressIndicator` for page loads |
| Screen header | `PageHeader` | A hand-rolled `AppBar` |
| Avatar | `UserAvatar` | `CircleAvatar` |

Extend a primitive rather than inlining a copy of it. A second implementation of a
thing that already exists is how the system drifts.

## Checks

`make design-check` from the repo root greps for the banned patterns. It is cheap and
runs in CI. The frontend analyzer must also report zero issues — warnings and infos
included, not just errors.
