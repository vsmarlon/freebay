# FreeBay hardening baseline — P0

## Run identity

- Branch: `feat/production-hardening`; no branch/commit/push performed.
- Revision tested: `60f5eca1554b1ec799d62e56342b062c1ee39631`.
- Initial checkout was clean. Evidence files in this directory and this report are the only intended persistent additions; generated `order_providers.g.dart` drift was restored after checking its exact hash-only change.
- Windows; Node `v24.10.0`, npm `11.6.1`, Flutter `3.44.4`, Dart `3.12.2`.
- Test DB: host `localhost:5432`, database `freebay_test_db`, schema `public`. Credentials are not recorded.
- Integration/E2E ran via scripts loading `.env.test`, forcing `NODE_ENV=test`, and the guarded schema-push script (localhost/loopback only, approved ports only, exact test DB name). Schema push reported already in sync. Test setup truncates test tables after each test; fixtures are suite-owned. No runtime `.env` sync/seed or migration was run.
- Each gate's complete redacted stdout/stderr is in `<label>.log`; command, cwd, UTC start/end, and exact process exit code are in `<label>.json`. The capture runner lives outside the repository at `C:/Users/Qiyana/AppData/Local/Temp/opencode/freebay-baseline-run.cjs`.

## Gates

| Gate / exact command | CWD | Result | Exit |
|---|---|---|---:|
| `npx tsc --noEmit` | `nest-backend` | Pass | 0 |
| `npm run lint` | `nest-backend` | Pass | 0 |
| `npm test` | `nest-backend` | Pass | 0 |
| `npm run build` | `nest-backend` | Pass | 0 |
| `npm run test:safety` | `nest-backend` | Pass | 0 |
| `npm run test:integration` | `nest-backend` | Pass; test schema already in sync | 0 |
| `npm run test:e2e` | `nest-backend` | Pass; 4 suites, 26 tests | 0 |
| `dart run build_runner build --delete-conflicting-outputs` | `frontend` | Pass; generated one existing hash change, recorded/restored | 0 |
| `dart format --output=none --set-exit-if-changed lib test libs/freebay_design_system/lib` | `frontend` | **Fail**: reports `test\features\payments\payment_view_test.dart` changed | 1 |
| `flutter analyze --fatal-infos lib test libs/freebay_design_system/lib` | `frontend` | Pass; no issues found | 0 |
| `flutter test` | `frontend` | **Fail**: `test/shared/services/http_client_logout_test.dart`, `logout preserves the captured bearer and does not refresh on 401`; expected length 1, actual `[]` | 1 |
| `node scripts/ci-check.js` | repo root | Pass | 0 |
| `npm run test:ci-scripts` | repo root | Pass | 0 |
| `make test` | repo root | **Fail** at Dart format gate, same `payment_view_test.dart` formatting failure | 1 |

Evidence files: `tsc`, `lint`, `backend-unit`, `backend-build`, `backend-safety`, `backend-integration`, `backend-e2e`, `frontend-codegen`, `frontend-format`, `frontend-analyze`, `frontend-test`, `root-ci-check`, `root-ci-scripts`, `root-make-test` (each `.json` and `.log`). `backend-e2e.log` records 4/4 suites and 26/26 tests passing. `frontend-test.log` contains the failing assertion and suite summary. `root-make-test.log` records where make stopped. No gate was blocked by unavailable tools/services.

## P0 measurements

Definitions use tracked `nest-backend/src/**/*.spec.ts`; TS-source-only patterns excluding spec/integration/E2E files; non-test transaction call sites exclude concrete `data/repositories`; PrismaService imports exclude tests and concrete data repositories; frontend excludes generated `.g.dart`/`.freezed.dart` for dynamic-line count.

| Measurement | Result |
|---|---:|
| Tracked backend `*.spec.ts` | **99 files** |
| Backend offending `as unknown as`, `as any`, `: any`, `any[]` matches in non-test `*.ts` source | **0 lines** |
| Non-test `$transaction(...)` call sites outside data repositories | **15 call sites / 12 files** |
| Non-test PrismaService import files outside `data/repositories` and `shared/infra` | **30 files** |
| Exported `Prisma*Repository` class names | **13** |
| Non-generated frontend `dynamic` match lines (`frontend/lib`, `.g.dart` and `.freezed.dart` excluded) | **158 lines** |
| Frontend files importing a feature `domain/repositories` contract | **20 files** |
| Backend abstract repository port files in `modules/**/domain/repositories` | **6 files** |
| Prisma `model` declarations | **45** |

PrismaService import files (the exact non-test matches from the configured scope):

