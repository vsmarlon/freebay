# Agent documentation update

## Scope

- Base: `4558181`, detached worktree `freebay-agent-docs`.
- Documentation only. No application source, tests, skills, `.agents/`, or `.claude/` files changed.
- `docs/FEATURE_TRUTH.md` left unchanged; implementation/runtime statements remain owned by its existing evidence process.
- The hardening plan's UX1–UX3 precede P1; this report does not claim any UX or hardening phase is complete.

## Changes

| File | Change |
|---|---|
| `AGENTS.md` | Condensed shared contract; linked truth, hardening, skill, test, and verified-command sources; corrected backend/frontend layer claims. |
| `CLAUDE.md` | Replaced stale duplicated architecture/test/payment narrative with `@AGENTS.md` and Claude-specific Flutter analyzer guidance. |
| `nest-backend/CLAUDE.md` | Added local Either/error, mixed-repository, transaction, and DB-test guidance. |
| `frontend/CLAUDE.md` | Added local design-system, routing/state, keep-alive, codegen, and validation guidance. |
| `README.md` | Replaced stale feature-status/schema inventories with verified-truth pointers, a compact architecture/setup guide, and runnable existing commands; removed unapproved provider assertions. |
| `docs/HARDENING_PLAN.md` | Added phase-ordered plan based on the existing owner plan, preserving gates/decisions and correcting the F1 baseline to 12 domain→data-repository import files; P9 inventory says six port files. |
| `docs/test-runs/2026-09-30/agent-docs/REPORT.md` | Recorded scope, decisions held for owner, and documentation-only verification. |

## Owner decisions intentionally left open

README's AbacatePay/PagBank claims conflict with current Stripe code/docs. No provider migration or payment-history rewrite was inferred. P1 requires owner resolution before changing that narrative. Any detailed payment lifecycle change stays in its owning payment docs/ADR, not agent guidance.

The six measured abstract-port files are an inventory count, not a list of six P9 removals. P9 remains optional and owner-decided per candidate. Migration policy remains unchanged; P10 is owner-only.

## Verification

- Reviewed baseline measurements and corrected F1: the 20-file feature-domain-contract metric is distinct from the 12-file `domain` → `data/repositories` boundary metric.
- Markdown links and commands were checked by inspection against the worktree. No full test, lint, analyzer, or branch gate was run: this docs-only slice follows UX-first cadence and the parent runs full gates after three phases.
- README no longer asserts an approved payment provider; provider-specific product narrative remains an owner decision.
