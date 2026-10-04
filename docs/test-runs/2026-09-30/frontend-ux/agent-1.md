# Frontend UX hardening — executor 1

Date: 2026-09-30  
Workspace: `C:\Users\Qiyana\Documents\GitHub\ME\freebay`, shared multi-agent checkout. Initial HEAD `455818164b7b87e5d57eb1dd84313eacd9ce580b`; no commit or branch change. Pre-existing story-viewer test, device evidence, baseline report, `docs/HARDENING_PLAN.md`, and other work were not edited.

## Completed

- `frontend/lib/main.dart`: storage and Hive initialization run concurrently before app execution. Deferred Stripe readiness and Firebase initialization also run concurrently, then notification setup and launch-payload consumption run in order. Initialization errors are reported without preventing the app fallback.
- `frontend/lib/shared/services/payment_sdk_service.dart`: added one shared Stripe readiness future; both existing native PaymentSheet call sites await it to avoid racing deferred setup.
- `frontend/lib/shared/services/notification_service.dart`: after Firebase listeners attach, initialization retries token retrieval/registration to close the early-auth-hydration window.
- `frontend/lib/shared/services/storage_service.dart`: added version-1, user-namespaced JSON cache APIs (`readCachedJson`, `writeCachedJson`, `clearUserCache`) backed by Hive, with a 512 KiB UTF-8 encoded-entry bound, corrupt-entry discard, cache generation fencing, and purge after credential clearing. Main enables cache access after Hive initialization. The cache contains no credentials and cache failures do not break online operations.
- `frontend/lib/shared/services/http_client.dart`: retries GET requests at most twice with exponential delay plus jitter for connection errors/timeouts and HTTP 502/503/504. Mutation methods are not replayed; retries stop when canceled or the captured auth session generation changes. Existing 401 refresh flight and logout paths remain separate.
- `frontend/lib/shared/providers/connectivity_status_provider.dart`: added generated Riverpod `connectivityStatusProvider`, emitting initial and changed radio connectivity as `Stream<bool>` (`true` means at least one non-`none` connection; it does not assert internet reachability). Generated output is deferred to the coordinator's codegen step.
- Added focused tests for GET retry/mutation non-replay, timeout/session invalidation/cancellation, and user-isolated cache purge including a pending write.

## TDD and verification

Retry test authoring gap: no existing focused service test established bounded transient GET retries while distinguishing unsafe mutation replay. RED command: `flutter test test/shared/services/http_client_retry_test.dart` in `frontend`. Intended failure observed: GET returned Dio 503 and the test expected 3 adapter requests; mutation remained one request. The combined pre-fix run eventually hit test timeouts because the initial implementation retried from inside the queued auth interceptor; that implementation was replaced with a preceding regular interceptor. This was a real implementation deadlock, not the intended RED.

Cache test authoring gap: no existing behavior test showed user namespace isolation and that clearing one user's cache removes only that user's entry. The test is part of the focused run; a separate pre-implementation RED was not run because the service API did not exist yet. The latest pending-write purge, timeout/cancellation, startup parallelism, notification token retry, Stripe readiness, and connectivity provider edits have not been verified after resumed implementation. Do not treat earlier GREEN/analyze output as proof for these final edits.

Exact final focused commands/results:

- `dart format lib/main.dart lib/shared/services/http_client.dart lib/shared/services/storage_service.dart test/shared/services/http_client_retry_test.dart test/shared/services/storage_service_cache_test.dart` — `Formatted 5 files (0 changed)`; exit 0.
- `flutter test test/shared/services/http_client_retry_test.dart test/shared/services/http_client_logout_test.dart test/shared/services/storage_service_cache_test.dart` — `All tests passed!`; 5 tests; exit 0. Existing captured-bearer logout regression included; retry cases cover bounded 503 retry, mutation non-replay, and session-generation invalidation.
- `dart analyze lib/main.dart lib/shared/services/http_client.dart lib/shared/services/storage_service.dart test/shared/services/http_client_retry_test.dart test/shared/services/storage_service_cache_test.dart` — `No issues found!`; exit 0.

The focused adapter tests are not a real-backend/device journey and do not prove offline state or runtime performance. No performance gain is claimed. The recorded commands ran before the latest resumed edits; exact final-version verification remains pending. Full frontend codegen, format gate, analyze/test suite, APK build, root CI gates, and device/perf checks are left for the coordinator's final wave.

## Consumer handoff and limits

- Cache API for other agents: static `StorageService.readCachedJson({required String userId, required String key})`, `writeCachedJson({required String userId, required String key, required Map<String, Object?> json})`, `clearUserCache({String? userId})`. Call cache reads/writes only for explicitly permitted public feed/profile data and stale display data; never treat cached order/payment state as authoritative. `clearTokens()` clears this cache globally after secure token deletion. Account-switching code should call `clearUserCache(userId: oldUserId)` when appropriate; cache contents must be selected by the current authenticated user ID.
- HTTP request cancellation can use the existing Dio request `cancelToken` option; shared HTTP GET retries honor it. Feature providers/repositories should cancel their own requests on disposal rather than globally canceling other requests.
- Connectivity consumer API: generated `connectivityStatusProvider` is `AsyncValue<bool>`; `true`/`false` means radio connectivity only, not internet reachability.
- Stripe entry points await `PaymentSdkService.ensureReady()`; native PaymentSheet device proof remains outstanding.
- Existing product-repository Hive cache was not migrated because that repository is outside this agent's allowed files. Agent 2/product-repository owner should adopt the shared cache API rather than retain an independent cache box.
- Agent 6 owns root localization wiring; this executor did not alter localization imports or ARBs.

## Not done

Feature screens, widgets, and feature repositories remain outside this executor's ownership. This does not complete all UX U0–U8 behavior. Generated connectivity provider output, final frontend gates, and device validation remain pending in the coordinator wave.
