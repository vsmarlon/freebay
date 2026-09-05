# GEMINI.md - FreeBay Architecture & Gemini Agent Directives

> **MANDATORY DIRECTIVE FOR ALL AI AGENTS & ASSISTANTS**:
> You MUST explicitly review, follow, and adhere to the architectural skills located in [`.agents/skills/`](./.agents/skills/) (and mirrored in [`.claude/skills/`](./.claude/skills/)) when reading, scaffolding, refactoring, or extending any part of FreeBay.

---

## 🛠️ Common Commands for Verifying Work

Before completing tasks or opening PRs, agents must run the following verification commands to ensure zero errors, zero linter warnings, and passing tests across both backend and frontend.

### 1. Backend (`cd nest-backend`)

```bash
# Typecheck (TypeScript compiler check - zero errors required)
npx tsc --noEmit
# or
npm run tsc:check

# Unit & Use Case tests (Jest)
npm test

# Run a single test file
npx jest src/modules/auth/usecases/register.usecase.spec.ts

# Run tests by name pattern
npx jest --testNamePattern "should return error"

# Integration tests (requires Docker PostgreSQL + Redis or test DB)
npm run test:integration

# Linting & code style
npm run lint
npm run lint:fix

# Prisma schema sync & migrations
npm run prisma:generate     # regenerate client after schema changes
npm run prisma:migrate      # create & apply local dev migration
npm run prisma:studio       # open Prisma database GUI

# Production build test
npm run build
```

### 2. Frontend (`cd frontend`)

```bash
# Static analysis (STRICT: 0 errors, 0 warnings, 0 infos required)
flutter analyze

# Unit & Widget tests
flutter test

# Run a single Flutter test file
flutter test test/features/auth/presentation/login_page_test.dart

# Code generation (Freezed @freezed -> .freezed.dart & JsonSerializable -> .g.dart)
flutter pub run build_runner build --delete-conflicting-outputs

# Dependency sync
flutter pub get

# Debug build check
flutter build apk --debug
```

### 3. Root Level & CI Pipeline (`/`)

```bash
# Unit test suite (TypeScript + Jest backend + Flutter unit tests)
make test-unit

# Integration test suite (Flutter integration with headless Chrome)
make test-integration

# Complete test suite
make test

# Start local test DB & Redis dependencies for integration tests
docker compose -f docker-compose.test.yml up -d
```

---

## 📚 FreeBay Agent Skills Directory

All agents must follow the conventions defined in the corresponding skill before writing or modifying code:

