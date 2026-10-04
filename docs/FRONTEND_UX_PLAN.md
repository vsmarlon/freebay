# Frontend UX hardening plan

**Status:** source implementation is integrated; current Flutter verification is **not green**. Format, analyze and test failed; code generation and a subsequent debug APK build passed. The APK launch reached the localized login screen on an Android 11 Galaxy A30, not an authenticated journey or complete device UX gate. See [`docs/test-runs/2026-10-01/frontend-ux-finalization/REPORT.md`](test-runs/2026-10-01/frontend-ux-finalization/REPORT.md) and [`docs/test-runs/2026-10-01/current-flutter-verification/REPORT.md`](test-runs/2026-10-01/current-flutter-verification/REPORT.md) for exact outcomes and limits. This is not a release-readiness claim. Read `docs/FEATURE_TRUTH.md` before changing feature claims, `frontend/DESIGN.md` before UI work, and `docs/HARDENING_PLAN.md` for the surrounding hardening boundaries. Preserve unrelated working-tree changes.

## Intent and outcomes

Improve the existing Flutter journeys rather than imitate features FreeBay does not provide. Keep the established Digital Brutalist system, existing API and persistence contracts, privacy boundaries, all five `AppShell` tab indexes, and current route constants. Scope includes accessibility, loading/error/empty/offline states, interaction feedback, and performance where measured. Do not infer backend, payment-provider, or device readiness from a client-side change.

Targets to measure, not assert without evidence: warm navigation under one second on the specified device; fewer than 1% frames over 16 ms on the target scroll path; no repeated keyboard presentation when returning to an already mounted tab. Record device, build mode, fixture, sample size, raw results, and blockers; do not treat these targets as already achieved.

## Phases

| Phase | Scope | Acceptance / evidence |
|---|---|---|
| U0 | Baseline and journey inventory | **Recorded.** Historical device baseline is diagnostic only; finalization source and gate evidence is in the report linked above. |
| U1 | Critical first-use and navigation order | **Implemented, source/focused-test evidence.** Five shell indexes/routes retained; no complete buying/provider journey is claimed. Device journey/back-restore observation remains pending. |
| U2 | Refresh, cache, and privacy-safe lifecycle | **Implemented, focused cache/state evidence.** User cache purge/write ordering and privacy boundaries are covered in the finalization report; production persistence/device lifecycle remain unverified. |
| U3 | In-flight requests and source identity | **Implemented, focused evidence.** Pagination and social mutation reconciliation were updated; see report for the focused test blockage and integrated final gates. |
| U4 | Media/loading/offline polish | **Implemented in source.** Shared shimmer, public-media BlurHash wiring, native editor source and localization are present. Production schema was not verified; local development schema evidence and device pixel validation are recorded separately. |
| U5 | Measured rebuild reduction | **Not complete.** No comparable post-change profile is available; the historical diagnostic sample does not establish target attainment. |
| U6 | Accessibility and design-system ratchet | **Source changes integrated; physical accessibility checks pending.** Labels, hit targets, reduced motion, and approved contrast changes do not establish text-scaling/device accessibility success. |
| U7 | Frontend state and feature-boundary guidance | **Guidance updated.** Stories and media editor have owning Dart feature boundaries; native platform implementation remains in platform folders. |
| U8 | Physical-device observation | **Pending.** Native compositor pixels, editor journeys, and UX walk-through have not been run on physical devices. |

### U1 ordering rule

Do not reorder shell indexes, rewrite unrelated routes, or disrupt the user's open state merely to make navigation appear consistent. First-use copy and primary actions must lead to existing supported journeys. Where a journey currently stops, state that limit plainly rather than inventing a successful end state.

### U2 privacy and refresh constraints

Only cache data whose visibility and invalidation contract are understood. Do not persist private data in an app-wide/public cache. Session/account changes and explicit revocation must invalidate private data. Preserve cursor and ordering contracts. Defer threshold tuning until a repeatable measurement demonstrates a need.

### U4 localization and media constraints

Use Flutter SDK `flutter_localizations` and generated `gen-l10n` output from complete English and Brazilian Portuguese ARB catalogs. Runtime resolution supports `en` and `pt_BR`; Portuguese maps to `pt_BR`, and unsupported locales currently fall back to `pt_BR`. Do not add a language picker or locale persistence without a separate product request. Translate visible user-facing UI only; never translate API enums, identifiers, backend values, logs, method-channel contracts, or stored entity fields. Failure codes and server error payloads remain protocol data; presentation maps stable failure types/codes to localized copy and does not display arbitrary raw server text. Preserve integer cents and the current `R$` / two-decimal Brazilian currency output exactly; locale-aware date/time copy must not alter timestamps or stored UTC instants. BlurHash is a placeholder, not a media cache or replacement for authorization, cancellation, image decoding, or native pixel composition. Catalog key parity/source scans do not prove generated localization compilation; record that separately in the verification report.

## Operating agreement and hardening protocol

- Work only in the authorized UX scope; no commits, pushes, resets, migrations, destructive operations, or edits to unrelated user work.
- Read `FEATURE_TRUTH.md`, `DESIGN.md`, the applicable `.agents/skills` (and test-audit for tests) before edits. Follow behavior test-first where an actual behavioral regression is being fixed; do not manufacture a RED from missing generated code, broken fixtures, or tool availability.
- Keep independent UI/content changes separate from backend/API/schema and pure hardening refactors. Preserve routes, money units, privacy, account isolation, and existing design-system contracts.
- Run focused checks after each coherent slice. Run the full verification gates only after all parallel work is integrated and dependencies/code generation are settled. Capture exact commands, working-tree identity, environment without secrets, statuses, logs, and evidence in the report. Unknown or blocked means blocked, not passed.
- Update `FEATURE_TRUTH.md` only when implementation evidence changes and name the exact boundary and verification. This plan alone is not evidence.

## Deferred / explicitly authorized in this UX track

The owner authorized English + pt-BR localization using SDK `flutter_localizations` / ARB generation, `flutter_blurhash: ^0.9.1`, and scoped native accessibility/image-compositor work. The integrated source also includes the approved cross-cutting cache, interaction-guard, feature-boundary, and design-token work tracked in the linked finalization report. This does not authorize broad feature redesign, API/payment behavior changes, new locale preference persistence, or media storage redesign. Native source alignment is not pixel-validation evidence; Android and iOS execution remain device gates. Anything beyond the recorded UX scope remains deferred until separately approved.

## Completion report contract

Use `docs/test-runs/2026-10-01/frontend-ux-finalization/REPORT.md`. Distinguish implementation status from verification status; list exact commands and exit results; identify integrated work and remaining device/performance evidence; report deviations and blockers. Do not mark U0–U8 complete based solely on code edits.
