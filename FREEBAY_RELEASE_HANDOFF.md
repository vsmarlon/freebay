# FreeBay production release execution ledger

Updated: 2026-09-14

- Repository: `C:\Users\Qiyana\Documents\GitHub\ME\freebay`
- Branch: `feat/production-hardening`
- Default PR target: `master`
- Parent issues: [#1](https://github.com/vsmarlon/freebay/issues/1), [#2](https://github.com/vsmarlon/freebay/issues/2)
- State: planning approved; execution active.

This file is the canonical execution ledger. Read root `AGENTS.md`, the relevant
`.agents/skills/*/SKILL.md`, the linked GitHub issue, and the current code before
editing. Never resume the old interview.

## Operating contract

- The huge dirty worktree is the intended baseline. Preserve it and all unrelated
  dirty work. Do not reset, clean, revert, format, or run codegen repo-wide.
- Implement serially: one issue, one executor, then the next issue in the order below.
- Before each issue, capture its changed-path allowlist baseline. The executor may
  edit only that allowlist; reject unrelated changes.
- Each executor reads the relevant FreeBay skills, writes focused regression tests
  first, edits only its allowlist, runs issue-local validation, and records results
  or blockers here before proceeding.
- Do not run tester, correctness reviewer, or security auditor per issue.
- After all implementation scopes are complete, run exactly one cumulative tester
  pass, one cumulative correctness review, and one cumulative security audit. Fix
  findings and rerun affected checks. Attach evidence only then; close eligible
  issues only after evidence is attached.
- No secrets, credentials, tokens, personal data, or unrun-check claims in this file.

## GitHub state

Setup is complete: [#13](https://github.com/vsmarlon/freebay/issues/13) and
[#14](https://github.com/vsmarlon/freebay/issues/14) are open; #1 links #2, #32,
and #33; #2 links #32 and #33; #32 and #33 exist. Keep issues open until final
tester, reviewer, and security evidence is complete.

## Execution order and status

Order: #3, #4, #25, #6, #13, #14, #22, #23, #27, #26, #28, #24, #30,
#32 Connect onboarding, #33 Connect transfers, closed-child regressions, final
physical-device checkpoint, #2, release automation/audit, #1.

| Scope | Implementation | Local validation | Final tester | Review | Security | GitHub |
|---|---|---|---|---|---|---|
| #3 order contract | DONE | PARTIAL | PENDING | PENDING | PENDING | OPEN |
| #4 wallet states | DONE | PARTIAL | PENDING | PENDING | PENDING | OPEN |
| #25 checkout email | DONE | PARTIAL | PENDING | PENDING | PENDING | OPEN |
| #6 biometric consent | DONE | PASS | PENDING | PENDING | PENDING | OPEN |
| #13 price filter | DONE | PASS | PENDING | PENDING | PENDING | OPEN |
| #14 category gesture | DONE | PASS | PENDING | PENDING | PENDING | OPEN |
| #22 profile posts | DONE | PARTIAL | PENDING | PENDING | PENDING | OPEN |
| #23 saved posts | DONE | PARTIAL | PENDING | PENDING | PENDING | OPEN |
| #27 Following feed | DONE | PARTIAL | PENDING | PENDING | PENDING | OPEN |
| #26 stories | DONE | PASS | PENDING | PENDING | PENDING | OPEN |
| #28 Vendas | DONE | PARTIAL | PENDING | PENDING | PENDING | OPEN |
| #24 product chat | DONE | PASS | PENDING | PENDING | PENDING | OPEN |
| Completed-scope device checkpoint | N/A | PENDING | PENDING | PENDING | PENDING | N/A |
| #30 live location | DONE | PASS | PENDING | PENDING | PENDING | OPEN |
| #32 Connect onboarding | DONE | PASS | PENDING | PENDING | PENDING | OPEN |
| #33 Connect transfers | DONE | PARTIAL | PENDING | PENDING | PENDING | OPEN |
| Closed-child regressions | PENDING | PENDING | PENDING | PENDING | PENDING | OPEN |
| #2 release gate | PENDING | PENDING | PENDING | PENDING | PENDING | OPEN |
| Release automation/audit | PENDING | PENDING | PENDING | PENDING | PENDING | OPEN |
| #1 production release | PENDING | PENDING | PENDING | PENDING | PENDING | OPEN |
| GitHub setup | DONE | N/A | N/A | N/A | N/A | DONE |

### #3 executor record

Changed paths:

```text
nest-backend/src/modules/orders/orders.controller.ts
nest-backend/src/modules/orders/usecases/create-order.usecase.ts
nest-backend/src/modules/orders/types/order.types.ts
nest-backend/src/modules/orders/dtos/order.dto.ts
nest-backend/src/modules/orders/orders.controller.spec.ts
frontend/test/features/orders/order_service_regression_test.dart
```

Results: backend tsc pass; focused Jest 15 pass; focused ESLint pass; Flutter
focused 4 pass; focused analyze no issues; diff check pass. PostgreSQL integration
is blocked by `.env.test` authentication for user `test`. Real DB atomicity,
no-partial-order behavior, server-derived persistence, and real-repository errors
remain unproven.

### #4 executor record

Changed paths:

```text
nest-backend/src/modules/wallet/usecases/get-wallet.usecase.integration-spec.ts
frontend/test/features/wallet/wallet_controller_test.dart
frontend/lib/features/wallet/presentation/pages/wallet_page.dart
```

Validation: wallet Jest 1 suite/3 tests PASS; backend tsc PASS; wallet ESLint 0
errors/warnings PASS; Flutter focused 5 tests PASS; focused analyze 0 issues PASS;
diff check PASS. PostgreSQL integration executed 0 tests and was BLOCKED by `.env.test`
P1000 authentication for user `test`; repeated/concurrent one-wallet/zero-ledger proof
remains unproven. Unique/upsert, zero/empty rendering, loading/failure/retry/logout/
account-switch, A/B isolation, no withdrawal/Connect scope, and allowlist-only changes
passed available checks. Final tester/review/security remain PENDING.

### #25 executor record

Changed paths:

```text
frontend/lib/features/payments/presentation/pages/payment_page.dart
frontend/lib/features/payments/presentation/providers/payment_providers.dart
frontend/test/features/payments/payment_page_test.dart
nest-backend/src/modules/payments/usecases/create-payment-session.usecase.ts
nest-backend/src/modules/payments/usecases/create-payment-session.usecase.spec.ts
```

Test-first initial backend regression: 12 pass/3 fail. Final Jest: 15 pass;
backend lint PASS; tsc PASS; focused Flutter page 1 pass; full payment folder 10
pass; focused analyze no issues; scoped format check applied formatting to 3
allowlisted files; diff check PASS. Existing integration spec ran 4 tests but was
BLOCKED by the test-database cleanup safety guard refusing the configured database.
Available checks prove outside-build init, preserved edits, undefined/empty/whitespace
normalization plus trim, the existing auth fallback seam, A/B identity reset/isolation,
and no added logging/persistence. No final-pass claims; final tester/review/security
remain PENDING.

### #6 executor record

Changed paths:

```text
frontend/lib/shared/services/storage_service.dart
frontend/lib/features/auth/domain/usecases/biometric_login_usecase.dart
frontend/lib/features/auth/presentation/controllers/auth_controller.dart
frontend/lib/features/onboarding/presentation/pages/welcome_setup_page.dart
frontend/lib/features/auth/presentation/pages/login_page.dart
frontend/lib/features/auth/presentation/pages/register_page.dart
frontend/lib/features/auth/presentation/pages/complete_profile_page.dart
frontend/lib/features/auth/presentation/widgets/enable_biometry_sheet.dart
frontend/lib/features/profile/presentation/widgets/profile_settings_sheet.dart
frontend/test/features/auth/biometric_login_usecase_test.dart
frontend/test/features/auth/logout_clears_biometric_test.dart
frontend/test/features/auth/biometry_owner_wiring_test.dart
frontend/test/features/onboarding/welcome_setup_page_test.dart
```

Test-first failures: biometric test initial 5 pass/1 fail; account-switch test
initial 1 fail due async callback, then corrected. Final issue regression set 19
pass; focused analyze 0 issues; new tests format check PASS; diff check PASS; no
type escape hatch. Implemented and tested: `/welcome` is the sole owner; no
login/register/complete-profile prompt; user-keyed completion; decline/cold boot/no
enrollment/native cancel; owner mismatch; actual account-switch cleanup; logout
clear; expiry preserve; Settings explicit wiring. Device/native evidence is deferred
to the final tester. Implementation files had pre-existing baseline
formatting/line-ending differences and were not mass-formatted. No final
tester/review/security claims; those remain PENDING.

### #13 executor record

Changed paths:

```text
frontend/lib/features/product/presentation/widgets/product_filter_bar.dart
frontend/test/features/product/product_filter_bar_test.dart
```

`explorar_page.dart` was inspected and preserved as baseline; it was not changed by
the executor. Red test: 0 pass/1 fail because drag emitted a callback. Four passing
tests: applies only after Apply; Cancel restores/no apply; Apply full range emits
null; dismissal/reopen restores applied. Focused analyze no issues; scoped format 0
changed; scoped design check PASS; diff check PASS.

Acceptance: no drag-end commit, local draft, accessible Apply exactly once,
cancel/dismiss no callback, and full range maps to host min/max `null`. Device
request-count evidence is deferred to the final tester. No final
tester/review/security claims; those remain PENDING.

### #14 executor record

Changed paths:

```text
frontend/lib/features/product/presentation/widgets/category_filter_panel.dart
frontend/test/features/product/category_gesture_test.dart
```

`app_shell.dart` and its existing test were unchanged but tested. With the absorber
restored, the red reproduction was the vertical category drag test: 0 pass/1 fail.
Final product folder: 8 pass; app shell: 5 pass; combined: 13 pass; focused analyze
no issues; scoped format final 0 changed; design and diff checks PASS. Test names:
vertical category drag scrolls/no page change; category tap selects once; product tap
keeps existing destination; horizontal swipe outside panel changes page; existing
shell swipe/nav/drawer tests.

Root cause: the absorber's horizontal recognizer competed in the gesture arena and
stole diagonal/vertical-intended drags; removing it lets native axis recognizers
arbitrate. Device evidence is deferred. No final-pass claims; final
tester/review/security remain PENDING.

### #22 executor record

Changed paths:

```text
nest-backend/src/modules/social/data/repositories/post-database.repository.ts
nest-backend/src/modules/social/data/repositories/post-database.repository.spec.ts
nest-backend/src/modules/social/types/social.types.ts
nest-backend/src/modules/social/usecases/get-user-posts.usecase.ts
nest-backend/src/modules/social/usecases/get-user-posts.usecase.spec.ts
frontend/lib/features/social/data/repositories/social_repository.dart
frontend/lib/features/profile/presentation/controllers/profile_controller.dart
frontend/lib/features/social/presentation/pages/my_posts_page.dart
frontend/test/features/profile/user_posts_pagination_test.dart
```

Focused backend: 2 suites/9 pass; tsc pass; focused ESLint pass. Flutter
profile/social: 17 pass; scoped analyze no issues; scoped format 0 changed; diff
check pass. Strict malformed, wrong-scope, and wrong-profile cursors return
controlled errors; paging has deterministic ties and authoritative metadata; the
frontend dedupes, handles terminal pages, retries with the same cursor, and
preserves the existing list.

PostgreSQL integration command:

```bash
npm run test:integration -- --runInBand src/modules/social
```

It was blocked before tests by `.env.test` P1000 authentication for user `test`.
Full Flutter analyze has 3 pre-existing infos in `payment_page_test` and was not
the issue gate. No final-pass claims; final tester/review/security remain PENDING.

### #23 executor record

Changed paths:

```text
nest-backend/src/modules/social/data/repositories/saved-post-database.repository.ts
nest-backend/src/modules/social/data/repositories/saved-post-database.repository.spec.ts
nest-backend/src/modules/social/usecases/get-saved-posts.usecase.ts
nest-backend/src/modules/social/usecases/get-saved-posts.usecase.spec.ts
nest-backend/src/modules/social/types/social.types.ts
frontend/lib/features/social/data/repositories/social_repository.dart
frontend/lib/features/profile/presentation/pages/saved_posts_page.dart
frontend/test/features/social/social_repository_regression_test.dart
frontend/test/features/social/saves_provider_test.dart
frontend/test/features/profile/saved_posts_page_test.dart
```

Red Flutter result: 4 pass/1 fail, exposing `setState` during build and repeated
failed footer loads. Final focused Flutter: 6 pass. Backend focused: 2 suites/4
pass; social slice: 12 suites/40 pass; tsc/lint/analyze/format/diff checks PASS.
Direct coverage includes malformed/wrong-scope/wrong-user no-query, auth scope,
the `SavedPost` `createdAt/id` predicate and visibility query, metadata, dedupe,
unsave success/remove, failure/restore/retry, and failed refresh list/cursor
preservation.

Integration remains blocked by `.env.test` P1000; real DB tied-row, returned
visibility, and isolation behavior remain unproven. The format command was corrected
after one wrong-root no-file invocation. No final-pass claims; final
tester/review/security remain PENDING.

### #27 executor record

Changed paths:

```text
nest-backend/src/modules/social/data/repositories/post-database.repository.ts
nest-backend/src/modules/social/data/repositories/post-database.repository.spec.ts
nest-backend/src/modules/social/types/social.types.ts
nest-backend/src/modules/social/usecases/get-feed.usecase.ts
nest-backend/src/modules/social/usecases/get-feed.usecase.spec.ts
frontend/lib/features/social/presentation/providers/feed_provider.dart
frontend/lib/features/profile/presentation/providers/follow_status_provider.dart
frontend/test/features/social/feed_provider_test.dart
frontend/test/features/profile/follow_state_test.dart
```

No initial behavioral red was captured; later contract-first runs failed on TypeScript
type/repository mismatches before green. Final focused backend get-feed+repo: 2
suites/7 pass; social slice earlier: 12 suites/45 pass; tsc/ESLint pass. Flutter
feed/follow: 6 pass; analyze no issues; diff check pass.

Coverage: the usecase owns strict following-feed scope/user/feed/filter parsing and
typed no-query failures; the repository cursor is decoded and applies followed,
deleted, and block filters with deterministic tied keyset paging. Explore offset is
unchanged. The frontend resets scope, ignores stale results, dedupes, retries, keeps
posts and cursor on failed follow/unfollow, and resets on successful follow/unfollow.

Integration `npm run test:integration` was blocked by `.env.test` P1000. This records
the TDD red-evidence deviation accurately. No final-pass claims; final
tester/review/security remain PENDING.

### #26 executor record

Cumulative changed paths:

```text
frontend/lib/features/social/presentation/pages/create_story_page.dart
frontend/lib/features/social/presentation/providers/feed_provider.dart
frontend/lib/features/social/presentation/pages/my_stories_page.dart
frontend/test/features/social/create_story_submission_test.dart
nest-backend/src/modules/stories/stories.controller.ts
nest-backend/src/modules/stories/stories.controller.spec.ts
```

Red compilation was caused by missing `StorySubmissionCoordinator`. Focused
submission: 3 pass; focused social: 8 pass; full Flutter: 164 pass; backend story
controller: 1 suite/2 pass; tsc and backend full lint PASS; final scoped analyze no
issues; final scoped format: 2 files/0 changed after formatting only the new test;
diff check PASS. Full Flutter analyze reported 3 infos in the earlier
`payment_page_test.dart`, a cumulative gate item to fix, with no errors/warnings.

Direct tests prove duplicate request suppression, canonical returned `userId`, global
and user invalidation once, no optimistic insert, failure without invalidation, retry,
and backend cleanup `Left`/no cleanup `Right`. PostgreSQL integration was not
attempted. No final-pass claims; final tester/review/security remain PENDING.

### #28 executor record

Cumulative changed paths:

```text
nest-backend/src/modules/orders/orders.controller.ts
nest-backend/src/modules/orders/orders.controller.spec.ts
nest-backend/src/modules/orders/data/repositories/order-database.repository.ts
nest-backend/src/modules/orders/data/repositories/order-database.repository.spec.ts
nest-backend/src/modules/orders/dtos/order.dto.ts
nest-backend/src/modules/orders/types/order.types.ts
frontend/lib/features/orders/presentation/pages/orders_page.dart
frontend/lib/features/orders/presentation/providers/order_providers.dart
frontend/lib/features/orders/presentation/providers/order_providers.g.dart
frontend/lib/features/orders/presentation/providers/order_providers_state.dart
frontend/lib/features/orders/presentation/providers/order_providers_state.freezed.dart
frontend/test/features/orders/order_service_regression_test.dart
frontend/test/features/orders/sales_list_provider_test.dart
frontend/test/features/orders/orders_page_test.dart
```

No original red was captured. Later red: backend 27 pass/1 fail, exposing missing
`IsOptional` on absent status, and Flutter harness 9 pass/3 fail. Final backend:
2 suites/28 pass; tsc/lint PASS. Flutter: 12 pass; scoped analyze no issues;
format: 6 files/0 changed; diff check PASS.

Direct coverage: dedicated sales DTO all allowed/absent/invalid/limits; authenticated
seller/status/scope cursor; keyset and metadata; provider status/reset/dedupe/failure-
preserved retry/loading states; accessible All/status, loading-more, inline retry with
cursor preservation, empty, terminal, and no Meus produtos. Scoped build_runner ran
earlier and wrote outputs; the final changed generated paths are only
`order_providers.g.dart` and `order_providers_state.freezed.dart`; no later codegen.
Integration was blocked by `.env.test` P1000. A wrong-root no-pubspec command was
corrected. No final-pass claims; final tester/review/security remain PENDING.

### #24 executor record

Cumulative changed paths:

The historical path `chat/mappers/conversation.mapper.ts` below was relocated in the
2026-09-28 response-boundary cleanup to `chat/dtos/conversation-response.ts`;
query payload types now live in `chat/data/repositories/conversation/payloads.ts`.

```text
nest-backend/src/modules/chat/chat.controller.ts
nest-backend/src/modules/chat/chat.controller.spec.ts
nest-backend/src/modules/chat/data/repositories/conversation-database.repository.ts
nest-backend/src/modules/chat/data/repositories/conversation-database.repository.spec.ts
nest-backend/src/modules/chat/dtos/chat.dto.ts
nest-backend/src/modules/chat/mappers/conversation.mapper.ts
nest-backend/src/modules/chat/usecases/start-conversation.usecase.ts
nest-backend/src/modules/chat/usecases/start-conversation.usecase.spec.ts
frontend/lib/core/router/app_routes.dart
frontend/lib/core/router/routes/chat_routes.dart
frontend/lib/features/chat/data/repositories/chat_repository.dart
frontend/lib/features/chat/presentation/pages/new_chat_page.dart
frontend/lib/features/product/presentation/pages/product_detail_page.dart
frontend/test/core/router/app_router_test.dart
frontend/test/features/chat/new_chat_page_test.dart
```

The schema was already dirty and was not edited by #24. No true behavioral red was
initially captured; compile/harness failures occurred before green. Final backend:
3 suites/11 tests; tsc/lint PASS; Prisma validate PASS. Frontend route/new-chat:
13 tests; focused analyze PASS; scoped format/diff PASS. `routes-check` and
`design-check` were blocked on Windows because the Makefile uses Unix `!`. No DB
integration, device, or full suites were run.

Direct acceptance covered: product seller check; normalized `DIRECT` /
`PRODUCT:<id>`; safe exact counterpart/product summaries; two products distinct and
same-product reuse; actual P2002 reread and non-P2002 failure; controller forwards
`productId`; exact editable unsent copy; Back sends no start/send; explicit edited
send once; duplicate guard; failed-send retry with the same `clientMessageId`;
generic route; and no backend greeting/message/order dependency. Final
tester/review/security remain PENDING.

### #30 executor record

The interrupted-session implementation covered measured current-location capture,
canonical bounded metadata, sender-scoped idempotency, retry reconciliation, safe
legacy rendering, external-map failure handling, and server timestamp conversion to
device-local time. It also retained one client message identity across retries and
rejected stale or mismatched delayed reconciliation.

Focused validation: backend chat suites finished at 30 passing tests with TypeScript
and lint passing; focused Flutter location/date tests finished at 7 passing tests with
focused analysis passing. A reviewer recheck reported `SHIP`, and the issue-local
security recheck reported `PASS`; these do not replace the pending cumulative final
passes. PostgreSQL integration remained blocked by `.env.test` P1000 authentication.
Device permission, map-provider, sender/recipient reload, local-time, and push-preview
evidence remains pending.

### #32 executor/tester record

Changed scope:

```text
nest-backend/src/modules/payments/types/connect.types.ts
nest-backend/src/modules/payments/dtos/connect.dto.ts
nest-backend/src/modules/payments/providers/stripe-provider.ts
nest-backend/src/modules/payments/providers/stripe-provider.spec.ts
nest-backend/src/modules/payments/usecases/get-connect-status.usecase.ts
nest-backend/src/modules/payments/usecases/get-connect-status.usecase.spec.ts
nest-backend/src/modules/payments/usecases/get-connect-dashboard-link.usecase.ts
nest-backend/src/modules/payments/services/seller-payout.service.ts
nest-backend/src/modules/payments/services/seller-payout.service.spec.ts
nest-backend/src/modules/payments/payments.controller.ts
nest-backend/src/modules/payments/payments.controller.spec.ts
nest-backend/src/shared/guards/webhook.guard.ts
nest-backend/src/shared/guards/webhook.guard.spec.ts
nest-backend/src/shared/interceptors/webhook-dedupe.interceptor.ts
nest-backend/src/shared/interceptors/webhook-dedupe.interceptor.spec.ts
frontend/lib/features/wallet/data/entities/connect_status_entity.dart
frontend/lib/features/wallet/data/entities/connect_status_entity.g.dart
frontend/lib/features/wallet/presentation/pages/wallet_page.dart
frontend/test/features/wallet/wallet_controller_test.dart
```

The public contract now exposes only `onboarding-required`, `requirements-due`,
`restricted`, or `transfer-ready`, plus current requirements. Fresh Accounts v2
recipient capability state is authoritative before transfers; cached booleans remain
database projections only. V1 snapshot and V2 thin webhooks are signature-verified,
and Express Dashboard access remains available for remediation without implying bank
payout readiness.

Tester validation: 12 backend suites/130 tests PASS; TypeScript and focused ESLint
PASS; 6 Wallet tests PASS; focused Flutter analysis PASS; targeted generated output
is consistent; diff check PASS. The configured Stripe return URI is not yet proven to
match the Android app scheme, so return/refresh deep-link evidence is deferred to the
final device/configuration checkpoint.

### #33 executor/tester record

Changed scope:

```text
nest-backend/prisma/schema.prisma
nest-backend/src/modules/payments/types/connect.types.ts
nest-backend/src/modules/payments/types/payment-provider.types.ts
nest-backend/src/modules/payments/providers/stripe-provider.ts
nest-backend/src/modules/payments/providers/stripe-provider.spec.ts
nest-backend/src/modules/payments/data/repositories/transaction-database.repository.ts
nest-backend/src/modules/payments/services/seller-payout.service.ts
nest-backend/src/modules/payments/services/seller-payout.service.spec.ts
nest-backend/src/modules/payments/usecases/create-payment-intent.usecase.ts
nest-backend/src/modules/payments/usecases/create-payment-session.usecase.ts
nest-backend/src/modules/payments/usecases/recover-dispute-transfer.usecase.ts
nest-backend/src/modules/payments/usecases/recover-dispute-transfer.usecase.spec.ts
nest-backend/src/modules/payments/data/repositories/transaction-transfer.integration-spec.ts
nest-backend/src/modules/payments/payments.controller.ts
nest-backend/src/modules/payments/payments.controller.spec.ts
nest-backend/src/modules/payments/payments.module.ts
nest-backend/src/modules/tasks/transfer-reconciliation.task.ts
nest-backend/src/modules/tasks/transfer-reconciliation.task.spec.ts
nest-backend/src/modules/tasks/tasks.module.ts
nest-backend/src/modules/admin/admin.controller.ts
nest-backend/src/modules/admin/admin.controller.spec.ts
nest-backend/src/modules/admin/admin.module.ts
nest-backend/src/modules/admin/usecases/list-transfer-failures.usecase.ts
nest-backend/src/modules/admin/usecases/list-transfer-failures.usecase.spec.ts
```

`Transaction` is the durable per-order allocation. Conditional database claims commit
before Stripe; deterministic keys, transfer groups, allocation metadata, leases, and
provider reconciliation cover retry/restart paths. Transfer success and the wallet
debit/ledger entry finalize atomically. Reversals have the same persisted lifecycle;
dispute-created and lost-dispute events enter a dedicated transfer-recovery path
without prematurely marking an order refunded. Retryable/terminal failures and an
opaque cursor page are operator-visible. No migration was added.

Tester validation: 13 suites/141 tests PASS; TypeScript, Prisma validation, lint,
build, and diff check PASS. The real PostgreSQL integration spec was added for
concurrent claims, atomic finalization/wallet debit, and replay idempotency, but its
run is blocked before Jest by `.env.test` P1000 authentication for user `test`.
Stripe test/live transfer, reversal, dispute, and restart evidence remains deferred.

### User-directed UI follow-up record

- Light mode uses stronger semantic ink over a warm ivory canvas while retaining the
  visible animated `aurora.frag`; retained safe frames are under
  `docs/device-runs/2026-09-14/`.
- Authenticated and guest Profile scaffolds are transparent so the shell aurora is
  visible again.
- The locale crash and UTC/local chat timestamp offset are covered by shared date
  parsing/formatting regressions.
- Active chat rows parse product context and show counterpart, latest preview/time,
  and a numeric unread badge; focused tests plus the then-current 186-test Flutter
  suite passed.
- The product-conversation composer uses the app field/button primitives, trims and
  disables invalid input, preserves retry identity, and refreshes the active list;
  8 focused tests passed.
- Every shared comment row, including replies, now has a fine top/bottom tonal step;
  4 focused tests and focused analysis pass without adding a banned divider.

### Cumulative local validation record (2026-09-14)

Backend PASS:

```text
npx tsc --noEmit
npm test -- --runInBand                       102 suites / 644 tests
npm run lint -- --quiet
npx prisma validate
npm run build
npm run test:safety                          5 tests
```

Frontend PASS:

```text
flutter analyze                              0 issues
flutter test                                 189 tests
flutter pub run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test libs/freebay_design_system/lib
flutter build apk --debug
direct design-system banned-pattern scan     0 matches / 410 files
direct raw-route-literal scan                0 matches
```

The first format check identified 25 active-scope Dart files; `dart format` was
applied, then analysis, all 189 tests, generated-code consistency, and the zero-change
format check passed again. Four test-only analyzer infos were removed from
`orders_page_test.dart` and `payment_page_test.dart`. `build_runner` wrote six outputs
and warned that `--delete-conflicting-outputs` is now ignored. The debug APK was built
at `frontend/build/app/outputs/flutter-apk/app-debug.apk`; Gradle emitted a non-failing
future-compatibility warning for `sentry_flutter` and `stripe_android` applying KGP.

`npm run test:integration -- --runInBand` still stops during `prisma:test:sync`, before
Jest, with P1000 authentication for local PostgreSQL user `test`. `make design-check`
and `make routes-check` still fail under Windows because `cmd.exe` cannot execute the
Makefile's POSIX `!`; the equivalent direct scans above pass. Full `git diff --check`
passes with only expected LF-to-CRLF checkout warnings.

Final device-checkpoint discovery: `GET /health` returned healthy from the development
backend on `localhost:3000`, but `mobile_list_available_devices` returned an empty
device list and Dart DTD reported no running debug process. No remote/cloud device was
allocated because that requires explicit user approval. Physical-device evidence is
therefore blocked until a local Android/iOS device is connected and Flutter is run.

## Current checkpoint

Completed implementation: #3, #4, #25, #6, #13, #14, #22, #23, #27, #26, #28,
#24, #30, #32, and #33. Cumulative local unit, type, lint, format, codegen, policy,
and build gates pass. Remaining work: closed-child device regressions, the final
device/Stripe checkpoint, #2, and release automation/#1. Known blockers: P1000 test
DB for #3/#4/#22/#23/#27/#28/#30/#33; #25 cleanup safety guard; Windows Make `!`;
Stripe return-URI configuration; and final external/live/iOS/device gates. Issues
remain open.

## Locked product decisions

- Seller orders stay in **Vendas**; products stay in **Meus produtos**.
- Product-chat draft is editable and unsent, prefilled with `Oi, ainda está disponível?`.
- Share only a newly measured location and show provider accuracy; do not invent an
  accuracy threshold or fallback location.
- Stripe Connect: FreeBay-owned checkout; Accounts v2 recipient accounts; Express
  Dashboard; hosted onboarding; separate charges and transfers; 10% integer-cent
  transfer math; FreeBay-owned negative-balance liability. Test and live modes are
  separate.
- For #22, #23, #27, and #28 use endpoint-specific opaque, scope-bound
  `(createdAt,id)` cursors. Preserve the existing shared CursorPage/base64 contract
  and leave wallet, chat, notification, and purchase pagination unchanged.
  Malformed or cross-scope cursors return controlled 4xx responses.

## Issue acceptance summaries

Use the issue link as the full contract; these are execution boundaries, not new
issue bodies.

- [#4](https://github.com/vsmarlon/freebay/issues/4): retain `Wallet.userId` unique/upsert;
  repeated and concurrent PostgreSQL runs prove one wallet and zero bootstrap ledger
  rows. Prove UI zero/empty/loading/failure/retry/logout/account switch, and that B
  never sees A. No withdrawal or Connect behavior.
- [#25](https://github.com/vsmarlon/freebay/issues/25): initialize once outside build,
  preserve edits, normalize null/empty/whitespace in the backend, use auth fallback
  only in documented cases, reset on identity change, isolate A/B, and do not
  log or persist beyond the payment contract.
- [#6](https://github.com/vsmarlon/freebay/issues/6): `/welcome` owns post-auth consent;
  remove login/register/complete-profile prompts. Key completion by user ID, enforce
  credential ownership and mismatch rejection, clear/revoke on logout/account switch
  while preserving the intended expiry path. Settings opt-in/out is later.
- [#13](https://github.com/vsmarlon/freebay/issues/13): keep a local draft with no
  `onChangeEnd` commit; explicit Apply commits exactly once; cancel/dismiss restores
  without fetch; full range means no filter. Prove request counts on device.
- [#14](https://github.com/vsmarlon/freebay/issues/14): reproduce first, then make the
  smallest gesture-arena fix. Prove vertical category scroll, category taps, product
  taps, parent swipes outside the panel, and unchanged destinations. No PageView
  replacement or custom recognizer unless a failing test requires it.
- [#22](https://github.com/vsmarlon/freebay/issues/22): scope the profile user and
  `(createdAt, post ID)` cursor; use descending keyset pagination with authoritative
  `items`/`hasMore`/`nextCursor`, ID dedupe, preserved scroll, and failed-cursor
  retention. Align MyPosts only as needed.
- [#23](https://github.com/vsmarlon/freebay/issues/23): cursor saved-row `createdAt/id`
  before mapping posts; enforce deleted and bidirectional block rules, dedupe, retain
  failed unsaves and remove successful unsaves immediately. Prove refresh durability
  and auth isolation. Do not invent a private-account model.
- [#27](https://github.com/vsmarlon/freebay/issues/27): retain followed/deleted/block
  filters; bind cursor to user/feed/filter with deterministic order; reset on
  follow/unfollow/filter; reject cross-filter cursors and dedupe. Do not invent
  private-profile behavior.
- [#26](https://github.com/vsmarlon/freebay/issues/26): guard duplicate submit, use
  one canonical reconciliation approach, refresh global and publishing-user stories,
  remove upload if persistence fails, and show no false story on failure or more than
  one on success.
- [#28](https://github.com/vsmarlon/freebay/issues/28): Vendas covers All plus
  `PENDING/CONFIRMED/SHIPPED/DELIVERED/DISPUTED/COMPLETED/CANCELLED`, with authenticated
  seller scope and seller/status cursor. Prove controls, loading-more, retry, empty,
  terminal, and status reset. Meus produtos remains separate.
- [#24](https://github.com/vsmarlon/freebay/issues/24): use typed `targetUserId` and
  `productId` route data; server-validates target product seller; safe summaries;
  normalized participants and `scopeKey` `PRODUCT:<id>` or generic `DIRECT`; reread
  unique conflicts and reuse. Use the exact editable unsent draft and explicit
  ordinary `clientMessageId` send. Back sends none; no backend greeting.
- [#30](https://github.com/vsmarlon/freebay/issues/30): denied/disabled location sends
  nothing; no hardcoded, last-known, or manual fallback. New current fix shows provider
  accuracy, supports retry without cutoff, and requires confirmation. Validate canonical
  `latitude/longitude/accuracyMeters/capturedAt` with optional address. Preserve one
  `clientMessageId` through REST/socket/retry/reload and existing uniqueness; push
  previews contain no coordinates.
- [#32](https://github.com/vsmarlon/freebay/issues/32): preserve recipient, Express,
  hosted, BR/BRL, FreeBay fees, and liability. Support `onboarding-required`,
  `requirements-due`, `restricted`, and `transfer-ready`; refresh capability before
  movement; distinguish transfer from bank payout. Wallet is actionable without a
  bank claim. Prove return/refresh/dashboard/account-switch/restricted evidence.
- [#33](https://github.com/vsmarlon/freebay/issues/33): persist transfer state,
  idempotency, attempts, retry/provider ID, reversal state/ID, and errors. Commit
  `PROCESSING` before Stripe; use `transfer_group` and allocation metadata; reconcile
  crashes/uncertain results; reuse a key only when no match exists. Success and wallet
  debit happen exactly once in a DB transaction. Errors are durable, retryable, or
  terminal; reversal intent precedes Stripe; refunds/disputes do not assume automatic
  reversal; Redis dedupe is not the sole replay guard; operators can see state. Allow
  only minimal Prisma fields, with schema sync and no migrations.

## Closed-child regression matrix

Run these as regression evidence only. A failed row reopens its issue and gets a
narrow serial executor. A passing row gets no speculative edit.

| Issue | Required evidence |
|---|---|
| #5 | No biometric prompt without consent; decline and returning consent paths |
| #7 | Keyboard open/close on every shell tab, light/dark, Android/iOS |
| #8 | Tab profile traces, retained scroll/state, no duplicate fetches |
| #9 | FeedDrawer/comment first-open before/after traces against device frame budget |
| #10 | Every unique people result, terminal Ver mais, retry without duplicates |
| #11 | Follow/unfollow immediate counts, failed rollback, reopen consistency |
| #12 | Backend 100-character boundary, client parity, complete detail title |
| #15 | Correct counterpart name/avatar for both participants after reload/socket update |
| #16 | One-to-six-line composer growth, scrolling cap, light/dark contrast |
| #17 | Sender/recipient media survives restart; failed upload absent |
| #18 | Permission denial, cancel cleanup, one durable playable audio message |
| #19 | Theme/background persistence, reset, readable light/dark rendering |
| #20 | Deterministic sorting, search reset, archive/unarchive with messages retained |
| #21 | Two real entry points use crop/preview; cancel uploads nothing |
| #29 | Animated background profile traces, pause lifecycle, light/dark appearance |
| #31 | Editor preserves draft/scroll; crop/draw/view-once; cancel none; send one |

## Final gates

Run the commands in root `AGENTS.md`; do not substitute green focused checks for
these gates.

Backend (`nest-backend`):

```bash
npx tsc --noEmit
npm test
npm run test:integration
npm run lint
npm run build
```

Frontend (`frontend`):

```bash
flutter analyze
flutter test
flutter pub run build_runner build --delete-conflicting-outputs
flutter build apk --debug
```

Root:

```bash
make test-unit
make test-integration
make test
```

Also require the cumulative physical Android/iOS device pass, Stripe sandbox
verification, live-mode Connect proof where applicable, deep-link/push and
accessibility evidence, and the single final correctness/security passes. iOS
signing/store setup and physical-device access are explicit blockers, not reasons
to claim completion.

### Evidence matrix

| Criterion | Command/device/environment | Expected | Artifact | Owner | Blocker |
|---|---|---|---|---|---|
| Issue acceptance | Focused issue command or device scenario | Approved behavior passes | Test output/screenshot/video | Executor | Yes/No |
| Backend gate | `nest-backend` commands above; test DB | All required suites pass | CI/log artifact | Release owner | Yes/No |
| Frontend gate | `frontend` commands above | Analyze/tests/build pass | CI/log artifact | Release owner | Yes/No |
| Performance gate | `node scripts/perf-check.js --all --device <id>` on provisioned device/backend/fixtures | Build and raster budgets pass on same-device measured baselines; blocked is not passed | `docs/test-runs/<date>/perf-<flow>.md` | Release owner | Yes/No |
| Device flows | Physical Android and iOS | Auth, chat, location, push, links, checkout pass | Device report/video | Tester | Yes/No |
| Stripe Connect | Test mode, then approved live environment | Onboarding, transfer, webhook, dispute and liability behavior pass | Stripe/event report | Payments owner | Yes/No |
| Review/security | One cumulative pass after implementation | Findings fixed and affected checks rerun | Review/audit report | Reviewer/auditor | Yes/No |

## Release closure

- Close #2 only after every child issue has its required implementation, local and
  cumulative evidence, with no unresolved blocker.
- #1 release automation may change only `.github/workflows/`, `Makefile`, and
  release documentation. Keep #1 open if live Stripe Connect, iOS signing/store
  setup, or physical-device evidence is unavailable.
- Do not open the final PR until #1 and #2 are eligible for closure and the target
  is `master`.

## Suggested skills by domain

- Coordination and ledger: `orchestrator`, `ponytail`, `writing-great-tests`,
  `diagnosing-bugs`.
- Backend/data: `freebay-backend-module`, `freebay-data-model`,
  `freebay-system-design`.
- Flutter/product flows: `freebay-flutter-feature`, `freebay-design-system`,
  `freebay-app-flows`, `freebay-mobile-mcp`, `freebay-perf`.
- Payments: `stripe-best-practices`, `connect-recommend`,
  `connect-required-verification-information`, `stripe-docs`.

## Continuation

Run the single final physical-device/Stripe matrix in `docs/DEVICE_TESTING.md` with
Flutter running, including the closed-child rows above. Record artifacts and blockers
here. Cumulative local gates are complete; do not rerun them without a subsequent code
change. The user explicitly deferred further mobile-MCP interaction until this final
checkpoint. Do not resume the old interview.
