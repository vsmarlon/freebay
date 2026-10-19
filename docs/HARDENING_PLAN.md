# FreeBay hardening plan

**Audience:** code agent and repository owner on `feat/production-hardening`.
**Base audit:** `f48a5be` (2026-09-26). **Status:** plan, not a completion report.
**Baseline histórica:** [`docs/test-runs/2026-09-30/hardening-baseline/REPORT.md`](test-runs/2026-09-30/hardening-baseline/REPORT.md), revisão `4558181`; números descrevem aquele snapshot, não gates atuais.

This is behavior-preserving hardening except for the authorized UX track. It is not a production-readiness claim. Read [`FEATURE_TRUTH.md`](FEATURE_TRUTH.md) before product claims and [`FREEBAY_PRODUCTION_TRACKER.md`](FREEBAY_PRODUCTION_TRACKER.md) for release risks. Preserve historical baseline failures and follow-up evidence.

## Fixed decisions

| ID | Decision |
|---|---|
| D1 | Backend follows the selective modular policy in [ADR 0004](adr/0004-selective-modular-backend-architecture.md), complemented by [ADR 0005](adr/0005-module-template-public-api-uow-events.md): tiers/template, public API via `index.ts`, and current ALS transaction access via `TransactionHost.tx`. UnitOfWork/TxContext and DomainEvents are revoked. Own concrete repository is permitted only for Tier B CRUD within its module. This does not authorize migrations or owner-gated slices. |
| D2 | Flutter logic-only domain use cases may import data entities, not data repositories. Keep existing domain repository interfaces. |
| D3 | Keep `EitherInterceptor`. Canonical controller form is `unwrap(await useCase.execute(...))`; preserve the original `AppError`, status, and mapping. Never wrap it in a default-400 error. |
| D4 | `ThingDatabaseRepository` is the role-name exception. Rename class names only; repository files and provider tokens are already correct. |
| D5 | P4 uses deterministic `--boundaries` rules and a shrinking-only baseline; it is included in no-argument checks. |
| D6 | `AGENTS.md` is shared guidance; root `CLAUDE.md` imports it and adds Claude-only guidance. `.agents/skills` is canonical. In a new checkout, verify `.claude/skills` identity and git mode `120000`, and check Windows `core.symlinks` before treating it as a link; edit only the canonical path. |
| D7 | Refactors preserve API/schema/error/status/money behavior unless separately approved. The infra-only batch is implemented and focused lifecycle/rollback/isolation evidence exists; full E2E passed 8 suites/50 tests with test keys. See [dated report](test-runs/2026-10-18/backend-infra/REPORT.md). No broader financial migration/schema/search-index change. |

## Operating agreement and stops

- Stay on `feat/production-hardening`; do not commit/push unless requested. Preserve pre-existing dirty work.
- Complete UX1–UX3 before production P1 work. Documentation-only consolidation is allowed before UX completion; it does not change phase order or complete P1. **Owner exceptions:** ARCH-02/P4 + PERF-01/PERF-03 have historical focused E2E evidence (2026-10-16); the separate Prisma/ALS batch has focused lifecycle/rollback/isolation evidence. Full E2E follow-up passed 50/50 with ephemeral test CPF keys; exact status/gates live in the [dated report](test-runs/2026-10-18/backend-infra/REPORT.md). Neither exception authorizes further financial refactors, DB/schema changes, dependencies or migrations.
- P4 is a limited static baseline, not cycle detection. Historical search gates are not fresh/performance evidence. Do not repeat either as current proof; consult the linked report for the infrastructure batch.
- Database tests use `.env.test` and guarded `freebay_test_db` only. P10 migrations are owner-only. No non-test DB setup, schema push, or seed.
- No dependencies, type escapes (`any`, `as any`, `as unknown as`), lint suppressions, or weakened assertions. Preserve behavior, contracts, schema, errors/statuses, and money semantics. Money code is read-only except P5 and P8 after written owner approval.
- Stop for `forwardRef`, casts/suppressions, weakened tests, unapproved behavior/schema/API/dependency changes, or unresolved owner policy. Characterize uncovered behavior before refactoring. Never report a planned phase as completed.

## P0 — Baseline and risk map

Counts are static source-inspection leads, not runtime defect counts. Reuse the baseline report's definitions for comparisons.