| Skill Name | Target Stack & Scope | Location |
|---|---|---|
| **[`freebay-app-flows`](./.agents/skills/freebay-app-flows/SKILL.md)** | End-to-end user journeys, sequence flows, state hierarchy, and navigation routes (Auth, Biometry, Google Login, Onboarding, Wallet, Chat, Profile, Feed/Explore, Checkout, Disputes, Notifications). | [`.agents/skills/freebay-app-flows/SKILL.md`](./.agents/skills/freebay-app-flows/SKILL.md) |
| **[`freebay-design-system`](./.agents/skills/freebay-design-system/SKILL.md)** | Flutter "Digital Brutalist" UI: strict 0px border radius, no drop shadows (tonal layering only), no divider lines, Space Grotesk / Inter fonts, `#8A1083` magenta accent, 150ms linear micro-animations, dark mode tokens, and widget primitives. | [`.agents/skills/freebay-design-system/SKILL.md`](./.agents/skills/freebay-design-system/SKILL.md) |
| **[`freebay-flutter-feature`](./.agents/skills/freebay-flutter-feature/SKILL.md)** | Frontend Flutter Clean Architecture: `data/domain/presentation` layers, Riverpod state management, Dio HTTP client, `safeCall` error wrapper, GoRouter route definitions, and widget tests. | [`.agents/skills/freebay-flutter-feature/SKILL.md`](./.agents/skills/freebay-flutter-feature/SKILL.md) |
| **[`freebay-backend-module`](./.agents/skills/freebay-backend-module/SKILL.md)** | NestJS Backend vertical slices: `dtos/` with `class-validator` + `@ApiDoc`, single-class `usecases/` returning `Either<AppError, Output>`, `domain/repositories/` abstract interfaces, `data/repositories/` concrete Prisma repos, mappers, and colocated `*.spec.ts` tests. | [`.agents/skills/freebay-backend-module/SKILL.md`](./.agents/skills/freebay-backend-module/SKILL.md) |
| **[`freebay-data-model`](./.agents/skills/freebay-data-model/SKILL.md)** | PostgreSQL / Prisma schema conventions: strict monetary **cents-as-Int** (`price Int // em centavos`), real enums over strings, mandatory `onDelete` cascading rules, foreign key indexing, and migration workflows. | [`.agents/skills/freebay-data-model/SKILL.md`](./.agents/skills/freebay-data-model/SKILL.md) |
| **[`freebay-system-design`](./.agents/skills/freebay-system-design/SKILL.md)** | End-to-end system design: C2C escrow lifecycle, Socket.IO `/chat` gateway, Stripe PaymentSheet & Checkout Sessions, Redis token blacklist, background cron tasks, and security isolation. | [`.agents/skills/freebay-system-design/SKILL.md`](./.agents/skills/freebay-system-design/SKILL.md) |
| **[`freebay-mobile-mcp`](./.agents/skills/freebay-mobile-mcp/SKILL.md)** | Mobile MCP device automation, UI inspection, end-to-end test execution, screenshot verification, and physical/virtual Android/iOS device interactions. | [`.agents/skills/freebay-mobile-mcp/SKILL.md`](./.agents/skills/freebay-mobile-mcp/SKILL.md) |
| **[`stripe-best-practices`](./.agents/skills/stripe-best-practices/SKILL.md)** | Stripe payments, Checkout Sessions vs PaymentIntents, webhook signature validation, idempotency, and secure payment handling. | [`.agents/skills/stripe-best-practices/SKILL.md`](./.agents/skills/stripe-best-practices/SKILL.md) |
| **[`stripe-apps`](./.agents/skills/stripe-apps/SKILL.md)** | Stripe App architecture, extensions, manifest configuration, and merchant UI integrations. | [`.agents/skills/stripe-apps/SKILL.md`](./.agents/skills/stripe-apps/SKILL.md) |
| **[`connect-recommend`](./.agents/skills/connect-recommend/SKILL.md)** | Stripe Connect platform onboarding, seller payout configurations, and multi-party escrow handling. | [`.agents/skills/connect-recommend/SKILL.md`](./.agents/skills/connect-recommend/SKILL.md) |

---

## 🏛️ Core Architectural Principles & Deep Modules

FreeBay is engineered around **deep modules** placed at clean seams to ensure high testability, robust locality, and low cognitive overhead for AI agents and human developers alike.

### 1. Backend Vertical Slices (`nest-backend/`)

- **Vertical Structure**: No horizontal layer soup. Each feature module in `src/modules/<feature>/` owns its DTOs, controllers, use cases, domain repositories, concrete data repositories, and mappers.
- **Deep Use Cases**: Every use case is a single-class file (`*.usecase.ts`) returning an explicit `Either<AppError, Output>` (or `Either<AppError, void>` for pure mutations). Use cases encapsulate full business rules, invariants, and transaction orchestrations rather than delegating them to paper-thin services.
- **Repository Seams**: Use cases depend exclusively on abstract repository interfaces (`domain/repositories/`). Concrete Prisma repositories (`data/repositories/`) implement these interfaces and handle database queries, transactions (`tx?: Prisma.TransactionClient`), and error translations (`DatabaseError`).
- **Interceptor & Filter Pipeline**:
  - `LoggingInterceptor` (outermost)
  - `TransformInterceptor` (wraps successful output in `{ success: true, data: ... }`)
  - `EitherInterceptor` (unwraps `Right(value)` or throws `Left(AppError)`)
  - `AllExceptionsFilter` (catches errors and formats `{ success: false, error: { code, message }, timestamp, path }`)

### 2. Frontend Clean Architecture (`frontend/`)

