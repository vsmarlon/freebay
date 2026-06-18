# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Commands

### Backend (`cd nest-backend`)

```bash
npm run start:dev        # dev server with watch mode
npm run build             # nest build
npm test                  # jest (all specs)
npx tsc --noEmit          # type-check only, no output

# Single test file
npx jest src/modules/auth/usecases/register.usecase.spec.ts
# Single test by name
npx jest --testNamePattern "should return error" src/modules/auth/usecases/register.usecase.spec.ts

npm run test:integration  # syncs .env.test DB schema, then runs jest.config.integration.js
npm run prisma:generate   # regenerate client after schema changes
npm run prisma:migrate    # create + apply a dev migration
npm run prisma:studio     # open DB GUI
npm run lint               # eslint --fix available via lint:fix
```

Seed data: `db/seeds/001_seed_dev.sql` (run manually against your dev DB; no npm script wraps it).

### Frontend (`cd frontend`)

```bash
flutter pub get
flutter run                              # run on connected device/emulator
flutter test                             # all unit/widget tests
flutter test test/some_widget_test.dart  # single test file
flutter analyze                          # static analysis
flutter build apk --debug
```

### Root `Makefile`

References a `backend/` directory that does not exist in this repo (the backend lives in `nest-backend/`) — `make test` / `make test-unit` will fail with `cd backend` errors. Run the backend/frontend commands above directly instead of relying on the Makefile until it's updated.

---

## Backend Architecture (`nest-backend/`)

**NestJS** (Express platform) with Prisma/PostgreSQL, organized as **vertical feature modules**, not horizontal layers. There is no `domain/application/infra/presentation` split — each module owns its full stack:

```
src/
├── app.module.ts          # imports every feature module + global ThrottlerGuard
├── main.ts
├── shared/
│   ├── core/               # either.ts (Either<L,R>), errors.ts (AppError subclasses), types.ts
│   ├── auth/, guards/       # NonGuestGuard, RolesGuard, webhook.guard — Nest CanActivate guards
│   ├── decorators/          # @Public(), @CurrentUser(), @Roles()
│   ├── infra/prisma/        # PrismaService
│   ├── infra/redis/         # RedisService (token blacklist, cache)
│   ├── http/                 # global exception filter, logging/response/transform interceptors
│   ├── swagger/              # @ApiDoc() composite decorator for OpenAPI docs
│   └── utils/                # e.g. SanitizeText decorator
└── modules/
    └── <feature>/                  # auth, users, products, category, social, wallet,
        ├── <feature>.module.ts     # orders, payments, chat, notifications, disputes,
        ├── <feature>.controller.ts # reports, reviews, favorites, cart, tasks
        ├── dtos/            # class-validator + @nestjs/swagger DTO classes
        ├── repositories/    # concrete Prisma*Repository classes (no I*Repository interfaces)
        ├── usecases/        # one class per use case, returns Either<AppError, Output>
        ├── mappers/         # Prisma model → API response shape
        ├── guards/          # module-specific guards (e.g. auth/guards/jwt-auth.guard.ts)
        └── services/        # third-party integrations (e.g. ResendService for email)
```

### DI wiring

Standard Nest DI: every controller, use case, and repository is `@Injectable()`, registered in its module's `providers: []`, and injected via constructor. Nothing is manually `new`'d in route files. Repositories are injected as **concrete classes** (e.g. `private userRepository: PrismaUserRepository`), never behind an interface.

### Either pattern

Use cases return `Either<AppError, Output>` from `@/shared/core/either`. Never throw for expected business errors — throw only for truly exceptional/unexpected failures or from guards (Nest `ForbiddenException`, etc.).

```typescript
// usecase
async execute(input: Input): Promise<Either<AppError, Output>> {
  if (!entity) return left(new NotFoundError('Product'));
  return right({ entity });
}

// controller checks the result and throws/returns accordingly (see existing
// controllers for the project's response-shaping convention before adding new ones)
```

`AppError` subclasses live in `shared/core/errors.ts` (`NotFoundError`, `UnauthorizedError`, `ForbiddenError`, `EmailAlreadyExistsError`, `InvalidCredentialsError`, `InsufficientBalanceError`, etc.) and carry `code`, `message`, `statusCode`.

### Auth & guards

JWT auth uses Passport (`@nestjs/passport`) with a `JwtAuthGuard` per module (e.g. `modules/auth/guards/jwt-auth.guard.ts`) plus shared guards in `shared/guards/`:

| Guard | Behaviour |
|---|---|
| `JwtAuthGuard` (Passport) | Validates JWT; sets `request.user` |
| `@Public()` decorator | Marks a route to skip the global JWT guard |
| `NonGuestGuard` | Throws `ForbiddenException` if `request.user.isGuest === true` |
| `RolesGuard` + `@Roles()` | Restricts by role via `Reflector` metadata |
| `webhook.guard.ts` | Validates payment-provider webhook signatures |

