> **Feature truth:** Read [`docs/FEATURE_TRUTH.md`](docs/FEATURE_TRUTH.md) before proposing or claiming a capability. It records code-verified paths, limits, and evidence; update it only when verified evidence changes.

# FreeBay agent guidance

## Start here

- ALWAYS START WITH @grill-with-docs SKILL.
- For every code change, load the applicable skill from [`.agents/skills/`](.agents/skills/) before inspecting or editing that area. This directory is canonical; do not assume `.claude/skills/` is a symlink without checking git mode and identity.
- Read [`docs/HARDENING_PLAN.md`](docs/HARDENING_PLAN.md) when working on the production-hardening track. Its phase order, baseline, decisions, owner gates, and stop rules are authoritative for that work.
- Read [`frontend/DESIGN.md`](frontend/DESIGN.md) before Flutter UI changes. It owns design tokens.
- **Visual evidence is part of testing (owner rule, 2026-11-06):** user-visible UI changes must ship screenshot proof — web via Playwright fixtures/real backend, Flutter via device capture — saved to a screenshots folder and reviewed against the design system before the change closes. A code/unit pass with no image proof does not close a visual change. WebGL/animations must be capturable (`preserveDrawingBuffer` for the aurora canvas).
- Keep examples and claims tied to current source/configuration. A test pass, generated client, or synchronized test DB does not prove production runtime behavior.

## Architecture contracts

Backend target: [ADR 0004](docs/adr/0004-selective-modular-backend-architecture.md) and [ADR 0005](docs/adr/0005-module-template-public-api-uow-events.md); active scope/status: [backend architecture plan](docs/BACKEND_ARCHITECTURE_PLAN.md); phase order and safety gates: [hardening plan](docs/HARDENING_PLAN.md). Concrete implementation recipes (not authorization): [backend guide](docs/BACKEND_IMPLEMENTATION_GUIDE.md). Controllers delegate and preserve the original `AppError` and HTTP mapping.

| Area | Required boundary |
|---|---|
| Frontend | Feature code lives under `frontend/lib/features/`; state/API/UI remain in their existing feature seams. In a logic-only domain use case, data entities are allowed; concrete data repositories are not. Keep existing domain repository abstractions where present. Not every feature has all Clean Architecture layers. |
| Frontend HTTP | Repositories call backend endpoints through Dio and adapt results with `requestEither`; no direct database access. |
| State/navigation | Riverpod owns shared/server/business state; `setState` is for local ephemeral UI. Use `AppRoutes` constants/builders, not route literals. |
| Persistence | Prisma schema is `nest-backend/prisma/schema.prisma`. Money is integer cents. Follow `freebay-prisma` and `freebay-data-model` for DB work; production/test/runtime DBs are distinct evidence targets. |
| Backend modules | Selective ports: Tier B CRUD may use its own concrete repository; module-to-module calls use the owner's narrow `index.ts` API. Domain imports neither Nest nor Prisma. Transaction pattern and current exceptions are in ADR 0005; do not infer authorization for another slice from examples. |

## Type safety

Keep types truthful in production and tests. Bare `any`, `as any`, and `as unknown as` are prohibited. Narrow `unknown`, declare genuine unions, and correct third-party types in one typed helper. For class dependencies in Nest tests, inject partial `useValue` mocks through `Test.createTestingModule` rather than asserting a mock into a class type. If an unavoidable cast remains, isolate it in one named helper with a reason; never put it in a spec.

### Backend type placement (`nest-backend`)

- Interfaces and type aliases belong in module `types/` (domain contracts, repository payloads, value sets) or `dtos/` (request/use-case boundary shapes) — never inline in use-case, service, controller, or repository class files. Repository folders hold only DB-calling classes plus their private helpers; exported contract types live in the module `types/` folder.
- Value-set string unions (risk levels, statuses, modes, sorts, list kinds) become TypeScript string enums (`enum X { A = 'a' }`) in the owning module's `types/` file. Prisma-mirrored value sets stay as Prisma enums or `(typeof CONST)[number]` derived types. Discriminated unions of object shapes stay as genuine TS unions.
- Domain repository ports stay in `domain/repositories/`; their payload/record types live in module `types/` and are imported by the port.

## Web style gates (`web/`)

- Icons are the project's own inline SVG strokes (or images), PortfolioTW-style. Third-party icon packages are banned (`lucide-react`, `react-icons/*`, `@heroicons/*`, `@phosphor-icons/*`, `react-feather`); ESLint `no-restricted-imports` rejects them.
- No `useEffect` in new code. Derive state during render, keep logic in event handlers, and express subscriptions through framework primitives instead of mount/unmount effects. ESLint `no-restricted-syntax` rejects `useEffect`/`React.useEffect`; `legacyEffectFiles` in `web/eslint.config.js` lists grandfathered legacy files pending migration — delete entries there as each file is migrated, never add new ones.
- Tailwind CSS 4 only for web styling. No hand-written component/feature CSS except the minimal globals in `app/styles.css`. Shared primitives live in `app/components/`; icons are the project's own inline SVG strokes via the `Icon`/`appIcons` map in `app/components/index.tsx` — never import a third-party icon package.
- React web changes must follow the `vercel-react-best-practices` skill (loaded for every web change); prefer TanStack Query for data, useSyncExternalStore for subscriptions, callback refs for imperative sync, and `<Navigate>` for redirects over effects.

