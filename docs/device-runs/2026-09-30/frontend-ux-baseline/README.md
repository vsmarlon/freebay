# Frontend UX U0 evidence — 2026-09-30

**Status: profile UX tour completed; final app returned to Feed.** No production edits or test/build commands were made.

- Device: physical Galaxy A30 (`SM-A305GT`), Android 11, id `RX8M70JDTQV`.
- App: `com.freebay.app`, profile mode, attached to the current running VM without restarting or terminating it. Startup JSON is `frontend/build/start_up_info.json`; exact source revision is unproven.
- Starting screen was populated Feed (`feed-before.png`). Profiler screenshot call failed on an unsupported inspector method; mobile screenshot captured the screen.
- Inspected real screens in the tab tour: Feed → Explore (products visible) → Wallet (zero balances and empty transactions; did not enter receive/payment setup) → Messages → existing Carol Vintage & Curadoria chat. Opened then dismissed the composer keyboard without typing or sending. Visited Profile, then returned to Feed. Screen hierarchy was checked after each transition.
- During chat, the selected thread was an existing conversation; no message was sent. No like, payment, or content creation was triggered.
- Seven profile frame windows totaling 31 seconds of requested capture duration ran during vertical feed swipes. Detailed measured summaries are in `docs/test-runs/2026-09-30/frontend-perf-baseline/README.md`.
- Final foreground check reported `com.freebay.app`; Feed was restored. Screenshot `feed-final.png`.
- Final crash query returned no reports. HTTP profile showed no requests (backend reachability unverified). A previous filtered device-log capture saved 0 entries (`device.log`); later capture saved 100 raw entries (`device-final.log`), unreviewed.
- No cold-launch recording or startup trace was captured; the app was intentionally not stopped/relaunched. No video artifact is claimed. Earlier failed recording attempt did not produce a usable file.

Artifacts: `feed-before.png`, `feed-restored.png`, `profile-feed-after-scroll.png`, `feed-final.png`, `device.log`, `device-final.log`. Profiler screenshot failure, startup values, per-window frames, and capture caveats are recorded in `../../../test-runs/2026-09-30/frontend-perf-baseline/README.md`.
