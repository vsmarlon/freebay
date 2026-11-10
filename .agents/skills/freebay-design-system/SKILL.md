---
name: freebay-design-system
description: Use when writing or reviewing FreeBay Flutter UI, visual tokens, components, or motion.
---

# Digital Brutalist UI

Read [`frontend/DESIGN.md`](../../../frontend/DESIGN.md) before UI edits. It is the sole token authority; do not copy token values here. Read component exports in `frontend/lib/core/ui.dart` and reuse existing primitives.

- Square geometry (0 radius); tonal layering or `AppDepth` hard-offset depth, never blur; separate sections with tonal blocks, not lines/dividers.
- Resolve colors through theme context; typography uses `AppTypography` and variable-font weight helpers; motion uses `AppMotion` roles. Avoid hand-coded brightness branches and raw duration/easing values.
- Use accessible labels/actions and the existing loading, empty and error components. Preserve native continuous gestures, reverse scrolling and keyboard behavior where applicable.
- `make design-check`, format/analyze commands are defined in root `AGENTS.md`; run applicable gates and report real output. Do not assert device validation from widget evidence.
