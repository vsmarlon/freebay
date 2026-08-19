# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Always run `cd frontend && flutter analyze` after any frontend change and fix every issue it reports (warnings and infos, not just errors) before considering the work done — zero-issue output is the bar, not "no errors."**

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

Run after finishing large work.

---

## Backend Architecture (`nest-backend/`)

**NestJS** (Express platform) with Prisma/PostgreSQL, organized as **vertical feature modules**, not horizontal layers. There is no top-level `domain/application/infra/presentation` split — each module owns its full stack. Inside that vertical slice, most modules additionally split the repository layer into an abstract `domain/repositories/` interface and a concrete `data/repositories/` Prisma implementation (see DI wiring below); a couple of modules (`payments`, `notifications`) still inject a concrete repository directly with no abstract layer:

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
        ├── domain/repositories/  # abstract Repository classes (most modules)
        ├── data/repositories/    # concrete Prisma*Repository implementations (most modules)
        ├── repositories/    # flat concrete repository folder (modules not yet migrated to domain/data split)
        ├── usecases/        # one class per use case, returns Either<AppError, Output>
        ├── mappers/         # Prisma model → API response shape
        ├── guards/          # module-specific guards (e.g. auth/guards/jwt-auth.guard.ts)
        └── services/        # third-party integrations (e.g. ResendService for email)
