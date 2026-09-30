> **Feature truth:** Read [`docs/FEATURE_TRUTH.md`](docs/FEATURE_TRUTH.md) before proposing or claiming a capability. It records code-verified paths, limits, and evidence; update it only when verified evidence changes.

# FreeBay agent guidance

## Start here

- For every code change, load the applicable skill from [`.agents/skills/`](.agents/skills/) before inspecting or editing that area. This directory is canonical; do not assume `.claude/skills/` is a symlink without checking git mode and identity.
- Read [`docs/HARDENING_PLAN.md`](docs/HARDENING_PLAN.md) when working on the production-hardening track. Its phase order, baseline, decisions, owner gates, and stop rules are authoritative for that work.
- Read [`frontend/DESIGN.md`](frontend/DESIGN.md) before Flutter UI changes. It owns design tokens.
- Keep examples and claims tied to current source/configuration. A test pass, generated client, or synchronized test DB does not prove production runtime behavior.

## Architecture contracts

| Area | Required boundary |
|---|---|
| Backend | NestJS vertical modules under `nest-backend/src/modules/<feature>/`. Use cases hold business decisions and return `Either<AppError, Output>` (or `void` for mutations). Concrete repositories own database access. Existing modules vary: do not add repository ports or impose uniform layers without approval. |
| Backend HTTP | Controllers delegate, then preserve the original `AppError` when unwrapping `Either`; global interceptors/filter shape success and errors. Do not convert failures to default HTTP 400. |
| Frontend | Feature code lives under `frontend/lib/features/`; state/API/UI remain in their existing feature seams. Domain logic may depend on entities and existing domain contracts, not concrete data repositories. Not every feature has all Clean Architecture layers. |
| Frontend HTTP | Repositories call backend endpoints through Dio and adapt results with `requestEither`; no direct database access. |
| State/navigation | Riverpod owns shared/server/business state; `setState` is for local ephemeral UI. Use `AppRoutes` constants/builders, not route literals. |
| Persistence | Prisma schema is `nest-backend/prisma/schema.prisma`. Money is integer cents. Follow `freebay-prisma` and `freebay-data-model` for DB work; production/test/runtime DBs are distinct evidence targets. |

## Type safety

Keep types truthful in production and tests. Bare `any`, `as any`, and `as unknown as` are prohibited. Narrow `unknown`, declare genuine unions, and correct third-party types in one typed helper. For class dependencies in Nest tests, inject partial `useValue` mocks through `Test.createTestingModule` rather than asserting a mock into a class type. If an unavoidable cast remains, isolate it in one named helper with a reason; never put it in a spec.

## Tests and evidence

- For behavior changes: **RED → GREEN → REFACTOR**. The RED run must fail for the intended behavior, not compilation, broken setup, or unavailable dependencies.
- Prefer E2E for journeys. Add isolated tests only for a concrete failure the existing broader tests do not catch. Load [`test-audit`](.agents/skills/test-audit/SKILL.md) whenever authoring, changing, reviewing, or sweeping tests.
- Preserve distinct money, authorization, concurrency, and recovery checks until equivalent broader evidence is verified.
- Record E2E evidence under `docs/test-runs/<date>/`: revision including dirty changes, environment without credentials, fixtures/reset, exact steps/commands, expected/actual result, exit status, and relevant logs/screenshots. Mark blocked runs blocked.
- Use the skill for the relevant device/performance/database workflow. Do not infer provider, device, or runtime-schema success from unit tests or a test database.

## Definition of done

Done means the changed behavior has focused verification; relevant architecture/format/analyzer checks pass; every required gate for the task or hardening cadence has an exact result recorded; documentation reflects only verified behavior; and the final diff contains only owned, intended files. Run existing gates—do not add a unit test mechanically for every file.

### Backend (`nest-backend`)

```bash
npx tsc --noEmit
npm run lint
npm test
npm run build
npm run test:safety
npm run test:integration
npm run test:e2e
```

Integration/E2E need explicitly configured native/external PostgreSQL and Redis; use the guarded test configuration. `npm run db:sync`/`db:seed` are development workflows, not production initialization. Never create/run migrations unless the owner explicitly takes the migration phase.

### Flutter (`frontend`)

```bash
dart format --output=none --set-exit-if-changed lib test libs/freebay_design_system/lib
flutter analyze --fatal-infos lib test libs/freebay_design_system/lib
flutter test
flutter build apk --debug
```

After entity/codegen changes, run `dart run build_runner build --delete-conflicting-outputs` from `frontend` and review generated-file changes.

### Root

```bash
node scripts/ci-check.js
npm run test:ci-scripts
make test
```

For a perf-sensitive journey, use [`freebay-perf`](.agents/skills/freebay-perf/SKILL.md) and the flow gate `node scripts/perf-check.js <flow> --device <id>` when its backend, fixture, and device prerequisites are available. See the skill for valid flows and evidence requirements.

## Skills index

See [`.agents/skills/`](.agents/skills/) for flow, Flutter, backend, data, design, Prisma, performance, system-design, device, Stripe, and test-audit instructions. Load only the skill relevant to the task; its instructions refine this shared contract.
