# FreeBay hardening plan

**Audience:** code agent and repository owner on `feat/production-hardening`.
**Base audit:** `f48a5be` (2026-09-26). **Status:** plan, not a completion report.
**Baseline:** [`docs/test-runs/2026-09-30/hardening-baseline/REPORT.md`](test-runs/2026-09-30/hardening-baseline/REPORT.md), at `4558181`; the full Flutter suite is green (234 tests).

This is behavior-preserving hardening except for the authorized UX track. It is not a production-readiness claim. Read [`FEATURE_TRUTH.md`](FEATURE_TRUTH.md) before product claims and [`FREEBAY_PRODUCTION_TRACKER.md`](FREEBAY_PRODUCTION_TRACKER.md) for release risks. Preserve historical baseline failures and follow-up evidence.

## Fixed decisions

| ID | Decision |
|---|---|
| D1 | Backend use cases use concrete database repositories. Add no backend repository ports except P5 `TransactionRunner`. P9 considers existing ports for optional removal. |
| D2 | Flutter logic-only domain use cases may import data entities, not data repositories. Keep existing domain repository interfaces. |
| D3 | Keep `EitherInterceptor`. Canonical controller form is `unwrap(await useCase.execute(...))`; preserve the original `AppError`, status, and mapping. Never wrap it in a default-400 error. |
| D4 | `ThingDatabaseRepository` is the role-name exception. Rename class names only; repository files and provider tokens are already correct. |
| D5 | P4 uses deterministic `--boundaries` rules and a shrinking-only baseline; it is included in no-argument checks. |
| D6 | `AGENTS.md` is shared guidance; root `CLAUDE.md` imports it and adds Claude-only guidance. `.agents/skills` is canonical. The `.claude/skills` mirror/symlink status remains unverified in this docs slice; verify identity, git mode, and Windows `core.symlinks=true` before treating it as a symlink. |
| D7 | P1–P9 are pure refactors unless a separately approved decision says otherwise. No API/schema/error/status/money behavior changes. UX is the prior authorized exception. |

## Operating agreement and stops

- Stay on `feat/production-hardening`; make atomic commits per logical part. No new branch, force-push, push to `main`, or PR unless requested.
- Complete UX1–UX3 before P1. Behavior changes are test-first and separate from pure-refactor commits. Full branch gates run after each three phases and at the end; focused behavior and structural checks run per slice. Record evidence under `docs/test-runs/<date>/`, including tested revision/dirty state, environment without credentials, exact commands and exit codes, and logs. A blocked gate is not a pass.
- Database tests use `.env.test` and guarded `freebay_test_db` only. P10 migrations are owner-only. No non-test DB setup, schema push, or seed.
- No dependencies, type escapes (`any`, `as any`, `as unknown as`), lint suppressions, or weakened assertions. Preserve behavior, contracts, schema, errors/statuses, and money semantics. Money code is read-only except P5 and P8 after written owner approval.
- Stop for `forwardRef`, casts/suppressions, weakened tests, unapproved behavior/schema/API/dependency changes, or unresolved owner policy. Characterize uncovered behavior before refactoring. Never report a planned phase as completed.

## P0 — Baseline and risk map

Counts are static source-inspection leads, not runtime defect counts. Reuse the baseline report's definitions for comparisons.

| Phase | Outcome | Gate |
|---|---|---|
| P0 | Reproducible source counts and gate evidence | Evidence only; no readiness claim |
| UX | Stories, Close Friends, feed/profile timeline usability | Approved behavior scope; physical Galaxy A30 evidence |
| P1 | Documentation agrees with code | Stop at owner-policy conflicts |
| P2 | Error alias, controller unwrap, repository class names | Preserve DI and HTTP status |
| P3 | Users owns user persistence | Stable auth token/import; no cycle |
| P4 | Architecture-boundary regression gates | New violations fail; baseline cannot grow |
| P5 | Explicit transaction ownership | Owner reviews money-sensitive slices |
| P6 | Measured type-safety ratchet | One lint group at a time; zero before enable |
| P7 | Remove proven pass-through use cases only | Preserve contracts and meaningful behavior |
| P8 | Webhook event model proposal | Written owner approval before implementation |
| P9 | Optional legacy-port removals | Owner decides each port |
| P10 | Migration workflow | Owner only; no agent migration work |

Baseline measures: 99 backend `*.spec.ts`; zero backend type-escape matches in its defined non-test scope; 15 `$transaction` sites in 12 non-repository files; 30 non-test `PrismaService` import files outside repository/infra exclusions; 13 exported `Prisma*Repository` names; 158 non-generated Flutter `dynamic` match lines; 6 backend abstract-repository-port files; 45 Prisma models. The report's 20 files importing feature `domain/repositories` contracts is a different scan, not the P0 boundary count.