```

### DI wiring

Standard Nest DI: every controller, use case, and repository is `@Injectable()`, registered in its module's `providers: []`, and injected via constructor. Nothing is manually `new`'d in route files. Most modules now inject the **abstract** `domain/repositories/*.repository.ts` class into use cases (e.g. `private readonly orderRepository: OrderRepository`), bound to its concrete `data/repositories/*-database.repository.ts` implementation via `{ provide: AbstractRepo, useExisting: ConcreteRepo }` in the module's providers array — concrete repositories inject `PrismaService` to run queries, use cases never do. The `payments` module has abstract repos for `TransactionRepository`, `ProductRepository` (tx methods), `OrderRepository` (tx methods), and `WalletRepository` (tx methods) — but still uses `PrismaService` directly for the `$transaction` wrapper and transaction-table CRUD. The `notifications` module still injects the concrete Prisma repository class directly with no abstract layer.

### Either pattern

Use cases return `Either<AppError, Output>` from `@/shared/core/either`. Never throw for expected business errors — throw only for truly exceptional/unexpected failures or from guards (Nest `ForbiddenException`, etc.).

```typescript
// usecase
async execute(input: Input): Promise<Either<AppError, Output>> {
  if (!entity) return left(new NotFoundError('Product'));
  return right({ entity });
}

// controller checks the result (see full convention below)
```

`AppError` subclasses live in `shared/core/errors.ts` (`NotFoundError`, `UnauthorizedError`, `ForbiddenError`, `EmailAlreadyExistsError`, `InvalidCredentialsError`, `InsufficientBalanceError`, `DatabaseError`, `NotImplementedError`, etc.) and carry `code`, `message`, `statusCode`.

### Void return convention for mutations

Pure-mutation usecases that don't return meaningful data should use `Either<AppError, void>` instead of `Either<AppError, { verb: boolean }>`. Return `right(undefined)` on success. Controllers should just check `result.isLeft()` — no `.verb` field access needed. Query usecases that need to return data (e.g. `check-favorite` → `{ isFavorited: boolean }`, `confirm-delivery` → `{ sellerAmount: number }`) keep their output types.

### Transactional repository pattern

Repository methods that need to participate in `prisma.$transaction` accept an optional `tx?: Prisma.TransactionClient` parameter. The usecase wraps the transaction via `this.prisma.$transaction(async (tx) => { ... })` and passes `tx` to each repo call:

```typescript
// repository method signature
abstract creditPending(userId: string, amount: number, tx?: Prisma.TransactionClient): RepositoryResponse<void>;

// usecase
await this.prisma.$transaction(async (tx) => {
  await this.productRepo.updateInventoryOnSale(productId, tx);
  await this.orderRepo.confirm(orderId, tx);
  await this.walletRepo.creditPending(sellerId, amount, tx);
});
```

### Controller response-shaping convention

Every controller follows the same pattern: query a usecase, check `isLeft()`/`isRight()`, return early on error. Three interceptors handle the rest:

1. **`EitherInterceptor`** (`shared/http/response.interceptor.ts` — innermost) — catches raw `{ _tag: 'left', value }` Either objects returned from controllers and throws them as `AppError` exceptions so Nest's exception filter can handle them. On `right()`, it unwraps `either.value` and passes the inner value to the next interceptor.
2. **`TransformInterceptor`** (`shared/http/transform.interceptor.ts` — middle) — wraps every successful response in `{ success: true, data: <value> }`.
3. **`AllExceptionsFilter`** (`shared/http/exception-filter.ts` — global filter) — catches all thrown exceptions and renders `{ success: false, error: { code, message }, timestamp, path }`.

**Register order matters** (in `main.ts`): `LoggingInterceptor` (outermost) → `TransformInterceptor` → `EitherInterceptor` (innermost, runs first). Because `EitherInterceptor` unwraps `left()`/`right()` before `TransformInterceptor` wraps the value, error responses are correctly shaped as HTTP errors, not 200 OK with an Either buried in `data`.

**Canonical controller pattern:**

```typescript
@Post('resource')
@HttpCode(HttpStatus.CREATED)
@ApiDoc({ summary: '…', bodyType: …, responseStatus: 201, auth: true })
async create(@CurrentUser() user: AuthUser, @Body() body: CreateDTO) {
  const result = await this.someUseCase.execute({ userId: user.userId, ...body });
  if (result.isLeft()) {
    // EitherInterceptor will throw this as an AppError; AllExceptionsFilter shapes the response
    return left(new AppError(result.value.code, result.value.message));
  }
  return result.value; // TransformInterceptor wraps in { success: true, data: … }
}
```

Do NOT `throw` business errors in controllers — return `left(new AppError(…))` so `EitherInterceptor` handles them consistently. The exceptions are Nest guards (`ForbiddenException`, `BadRequestException` for invalid file uploads) which are caught by `AllExceptionsFilter`.

### One-class-per-usecase rule

Every use case file must contain **exactly one exported class**. This keeps each file focused and testable (`let sut: SomeUseCase`). New use cases should always be one-per-file.

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
- Most modules inject an abstract `domain/repositories/*.repository.ts` class (bound to a concrete `data/repositories/*-database.repository.ts` implementation via `useExisting`); `notifications` still injects the concrete Prisma class directly. `payments` uses abstract repos but still injects `PrismaService` for the `$transaction` wrapper. Either way, keep method signatures strongly typed (real enums, not bare `string`).
- Use `DatabaseError` for infrastructure/DB failures in catch blocks, not bare `AppError('INTERNAL_ERROR', ...)`. Use `NotImplementedError` for stubbed/placeholder usecases.
- Mutation usecases that don't return meaningful data should use `Either<AppError, void>` (return `right(undefined)`) instead of `Either<AppError, { verb: boolean }>`.
- Files: kebab-case (`register.usecase.ts`, `prisma-user.repository.ts`). Classes: PascalCase. Test files: `.spec.ts`, colocated next to the file under test.
- Rate limiting via `@nestjs/throttler` is applied globally (`APP_GUARD` in `app.module.ts`) with `short`/`medium`/`long` buckets; sensitive routes (e.g. `auth/register`) add a tighter `@Throttle(...)` override.
- **Throttler buckets** (from `app.module.ts`): `short` = 10 req/s, `medium` = 60 req/min (default), `long` = 1000 req/h. Override per route with `@Throttle({ short: { limit, ttl } })`.

### WebSocket / Chat

Chat uses **Socket.IO** with a dedicated NestJS WebSocket gateway at `modules/chat/chat.gateway.ts` on namespace `/chat`.

**Auth handshake:** The client sends a JWT access token via `client.handshake.auth.token` (or the `Authorization` header). The gateway validates it with `JwtTokenValidatorService` and disconnects unauthenticated clients.

**Two chat models:**
- **Order chat** — `ChatMessage` model in Prisma, linked to an `Order`. Used for buyer-seller communication about a specific order. REST endpoints in `chat.controller.ts`.
- **Direct Messages** — `DirectConversation` (two-party) + `DirectMessage` models. Conversation-level REST endpoints, message-level Socket.IO events.

WebSocket events mirror CRUD operations on messages. For history/management, use the REST endpoints.

### Frontend routing & guards

Routes are configured in `frontend/lib/core/router/app_router.dart` using **go_router** with a `StatefulShellRoute` (bottom nav tabs). All route path strings are centralized as `static const` variables in `frontend/lib/core/router/app_routes.dart` (e.g. `AppRoutes.feed`, `AppRoutes.login`). Hardcoded path strings should not be used. Guard logic uses Riverpod state:

- **Auth gate:** `redirect` callback checks the auth provider. Unauthenticated users are redirected to `AppRoutes.login` except for public routes (marked via a list of public paths).
- **Guest vs authenticated:** Guest users can browse public content but are redirected to login for guarded actions.
- **Page transitions:** `CustomTransitionPage` with slide + fade, 150ms/`Curves.linear` per the design system.

### Mapper pattern

Prisma models are never returned directly as API responses. Each module has a `mappers/` directory with pure functions that transform Prisma types → API response types:

```typescript
// modules/users/mappers/user.mapper.ts
export function toUserResponse(user: User): UserResponse {
  return {
    id: user.id,
    displayName: user.displayName,
    avatarUrl: user.avatarUrl,
    bio: user.bio,
    // … only expose what the API consumer needs; never leak passwordHash, etc.
  };
}
```

Mappers handle null/default values and ensure response shape consistency. They are called from controllers or usecases before returning data.

### Running seeds

Seed data is at `db/seeds/001_seed_dev.sql` — raw SQL for Prisma/PostgreSQL. Run manually:

```bash
# Using psql or any Postgres client against your dev DB
psql -h localhost -U postgres -d freebay -f db/seeds/001_seed_dev.sql
```

The seed populates: demo users, categories, sample products, and social posts for local development. There is no npm script wrapping it — run it directly.

### Integration tests

Integration tests live alongside unit specs (`*.spec.ts`) but run under a separate Jest config (`jest.config.integration.js`) against `.env.test`:

```bash
npm run test:integration   # syncs schema + runs integration suite
npm run test:integration:watch
npm run test:integration:cov
```

The `.env.test` database is synced via `prisma db push --accept-data-loss` before each run. Integration tests are **not** included in plain `npm test`. They require a local PostgreSQL + Redis instance (use `docker-compose.test.yml` from the repo root).

### Swagger UI

Swagger is configured in `main.ts` via `@nestjs/swagger` `SwaggerModule`. The UI is available at:

```
http://localhost:{PORT}/api
```

All endpoints are documented with `@ApiDoc()` (a composite decorator from `shared/swagger/api-doc.decorator`). Request DTOs use `@ApiProperty` for schema generation. Bearer auth is configured globally — click "Authorize" in Swagger UI to add a JWT token.

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

Note: The hand-rolled `shared/either/either.dart` is the project's own Either implementation and is used universally. Do not import `dartz` for Either. All entity, repository, usecase, and UI files must use this custom implementation.

### Tab pages inside the swipeable shell

`AppShell` (`core/components/app_shell.dart`) hosts the 5 bottom-nav tabs in a single `PageView` that keeps every tab mounted simultaneously. Any page registered there must:
- Mix in `AutomaticKeepAliveClientMixin` (`wantKeepAlive => true`, call `super.build(context)` at the top of `build()`) so swiping away and back doesn't reset scroll position or rebuild from scratch.
- Guard data-loading calls (e.g. `loadFeed()`) so they run once per provider lifetime — only on first load or an explicit pull-to-refresh/`invalidate()` — never unconditionally in `initState`/`build`.
- Prefer non-`autoDispose` Riverpod providers (`StateNotifierProvider`, plain `FutureProvider`/`.family`) for tab data so state survives tab switches; only use `autoDispose` for screens outside the shell.

### Entity codegen convention

Every entity with JSON (de)serialization must use `@JsonSerializable()` (from `json_annotation`) with a generated `part 'x.g.dart'`, never a hand-written `fromJson`/`toJson`. If an entity needs custom preprocessing before mapping (e.g. flattening a nested API shape), do that preprocessing on the raw `Map` and then call the generated `_$XFromJson`, rather than writing the whole mapping by hand. After adding or editing any `@JsonSerializable`/`@freezed` class, run:
```
cd frontend && flutter pub run build_runner build --delete-conflicting-outputs
```

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

Payment provider: **Stripe** (Checkout Sessions — PIX auto-offered for Brazilian customers, credit card otherwise). Webhook events: `checkout.session.completed` / `checkout.session.expired`. The `PaymentProvider` Prisma enum uses `STRIPE`. Escrow flow: `EscrowStatus` `HELD → RELEASED | REFUNDED`. Order lifecycle: `PENDING → CONFIRMED → SHIPPED → DELIVERED → DISPUTED → COMPLETED | CANCELLED`. Migration plan: see `docs/plans/2026-08-04-stripe-migration.md`. Mobile single-product checkout uses Stripe **PaymentSheet** (PaymentIntent, `POST /payments/payment-intent/:orderId`); web and cart keep Checkout Sessions (branched on `kIsWeb` in `payment_page.dart`). Webhook events: `checkout.session.completed` / `checkout.session.expired` / `payment_intent.succeeded` / `payment_intent.canceled` / `payment_intent.payment_failed`. See `nest-backend/src/modules/payments/docs/adr/0001-payment-sheet-migration.md`.

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
