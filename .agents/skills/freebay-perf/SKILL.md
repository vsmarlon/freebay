---
name: freebay-perf
description: Use for FreeBay Flutter rendering, scrolling, animation, frame timing, image, or jank work and device validation.
---

# Performance evidence

Read `docs/DEVICE_TESTING.md` and `freebay-app-flows`; prepare an awake, unlocked device, live backend and representative authenticated fixture. Never measure an empty, skeleton, error or loading-only screen.

At repo root run `node scripts/perf-check.js <flow> --device <id>` for a supported flow (`feed_scroll`, `explore_scroll`, `chat_scroll`, `story_view`, `product_detail`); inspect runner help/source before assuming flags. Baselines are device/fixture-specific; update only after reviewing a valid measurement. Missing frames/metrics is failure, not a pass.

For diagnosis use a live profile VM service and capture frame timings/CPU while exercising the measured screen. Repeat the gate after edits. Record revision, device/OS, fixture, command, metrics, evidence and blockers in `docs/test-runs/<date>/`; no hardware/backend means blocked, not substituted with a mocked test.
