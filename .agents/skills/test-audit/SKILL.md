---
name: test-audit
description: Use whenever writing, changing, reviewing, or auditing FreeBay tests; read CAMPAIGN.md for subsystem-wide campaigns.
---

# Test value gate

For behavior changes, follow the tests and evidence policy in `AGENTS.md`; prefer real HTTP/database/device boundaries. Read `docs/FEATURE_TRUTH.md` when capability status matters. For a subsystem-wide test sweep, read [CAMPAIGN.md](CAMPAIGN.md) before work.

A user-visible or journey change is not verified by tests alone: confirm it on a real device following [`freebay-mobile-mcp`](../freebay-mobile-mcp/SKILL.md).

## Before adding/changing a test

State: (1) observable contract, (2) credible regression, (3) why stronger existing coverage misses it, (4) whether it requires a test-only seam. If any answer is missing, defer. Regression tests must detect the intended behavior failure, not merely fixture/compile problems.

Reject tests that merely echo mocks/helpers, inspect implementation trivia, duplicate stronger boundary coverage, assert inventories/exports, or pass for unrelated reasons. Keep independent money, security, concurrency, recovery, protocol and persistence contracts. Do not weaken an assertion to accommodate a refactor.

## Audit and validation

Trace test, production owner, callers, sibling implementations, existing coverage and history before removal. Record the concrete failure caught, non-test seam callers, replacement evidence, risk and focused command. Delete obsolete test-only seams only with owner-boundary proof.

Run focused owner/sibling test, then applicable gates from root `AGENTS.md`; do not report unavailable DB/device gates as passing. E2E artifacts belong under `docs/test-runs/<date>/` with tested revision, safe environment identity, reset/fixture steps, exact commands, actual outcomes and evidence. Review the complete diff for lost contracts. Commit/push only when authorized.
