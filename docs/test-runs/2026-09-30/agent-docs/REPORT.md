# Agent documentation update

## Scope

- Base: `4558181`, detached worktree `freebay-agent-docs`.
- Documentation only. No application source, tests, skills, `.agents/`, or `.claude/` files changed.
- `docs/FEATURE_TRUTH.md` left unchanged; implementation/runtime statements remain owned by its existing evidence process.
- The hardening plan's UX1–UX3 precede P1. P1 is **not complete**: the README provider mismatch remains explicitly owner-pending. No UX or hardening phase is claimed complete.

## Changes

| File | Change |
|---|---|
| `AGENTS.md` | Condensed shared contract; linked truth, hardening, skill, test, and verified-command sources; corrected backend/frontend layer claims. |
| `CLAUDE.md` | Replaced stale duplicated architecture/test/payment narrative with `@AGENTS.md` and Claude-specific Flutter analyzer guidance. |
| `nest-backend/CLAUDE.md` | Added local Either/error, mixed-repository, transaction, and DB-test guidance. |
| `frontend/CLAUDE.md` | Added local design-system, routing/state, keep-alive, codegen, and validation guidance. |
| `README.md` | Replaced stale feature-status/schema inventories with verified-truth pointers, a compact architecture/setup guide, and runnable existing commands. Preserved the historical payment section verbatim with an explicit owner-pending warning and separate Stripe code evidence. |
| `docs/HARDENING_PLAN.md` | Added phase-ordered plan based on the existing owner plan; corrected the F1 baseline to 12 domain→data-repository imports, enumerated the six abstract ports, and explicitly blocks P1 on provider-policy resolution. |
| `docs/test-runs/2026-09-30/agent-docs/REPORT.md` | Recorded scope, decisions held for owner, and documentation-only verification. |

## Owner decisions intentionally left open

The historical README AbacatePay/PagBank row is retained and visibly marked as owner-pending; it has not been silently deleted or endorsed. At `4558181`, source evidence includes `payments.module.ts` importing `StripeProvider`, `stripe-provider.ts` reading `STRIPE_SECRET_KEY`, and Stripe PaymentIntent/Checkout/Connect use cases. This does not mean the owner approved Stripe or prove real payments. P1 remains blocked until owner resolves the mismatch. Payment lifecycle detail remains in its owning payment docs/ADR.

The six measured abstract-port files are an inventory count, not a list of six P9 removals. P9 remains optional and owner-decided per candidate. Migration policy remains unchanged; P10 is owner-only.

## Verification

- Reviewed baseline measurements and corrected F1: the 20-file feature-domain-contract metric is distinct from the 12-file `domain` → `data/repositories` boundary metric.
- The six abstract port files found at this base are Auth/MagicLink, Users/Block, Follow, SafetyList, UserLookup, and Wallet. `ReviewRepository` is a concrete class directly injected by reviews use cases, not one of these abstract ports; P9 records the source distinction rather than miscounting it.
- New links/imports were manually checked against the worktree; `git diff --check` passed. No test, lint, analyzer, or full branch gate was run. This docs-only correction does not alter the three-phase verification cadence; the parent owns later full gates.
- `@AGENTS.md` and subtree `@../AGENTS.md` imports resolve relative to each CLAUDE file. The `.claude/skills` mirror/symlink identity is not asserted as verified; confirm git mode, content identity, and Windows `core.symlinks=true` during parent/agent4 integration.
- Files in this docs slice: root `AGENTS.md`, root `CLAUDE.md`, `README.md`, `docs/HARDENING_PLAN.md`, this report, and `frontend/CLAUDE.md` plus `nest-backend/CLAUDE.md`. No main-worktree changes are included here.