## Tests and evidence

- **Frontend has no tests: creating, keeping, or restoring any Flutter/Dart test under or for `frontend/` (`test/`, `integration_test/`, `test_driver/`) is forbidden. Frontend verification is format + analyze + build + real-device evidence.** Backend and web keep focused tests; tests may be written before or after implementation.
- Prefer E2E for journeys. Add isolated tests only for a concrete failure the existing broader tests do not catch. Load [`test-audit`](.agents/skills/test-audit/SKILL.md) whenever authoring, changing, reviewing, or sweeping backend or web tests.
- Preserve distinct money, authorization, concurrency, and recovery checks until equivalent broader evidence is verified.
- A red-green test pass never closes a user-visible change. Reproduce the defect and confirm the fix on a real device through [`freebay-mobile-mcp`](.agents/skills/freebay-mobile-mcp/SKILL.md) flows, and report the device evidence with what stays test-only verified.
- Record E2E evidence under `docs/test-runs/<date>/`: revision including dirty changes, environment without credentials, fixtures/reset, exact steps/commands, expected/actual result, exit status, and relevant logs/screenshots. Mark blocked runs blocked.
- Use the skill for the relevant device/performance/database workflow. Do not infer provider, device, or runtime-schema success from unit tests or a test database.

## Definition of done

Done means the changed behavior has focused verification plus real-device confirmation when the change is user-visible; relevant architecture/format/analyzer checks pass; every required gate for the task or hardening cadence has an exact result recorded; documentation reflects only verified behavior; and the final diff contains only owned, intended files. Run existing gates—do not add a unit test mechanically for every file.

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
dart format --output=none --set-exit-if-changed lib libs/freebay_design_system/lib
flutter analyze --fatal-infos lib libs/freebay_design_system/lib
flutter build apk --debug
```

After entity/codegen changes, run `dart run build_runner build --delete-conflicting-outputs` from `frontend` and review generated-file changes.

### Web (`web/`)

```bash
npx tsc --noEmit
npm run lint
npm test
npm run build
```

Mocked E2E (`npm run test:e2e`) needs port 5173 free. When a dev server holds it, run `npx playwright test --config=e2e/playwright.local.config.ts` instead — same journeys on ports 5174/3333, touching neither the dev server nor the real backend.

### Root

```bash
node scripts/ci-check.js
npm run test:ci-scripts
make test
```

For a perf-sensitive journey, use [`freebay-perf`](.agents/skills/freebay-perf/SKILL.md) and the flow gate `node scripts/perf-check.js <flow> --device <id>` when its backend, fixture, and device prerequisites are available. See the skill for valid flows and evidence requirements. Blocked as of 2026-10-26: the frontend integration-test driver was removed with the no-frontend-tests rule; do not re-add it without the owner.

## Git e testes: comandos proibidos sem confirmação do owner

Regras rígidas, reforçadas mecanicamente por `permissions` em `opencode.json` (o agente **nem consegue** executá-los):

- **Nunca rode, em nenhuma sessão/agente:** `git commit`, `git push`, `git add .`/`-A`/`--all`/`-u`/`--pathspec-from-file`, `git stash`, `git reset`, `git rebase`, `git merge`, `git cherry-pick`, `git clean`, `git rm`, `git checkout`, ou suítes inteiras de teste (`npm test`, `npm run test*`, `make test`, `npx vitest run` sem arquivo, `npx playwright test`, `flutter test`).
- **Verificação é sempre arquivo único e escopada:** `npx tsc --noEmit`, `npx eslint <arquivos da tarefa>`, `npx vitest run <arquivo específico>` — nada de rodar a suíte inteira para "confirmar".
- **Antes de QUALQUER ação proibida** (mesmo que a tarefa a peça), pare e **confirme com o owner usando a ferramenta de pergunta (question tool)** e espere a resposta. Commits ficam por conta do owner; agentes apenas preparam código.
- **Outras sessões podem estar editando o repo ao mesmo tempo.** Trabalhe só nos arquivos da sua tarefa. Se o working tree estiver sujo com trabalho de outra sessão, não toque nesses arquivos e **não use stash/reset/checkout para "limpar"** — pare e pergunte ao owner.

## Skills index

See [`.agents/skills/`](.agents/skills/) for flow, Flutter, backend, data, design, Prisma, performance, system-design, device, Stripe, and test-audit instructions. Load only the skill relevant to the task; its instructions refine this shared contract.
