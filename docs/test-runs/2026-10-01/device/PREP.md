# Device verification prep — 2026-10-01

**Status: PREPARED / NOT RUN.** Device app and profile were not touched. Frontend gates/codegen are owned by another executor; resume device work only after that owner confirms completion and the source tree is frozen.

## Read-only preflight

- Current `HEAD`: `c9808b106c3d53f07837542e93f25fd52c6bfbe5`; working tree is extensively dirty (299 files in the inspected diff). This is not sufficient identity for the eventual APK: capture final `HEAD`, `git status --short`, and an artifact SHA-256 after codegen/gates and immediately before running it.
- Local device discovery returned Galaxy A30 (`SM-A305GT`), Android 11, `RX8M70JDTQV`, online. Use this id for every device tool call; no remote device.
- Read-only screen hierarchy currently shows FreeBay's **“SESSÃO EXPIRADA”** screen. Do not treat the existing process/profile as authenticated or as the final build.
- `GET http://127.0.0.1:3000/health` returned HTTP 200, service `freebay-backend`, status `ok`. Listener PID 25060 is `node ... nest-backend/dist/src/main`. This proves a health response only, not auth, DB schema/readiness, fixture availability, or that the APK reaches the same runtime.
- Android application id is `com.freebay.app`. `AppConfig` defaults to `http://localhost:3000` for Android debug/profile; USB requires `adb reverse tcp:3000 tcp:3000`. No reverse was issued in prep.
- Existing feed performance baseline is empty (`perf/baselines/feed_scroll.json`: no device, date, or metrics). Prior 2026-09-30 profile evidence is explicitly not a source-verified baseline: 4.213140s startup JSON (not a measured cold launch), 636 frames over 31s requested, 432/636 >16ms janky, 370 raster-janky, max reported worst frame 30.96ms; no aggregate FPS or raw-frame >32ms count. Do not represent it as a post-change comparison.

## Resume gates and exact commands

1. Wait for frontend owner confirmation that generated files and all frontend gates/build have finished. Capture source identity from the final shared tree (do not build concurrently):

   ```powershell
   git rev-parse HEAD
   git status --short
   Get-FileHash frontend/build/app/outputs/flutter-apk/app-profile.apk -Algorithm SHA256
   ```

   Capture the APK's package/version using Android build-tools `aapt dump badging frontend/build/app/outputs/flutter-apk/app-profile.apk` and record Flutter/Dart versions (`flutter --version`). Include the final tree identity and APK hash in the run report; never publish env values, tokens, or personal data.

2. Run the **unmocked production-channel pixel test** on the local Galaxy A30 (this installs/runs a test app; do not do it during the current owner gate):

   ```powershell
   cd frontend
   flutter test integration_test/native_image_compositor_test.dart -d RX8M70JDTQV
   ```

   This exercises `exportFinalImage` through the real registered Android MethodChannel and asserts rotated bounds/pixels, matrix-filtered pixels, stroke plus isolated eraser pixel retention, contain-fit letterbox mapping, visible text pixels, and `ImageEditorPage.onComplete` PNG callback. Pass proves this Android native composition contract only; it does not prove iOS parity or post/story/chat HTTP upload persistence. Record test exit status and logs. iOS native parity is **blocked on an iOS device/build host**, not inferred from Android.

3. For same-device performance, first establish an authenticated, populated feed with multiple real posts and verify backend/runtime fixture ownership. The current screen is expired and the runtime fixture is unverified, so **do not run the gate yet**. `feed_scroll` has no measured baseline; after a valid representative run, baseline creation is an explicit baseline mutation and must be recorded separately:

   ```powershell
   node scripts/perf-check.js feed_scroll --device RX8M70JDTQV --update-baseline
   node scripts/perf-check.js feed_scroll --device RX8M70JDTQV
   ```

   The script runs profile-mode `flutter drive`, applies USB reverse itself, requires >=30 measured frames, writes `docs/test-runs/2026-10-01/perf-feed_scroll.md`, and the update command also mutates `perf/baselines/feed_scroll.json`. Run once for baseline only after fixture/source/device identity are valid; run the non-update command for the regression gate. Do not use the 2026-09-30 observational capture as its baseline.

4. If an end-to-end upload proof is separately authorized and a safe account/fixture is available, exercise one public test post, story, and chat attachment using the editor's returned PNG; compare decoded pre-upload output pixels to bytes fetched from the real backend and retain request/result evidence without exposing account data. No payments, public/private personal content, or messaging a real recipient. No UI actions, registration, fixture creation, install/restart, adb reverse, profiler interaction, or upload were performed during prep.

## Resume blockers

- Frontend gates/codegen and final APK/source identity are pending another executor.
- Current app session is expired; safe authenticated fixture/account is not established.
- Runtime health is green, but runtime DB/schema/permissions and representative feed fixture are not verified.
- No same-device measured feed baseline exists. Native test remains unrun. iOS native validation requires an iOS host/device.
