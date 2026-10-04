# Device resume preflight — 2026-10-01

**Status: BLOCKED for integrated UX and performance validation.** Device preflight succeeded, but the installed APK is historical and the current-source Flutter attach failed to compile. No authentication, backend identity, runtime database, target UX flow, or performance measurement was verified.

**Branch / revision:** `feat/production-hardening` / `c9808b106c3d53f07837542e93f25fd52c6bfbe5` (HEAD unchanged). Pre-existing dirty WIP and concurrent feature moves remain preserved; checkout revision does not identify the installed APK.

**Environment:** Windows host; physical Samsung Galaxy A30, device `RX8M70JDTQV`, model `SM-A305GT`, Android 11, online. Credentials omitted. Flutter integration verification recorded concurrent localization/type/feature-move failures; see [`integration verification`](../integration-verification/frontend/REPORT.md).

## Preflight

| Check | Result |
|---|---|
| Device discovery | `mobile_list_available_devices` found `RX8M70JDTQV` (`SM-A305GT`, Android 11), online. |
| Launch installed `com.freebay.app` | Tool succeeded; app showed expired session. Tapping the visible **FAZER LOGIN** control (hierarchy ref `@e54`) reached an empty login form. No credentials were entered. |
| Terminate and relaunch | Both tool calls succeeded; foreground package was `com.freebay.app`. |
| Read-only installed package metadata | `versionName=1.0.0`, `versionCode=1`, `DEBUGGABLE`; installed `2026-09-30 00:48:04`, last updated `2026-09-30 01:45:26` (device-local timestamps). Historical package only; no current-source identity inferred. |
| Backend forwarding/config inspection | `adb reverse tcp:3000 tcp:3000` succeeded (exit 0). Inspected only public config `frontend/.env`: `API_BASE_URL=http://localhost:3000`. This does not establish backend identity or readiness. |
| Current-source attach | Attempted `flutter attach -d RX8M70JDTQV --app-id com.freebay.app --no-dds --dart-define=API_BASE_URL=http://localhost:3000 --pid-file C:/Users/Qiyana/AppData/Local/Temp/opencode/freebay-device-resume-attach.pid` from `frontend`, with output redirected to the temp log. It reached file syncing and then failed (exit 1) on Dart compile errors. |
| Live app VM / DTD | `listDtdUris` found no current connected live app session after attach failed. No hot restart or current-source proof. |
| Crash inventory | One Samsung `com.samsung.android.forest` report at `2026-10-01 00:00:54.213`; unrelated to FreeBay and not attributed to it. |

The failed attach output is preserved at `C:/Users/Qiyana/AppData/Local/Temp/opencode/freebay-device-resume-attach.log` on the host. Representative compiler errors include missing localization getters, non-constant expressions, and type/member errors across login, social, product, profile, orders, dispute, and chat files. No source was changed in this documentation lane. The preflight login screenshot is [`login-preflight-old-apk.png`](../../../device-runs/2026-10-01/device-resume/login-preflight-old-apk.png); it shows an empty form, not a completed login.

## Blockers and limits

- Current source could not attach because compilation failed; the installed historical APK is not evidence for current checkout behavior.
- No authentication was performed, and no backend/runtime database identity or fixture was confirmed. Guarded backend/fixture preparation is ongoing outside this lane.
- No target UX journey, complete branch/P1 flow, or provider behavior was exercised.
- No hot restart, current-source proof, or performance measurement occurred. Existing integration report records Flutter gates blocked; no APK was produced there.
- Do not interpret the unrelated Samsung crash record as a FreeBay crash.

## Next evidence needed

After the integrated Flutter compile blockers are resolved and a current APK/source identity is established, confirm the guarded backend and fixture identity, authenticate using an authorized test fixture, run the exact target journey, and record the result and any performance evidence separately. Until then this report remains a preflight-only blocked record.