```text
nest-backend/src/shared/shared.module.ts
nest-backend/src/modules/health/health.controller.ts
nest-backend/src/modules/chat/usecases/forward-messages.usecase.ts
nest-backend/src/modules/chat/services/chat-thread-access.service.ts
nest-backend/src/modules/disputes/disputes.module.ts
nest-backend/src/modules/wallet/wallet.module.ts
nest-backend/src/modules/disputes/usecases/withdraw-dispute.usecase.ts
nest-backend/src/modules/disputes/usecases/resolve-dispute.usecase.ts
nest-backend/src/modules/disputes/usecases/open-dispute.usecase.ts
nest-backend/src/modules/cart/usecases/checkout-cart.usecase.ts
nest-backend/src/modules/cart/usecases/checkout-cart/checkout-cart-reservation.ts
nest-backend/src/modules/payments/usecases/process-webhook.usecase.ts
nest-backend/src/modules/cart/usecases/checkout-cart/checkout-cart-compensation.ts
nest-backend/src/modules/cart/usecases/cart-usecases.module.ts
nest-backend/src/modules/payments/usecases/process-group-webhook.usecase.ts
nest-backend/src/modules/payments/usecases/expire-checkout-group.usecase.ts
nest-backend/src/modules/users/usecases/verify-phone.usecase.ts
nest-backend/src/modules/payments/services/seller-payout.service.ts
nest-backend/src/modules/payments/payments.module.ts
nest-backend/src/modules/notifications/notifications.module.ts
nest-backend/src/modules/notifications/services/notification.service.ts
nest-backend/src/modules/reviews/usecases/get-user-reviews/get-user-reviews.usecase.ts
nest-backend/src/modules/reviews/reviews.module.ts
nest-backend/src/modules/reviews/usecases/can-review-order/can-review-order.usecase.ts
nest-backend/src/modules/reviews/usecases/create-review/create-review.usecase.ts
nest-backend/src/modules/media/services/media-access.service.ts
nest-backend/src/modules/tasks/dispute-cleanup.task.ts
nest-backend/src/modules/tasks/escrow-release.task.ts
nest-backend/src/modules/tasks/story-cleanup.task.ts
nest-backend/src/modules/tasks/tasks.module.ts
```

The 13 exported class names are `PrismaOrderRepository`, `PrismaReviewRepository`, `PrismaConversationPreferenceRepository`, `PrismaDisputeRepository`, `PrismaSafetyListRepository`, `PrismaFollowRepository`, `PrismaBlockRepository`, `PrismaPostRepository`, `PrismaCommentRepository`, `PrismaLikeRepository`, `PrismaSavedPostRepository`, `PrismaShareRepository`, and `PrismaStoryRepository`.

## Corrected Flutter domain-to-data boundary metric

The earlier 20-file count above measures frontend files importing a feature `domain/repositories` contract; it does **not** measure domain importing data repositories. The requested P0 boundary scan was rerun exactly as follows:

```bash
rg --files-with-matches --glob '**/domain/**/*.dart' '^import .*/data/repositories/' frontend/lib/features
```

Result: **12 files** — 9 under auth, 2 under product, and 1 under social. Use this as the F1 baseline. Keep the original 20-file result as historical evidence for its separate metric; do not substitute it for F1.

## Follow-up boundary

The format failure was limited to `frontend/test/features/payments/payment_view_test.dart`; only that file was formatted. The exact root format gate now passes. Analyze remains green and `node scripts/ci-check.js` remains green.

The logout failure was a test-fixture defect, not a production logout defect. Tracing showed `AuthRepository.logout()` awaits `StorageService.getPushInstallationId()` before issuing HTTP. That storage method calls `SharedPreferences.getInstance()` when `_prefs` is unset, but the regression test initialized only Flutter secure-storage mocks. The empty adapter capture occurred because the request had not reached Dio. Recorded this finding here before changing the test; added SharedPreferences mock initialization only, preserving all three existing behavioral assertions. Focused rerun now captures the expected 401 logout request, preserves `Bearer access-token`, and verifies tokens are cleared; no production logout source changed.

Final verification: focused `flutter test test/shared/services/http_client_logout_test.dart` passed (0); `dart format --output=none --set-exit-if-changed frontend/lib frontend/test frontend/libs/freebay_design_system/lib` passed (0); `flutter analyze --fatal-infos lib test libs/freebay_design_system/lib` passed (0); full `flutter test` passed, 234 tests (0); `node scripts/ci-check.js` passed (0). Earlier post-format full test run failed (1) on the fixture issue and remains recorded as `flutter-test-full`; final passing run is `final-flutter-test`. All logs and manifests are retained in this directory. `frontend/test/features/payments/payment_view_test.dart` was changed only by `dart format`; its assertions and payment behavior are unchanged. Logout test assertions remain unchanged. No commits were made.
