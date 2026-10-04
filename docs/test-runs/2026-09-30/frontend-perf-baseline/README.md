# Frontend performance U0 evidence — 2026-09-30

**Status: Profile-mode startup and feed-scroll measurements captured; exact build revision and backend fixture provenance remain unverified.**

## Environment and attachment

- Physical device: Galaxy A30 (`SM-A305GT`), Android 11, device id `RX8M70JDTQV`.
- Foreground app: `com.freebay.app`, Flutter **profile** mode. Attached without app restart/termination through the currently advertised local DTD connection and the connected app VM service (connection tokens omitted).
- App info: Dart 3.12.2 stable, Android ARM64, service protocol 4.21, one isolate, root library `package:freebay/main.dart`. Profile mode confirmed by both attach and app-info.
- `frontend/build/start_up_info.json` was read after the user reported building/starting this profile app. File mtime and exact built source revision were not established. The user-provided build provenance is noted; source identity remains unproven.
- Screen showed populated feed/product cards. See device screenshots under `docs/device-runs/2026-09-30/frontend-ux-baseline/`.
- Backend reachability/fixture source: unverified. Profiler HTTP profile showed no requests during the capture.

## Startup values from `frontend/build/start_up_info.json`

- `timeToFirstFrameMicros`: **4,199,447 µs = 4.199447 s**.
- `timeToFirstFrameRasterizedMicros`: **4,213,140 µs = 4.213140 s**.
- `timeToFrameworkInitMicros`: **536,578 µs = 0.536578 s**.
- `timeAfterFrameworkInitMicros`: **3,662,869 µs = 3.662869 s**.
- `engineEnterTimestampMicros`: **2,342,437,820,426** (engine clock timestamp, not wall-clock time).
- These are values from the just-built artifact JSON, not an independently recorded cold-launch trace in this session. The running app was not terminated or relaunched.

## Feed-scroll capture (seven short windows)

The profiler screenshot API failed with `ext.flutter.inspector.getRootWidgetSummaryTree: Unknown method`; the device screenshot was used before frame capture. A first 30-second profiler call timed out. After current DTD reattachment, seven shorter captures were run while issuing vertical feed swipes at the screen center (no horizontal swipes, likes, sends, or payments). MCP provided summary and worst-five data per window, not an exportable raw per-frame trace.

| Window | Requested duration | Frames | Tool FPS | Janky (>16 ms budget) | Raster jank | Worst reported work (build + raster) |
|---:|---:|---:|---:|---:|---:|---|
| 1 | 3 s | 81 | 55.4 | 47 (58.0%) | 42 | 28.11 ms (1.03 + 27.08) |
| 2 | 5 s | 92 | 55.2 | 65 (70.7%) | 53 | 30.96 ms (2.40 + 28.57) |
| 3 | 5 s | 93 | 55.7 | 73 (78.5%) | 63 | 29.22 ms (1.01 + 28.21) |
| 4 | 5 s | 93 | 55.9 | 75 (80.6%) | 62 | 27.80 ms (1.50 + 26.30) |
| 5 | 5 s | 92 | 54.8 | 48 (52.2%) | 45 | 27.40 ms (0.48 + 26.91) |
| 6 | 3 s | 92 | 54.7 | 48 (52.2%) | 39 | 27.29 ms (1.26 + 26.04) |
| 7 | 5 s | 93 | 56.6 | 76 (81.7%) | 66 | 27.22 ms (1.31 + 25.91) |
| **Sum** | **31 s requested** | **636** | **not aggregated** | **432/636 (67.9%)** | **370** | **max 30.96 ms** |

Every window reported `SEVERE`; raster jank was identified as dominant. All worst frames returned by the tool are below 32 ms (maximum 30.96 ms), so no >32 ms frame appears in the returned worst-five summaries; exact all-frame >32 ms count cannot be established without raw samples. Per-window FPS does not reconcile arithmetically with returned frame count divided by requested duration, so FPS remains per-window and no aggregate FPS is claimed. The >16 ms janky totals are the profiler's own per-window counts. This is an actual on-device performance observation, not a clean baseline or backend-dependent release gate.

## Memory and supporting evidence

- Before scroll: **36.4 MB Dart heap**, **0.0 MB external**; profiler reported 94% of 38.5 MB.
- After scrolling: **39.2 MB**, **0.0 MB external**; profiler reported 95% of 41.1 MB.
- After Feed → Explore → Wallet → Messages → an existing conversation (composer keyboard opened/dismissed without typing) → Profile → Feed: **30.0 MB**, **0.0 MB external**; profiler reported 95% of 31.7 MB. These are point observations, not leak evidence.
- Final crash query returned no reports. The filtered HTTP profile was empty (backend reachability not established). Device logs are in the UX evidence folder; the later raw log capture has 100 entries and was not reviewed.
- Device screenshots: `feed-before.png`, `feed-restored.png`, `profile-feed-after-scroll.png`, `feed-final.png`. Profiler-native screenshot remains unsupported in this app's current service extensions.
- Rebuild counts are unavailable in profile mode. No `perf-check.js`, cold-start recording, exact source revision proof, or test/analyze/build/format verification was run.

## Reproduction boundary

Repeat after identifying the built source revision and confirming the backend fixture. Attach to the same Galaxy A30 profile VM, capture the same populated feed interaction, and compare on the same device/fixture. Current evidence uses Flutter profile frame events and startup JSON values; it is not a verified source-revision baseline.
