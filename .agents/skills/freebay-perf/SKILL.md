---
name: freebay-perf
description: Use for FreeBay Flutter performance work (scroll, animation, images, jank, frame timing, CPU profiling) and whenever validating a perf-sensitive UI change on a device.
---

# FreeBay performance verification

1. Read `freebay-app-flows` and `docs/DEVICE_TESTING.md` to identify the real journey and fixture. Check that the backend and an unlocked, awake Android/iOS device are reachable (native biometrics can stall hydration behind the lock screen). For chat, prepare an authenticated session with enough real messages; for stories, seed an image story. Never count an empty/skeleton/error page as a measurement.
2. Run `node scripts/perf-check.js <flow> --device <id>` at repo root. Flows in `perf/baselines/`: `feed_scroll`, `explore_scroll`, `chat_scroll`, `story_view`, `product_detail`. `--all` runs them serially. Without a measured baseline, run with `--update-baseline` locally, review the measurement, then rerun normally. Compare on the same device model/OS and same fixture; never update baselines to hide a regression. The gate records `docs/test-runs/<date>/perf-<flow>.md` with status, revision, environment, metrics and reproduction command. A blocked run is blocked, not green.
3. Investigate failures with the `flutter-profile` MCP against a live `flutter run --profile -d <id>` VM-service URI: capture frame timing and CPU hotspots on the same screen. `dart mcp-server` is for Dart/Flutter analysis and app inspection; it does not itself prove a frame budget. Follow `freebay-mobile-mcp` for device interaction. Re-run the profile gate after edits.

The runner uses `IntegrationTestWidgetsFlutterBinding.watchPerformance` (real `FrameTiming` for build **and** raster) and `flutter drive --profile --no-dds`; it fails on missing metrics, fewer than 30 frames, missed build/raster budgets, absolute thresholds or >20% regression from a measured baseline. Timings are hardware/fixture-specific. Hardware or backend absent: record the blocker rather than substituting a mocked/widget test. Do not add a hardware gate to `make test`/CI without an available, stable device and reviewed baselines.

## Agent setup

The skill is mirrored under `.claude/skills/` and discoverable via `AGENTS.md` by Claude Code, OpenCode and Codex. Project MCP settings: local `.mcp.json` for Claude, `opencode.json` for OpenCode, `.codex/config.toml` for Codex. Install once per workstation with `dart pub global activate flutter_profile_mcp`. The profiler starts with `dart pub global run flutter_profile_mcp:flutter_devtools_mcp` (works on Windows even when the Pub bin directory is missing from the parent process's PATH). Restart each agent client after changing its MCP configuration. A live VM service is still required to attach the profiler to an app.