Corrected P0 Flutter boundary metric: **12 files** import `data/repositories` from feature `domain` (9 auth, 2 product, 1 social):

```bash
rg --files-with-matches --glob '**/domain/**/*.dart' '^import .*/data/repositories/' frontend/lib/features
```

## Verification contract

Run at the three-phase cadence and final full-branch verification. Focused checks remain required for each slice. Backend commands run in `nest-backend`, Flutter commands in `frontend`, and root commands at repository root.

```text
nest-backend: npx tsc --noEmit
nest-backend: npm run lint
nest-backend: npm test
nest-backend: npm run build
nest-backend: npm run test:safety
nest-backend: npm run test:integration
nest-backend: npm run test:e2e
frontend:     dart run build_runner build --delete-conflicting-outputs
frontend:     dart format --output=none --set-exit-if-changed lib test libs/freebay_design_system/lib
frontend:     flutter analyze --fatal-infos lib test libs/freebay_design_system/lib
frontend:     flutter test
root:         node scripts/ci-check.js
root:         npm run test:ci-scripts
root:         make test
```

`npm run lint` enforces zero warnings; do not append flags. Integration/E2E use guarded scripts and `.env.test`. For a changed performance-sensitive flow, use `node scripts/perf-check.js <flow> --device <id>` when backend, fixture, and device are available. A passing test DB is not runtime DB, live-provider, or device evidence. The `4558181` baseline has 234 passing Flutter tests.

## UX track — before P1

Use the already-running physical Galaxy A30. Read [`FEATURE_TRUTH.md`](FEATURE_TRUTH.md), [`frontend/DESIGN.md`](../frontend/DESIGN.md), and the `freebay-app-flows`, `freebay-design-system`, and `freebay-mobile-mcp` skills. Use design tokens and route constants. This is the authorized behavior-changing track, separate from P1–P9 refactors.

### UX1 — Chat video and story readiness

- Address chat-video poster/thumbnail and viewer controls as well as story playback. Preserve view-once protections; do not introduce reusable media URLs.
- Use consistent sheets and swipe interactions; inner gestures must not dismiss or navigate the outer `AppShell`.
- Show media as ready only when media/duration is ready. Story press-and-hold pause is immediate; cancellation/release resumes predictably.
- Verify real chat and story video on A30. Do not claim screenshot prevention or atomic single-open behavior without evidence.

### UX2 — Close Friends and profile content kinds

- Manage Close Friends from following **or** followers candidates. This explicitly expands the earlier follower-only eligibility.
- Loss of the last follow edge revokes private access; block also revokes it. Unblock/refollow never restores membership automatically. Membership remains owner-controlled.
- Profile timeline has three distinct kinds: own regular **Posts**, own **Reposts** of any share-event type, and own product/listing posts labeled **Anúncios**. Existing catalog product posts may be Anúncios; this is not paid advertising or an ad platform.
- Preserve pagination, privacy filtering, and existing clients. Verify owner/non-owner, last-follow loss, block/unblock/refollow, private visibility, counts, search, empty/error/loading, and pagination against guarded test DB and on device.

### UX3 — Timeline and gesture finish

- Complete bounded/lazy profile timelines for self and other users. Keep all five `AppShell` tab indexes and global chrome stable; profile timeline swipes must not navigate the outer shell.
- Preserve reverse chat scrolling, keyboard, header/bottom controls, and accessible actions. Fix observed shared swipe/scroll-physics inconsistencies without changing unrelated navigation.
- Recheck combined journeys on A30, capture evidence, and run relevant perf checks. Update `FEATURE_TRUTH.md` only for verified outcomes; the plan itself is not completion evidence.

## P1 — Documentation correction (owner decision pending)

Audit root/subtree guidance, README, relevant architecture docs, and skills against code. Documentation only; stop at owner-policy conflicts.

