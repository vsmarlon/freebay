# P1 documentation audit

**Status:** audit only; P1 is not complete. **Scope:** read-only comparison of repository guidance and documentation against current source/configuration on 2026-10-01. No production or shared documentation was changed.

## Verified findings

- Backend port inventory is **six** abstract contracts: `auth/domain/repositories/magic-link.repository.ts`; `users/domain/repositories/{block,follow,safety-list,user-lookup}.repository.ts`; and `wallet/domain/repositories/wallet.repository.ts`. Concrete classes still named `Prisma*Repository` include social, stories, disputes, orders, reviews, and chat preference repositories, alongside database-role names. So docs should avoid implying a universal class naming convention or flat repository folder. The P9 inventory in `docs/HARDENING_PLAN.md` is accurate at audit time.
- `nest-backend/src/shared/http/response.interceptor.ts` defines `EitherInterceptor`; there is no shared `unwrap` file under `nest-backend/src`. Keep current plan language preserving original error/status; do not document a helper that does not exist.
- Jest config and package scripts confirm unit `*.spec.ts`, integration `*.integration-spec.ts` (`test:integration`), and E2E `*.e2e-spec.ts` (`test:e2e`). The root `AGENTS.md` backend test list includes `npm run build`, but backend `package.json` has that script; the `npx tsc --noEmit` invocation is valid against installed TS.
- Flutter feature directories are nonuniform: favorites/help/notifications/onboarding/profile lack one or more conventional layers; bug_report has `domain` and `presentation`, no `data`. Current root and subtree guidance correctly asks contributors to follow actual structure rather than enforce uniformity.
- **Owner decision (written, 2026-10-01): Stripe is the current provider (Recommended).** Documentation may describe implemented Stripe paths, with real payments and payouts explicitly unverified. This does not authorize financial behavior changes or P5/P8/P10 work. README remains unedited in this audit lane. `docs/HARDENING_PLAN.md` P8's `0002-webhook-event-model.md` is an explicitly planned deliverable, not a broken current link; the current ADR directory contains 0001 only, as expected before P8.
- `.claude/skills` is a filesystem symlink to `..\.agents\skills` (`Get-Item` reports `LinkType=SymbolicLink`, target `..\.agents\skills`), and git records mode `120000`. Local `core.symlinks=false`; this checkout materializes the link successfully despite that setting. Do not describe symlink status as unverified, and do not change git config. Windows checkouts may materialize differently; verify the actual path in the checkout.
- Repo plan versus supplied operational note: use checked-in `docs/HARDENING_PLAN.md` as authoritative per `AGENTS.md`. The document says work is on `feat/production-hardening` with atomic commits, while this audit lane's instruction prohibits commits and shared-doc edits. This audit made none. Provider policy is resolved; P1 remains open pending combined verification and the approved phase order, not an owner-policy blocker.
- The initial tree was already extensively dirty. A later `git status --short` reported **297 entries** (tracked modifications and untracked paths); this is existing user/parent WIP, not a clean baseline. No cleanup or reset was attempted.

## Remaining documentation corrections for the owner/docs-writer

