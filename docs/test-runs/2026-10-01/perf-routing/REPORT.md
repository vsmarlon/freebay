# Android performance-runner routing fix

- Tested revision: `c9808b1` plus the existing dirty working tree and this patch; no commit was created.
- Environment: Windows; Android hardware, ADB, Flutter, backend, and fixture were not exercised by this subtask.
- Observable contract: before Flutter drive, inspect selected-device ADB reverse mappings; preserve any mapping whose source is `tcp:3000`; only create the existing `tcp:3000` → `tcp:3000` default when absent. Inspection errors/nonzero status stop before drive or remapping.
- Regression reason: runner unconditionally changed source port 3000 to destination port 3000, overwriting an existing 3000 → 3110 mapping and routing the app away from the guarded backend.
- Test seam: Node VM executes the production CLI branch with external filesystem writes suppressed and child-process responses stubbed. Assertions observe mapping effect and whether drive was reached; no new production API or dependency.

## Verification

- RED: `node --test scripts/perf-check.test.js` — exit 1; 6 passed, 2 failed. The existing-mapping case failed because no `reverse --list` inspection occurred; inspection-failure case reached Flutter drive.
- GREEN: `node --test scripts/perf-check.test.js` — exit 0; 8 passed, 0 failed.
- `npm run test:ci-scripts` — exit 0; 14 passed, 0 failed.
- `git diff --check` — exit 0; emitted only existing line-ending conversion warnings for numerous already-dirty files.

Physical-device and performance measurements remain unverified and are not implied by these tests.
