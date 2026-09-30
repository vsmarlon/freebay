# FreeBay cross-stack hardening — 2026-09-26

## Revision, environment and fixture

- Tested commit: `f48a5be008ea8520995e68441656899499ca08a1` **plus the working tree** described below; changes were not committed.
- Windows / PowerShell 7, Node `v24.10.0`, Flutter `3.44.4`, Dart `3.12.2`.
- PostgreSQL and Redis listened locally on `5432` and `6379`. Backend HTTP E2E and integration tests used the guarded `freebay_test_db` (`public` schema); their fixture resets use `cleanDatabase` and unique test accounts. Stripe is overridden only for HTTP journeys that never call payments; no Stripe/FCM/email network is used by those tests. Restore the fixture with `cd nest-backend && npm run test:e2e` (test-only schema sync runs first).
- The app-configured local runtime database was `postgres` / `public` at `localhost`. The pre-sync Prisma diff contained **only** the seven old-index drops and six composite-index additions; `npm run db:sync` applied it and regenerated the client. `npx cross-env NODE_ENV=development npm run db:seed` successfully loaded the development demo fixture. No migrations were created or run. `prisma migrate diff --exit-code` afterward reported no difference. `pg_indexes` confirmed the six new indexes on `Product`, `Comment`, and `SavedPost`. This establishes schema presence, not measured query latency.

Pre-existing changes were present at `.claude/settings.local.json`, `AGENTS.md`, `CLAUDE.md`, `FREEBAY_RELEASE_HANDOFF.md`, `Makefile`, `docs/DEVICE_TESTING.md`, `frontend/libs/freebay_design_system/lib/components/brutalist_action_sheet.dart`, three existing Flutter tests (`orders_page_test.dart`, `sales_list_provider_test.dart`, `story_viewer_interaction_test.dart`), `nest-backend/test/e2e/setup-e2e.ts`, `package.json`, and untracked `.agents/skills/freebay-perf/`, `.claude/skills/freebay-perf/`, `.codex/`, `docs/FEATURE_MAP.md`, `docs/test-runs/2026-09-26/perf-feed_scroll.md`, `frontend/integration_test/`, `frontend/test_driver/`, `opencode.json`, `perf/`, `scripts/perf-check.js`, and `scripts/perf-check.test.js`. They were preserved.

This run changed `nest-backend/prisma/schema.prisma`, the social post/share/comment repositories and read/write use cases, `nest-backend/test/e2e/marketplace.journey.e2e-spec.ts`, `nest-backend/test/e2e/story-highlights.e2e-spec.ts`, and a social repository spec/use-case spec. On Flutter it changed the auth session invalidation, social feed/search/interaction providers, product feed/Explore page, post search page, and added `frontend/test/features/auth/social_session_isolation_test.dart`, `frontend/test/features/product/product_feed_refresh_test.dart`, `frontend/test/features/product/product_load_more_error_test.dart`, `frontend/test/features/social/post_search_race_test.dart`, and `frontend/test/features/social/post_search_error_test.dart`. The report itself is new.

## Red → green behavioral evidence

| Boundary | Expected | RED observed before implementation | Final outcome |
| --- | --- | --- | --- |
| HTTP + real PostgreSQL: block buyer ↔ seller, then read post/search/profile/timeline/reposts/comments and try like/share/save/comment | Blocked-authenticated viewers cannot read or interact; anonymous public reads remain public | Direct post returned `200` instead of `404` | `npm run test:e2e`: both directions hidden, writes rejected, unblocked guest reads still work; positive `hasReposted` search behavior preserved |
| Flutter post search through Dio with delayed HTTP | Latest query/filter wins; clear invalidates pending response | Only old query was requested; cleared results reappeared | Both delayed-response tests pass |
| Flutter catalog provider | Refresh cannot append an older load-more response | `['fresh', 'stale']` instead of `['fresh']` | Stale response discarded; cursor/retry retained |
| Flutter error UIs | Failed search and failed catalog pagination show retry, not empty results/silent failure | Neither displayed the error message | Both widget tests pass; catalog keeps existing products visible |
| Flutter session boundary | Logout clears previous feed, search, people search, likes/saves, including pending responses | Old posts/users/interaction overrides survived logout; newer people query was dropped | Six cross-session tests pass |
| Whole-app story-highlight E2E boot | No Stripe network/provider initialization for a story-only test | Invalid *test placeholder* Stripe key prefix prevented AppModule boot | Test now overrides unused Stripe provider; story journey passes against real DB |