| Phase | Outcome | Gate |
|---|---|---|
| P0 | Reproducible source counts and gate evidence | Evidence only; no readiness claim |
| UX | Stories, Close Friends, feed/profile timeline usability | Approved behavior scope; physical Galaxy A30 evidence |
| P1 | Documentation agrees with code | Stop at owner-policy conflicts; D1's former blanket port ban was superseded by owner decision 2026-10-16 (ADR 0004), without authorizing implementation. |
| P2 | Error alias, controller unwrap, repository class names | Preserve DI and HTTP status. Parcial entregue 2026-10-16: helper único `shared/http/unwrap.ts` usado pelos controllers de auth; alias `Failure = AppError` único (`failures.ts` removido); classes `Prisma*Repository` → `*DatabaseRepository` com DI preservado. **Segundo corte:** wrappers de desembrulho puro removidos (`reports.service.ts`, `category.service.ts` — controllers chamando use cases + `unwrap`); `reviews.service.ts` e `stories.service.ts` preservados (têm lógica além do unwrap; ficam para o corte D3). |
| P3 | Users owns user persistence (approved target) | Provider/API migration remains incomplete; resolve DA-04 without cycle and verify app boot/auth-user flows |
| P4 | Architecture-boundary regression gates | New violations fail; baseline cannot grow |
| P5 | Explicit transaction ownership | Current pattern in ADR 0005; per-slice approval/evidence remains required |
| P6 | Measured type-safety ratchet | One lint group at a time; zero before enable |
| P7 | Remove proven pass-through use cases only | Preserve contracts and meaningful behavior |
| P8 | Webhook event model proposal | Written owner approval before implementation |
| P9 | Optional legacy-port removals | Assess each legacy port under D1; owner decides individually. Retention is the default absent approval; no blanket removal or replacement is implied. |
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

## P1 — Documentation correction (provider policy pending)

Audit root/subtree guidance, README, relevant architecture docs, and skills against code. Documentation only; stop at owner-policy conflicts. Current documentation cleanup is authorized, but production P1 remains incomplete until provider policy is decided.

- Backend architecture follows [ADR 0004](adr/0004-selective-modular-backend-architecture.md) and [ADR 0005](adr/0005-module-template-public-api-uow-events.md); iteration scope/status and pending performance decisions live in [the backend plan](BACKEND_ARCHITECTURE_PLAN.md). DA-05 is resolved as `TransactionHost.tx`; the current batch is limited to shared infrastructure and two existing consumers, not general transaction migration.
- Verify actual feature layers; favorites, help, notifications, onboarding, and profile are not uniformly data/domain/presentation, bug reporting has no data path, and not every feature has a use case/repository.
- Document `AppError` status mapping and `EitherInterceptor`; do not claim every error becomes 400. Controller unwrap must preserve original errors.
- Check test suffixes and scripts in package configuration. Integration files use `*.integration-spec.ts`; E2E uses `npm run test:e2e`. Keep every example runnable.
- Payment-provider narrative conflicts (README AbacatePay/PagBank vs current Stripe code/docs): do not infer an owner decision or rewrite historical payment guidance until owner resolves policy. Stripe source is not provider approval or proof of real payments. Keep the conflict visible as pending; detailed payment flow remains in its owning docs.
- Fix stale duplicate void/dangling schema prose and vague “definition of done” with verified commands/evidence. Do not duplicate capability status owned by `FEATURE_TRUTH.md`.
- Keep root `CLAUDE.md` concise: import canonical `AGENTS.md` and add only Claude-specific guidance. Subtree guidance covers local Either/transaction, design, keep-alive, and codegen conventions; do not duplicate payment lifecycle detail.
- `.agents/skills` is canonical. Treat `.claude/skills` as symlinks only after identity and git mode `120000` prove it; on Windows verify `core.symlinks=true`. Claude hooks are optional only if present.
- Preserve exactly: `FREEBAY_RELEASE_HANDOFF.md`, `docs/CODEBASE_CLEANUP_PROGRESS.md`, and `docs/FREEBAY_PRODUCTION_TRACKER.md`.

After documentation edits, run the existing architecture script and tests; validate new Markdown paths, symbols, links, and commands against the repository. Record evidence; do not claim an audit without it. P1 is not complete while the provider-policy decision remains open.

## P2 — Backend error, unwrap, and repository names

- Keep `Failure` as an alias of `AppError` in `nest-backend/src/shared/core/errors.ts` if it adds no behavior. Repoint imports and remove `nest-backend/src/shared/errors/failures/failures.ts` only after checking identity and callers.
- Add/use the exact `shared/http/unwrap.ts` helper for auth controllers' local unwrap. Preserve the original `AppError`, status, envelope, and exception behavior.
- Rename `Prisma*Repository` class names only to established `*DatabaseRepository` names. Files already have correct names; do not change files or provider tokens. Check imports, DI tokens, and runtime strings; stop on collisions.
- Respect D4's role-based name exception. Run focused behavior/DI checks, then backend gates at cadence.

## P3 — User-repository ownership

Approved target: Users owns user persistence; source for `UserDatabaseRepository` is already under Users. P3 is **not complete**: Auth still registers the concrete provider, Users still imports Auth, and Auth/usecase consumers still depend on the concrete class. DA-04 remains open for public API/provider composition and email-verification ownership, not for whether Users is the target owner. The users barrel's concrete repository export is a transition exception.

Repository file placement is not provider ownership. Preserve injection behavior and token; resolve a cycle without `forwardRef`. No P3 provider move is part of the current infra-only batch; future execution requires its own approved arrangement and app-boot/auth-user verification.