- **Feature Slices**: Features reside in `lib/features/<feature>/` with `data/` (entities + concrete repositories), `domain/` (abstract repositories + usecases), and `presentation/` (Riverpod controllers, providers, pages, and widgets).
- **Freezed & JSON Codegen**: Entities use `@freezed` with `fromJson` to generate both `*.freezed.dart` (immutability, `copyWith`, equality) and `*.g.dart` (`fromJson`/`toJson` serialization) via `build_runner`.
- **Sealed Either**: Always use FreeBay's custom `Either<Failure, T>` from `package:freebay/shared/either/either.dart` (`Left(Failure)` / `Right(value)`). Never import `dartz`.
- **State Management**: Use `Riverpod` (`StateNotifierProvider`, `AsyncValue`, `FutureProvider`). Tab pages inside `AppShell` must mix in `AutomaticKeepAliveClientMixin` and guard fetch calls against unnecessary rebuilds.

---

## 🗄️ Database Schema & Relational Mapping

The database runs on PostgreSQL using Prisma ORM. Below is the systematic mapping of all core database models and their relational dependencies:

```mermaid
erDiagram
    User ||--o| Wallet : "1:1 owns wallet"
    User ||--o{ Product : "1:N sells products"
    User ||--o{ Post : "1:N creates social posts"
    User ||--o{ Order : "1:N buys or sells orders"
    User ||--o{ Follow : "1:N follower/following"
    User ||--o{ Block : "1:N blocker/blocked"
    User ||--o{ Dispute : "1:N initiates disputes"
    User ||--o{ Review : "1:N review giver/receiver"
    User ||--o{ DirectMessage : "1:N sends chat messages"
    User ||--o{ ConversationPreference : "1:N configures preferences"
    User ||--o{ Notification : "1:N receives notifications"

    Product ||--o{ ProductImage : "1:N contains images"
    Product ||--o{ Order : "1:N referenced in orders"
    Product ||--o{ Favorite : "1:N favorited by users"
    Product ||--o{ CartItem : "1:N added to shopping carts"
    Product ||--o| Post : "1:1 optionally featured in post cards"

    Post ||--o{ Comment : "1:N commented under"
    Post ||--o{ Like : "1:N liked by users"
    Post ||--o{ Share : "1:N shared by users"
    Post ||--o{ SavedPost : "1:N bookmarked by users"

    Order ||--o| Transaction : "1:1 holds payment details"
    Order ||--o| Dispute : "1:1 opens conflict case"
    Order ||--o{ ChatMessage : "1:N order-chat messages"
    Order ||--o{ Review : "1:N reviewed once per order"

    Wallet ||--o{ Withdrawal : "1:N requests money cashouts"

    DirectConversation ||--o{ DirectMessage : "1:N holds messages"
    DirectConversation ||--o{ ConversationPreference : "1:N holds user chat preferences"
```

---

## ⚡ High-Level API Request Flow (Either Monad & Interceptor Pipeline)

```mermaid
graph TD
    Client[HTTP Client / Mobile App] -->|1. JSON Payload| Controller[NestJS Controller]
    Controller -->|2. Calls execute| Usecase[Single-use Usecase execute]
    Usecase -->|3. Invokes Repo| AbstractRepo[Abstract Repository interface]
    AbstractRepo -->|4. DI Lookup| DataRepo[Concrete Prisma Data Repository]
    DataRepo -->|5. SQL Query / Transaction| DB[(PostgreSQL Database)]
    DB -->|6. Prisma Entity| DataRepo
    DataRepo -->|7. Returns Result| Usecase
    Usecase -->|8. Returns Either AppError, Output| Controller
    Controller -->|9. Returns Either| EitherInterceptor[EitherInterceptor: Unwraps right / Throws left]
    EitherInterceptor -->|10. Wraps success| TransformInterceptor[TransformInterceptor: success: true, data: ...]
    EitherInterceptor -->|11. On error| AllExceptionsFilter[AllExceptionsFilter: success: false, error: ...]
    TransformInterceptor -->|12. 200/201 JSON| Client
    AllExceptionsFilter -->|13. 4xx/5xx JSON| Client
```

