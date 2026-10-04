# Root initial verification

## Identity and scope

- Branch: `feat/production-hardening`; HEAD tested: `c9808b106c3d53f07837542e93f25fd52c6bfbe5`.
- The checkout was already extensively dirty, including frontend/backend work and edits to `scripts/ci-check.js`, its tests, `docs/HARDENING_PLAN.md`, and `docs/FEATURE_TRUTH.md`. Those changes are preserved; this lane added only its own evidence directory.
- Windows, Node/npm versions are not recorded in this lane. Capture runner: `C:/Users/Qiyana/AppData/Local/Temp/opencode/freebay-baseline-run.cjs`. Each gate has a redacted `.log` plus `.json` manifest with exact command, working directory, UTC timestamps, and exit code.
- Scope excludes `make test` and Flutter/backend suites, reserved for the parent final run. No database, migration, source, test, script, or baseline changes were made.

## Gates

| Exact command | Exit | Result |
|---|---:|---|
| `npm run test:ci-scripts` | 0 | Pass |
| `make architecture-check` | 0 | Pass |
| `make routes-check` | 0 | Pass |
| `git diff --check` | 0 | Pass |
| `node scripts/ci-check.js` | 1 | Expected initial RED: six design-ratchet additions, awaiting frontend executor |

The six initial ratchet findings are the D4 spacing entries in `orders_tab.dart`, `profile_tabs.dart`, and `feed_post_list.dart`, plus three D3 `Colors.white` entries in `story_page.dart`. Exact details are in `ci-check-initial.log`.

## Integrity and claims

- `git ls-files -u` returned no unmerged index entries. Conflict-marker scan over repository source/config/documentation extensions found none.
- P4's no-argument architecture-boundary checker is **not present/claimed**: current `scripts/ci-check.js` only runs the existing architecture/routes/design checks and the design ratchet; no `--boundaries` implementation was verified. The passing `make architecture-check` does not establish P4.
- Markdown local-link/path validation was not run across pre-existing user-edited documentation. Evidence files here use no Markdown links; their directory and referenced log/manifest files exist.

## Evidence files

`ci-scripts`, `architecture-check`, `routes-check`, `diff-check`, and `ci-check-initial` each have matching `.log` and `.json` files. No commit or branch operation was performed.
