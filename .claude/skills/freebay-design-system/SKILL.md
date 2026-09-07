---
name: freebay-design-system
description: Authoritative guide and token reference for the FreeBay "Digital Brutalist" Flutter design system — 0px radius, tonal layering without shadows, no divider lines, Space Grotesk / Inter typography, and curated brutalist component primitives.
---

# FreeBay Design System: "The Digital Brutalist"

**Read `frontend/DESIGN.md` before writing any Flutter UI in this repo.** It is the
source of truth for every token — colours, the surface ladder, the type scale, motion
roles, depth, spacing — and it is kept in sync with
`frontend/libs/freebay_design_system/lib/tokens/`. Values are deliberately not
repeated here: a hex that lives in two files is a hex that will drift.

## The rules that get broken most

1. **0px radius, everywhere.** The theme squares every Material widget that would
   round itself, so you never write `BorderRadius.zero` either. Avatars are squares.
2. **No blurred shadows.** Depth is a tonal step or the hard offset shadow from
   `AppDepth`. Any `blurRadius` is a bug.
3. **No divider lines.** Separate blocks with adjacent surface tones. This includes
   hairline `Border(bottom:)` used as a separator.
4. **Never read a colour from `isDark`.** `context.textPrimary`,
   `context.surfaceColor`, `context.borderColor` and the rest of `AppThemeContext`
   already resolve per brightness. An `isDark ? colorA : colorB` is always redundant
   and always drifts.
5. **Weights need `fontVariations`.** Both faces are variable fonts declared with a
   single asset; `fontWeight` alone renders as synthetic bold and collapses the
   ladder. Use `AppTypography.*` styles, and `.weight(n)` when you need to override.
6. **Motion uses `AppMotion` roles**, not raw milliseconds. `elasticOut`,
   `easeOutBack` and `easeInOut` are banned.
7. **Reach for the component before building one.** `AppButton`, `BrutalistBox`,
   `AppTextField`, `BrutalistIconButton`, `EmptyState`, `AppSnackbar`, `PageHeader`
   and the skeletons already exist. `DESIGN.md` has the full table of what to use
   instead of what.

## Where things live

- Tokens: `frontend/libs/freebay_design_system/lib/tokens/`
- Design system components: `frontend/libs/freebay_design_system/lib/components/`
- App-level components: `frontend/lib/core/components/`
- Import everything from `package:freebay/core/ui.dart` — never reach into the
  design system package directly from a feature.

## Verifying

`make design-check` greps for the banned patterns above. `make analyze` must be
clean at zero issues, infos included. `make format` gates `dart format`.
