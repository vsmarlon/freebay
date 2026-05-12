# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Commands

All commands assume you are in the relevant subdirectory (`nest-backend/` or `frontend/`) unless using the Makefile from the root.

### From the root (Makefile)

```bash
make test              # run everything: ts-check + jest + flutter unit + integration
make test-unit         # npx tsc --noEmit + jest + flutter test
make test-integration  # flutter drive headless (requires chromedriver)
make help
```

### Backend (`cd nest-backend`)

```bash
npm run start            # start dev server
npm run build          # prisma generate + tsc + tsc-alias
npm test               # jest (all specs)
npx tsc --noEmit       # type-check only, no output

# Single test file
npx jest src/application/usecases/auth/register.usecase.spec.ts
# Single test by name
npx jest --testNamePattern "should return error" src/application/usecases/auth/register.usecase.spec.ts

npm run prisma:generate   # regenerate client after schema changes
npm run prisma:migrate    # run pending migrations
npm run prisma:studio     # open DB GUI
npm run db:seed           # execute db/seeds/001_seed_dev.sql
npm run lint              # eslint
npm run format            # prettier
```

### Frontend (`cd frontend`)

```bash
flutter pub get
flutter run                             # run on connected device/emulator
flutter test                            # all unit tests
flutter test test/some_widget_test.dart # single test file
flutter analyze                         # static analysis
flutter build apk --debug
```

---

## Backend Architecture

The backend uses **Clean Architecture** with strict layering. Dependencies always point inward (domain ← application ← infra/presentation).

```
src/
├── domain/           # pure interfaces and types — no dependencies on anything else
│   ├── entities/     # plain TS interfaces (PostEntity, UserEntity, etc.)
│   ├── repositories/ # I*Repository interfaces + their input/output types
│   ├── errors/       # AppError subclasses (NotFoundError, UnauthorizedError, etc.)
│   └── either.ts     # Either<L,R> monad used by all use cases
├── application/
│   └── usecases/     # one class per use case, depends only on domain interfaces
├── infra/
│   ├── database/repositories/  # Prisma implementations of I*Repository
│   ├── http/
│   │   ├── fastify/app.ts      # plugin registration + route mounting
│   │   └── routes/             # DI wiring: repositories → controllers, or inline handlers
│   ├── redis/        # token blacklist, cache
│   └── storage/      # FileStorageService (base64 → disk)
└── presentation/
    ├── controllers/  # one class per domain area, receives repos, instantiates use cases
    ├── dtos/         # Zod schemas for request validation
    ├── middlewares/  # authGuard, authGuardOptional, requireNonGuest
    └── response.ts   # apiSuccess / apiError helpers
```

### Dependency Injection wiring

Repositories are instantiated **in route files** (`infra/http/routes/`) and passed into controllers or use cases via constructors. Controllers instantiate their own use cases from the injected repositories. Nothing below the route layer touches Prisma directly.

```typescript
// route file
const repo = new PrismaUserRepository();
const controller = new AuthController(repo);
app.post('/register', (req, reply) => controller.register(req, reply));
```

### Either pattern

All use cases return `Either<AppError, Output>`. Never throw for expected business errors.

```typescript
// use case
return left(new NotFoundError('Post'));   // failure
return right({ post });                   // success

// controller
const result = await useCase.execute(input);
if (isLeft(result)) {
  return reply.code(result.value.statusCode).send(apiError(result.value.code, result.value.message));
}
return reply.send(apiSuccess(result.value));
```

### Auth middlewares

Three variants used as `preHandler` arrays on routes:

| Middleware | Behaviour |
|---|---|
| `authGuard` | JWT required + blacklist check; 401 if missing/invalid |
| `authGuardOptional` | Tries JWT, sets `request.user` if valid, continues regardless |
| `requireNonGuest` | Must follow `authGuard`; 403 if `request.user.isGuest === true` |

Guest users can browse but cannot create posts, orders, reports, etc.

### Key constraints

- All monetary values stored in **cents** (`Int`) — never `Float`.
- Use `@/` path alias for all imports from `src/` (e.g. `@/domain/repositories`).
- Validate all request bodies with **Zod** schemas in `presentation/dtos/` — no inline validation in controllers.
- Domain repository interfaces must declare proper types (not `string` for enums, not `any[]` for returns). See `domain/repositories/report.repository.ts` for the `ReportReason` union type pattern.
- Files: kebab-case (`create-post.usecase.ts`). Classes: PascalCase. Interfaces: `I` prefix (`IUserRepository`). Test files: `.spec.ts`.

---

## Frontend Architecture

Feature-based Flutter app using **Riverpod** for state management, **Dio** for HTTP, and **go_router** for navigation.

```
lib/
├── core/
│   ├── theme/        # AppColors, AppTypography, dark mode
│   ├── components/   # Design System widgets (AppButton, AppTextField, AppCard…)
│   └── router/       # go_router config, route guards
├── features/
│   ├── auth/         # login, register, splash
│   ├── social/       # feed, posts, stories, likes, comments
│   ├── product/      # listings, search, details
│   ├── checkout/     # escrow flow
│   ├── wallet/       # balance, transactions, withdrawals
│   ├── chat/         # WebSocket messaging
│   ├── dispute/      # dispute handling
│   └── profile/      # user profiles, follow/block, reputation
└── shared/
    ├── services/     # HttpService (Dio), TokenService, StorageService
    └── errors/       # Failure types
```

Each feature follows: `data/services/` → `presentation/controllers/` (Riverpod notifiers) → `presentation/pages/` + `presentation/widgets/`.

### Design System: "The Digital Brutalist"

When building or modifying any frontend UI, invoke the `freebay-design-system` skill. The core rules are:

- **0px border radius** on everything — no exceptions, not even 2px
- **No standard shadows** — depth via tonal layering (surface color shifts) only
- **No divider lines** — section breaks via tonal blocking (adjacent surface tones)
- **Space Grotesk** for headlines/display, **Inter** for body/UI text
- **Primary color** `#8A1083` (magenta) used sparingly — "a laser, not a paint bucket"
- **Animations:** 150ms, `Curves.linear` — never ease-in-out
- **Buttons:** Custom `Container` + `InkWell` with signature gradient (`#660062` → `#8A1083`), not `ElevatedButton`
- **Price tags:** `surface_container_highest` (#E2E2E2) block with Space Grotesk typography
- **Surface hierarchy:** `#F9F9F9` → `#F3F3F3` → `#EEEEEE` → `#E2E2E2` (light to elevated)

Dark mode required on all screens.

---

## Database

Prisma schema (`backend/prisma/schema.prisma`) is the source of truth. After any schema edit:
1. `npm run prisma:migrate` — creates and applies migration
2. `npm run prisma:generate` — regenerates the Prisma client

Payment providers: **AbacatePay** (PIX) and **PagBank** (payouts to sellers). The `PaymentProvider` Prisma enum still uses legacy labels `PAGARME`/`WOOVI` for historical reasons — the adapters behind them target AbacatePay/PagBank. Escrow flow: `HELD → RELEASED | REFUNDED`.

---

## Testing patterns

**Backend (Jest + ts-jest):**
- Name the subject `sut` (`let sut: RegisterUseCase`)
- Mock repositories with `jest.fn()` or in-memory implementations
- Call `jest.clearAllMocks()` in `beforeEach`
- Spec files live alongside the source file they test

**Flutter:**
- Unit/widget tests in `test/`, integration tests in `integration_test/`
- Use `mocktail` for mocking
- Integration test driver: `test_driver/integration_test.dart` (standard boilerplate)