- Backend ports: baseline measured six port files. Inspect the current inventory before counts; do not claim every module has a port or prescribe nonexistent flat repository folders. Most concrete repositories are Prisma-backed; `ThingDatabaseRepository` is a named exception.
- Verify actual feature layers; features are not uniformly data/domain/presentation and not every feature has a use case/repository.
- Document `AppError` status mapping and `EitherInterceptor`; do not claim every error becomes 400. Controller unwrap must preserve original errors.
- Check test suffixes and scripts in package configuration. Integration files use `*.integration-spec.ts`; E2E uses `npm run test:e2e`. Keep every example runnable.
- Payment-provider narrative conflicts (README AbacatePay/PagBank vs current Stripe code/docs): do not infer an owner decision or rewrite the historical README payment section until the owner resolves policy. The code contains a Stripe implementation (`StripeProvider`, Stripe PaymentIntent/Checkout/Connect paths); that is code evidence, not provider approval or proof of real payments. Keep the prior payment text visible with an explicit pending-owner note, not hidden/deleted. Remove unsupported migration-plan references only after checking the actual ADR/path; keep detailed payment flow in its owning docs.
- Fix stale duplicate void/dangling schema prose and vague “definition of done” with verified commands/evidence. Do not duplicate capability status owned by `FEATURE_TRUTH.md`.
- Keep root `CLAUDE.md` concise (target 100–150 lines), importing canonical `AGENTS.md` and adding only Claude-specific guidance. Subtree guidance covers only local Either/transaction, design, keep-alive, and codegen conventions; do not duplicate payment lifecycle detail.
- `.agents/skills` is canonical. Treat `.claude/skills` as symlinks only after identity and git mode `120000` prove it; on Windows verify `core.symlinks=true`. Claude hooks are optional only if present.
- Preserve exactly: `FREEBAY_RELEASE_HANDOFF.md`, `docs/CODEBASE_CLEANUP_PROGRESS.md`, and `docs/FREEBAY_PRODUCTION_TRACKER.md`.

After documentation edits, run the architecture script/tests and validate new Markdown paths, symbols, links, and commands against the repository. Record evidence; do not claim an audit without it. P1 is not complete while the provider-policy decision remains open.

## P2 — Backend error, unwrap, and repository names

- Keep `Failure` as an alias of `AppError` if it adds no behavior. Repoint imports and remove the duplicate failure definition only after checking identity and callers.
- Add/use the exact `shared/http/unwrap.ts` helper for auth controllers' local unwrap. Preserve the original `AppError`, status, envelope, and exception behavior.
- Rename `Prisma*Repository` class names only to established `*DatabaseRepository` names. Files already have correct names; do not change files or provider tokens. Check imports, DI tokens, and runtime strings; stop on collisions.
- Respect D4's role-based name exception. Run focused behavior/DI checks, then backend gates at cadence.

## P3 — User-repository ownership

Move user persistence ownership to Users. Users provides/exports `UserDatabaseRepository`; Auth imports it from Users with the injection token unchanged. Do not leave Auth as owner/provider. Preserve behavior/API. If this creates a module cycle, do not use `forwardRef`: report at least two inexpensive arrangements and wait. Verify app boot and auth/user E2E.

## P4 — Stable architecture-boundary checks

Add `--boundaries` to `scripts/ci-check.js` and run it with no arguments. Store sorted `{file, specifier, rule}` entries in `scripts/boundaries-baseline.json`. `--update-baseline` removes resolved entries only and refuses additions. Exclude `*.spec.*`, integration, and E2E. Preserve existing checks. Add phony `boundaries-check` Make target and include it in help/tests.

- **B1:** Any file under `modules/A` cannot import another module's `data`, `usecases`, or `services` implementation, regardless of its own layer, including aliases and relative paths.
- **B2:** No PrismaService imports from usecases/controllers/services/tasks, except explicitly justified repository/infrastructure/health cases; no broad directory exemptions.
- **B3:** Controllers cannot import any Repository class.
- **F1:** Flutter feature domain cannot import feature `data/repositories`.
- **F2:** Flutter core cannot import feature implementations.

| Importing source | Allowed direction | Restricted direction |
|---|---|---|
| Backend `modules/A/**` | Its own module and shared contracts/infrastructure | Another module's `data/**`, `usecases/**`, or `services/**` implementation (B1) |
| Flutter feature `domain/**` | Domain contracts and data entities needed by logic-only use cases | Concrete feature `data/repositories/**` (F1) |
| Flutter `core/**` | Core/shared packages | Feature implementations (F2) |
| Backend controllers | DTOs, use cases, shared HTTP/auth contracts | Any Repository class (B3) |
| Backend use cases/controllers/services/tasks | Feature APIs and injected dependencies | `PrismaService` directly, except narrowly enumerated repository/infrastructure/health cases (B2) |

These are P4 target rules, not currently enforced guarantees at baseline `4558181`. Prove a new violation fails while known entries pass, revert it, and prove baseline update refuses growth. Reuse the 12-file F1 scan above, not the separate 20-file domain-contract metric. Keep agent rules compact and nonduplicative.

## P5 — Shared transaction runner

Add exactly two shared files: `TransactionRunner` abstraction and `PrismaTransactionRunner` implementation. Bind/export from `SharedModule` using `{ provide: TransactionRunner, useClass: PrismaTransactionRunner }`.

```ts
run<T>(work: (tx: Prisma.TransactionClient) => Promise<T>): Promise<T>
```

