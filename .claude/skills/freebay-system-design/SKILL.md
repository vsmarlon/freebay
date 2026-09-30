---
name: freebay-system-design
description: Complete system architecture and codebase structure guide for FreeBay — vertical-slice NestJS backend, Flutter Clean Architecture with Riverpod & GoRouter, PostgreSQL schema design, Stripe payment/escrow lifecycle, real-time Socket.IO chat, and security conventions.
---

# FreeBay System Design & Architecture Conventions

## 1. System Overview

FreeBay is a high-performance C2C (Consumer-to-Consumer) hybrid marketplace with integrated social feeds, real-time messaging, and financial escrow protection.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           CLIENT APPLICATIONS                               │
│   Flutter Mobile (Android & iOS)   │   Flutter Web / Responsive Desktop     │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ HTTPS / WSS
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         NESTJS BACKEND GATEWAY                              │
│  - Global ThrottlerGuard (Rate Limiting)   - Logging & Interceptors         │
│  - JwtAuthGuard / NonGuestGuard            - AllExceptionsFilter            │
│  - Socket.IO Gateway (/chat)               - Stripe Webhook Verification    │
└──────────────────────┬───────────────────────────────┬──────────────────────┘
                       │                               │
                       ▼                               ▼
┌──────────────────────────────────────┐     ┌────────────────────────────────┐
│         POSTGRESQL + PRISMA          │     │        REDIS IN-MEMORY         │
│  - User, Product, Order, Wallet      │     │  - JWT Blacklist on logout     │
│  - Financial Ledger & Escrow         │     │  - Rate limiting buckets       │
│  - Social Posts, Comments, Stories   │     │  - Feed / Category cache       │
└──────────────────────────────────────┘     └────────────────────────────────┘
```

---

## 2. Backend Architecture (`nest-backend/`)

### 2.1 Vertical Feature Slice Design
Instead of arbitrary horizontal layer divisions, each module in `src/modules/<feature>` encapsulates its full stack:
- **`dtos/`**: `class-validator` request DTOs, OpenAPI response DTOs, and explicit public-field projections. (Never use Zod).
- **`domain/repositories/`**: Abstract repository definitions defining business query contracts.
- **`data/repositories/`**: Concrete Prisma-powered implementations (e.g. `*-database.repository.ts`) injecting `PrismaService`.
- **`usecases/`**: Single-responsibility use cases, exactly one class per file. Every use case returns `Promise<Either<AppError, Output>>`.
- **Response boundaries**: select or project only public fields before returning. Keep Prisma payload types near repository queries; never return raw user rows.
- **`guards/`**: Module-specific access control guards (e.g. `JwtAuthGuard`, `NonGuestGuard`, `WebhookGuard`).

### 2.2 Either Monad Pattern
All business logic results are wrapped in a functional `Either<Left, Right>` type:
- `left(new AppError(...))` for expected domain errors (e.g. `NotFoundError`, `InvalidCredentialsError`, `InsufficientBalanceError`, `DatabaseError`).
- `right(data)` for successful operations.
- Controllers check `result.isLeft()` and return `left(...)`. The innermost `EitherInterceptor` unwraps the either, throwing `AppError` on `left` (rendered by `AllExceptionsFilter` with proper HTTP status code) and unwrapping `right` (formatted as `{ success: true, data: ... }` by `TransformInterceptor`).

### 2.3 Financial Transaction Safety
- All money is stored in **cents** (`Int`).
- Multi-step ledger mutations are wrapped inside `prisma.$transaction(async (tx) => { ... })` and pass `tx: Prisma.TransactionClient` to participating repository methods.
- Webhooks use idempotent deduplication to prevent double-crediting.

---

## 3. Frontend Architecture (`frontend/`)

### 3.1 Clean Architecture Hierarchy
```
lib/features/<feature>/
├── data/
│   ├── entities/          # Models with @JsonSerializable() and .g.dart codegen
│   └── repositories/      # Concrete repository implementing domain interface via Dio HttpClient
├── domain/
│   ├── repositories/      # Abstract repository interface
│   └── usecases/          # Business logic invokers returning Either<Failure, T>
└── presentation/
    ├── controllers/       # StateNotifier / Notifier classes managing UI state
    ├── providers/         # Riverpod providers for repository & usecases
    ├── pages/             # Route-registered screen widgets
    └── widgets/           # Feature-specific reusable UI components
```

### 3.2 Navigation & Tab Persistence
- Navigation is orchestrated via **GoRouter** with `StatefulShellRoute` in `core/router/app_router.dart`.
- Tab pages in `AppShell` mix in `AutomaticKeepAliveClientMixin` (`wantKeepAlive => true`) to preserve scroll position and avoid redundant network rebuilds.
- Centralized route constants in `core/router/app_routes.dart`.

---

## 4. Coding Conventions & Best Practices

1. **Zero Linter Warnings**: Always maintain 0 issues on `flutter analyze` and 100% pass on `npm test`.
2. **Path Aliasing**: In NestJS backend, use `@/` alias for all internal `src/` imports.
3. **No Dead Code**: Remove unused imports, abandoned mock files, and dead variables proactively.
4. **Idempotent Webhooks**: All external payment triggers must verify provider signatures and guarantee at-most-once execution.

---
