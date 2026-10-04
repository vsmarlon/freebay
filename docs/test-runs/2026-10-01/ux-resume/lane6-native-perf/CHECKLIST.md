# Parent execution checklist — Lane 6

Run only under parent control on the Galaxy A30 (Android 11). Preserve the already verified reverse mapping `tcp:3000 -> tcp:3110` to the guarded backend; do not reset it to `3000 -> 3000` or issue device/ADB commands from this lane. Device work, account/fixture selection and credentials remain parent-owned. Do not put credentials in evidence.

1. Confirm current diff/revision and record device model/OS, fixture identity without secrets, reset/setup, command exit status, relevant output and crash state in the evidence report.
2. From `frontend`, run the approved native compositor integration test on the parent-selected device/build setup, for example:
   `flutter test integration_test/native_image_compositor_test.dart -d <device-id>`
   This lane did not run it. Preserve all pixel assertions and report any failure verbatim.
3. From repository root, take the **first valid measurement as a new baseline**, not a comparison:
   `node scripts/perf-check.js chat_scroll --device <device-id> --update-baseline`
   Inspect the real conversation and output first. A missing fixture/summary, fewer than 30 frames, invalid metrics, or any budget failure is not a pass; do not describe it as valid measured evidence. Do not rerun/update solely to overwrite a failure without investigating it.
4. Only after a valid baseline has been reviewed and recorded, run the comparison gate:
   `node scripts/perf-check.js chat_scroll --device <device-id>`
5. Attach exact terminal output and the runner-produced `docs/test-runs/2026-10-01/perf-chat_scroll.md` (or actual UTC-date path), plus screenshot/crash observations where safe. Record both commands separately and do not claim UX1–UX3 complete from harness checks alone.

## Profile scroll baseline before any production edit

The profile scroll test currently cannot execute because Flutter test compilation hits unrelated stale generated-localization getters (recorded in `REPORT.md`). No production patch is authorized until the parent captures the before-frame profile on the live A30.

1. Cover both the signed-in user's own profile and another user's profile through their real routes. For each route, keep the same account, profile/fixture, Android 11 A30, profile-mode build, selected timeline kind and app revision before/after. Warm that profile and wait until timeline loading settles.
2. **Coordination observation (not the timing sample):** partially collapse the profile header with a drag that starts on the header; record the tab/header position. Then drag within the active timeline. Record whether the header moves and whether the list position advances. Repeat for Posts, Reposts, and Anúncios; tab swipes must not change shell branch.
3. **Comparable timing sample:** separately place the header/tab row in the same fully-collapsed/pinned position before each run. Capture live frame timings while repeatedly scrolling only the active list, with no tab switch or loading in progress. Sample each of the three kinds. Keep raw profiler output, frame count, build/raster timing data, device/OS, revision, fixture identity (no secrets), and exact interaction steps.
4. After the parent authorizes the minimal production change, repeat the identical warm-up, header position and scroll interactions on the same device/profile fixture. Compare before/after metrics; do not promise a frame-rate gain unless the measurements establish one. Keep scroll-coordination observations distinct from performance measurements.