1. Update the P1 paragraph in `docs/HARDENING_PLAN.md` for the written Stripe-current decision. Current wording still says owner policy is pending. Preserve implemented Stripe paths vs unverified real payments/payouts; do not change financial behavior or expand P5/P8/P10.
2. Treat P8 ADR `0002-webhook-event-model.md` as a planned future artifact, not a broken existing-file reference. Do not substitute the unrelated 0001 PaymentSheet migration ADR.
3. Keep the verified six-port count and nonuniform feature-layer guidance. The only misleading count wording found among related canonical skills is `.agents/skills/freebay-backend-module/SKILL.md` saying “existing five/six legacy ports”; exact current count is six. Smallest correction: “existing six legacy ports (see P9 inventory in `docs/HARDENING_PLAN.md`)”. No false claim of a port in every module or flat repository folders was found in audited guidance.
4. Keep error guidance accurate: `AuthController` and `AuthWebSessionController` each have a local `unwrap` that throws the original `AppError`; `EitherInterceptor` forwards `Left(AppError)` as an exception, and `AllExceptionsFilter` maps `AppError.statusCode`. No shared unwrap helper exists under backend `src`. Current guidance correctly says preserve status and does not claim all errors become 400.
5. README lines 19–36 still say provider policy is pending and the historical AbacatePay/PagBank table awaits owner decision, followed by a code observation tied to old revision `4558181`. Minimal future hunk: replace the pending-owner wording and current-status claims with a concise Stripe-current statement, name implemented PaymentIntent/Checkout/Connect/event paths, retain explicit real-payment/payout verification limits, and label any retained AbacatePay/PagBank description as historical. Owner authorized this after the combined gate; this audit has not applied it.
6. No duplicate “void” prose was found in specified guidance: `AGENTS.md` has one `(or void for mutations)` clause. No dangling schema text/link was found: README points to the existing schema and avoids duplicating models/enums/status. Definition of Done lists runnable scripts/evidence obligations; retain it without adding a duplicate checklist.
7. Do not edit shared docs, skills, source, or configuration in this lane. Parent/docs-writer owns corrections after combined verification. Preserve owner-protected trackers and dirty WIP.

## Checks and outputs

Commands run from repository root:

```text
git config --get core.symlinks                         -> false
git ls-files -s .claude/skills                         -> 120000 ... .claude/skills
Get-Item .claude/skills (LinkType, Target)             -> SymbolicLink, ..\.agents\skills
PowerShell scan of abstract repository declarations    -> PORTS=6
Get-ChildItem nest-backend/src/modules/payments/docs/adr -> 0001-payment-sheet-migration.md only; P8 0002 is planned, not expected yet
Read nest-backend/package.json and both Jest configs    -> scripts/suffixes match above
Get-ChildItem frontend/lib/features (layer inventory)  -> matches above
git status --short | Measure-Object                    -> 297 entries at audit time; existing dirty user/parent WIP, not clean baseline
```

### Markdown link and path check

PowerShell Markdown-link audit scoped to `AGENTS.md`, `CLAUDE.md`, `README.md`, `nest-backend/CLAUDE.md`, `frontend/CLAUDE.md`, and `frontend/AGENTS.md` (exit 0): `FILES=6 LINKS=16 EXISTS=16 MISSING=0`. Relative targets were resolved from each containing file; external URLs excluded. All 16 Markdown links resolve.

Backtick path-like scan (exit 0): `BACKTICK_PATHLIKE_CANDIDATES=29`. Concrete paths/directories exist. `nest-backend/src/modules/<feature>/`, `docs/test-runs/<date>/`, and `node scripts/perf-check.js <flow> --device <id>` are templates/commands, not literal paths; `lib/shared/l10n/` is relative to `frontend/AGENTS.md`. The one absent candidate is `nest-backend/src/modules/payments/docs/adr/0002-webhook-event-model.md`, a future P8 deliverable, not a current link defect. `nest-backend/.env.test` exists locally; no test config or gate was run.

Python link-check attempt exited 1 because Python is unavailable. First PowerShell attempt exited 0 but produced path-resolution errors for root-level files, so those counts were invalid. Corrected PowerShell script special-cased root-level files and produced the 16/16 result above. No test suite, architecture gate, device, perf, DB, or provider runtime check was run; this is source/document inspection, not runtime or release-gate evidence.

## Owner decision / stop condition

Owner answered: **Stripe is current (Recommended)**. Document implemented Stripe paths and retain explicit real-payment/payout verification limits. This is documentation authorization only; it does not approve P5, P8, P10, or any financial behavior change. Device lane reports no connected devices; device/performance remains pending and is not P1 completion evidence. P1 remains open until combined verification finishes and the parent authorizes safe documentation corrections.