Guest users can browse but cannot create posts, orders, reports, reviews, etc.

### Validation

DTOs in `modules/<feature>/dtos/` use **class-validator** decorators (`@IsString`, `@IsEmail`, `@MinLength`, …) plus `@nestjs/swagger` `@ApiProperty` for docs — not Zod. `@SanitizeText()` (from `shared/utils`) strips/normalizes free-text input.

### Key constraints

- All monetary values stored in **cents** (`Int`) — never `Float`.
- Use the `@/` path alias for imports from `src/` (e.g. `@/shared/core/either`).
- Domain repository interfaces are not used — repositories are concrete, injected Prisma classes; keep method signatures strongly typed (real enums, not bare `string`).
- Files: kebab-case (`register.usecase.ts`, `prisma-user.repository.ts`). Classes: PascalCase. Test files: `.spec.ts`, colocated next to the file under test.
- Rate limiting via `@nestjs/throttler` is applied globally (`APP_GUARD` in `app.module.ts`) with `short`/`medium`/`long` buckets; sensitive routes (e.g. `auth/register`) add a tighter `@Throttle(...)` override.

---

## Frontend Architecture (`frontend/`)

Flutter app using **Riverpod** for state, **Dio** for HTTP, **go_router** for navigation. Each feature follows full Clean Architecture, not just data→presentation:

```
lib/
├── core/
│   ├── theme/        # app_colors, app_typography, app_theme, dark mode
│   ├── components/   # Design System widgets (AppButton, BrutalistBox, SocialPost, …)
│   ├── providers/    # cross-feature Riverpod providers (e.g. theme_provider)
│   └── router/       # app_router.dart (go_router config + route guards)
├── features/
│   └── <feature>/                # auth, social, product, checkout, wallet, chat,
│       ├── data/                 # dispute, profile, cart, favorites, notifications,
│       │   ├── entities/         # orders, payments, reviews
│       │   └── repositories/     # concrete repo implementing the domain interface
│       ├── domain/
│       │   ├── repositories/     # abstract repository interface
│       │   └── usecases/
│       └── presentation/
│           ├── controllers/      # Riverpod notifiers
│           ├── providers/
│           ├── pages/
│           └── widgets/
└── shared/
    ├── either/        # hand-rolled sealed Either<L,R> (fold/leftOrNull/rightOrNull)
    ├── errors/        # Failure types
    ├── services/      # http_client (Dio), storage_service, biometry_service,
    │                  # notification_service, image_upload_service
    ├── models/, config/, templates/
```

Note: the `dartz` package is also a dependency, but `shared/either/either.dart` is the project's own Either — prefer it for consistency within a feature unless the surrounding code already uses `dartz`.

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

Check `core/components/` before building any UI pattern from scratch (e.g. `BrutalistBox`, `BrutalistFilterChip`, `EmptyState`, `SectionTitle`, `MenuListTile`, `StatColumn`) — extend a primitive instead of inlining a copy.

Dark mode required on all screens.

---

## Database

Prisma schema (`nest-backend/prisma/schema.prisma`) is the source of truth. After any schema edit:
1. `npm run prisma:migrate` — creates and applies migration
2. `npm run prisma:generate` — regenerates the Prisma client

Payment providers: **AbacatePay** (PIX) and **PagBank** (payouts to sellers). The `PaymentProvider` Prisma enum still uses legacy labels `PAGARME`/`WOOVI` for historical reasons — the adapters behind them target AbacatePay/PagBank. Escrow flow: `EscrowStatus` `HELD → RELEASED | REFUNDED`. Order lifecycle: `PENDING → CONFIRMED → SHIPPED → DELIVERED → DISPUTED → COMPLETED | CANCELLED`.

Chat is real-time via a Nest WebSocket gateway (`modules/chat/chat.gateway.ts`), alongside REST endpoints in `chat.controller.ts` for history/management.

---

## Testing patterns

**Backend (Jest + ts-jest, NestJS testing utilities):**
- Name the subject `sut` (`let sut: RegisterUseCase`)
- Build with `Test.createTestingModule({ providers: [...] }).compile()`, mocking repositories via `{ provide: PrismaUserRepository, useValue: mockUserRepository }`
- Spec files live alongside the source file they test (`*.spec.ts`)
- `npm run test:integration` runs a separate suite (`jest.config.integration.js`) against `.env.test`, syncing the schema with `prisma db push` first — these are not run by plain `npm test`

**Flutter:**
- Unit/widget tests in `test/`, integration tests in `integration_test/`
- Use `mocktail` for mocking
- Integration test driver: `test_driver/integration_test.dart` (standard boilerplate)