## P4 — Architecture-boundary checks (limited static rules)

**Snapshot (2026-10-18):** the existing gate has 242 findings under its current definitions (F1 12, F2 64, **B1 61**, B2 18, B3 5, **B4 80**, B5 2). Dated counts are not a promise about later trees. B1 catches direct imports and reexports targeting configured `data`/`usecases`/`services` paths; it does not follow exports transitively through a barrel or detect all cycles. B4 role/path detection includes configured usecase/controller names, not every `application`/query path. B5 checks direct forbidden imports in `domain/**`, not transitive dependencies. Inspect/extend tests before relying on broader guarantees; never clear debt by renaming or hiding imports behind barrels.

The gate is already present in `scripts/ci-check.js`; use `--boundaries` and the no-argument invocation to verify it. Baseline entries are deterministic `{file, specifier, rule}`; update may remove resolved debt but must refuse additions. Preserve existing checks and tests. This status does not imply broader rules than the script currently implements.

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

The bullets above are intended boundaries, not all guarantees enforced by today's implementation. Before cosmetic moves, make the relevant rule explicit and test its false-positive/false-negative limits. Keep the baseline monotonic, and reuse the 12-file F1 definition above rather than the separate 20-file metric.

## P5 — ALS transaction spans

**Implementação e evidência:** spans curtos `@Transactional()` usam `TransactionHost<TransactionalAdapterPrisma>.tx`, sem proxy/injection proxy/UoW; SharedModule é o único class provider de Prisma. Lifecycle AppModule, rollback P2025/readback, isolamento concorrente e mutation control estão registrados no [relatório](test-runs/2026-10-18/backend-infra/REPORT.md). Hook 1/1 não mede pools/conexões ativas. Reviews mantém nested create e reputação externa; demais transações permanecem legadas. Full E2E passou 8 suites/50 tests com chaves de teste; ver relatório datado.

The callback/`Prisma.TransactionClient` sketch in the earlier P5 design is superseded and must not be implemented. `TransactionHost.tx` is the approved access shape, not blanket permission to migrate other slices. Further slices require explicit approval and evidence:

Reviews uses nested Prisma create for review+images (reputation remains outside); disputes withdraw/resolve already use ALS spans. These are not pending migrations. Current infra batch verifies/sanitizes their shared runtime and transaction client access, without changing their business queries.

Remaining candidates, each requiring its own owner go and focused rollback/behavior evidence:

1. Task cleanup and escrow release.
2. Cart checkout: reservation, compensation, main checkout (three slices).
3. Payments: webhook/expiry use cases, then seller payout.

Do not invent dispute-create migration. In the approved infra batch, do not alter financial query order/rules, claims, wallet behavior, or external calls. Verify real rollback after a later write fails and concurrent ALS context isolation; callback-only fakes are not rollback evidence. Recheck the actual boundary gate; no next feature slice is implied.

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

The six abstract-port files present at `4558181` are `auth/domain/repositories/magic-link.repository.ts`; `users/domain/repositories/block.repository.ts`, `follow.repository.ts`, `safety-list.repository.ts`, and `user-lookup.repository.ts`; and `wallet/domain/repositories/wallet.repository.ts`. `ReviewRepository` is not a seventh abstract port in this inventory: reviews directly inject concrete `PrismaReviewRepository`. Recheck inventory before P9. Assess each existing port under accepted D1; owner decides individually whether it remains or is removed. Do not add replacement abstractions/dependencies mechanically. Any approved removal is one at a time with binding, implementation, injection, and behavior checks; retention is valid where the boundary is justified.

## P10 — Migration workflow (owner only)

The agent never creates or runs migrations. When owner takes this phase, verify installed Prisma CLI `migrate diff --help` flags; generate empty-schema-to-current `0_init` SQL; resolve already-applied history; verify fresh-DB deploy; and ensure CI checks migration history/diff exit and deploy. Production/staging deploy via migrations, not `db push`; local disposable development keeps schema sync until owner changes policy. No separate ADR requirement unless requested. Until owner executes and approves transition, no-migration rule remains.

## Explicitly deferred

- No EitherInterceptor migration (roughly 26 controllers return Either directly); preserve original error/status and never default-400 wrap.
- Broad direct-Prisma cleanup outside approved planned slices and chat/social module splits are deferred. Audit leads: 86 chat files and 82 social files, not read-query counts.
- Payments-module splitting is optional/deferred, not required P8 work.
- Preserve the three trackers named in P1. Provider narrative, module splits, API/schema changes, migrations, new dependencies, and security/privacy semantics need explicit owner decision.

## Phase evidence record

For every phase/logical commit record branch and commit range; tested revision and dirty-tree identity; environment without credentials; preserved/changed behavior; files/responsibilities; focused verification commands and outcomes; full gates and exit codes or reason not run; identical-definition before/after counts; device/perf evidence; removed assertions and equivalent evidence; deviations; unresolved decisions; and stop conditions. A commit message, clean diff, or green subset is not completion evidence.
