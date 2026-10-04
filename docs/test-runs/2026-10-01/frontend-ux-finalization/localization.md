# Frontend localization source integration

**Status:** source integration complete; generated localization and full frontend gates remain pending the parent-session final generation/freeze.

## Changes

- Merged the current shared-key handoffs into `frontend/lib/shared/l10n/app_en.arb` and `app_pt_BR.arb`, including plural/parameter metadata and Favorites/Purchases headings. The two catalogs currently contain **964 message keys each** (excluding `@` metadata keys).
- Replaced remaining routed error, safe-link, FAQ, orders, dispute, profile, and chat UI copy with localization lookups. Localized Favorites/Purchases headings without changing their media rendering.
- Replaced relative timestamps in chat list, chat header, and comments with localized formatting. Absolute fallback dates format the local instant, not its UTC calendar date. Story overlay default text now uses the existing localized editor default.
- Kept `app_pt.arb` as its existing locale stub; runtime resolution explicitly maps Portuguese to `pt_BR` and otherwise falls back to Brazilian Portuguese.

## Verification performed

- Node JSON validation and catalog-key parity check: **passed**, 964 messages in each English and Brazilian Portuguese catalog; no missing counterpart keys.
- Getter/member scan over `frontend/lib`: **no unknown localization members found** in `strings`, `l10n(context)`, `l10n(ctx)`, or `l10n(consumerContext)` expressions.
- Scoped `git diff --check`: **passed**, exit 0.
- Flutter code generation, format, analyze, tests, and build were intentionally not run before the coordinated source freeze.

## Pending

Run from `frontend` after all source owners freeze:

```bash
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test libs/freebay_design_system/lib
flutter analyze --fatal-infos lib test libs/freebay_design_system/lib
flutter test
flutter build apk --debug
```

Then review generated output and localization fixtures/assertions. Keep failures and blocked gates distinct from passes.
