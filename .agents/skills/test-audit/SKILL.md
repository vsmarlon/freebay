---
name: test-audit
description: Invoke whenever writing, changing, reviewing, or sweeping tests. Authoring gate for new tests plus audit workflow for low-value, implementation-coupled, or duplicative tests and the test-only production seams they demand.
---

# Test Audit

Three modes, one value bar. **Authoring** gates each new or changed test. **Audit** finds tests that re-assert source, duplicate stronger proof, couple behavior to implementation, or keep test-only production seams alive. **Campaign** covers every test file owned by one subsystem; read [CAMPAIGN.md](CAMPAIGN.md) before starting one. Continue broad audits as separate coherent follow-ups; optimize for confidence, not deletion count.

Follow `AGENTS.md` testing policy: RED → GREEN → REFACTOR for behavioral changes, prefer real application boundaries, and record reproducible E2E evidence in `docs/test-runs/<date>/`. Before claiming a FreeBay capability, read `docs/FEATURE_TRUTH.md`.

## Authoring gate

Before adding or changing a test, answer all four questions; a missing answer means the test is not ready:

1. What observable behavior, invariant, or independent contract does it protect?
2. What credible regression makes it fail?
3. Why does existing coverage not already catch that failure? Each contract has one primary test owner at the strongest practical boundary. A second layer needs a distinct risk, such as transport or lifecycle failure the owner cannot reach. Prefer extending a table-driven case or shared fixture to adding a near-duplicate; consolidate duplicated setup in the same change.
4. Does it demand an export, flag, wrapper, or injection hook with no production caller? If so, exercise the real boundary instead.

Apply every junk pattern below. A match fails the authoring gate unless the retention bar identifies the independent contract it guards. If behavior-preserving refactoring breaks the test, rewrite it at the owning boundary before landing it.

A bug regression must fail on pre-fix code for the intended reason (not a compile error or broken fixture), then pass after the owner-boundary repair. One regression at that boundary covers the bug; do not replay the same scenario at every layer.

## Junk patterns

- Assertion-free coverage probes; self-comparisons and identity copiers.
- Copied fixtures, inventories, manifests, or export lists; exact source, import, or string greps.
- Private predicate or call-shape tests duplicated at real boundaries; duplicate invocations of the same contract; provider-local replays of shared helpers.
- Tests whose sole purpose is preserving test-only exports, globals, or wrappers; dead production code called only by tests.
- Expected values produced by the helper or renderer under test; mocks that implement the asserted behavior, or one identical mock standing in for different APIs.
- Fixtures that supply the receipt, admission, or callback ordering the owner should produce; persistence asserted against a store the path never writes.
- Capability tests that restate declared flags instead of exercising promised delivery or acknowledgement.
- Negative controls that pass for an unrelated reason (a different guard or unreachable rejection).
- Names or fixtures that promise more than the input exercises (for example, “retires the window” when the test never checks that the window was cleared).

## Audit workflow

1. **Discover read-only.** Read root and scoped `AGENTS.md` files; inspect complete tests and production owners, entry points, callers, callees, sibling implementations, overlapping tests, CI routing, and relevant history. For dependency-backed claims, inspect dependency source or types. For broad scope, investigate backend (`nest-backend/`), frontend (`frontend/`), scripts/tooling, and cross-cutting patterns in parallel where useful. Report evidence before editing; outside a campaign choose a few high-confidence candidates.
2. **Apply the retention bar.** Keep independent public API, plugin SDK, protocol, config, migration, storage, security, platform, default, prompt-byte, generated cross-language, package, release, and architecture contracts. Keep observable call ordering and credible regressions. Source inspection can be the cheapest independent guard when it fails on a user-facing key, byte, or path change yet survives an identifier-only refactor. If a retained test fails on the baseline, reproduce the possible product bug and repair the owner rather than deleting the test. Static or slow alone is not a deletion reason.
3. **Record candidate evidence before edits.** For every proposed removal, identify: exact test name/location; failure it can actually detect; non-test callers of its production/support seam; stronger remaining owner-boundary proof (or why no proof is needed); relevant history and why it exists; production/test-support deletion unlocked; risk and focused validation command. Missing evidence means defer the candidate.
4. **Edit one coherent owner-boundary batch.** Remove obsolete test-only exports, globals, wrappers, and dead production paths rather than preserving aliases. Move retained regressions to canonical owners. Consolidate repeated package/dependency assertions into one generic contract. Prefer net-negative production LOC; do not replace low-value tests with the same implementation assertions or turn uncertain candidates into cleanup.
5. **Validate and hand off** using the gates below. Do not edit source or tests while a test runner is still running in this checkout.

## Validation

- Run the smallest affected owner and sibling tests first: `npx jest <spec-path> --runInBand` in `nest-backend/`; `flutter test test/<path>.dart` in `frontend/`; `node --test scripts/<file>.test.js` at repo root. Use the corresponding integration/E2E command in `AGENTS.md` when that is the owning boundary; do not substitute mocked success for a blocked real-DB/device run.
- When removing source greps or plan assertions, execute the script or dry-run that owns the real contract. Format touched Dart files with `dart format <paths>`; run `git diff --check` and inspect `git diff --numstat` (account for untracked files). Report production/tooling LOC separately from tests and test support.
- Classify affected gates against `AGENTS.md` and `.github/workflows/ci.yml`, then run the applicable gates: backend typecheck/lint/unit/integration/E2E, frontend analysis/tests/build, root architecture gates and script tests. Record blocked gates as blocked and say why. After the final edits, independently review the complete diff for lost contracts, dead seams, and accidental unrelated changes.

## Landing and handoff

Commit, push, open a PR, or land only when authorized. Land one coherent PR at a time; after landing, refresh from current main and redo read-only discovery for the next batch.

Report root cause and removed junk categories; production owner simplifications; retained false positives and why they matter; focused and full proof actually run; production versus test LOC; PR/merge state; and named follow-ups.