Use `$transaction` defaults; add no options (isolation, max-wait, timeout). Migrate one logical slice per commit, in order:

1. `reviews/usecases/create-review/create-review.usecase.ts`.
2. Disputes: withdraw, then resolve.
3. Task cleanup and escrow release.
4. Cart checkout: reservation, compensation, main checkout (three slices).
5. Payments: webhook/expiry use cases, then seller payout.

Do not invent dispute-create migration. Change injection/orchestration only; preserve callback query order/behavior byte-for-byte in effect and use `tx` for transaction queries. Stop on root-Prisma calls in callbacks or option changes. If at least three specs need the same fake, use one shared typed fake under `test/helpers`; retain rollback/atomicity assertions. Recheck boundaries per slice.

## P6 — Type-safety ratchet

Enable one analyzer group at a time, in order: `strict-raw-types`, `strict-inference`, `strict-casts`, `avoid_dynamic_calls`. Measure and fix feature by feature; reach zero before enabling each flag in a separate config commit. Narrow types without casts, suppressions, or behavior/protocol changes.

Prioritize chat/socket, chat repository, stories, follows/blocks, cursors, and notifications. Keep generated JSON/Freezed files generated. Replace handwritten JSON only when codegen demonstrably covers the shape; do not blindly convert `JsonSerializable` forms or add speculative helpers. Socket behavior is out of scope.

## P7 — Audited pass-through use cases

Inventory every use case first. **PASS-THROUGH** means one input forwarded unchanged to one repository call with no validation, branching, orchestration, mapping, or meaningful result handling. Everything else is **KEEP**. Delete only proven dead wrappers, one feature/atomic slice at a time; auth last. Keep interfaces and meaningful contracts. Do not add domain layers to profile, notifications, favorites, onboarding, or help for uniformity. Report classifications/evidence; F1 must shrink or have a specific justified exception.

## P8 — Webhook event design; owner gate

**Design only until written owner approval.** Exact ADR path: `nest-backend/src/modules/payments/docs/adr/0002-webhook-event-model.md`.

1. Document the current event table only: two existing webhooks, actual outcomes/side effects, duplicate-delivery behavior, and duplicated blocking regions with exact source ranges. Add proposed event union and exhaustive edge-case map. Verify claims against source/tests; do not propose module/cycle splits.
2. Characterize existing behavior with existing integration cases; record existing counts and GREEN result, not a speculative contract.
3. Stop for written owner approval. Only then implement the approved mapping in a small change; do not expand financial scope or invent behavior. Preserve outcomes and rerun payment integration/E2E.

Without written approval, no P8 production-code changes.

## P9 — Optional legacy ports

The six abstract-port files present at `4558181` are `auth/domain/repositories/magic-link.repository.ts`; `users/domain/repositories/block.repository.ts`, `follow.repository.ts`, `safety-list.repository.ts`, and `user-lookup.repository.ts`; and `wallet/domain/repositories/wallet.repository.ts`. `ReviewRepository` is not a seventh abstract port in this inventory: reviews directly inject concrete `PrismaReviewRepository`. Recheck the inventory before a P9 decision; the owner decides individually whether any existing port should remain or be removed. Do not add replacement abstractions/dependencies. If approved, remove one at a time with bindings, implementation, injections, and behavioral checks; preserve DI behavior and report retained ports/reasons.

## P10 — Migration workflow (owner only)

The agent never creates or runs migrations. When owner takes this phase, verify installed Prisma CLI `migrate diff --help` flags; generate empty-schema-to-current `0_init` SQL; resolve already-applied history; verify fresh-DB deploy; and ensure CI checks migration history/diff exit and deploy. Production/staging deploy via migrations, not `db push`; local disposable development keeps schema sync until owner changes policy. No separate ADR requirement unless requested. Until owner executes and approves transition, no-migration rule remains.

## Explicitly deferred

- No EitherInterceptor migration (roughly 26 controllers return Either directly); preserve original error/status and never default-400 wrap.
- Direct Prisma access and chat/social module splits are deferred. Audit leads: 86 chat files and 82 social files, not read-query counts.
- Payments-module splitting is optional/deferred, not required P8 work.
- Preserve the three trackers named in P1. Provider narrative, module splits, API/schema changes, migrations, new dependencies, and security/privacy semantics need explicit owner decision.

## Phase evidence record

For every phase/logical commit record branch and commit range; tested revision and dirty-tree identity; environment without credentials; preserved/changed behavior; files/responsibilities; focused RED/GREEN commands and outcomes; full gates and exit codes or reason not run; identical-definition before/after counts; device/perf evidence; removed assertions and equivalent evidence; deviations; unresolved decisions; and stop conditions. A commit message, clean diff, or green subset is not completion evidence.
