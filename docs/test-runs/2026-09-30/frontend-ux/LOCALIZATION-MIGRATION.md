# Localization migration handoff

**Preparation status:** catalog prepared; no consuming UI files migrated in this wave. The app root and consumer files have explicit parallel owners; wait for their freeze before migration. Do not count catalog preparation as app localization being live.

## Catalog and generated API

- `frontend/lib/shared/l10n/app_en.arb` — English template and fallback (`en`).
- `frontend/lib/shared/l10n/app_pt_BR.arb` — Brazilian Portuguese (`pt_BR`).
- `frontend/l10n.yaml` — Flutter SDK gen-l10n output is `frontend/lib/shared/l10n/generated/app_localizations.dart`, class `AppLocalizations`; no removed `flutter_gen` synthetic import.
- `frontend/lib/shared/l10n/app_localizations_context.dart` — consumer API is `l10n(context).<generatedGetter>`.
- Catalog currently has **475 message entries per locale**. Interpolation and ICU plural metadata are duplicated with matching declared Dart types across both locales. Recheck key and placeholder parity before every code-generation run.
- `frontend/pubspec.yaml` now declares SDK `flutter_localizations` and owner-approved `flutter_blurhash: ^0.9.1`. Dependency lock refresh is deferred to the coordinated final dependency/codegen stage.

## Source-read coverage informing catalog

Catalog entries were drawn from actual user-facing callsites and shared helper behavior, including auth validation/session/biometry, feed and stories, profile and close-friends, chat and its native-backed image-editor UI, listings/cart/checkout/payments, orders/disputes, wallet, notifications, onboarding, bug reporting, empty states, failure presentation, date/time helpers, and accessibility labels.

Read directly in this preparation: `shared/errors/failures/failures.dart`, `shared/utils/date_utils.dart`, `core/utils/time_utils.dart`, `core/components/empty_state.dart`, `core/components/app_snackbar.dart`, chat image editor toolbar/views/page, and `shared/services/upload_service.dart`. The platform compositor sources (`android/.../NativeImageCompositor.kt`, `ios/Runner/NativeImageCompositor.swift`) carry validation/protocol errors, not end-user UI copy; do not translate their exceptions or channel keys. Design-system controls (`frontend/libs/freebay_design_system/lib/components/`) must stay app-agnostic; callers pass localized `label`, `hint`, and semantics copy.

## Consumer migration distribution (read-only scan)

This counts Dart files matching probable UI-callsite tokens (`Text(`, `label:`, `hintText:`, `title:`, `tooltip:`, `message:`), so it is a **candidate inventory**, not an AST-verified count of translatable literals. Dynamic user content, route metadata, API values, and logs must be inspected and excluded rather than translated mechanically.

| Consumer source family | Candidate files |
|---|---:|
| `frontend/lib/features/auth/**` | 9 |
| `frontend/lib/features/social/**` | 34 |
| `frontend/lib/features/profile/**` | 21 |
| `frontend/lib/features/chat/**` | 46 |
| `frontend/lib/features/product/**` | 17 |
| `frontend/lib/features/cart/**` | 1 |
| `frontend/lib/features/payments/**` | 2 |
| `frontend/lib/features/orders/**` | 8 |
| `frontend/lib/features/dispute/**` | 3 |
| `frontend/lib/features/wallet/**` | 5 |
| `frontend/lib/features/notifications/**` | 3 |
| `frontend/lib/features/onboarding/**` | 3 |
| `frontend/lib/features/bug_report/**` | 1 |
| `frontend/lib/core/**` | 33 |
| `frontend/lib/shared/**` | 1 |
| `frontend/libs/freebay_design_system/lib/**` | 2 (caller-injected labels only) |

Inventory command (run from repository root; use file list plus `rg -n` to review actual literals before translating):

```powershell
$pattern = 'Text\(|label:|hintText:|title:|tooltip:|message:'
rg -l $pattern frontend/lib frontend/libs/freebay_design_system/lib -g '*.dart'
```

## Next-wave implementation order

1. After app-root freeze, wire `AppLocalizations.localizationsDelegates` and `.supportedLocales` to `MaterialApp.router` in the actual root (`frontend/lib/main.dart` in this checkout). Leave locale unset so Flutter resolves device locale; ensure English is first fallback. Do not add a language preference.
2. Migrate shared leaf components/helpers first (`core/components`, `shared/errors` presentation mapping, date/time formatting), then feature pages/widgets by owner: auth/onboarding; social/profile; marketplace/cart/payments/orders/disputes/wallet; chat including the Flutter editor controls; notifications/bug report.
3. Localize user-visible validation and generic errors at UI/presentation boundaries. Do not translate `Failure.message` when it is arbitrary backend text, server enums/statuses, analytics/logs, native validation exceptions, serialized entity data, or method-channel keys. Prefer a stable failure type/code to localized message mapping. Ensure no raw exception string leaks into UX.
4. Preserve the current cents integer and exact Brazilian `R$` formatting contract; dates/times may format per active locale without changing UTC storage or business comparisons. Add plural and interpolation tests at the actual generated localizations boundary.
5. Have DS widgets receive app-localized caller parameters without importing `AppLocalizations`; accessibility semantics labels belong at real interactive callsites.
6. Add `BlurHash` only where the image entity/endpoint actually supplies a valid hash; verify malformed/absent hash fallback and that loading, authorization, cancellation, and image caching still use existing paths.
7. Generate localizations, regenerate lockfile/dependencies, run focused localization tests, then run final formatter/analyzer/test/build/root gates. Update `FEATURE_TRUTH.md` to describe shipped localization and explicitly separate code/config evidence from device-tested language coverage.
