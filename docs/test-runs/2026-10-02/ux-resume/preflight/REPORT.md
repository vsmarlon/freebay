# UX resume preflight — 2026-10-02

- Revision: `c9808b106c3d53f07837542e93f25fd52c6bfbe5` (extensively dirty working tree; frontend, backend, scripts, and docs changed).
- Scope: non-destructive readiness checks before backend/device preparation. No commit, migration, hardening work, fixture write/delete/reset/seed, or UX device interaction was performed.
- Evidence: observations below came from parent-session terminal/tool output. No newly saved raw log exists for these parent calls; do not treat this report as a raw command transcript.

## Environment and data safety

Listener inspection (`Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -in @(3000,3110,5432,6379) } | Select-Object LocalAddress,LocalPort,OwningProcess`) found PostgreSQL on 5432 (PID 5752), local Redis on 6379 (PID 4336), an unknown node process on wildcard port 3000 (PID 30908), and no listener on 3110. Safe process classification confirmed `dist-main`, but did not establish an approved/safe bootstrap. The environment DB remains unknown and was left untouched.

The root read-only readiness script, `node C:\Users\Qiyana\AppData\Local\Temp\opencode\freebay-device-backend\pg-readiness.cjs`, exited 0 and reported `freebay_test_db`, schema `public`, `in_recovery: false`. The guarded test environment loaded `.env.test` and validated only local `freebay_test_db` before querying; no non-test database was queried. A guarded Redis probe also loaded `.env.test`, validated loopback Redis on 6379, returned `PONG`, and exited 0. Credentials were not logged.

A subsequent guarded PostgreSQL read-only probe used the same `.env.test` guard and a read transaction. It emitted counts only (no row contents or identities): owners 0, posts 0, reposts 0, products 0, active stories 0, messages 0; identity `freebay_test_db/public`, recovery false; exit 0. The earlier synthetic `uxr261001` fixture is no longer present. Device preparation must provision fixtures non-destructively after backend gates; older gates expected a clean DB.

## Checks

| Command / observation | Result |
| --- | --- |
| `node scripts/ci-check.js` | Exit 0; silent. |
| `npm run test:ci-scripts` | Exit 0; 14/14 tests passed. |
| `flutter test --no-pub test/features/profile/follow_state_test.dart` | Exit 0; 7 passed. No source edits were made by this check. A prior count failure is not the current result. |
| `flutter test --no-pub test/features/profile/follow_state_test.dart test/features/profile/profile_timeline_tabs_test.dart test/features/profile/profile_settings_sheet_test.dart` | Exit 1. All 7 follow cases executed and passed, but compilation reported a cascade/loading error: gear test missing `Failure`/`CancelToken` types, wrong `go_router` indexed-stack custom-builder argument, and `ProviderScope` not an `InheritedWidget`. Profile tabs ran but failed because `PROFILE HEADER` was absent at `getCenterline200`; this is not the intended scroll RED. Old missing localization getters no longer failed compilation. Treat these as setup failures, not behavior-RED evidence. Executor repair evidence belongs separately in `flutterprep/`. |

## Device and installed artifact

`mobile_list_available_devices` found online physical device `RX8M70JDTQV`, Samsung SM-A305GT, Android 11. ADB reverse inspection (`adb -s RX8M70JDTQV reverse --list`) exited 0 and listed USB FFS `tcp:3000 tcp:3000`; it did not show the protected 3110 mapping, so this does not establish that the device works against the backend. No mobile UX interactions, screenshots, or performance run were performed. The DTD connection identified a running Flutter app with package `freebay`; build identity was unknown. The WebSocket URI is intentionally omitted.

The installed base APK was pulled to private temporary storage and hashed against `frontend/build/app/outputs/flutter-apk/app-debug.apk`. They matched: 179,246,288 bytes, SHA-256 `b8fc267c386e969a5189ba7dee9c2c82d56987b7a5c62a7a1a4695c41f2b10d1`; local artifact timestamp was 2026-10-02 11:06:54.824 -03. This confirms the installed APK matches the handoff artifact, not a fresh rebuild or final-state proof.

## Handoff and remaining gates

The parent approved a minimal email-OTP authentication/CPF-change plan after the configured advisor failed with `Unsupported parameter: temperature`; a read-only general-advisor fallback was used. The planned proof is control of the stored email, not government identity proof. Current email control itself is sufficient; no verified-email prerequisite is asserted. Required binding is current email + user + normalized CPF, with TTL, atomic consume/attempt handling, and rate limits. Pending contacts/name changes and the 90-day scope are not complete; do not claim full P1–P10 coverage.

Profile the app before capture under the L6 checklist, before applying the primary-false patch. Final gates remain pending: new-hash verification, device five-flow NEWBASELINES, and `make test` last. Do not update `docs/FEATURE_TRUTH.md` from this preflight alone.