## Repeatable checks (all exit status 0)

| Command (directory) | Actual |
| --- | --- |
| `npm run tsc:check`, `npm run lint`, `npm run build` (`nest-backend`) | Pass |
| `npm test -- --runInBand` (`nest-backend`) | 99 suites / 606 tests passed |
| `npm run test:integration` (`nest-backend`) | 17 suites / 99 tests passed against the local guarded test database |
| `npm run test:e2e` (`nest-backend`) | 2 suites / 18 tests passed, real HTTP + test database |
| `npm run test:runtime-db` (`nest-backend`) | 1 read-only real-runtime-DB query passed |
| `npm run prisma:test:sync`, `npm run db:sync`, `npx cross-env NODE_ENV=development npm run db:seed` (`nest-backend`) | Test DB and local runtime DB synced; dev seed succeeded |
| `npx prisma migrate diff --from-config-datasource --to-schema prisma/schema.prisma --exit-code` (`nest-backend`) | No difference detected against local runtime DB |
| `npm run test:safety` (`nest-backend`) | 5/5 passed |
| `flutter analyze --fatal-infos lib test libs/freebay_design_system/lib` (`frontend`) | No issues |
| `flutter test --coverage` (`frontend`) | 219 tests passed |
| `flutter build apk --debug` (`frontend`) | APK built successfully at `frontend/build/app/outputs/flutter-apk/app-debug.apk` |
| `node scripts/ci-check.js`, `npm run test:ci-scripts`, `dart format --output=none --set-exit-if-changed frontend/lib frontend/test frontend/libs/freebay_design_system/lib`, `git diff --check` (root) | Pass; 8/8 CI-script tests, 0 formatter changes |

Relevant non-failure log notes: the real-DB Jest runs printed a `pg` deprecation warning about querying on a busy client; some negative-path tests logged expected simulated Nest/Prisma errors. The debug APK build warned that the installed `sentry_flutter` and `stripe_android` plugins still apply Kotlin Gradle Plugin and may need an upstream-compatible version for a future Flutter release. There were no Dart analysis warnings or infos.

## Device/performance verification: BLOCKED

The connected Galaxy A30 (`SM-A305GT`, Android 11, `RX8M70JDTQV`) remained on its lock/Always-On Display after HOME. FreeBay was not installed on it; `http://127.0.0.1:3000/health` returned no HTTP status because the app backend was not running. The existing `perf-feed_scroll.md` already records a blocked feed run from the same device. The Explore profile gate was **not** run: it requires an unlocked device, installed profile build, reachable backend and at least four real products. No screenshot, frame count, FPS, jank rate, or speedup is claimed. Restore the device/backend per `docs/DEVICE_TESTING.md`, then run `node scripts/perf-check.js explore_scroll --device RX8M70JDTQV --update-baseline` for a first measured baseline, review it, and rerun without `--update-baseline`; retain the script's report and screenshots under `docs/test-runs/` / `docs/device-runs/`.

## Remaining measured-work candidates

- Explore feed still fetches/ranks a fixed window of 300 fully included posts for each page (`post-query-helpers.ts`); posts older than that window are not eligible. This needs a defined ranking/pagination contract and representative data before changing semantics.
- Post/product `contains` searches and deep offset comment pagination need representative-size `EXPLAIN (ANALYZE, BUFFERS)` on the actual workload before adding text-search infrastructure or claiming a latency improvement. The new B-tree indexes address common browse, comment-thread and saved-post filter/order shapes; price-descending order with ascending ID ties may still require extra sorting.
- Physical-device UI/performance and the full Flutter auth→feed→explore→checkout journey are not verified by the Flutter widget tests or backend HTTP E2E checks above.