---

## 💳 Payment & Escrow Lifecycle (Stripe & Crypto)

```mermaid
graph TD
    Client[Flutter Mobile / Web] -->|1. POST /payments/payment-intent/:orderId (Mobile) OR /checkout/:orderId (Web)| Controller[NestJS PaymentsController]
    Controller -->|2. Invokes| Usecase[CreatePaymentIntentUseCase / CreatePaymentSessionUseCase]
    Usecase -->|3. Requests Session/Secret| Provider[StripeProvider / CryptoPaymentProvider]
    Provider -->|4. API Call| Stripe[Stripe API / Monero RPC]
    Stripe -->|5. clientSecret / checkoutUrl / Subaddress| Provider
    Provider -->|6. Saves Transaction PENDING| Repo[TransactionDatabaseRepository]
    Repo -->|7. Prisma Insert| DB[(PostgreSQL)]
    Usecase -->|8. Returns credentials| Client
    Client -->|9. Native PaymentSheet OR Web Checkout| Stripe
    Stripe -->|10. Webhook: payment_intent.succeeded / checkout.session.completed| Guard[WebhookGuard & DedupeInterceptor]
    Guard -->|11. Validated Event| WebhookUC[ProcessWebhookUseCase]
    WebhookUC -->|12. Transaction PAID + Escrow HELD + Order CONFIRMED| DB
    WebhookUC -->|13. Push Notifications| Notif[NotificationService]
```

---

## 🎨 Digital Brutalist Design System Reference

| Token / Concept | Specification | Implementation Rule |
|---|---|---|
| **Corner Radius** | `0.0` (Strict 0px) | Never use `BorderRadius.circular()`. Only `BorderRadius.zero` or no decoration radius. |
| **Elevation & Depth** | Tonal layering | Never use `BoxShadow` or elevation blur. Shift background surface tones (`#F9F9F9` → `#F3F3F3` → `#EEEEEE` → `#E2E2E2`). |
| **Separators** | Tonal blocking | Never use standard `Divider()`. Contrast adjacent blocks or outline with crisp 1px borders. |
| **Primary Accent** | `#8A1083` (Magenta) | Use sparingly as a focal laser (CTA buttons, status badges, active indicators). |
| **Typography** | Space Grotesk & Inter | Space Grotesk for display/headlines/price tags (`AppTypography.display*`); Inter for UI body (`AppTypography.body*`). |
| **Micro-Animations** | 150ms `Curves.linear` | Snappy, mechanical brutalist feedback without bouncy ease curves. |
| **Dark Mode** | Full dark theme support | Always check theme extensions and `context.isDark`. |

---

## 🔒 Non-Negotiable Architecture Invariants

1. **Zero Linter Warnings & Continuous Integration**:
   - Backend: Must pass `npx tsc --noEmit` and `npm test` with zero failures.
   - Frontend: Must pass `flutter analyze` with 0 warnings, 0 infos, 0 errors, and all tests in `flutter test` passing.
   - CI Pipeline: All PRs must pass the GitHub Actions workflow (`.github/workflows/ci.yml`) including PostgreSQL & Redis service tests.
2. **Cents as Integers**: All monetary amounts must be stored as integers representing cents in both Prisma and Dart (`1990` = R$ 19,90).
3. **No Unhandled Throws**: Business failures in use cases must return `left(new AppError(...))` or `Left(Failure(...))`. Never throw raw unhandled exceptions.
4. **Prisma Payload Typing**: Database repository returns and mappers must use `Prisma.validator<...>()` to derive strict `Prisma.*GetPayload` types. Avoid untyped `as unknown as` assertions.
5. **Privacy Crypto Escrow**: Untrackable payments must adhere to the `CryptoPaymentProvider` contract (Monero XMR via `monero-wallet-rpc` ephemeral subaddresses and atomic piconero tracking).
6. **Digital Brutalist Aesthetics**: Never add `BorderRadius.circular()`, blurred drop shadows, or standard `Divider()` widgets to the Flutter UI.
