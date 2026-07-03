# FreeBay — Reviewed Architecture TODO (Verified)

> **Verified Status:** Ground-truth audit of the codebase to correct stale tracker items, identifying exactly what OpenCode claimed vs. what is actually implemented.
> **Correction:** Standardized directory layout to **REMOVE all `api/` folders** across the codebase. Controllers, services, and main modules live at the root of the feature folder.
> **Priority:** `[CRIT]` blocking / reject PR · `[HIGH]` important · `[MED]` nice-to-have · `[LOW]` eventual
> **Status key:** `[ ]` pending · `[~]` in progress · `[✓]` done · `[✗]` blocked

---

## 🛑 Clean Architecture Strict Rules (No `api/` folder)
Every module in FreeBay must follow this exact structure. No exceptions.

```
modules/<feature>/
├── <feature>.controller.ts       ← delegates to service, zero business logic
├── <feature>.service.ts          ← unwraps Either → ResponseEntity / raw output
├── <feature>.module.ts           ← main module, registers controller, service, imports usecase modules
├── usecases/
│   └── <action>/
│       ├── <action>.usecase.ts         ← single execute(), injects abstract repo
│       ├── <action>.usecase.module.ts  ← provide/useClass binding lives HERE
│       └── <action>.usecase.spec.ts
├── domain/
│   └── repositories/
│       └── <entity>.repository.ts     ← abstract class, pure TypeScript, no deps
└── data/
    └── repositories/
        └── <entity>-database.repository.ts  ← implements abstract, uses PrismaService
```

**PR Rejection Criteria:**
- **No `api/` subfolders** under modules. Controllers, services, and modules must be at the feature root.
- **No `any` or `unknown`** in abstract repos, data repos, usecases, or services.
- **No `throw` for expected failures** → always return `left(new AppError(...))` or `left(Failure)`.
- **No direct `PrismaService` injection in usecases** → must use abstract repositories.
- **No business logic or raw DB queries in controllers** → only delegating to services.
- **`provide/useClass` binding** must live in the Usecase module only.
- **All DTO properties** must be `readonly`.

---

## 🔍 Ground-Truth Verification of Claims

Below is the verified status of what OpenCode claimed to have completed versus reality:

| OpenCode Claim | Actual Status | Codebase Reality / Findings |
|----------------|---------------|-----------------------------|
| **Cart module fully refactored** | `[✓] Verified` | Abstract repo, data repo, service, and thin controller are present. (Needs `api/` folder removal) |
| **Orders module fully refactored** | `[✓] Verified` | Usecase split into 6 files, uses abstract repo, controller uses service. (Needs `api/` folder removal) |
| **Social module fully refactored** | `[✓] Verified` | 19 usecases split, 6 abstract repos, 6 data repos, service layer exists. (Needs `api/` folder removal) |
| **Stories extracted from social** | `[✓] Verified` | Own module at `modules/stories/` exists with correct Clean structure. (Needs `api/` folder removal) |
| **Category & Favorites fixed** | `[✓] Verified` | Either pattern returns correctly, services unwrap. (Needs `api/` folder removal) |
| **Reports & Auth modules clean** | `[~] Part-Verified` | Auth service catch blocks still contain `throw new AppError(...)` (Violation). |
| **Chat module fully refactored** | `[FAILED] ❌` | `conversation-preference` and `message` repositories are not in domain/data. Gateway still uses concrete repos. Usecases inject `PrismaService` directly. |
| **Build errors (catch blocks) fixed** | `[✓] Verified` | `catch {` syntax errors fixed across the 8 files. |

---

## 🔴 Phase 0: Forbidden Patterns & `any`/`unknown` Fixes `[CRIT]`

These violations are blocking, bypass TypeScript strict safety, and must be resolved immediately.

- [ ] **0.1** `modules/chat/data/repositories/conversation-database.repository.ts:84` — replace `const query: any = { data };` with proper `Prisma.ConversationUpdateInput` type
- [ ] **0.2** `modules/cart/dtos/cart.dto.ts:95` — replace `readonly product!: unknown;` with proper type
- [ ] **0.3** `modules/cart/usecases/get-cart.usecase.ts:12` — replace `product: unknown;` with proper type
- [ ] **0.4** `modules/disputes/effect-harness/test-notifications.layer.ts:6` — type `args: unknown[];`
- [ ] **0.5** `modules/favorites/dtos/favorite.dto.ts:5` — type `readonly products: unknown[];`
- [ ] **0.6** `modules/payments/dtos/payment.dto.ts:14` — type `data: unknown;`
- [ ] **0.7** `modules/payments/providers/abacatepay.provider.ts:49` — type `verifyWebhook(signature: string, body: unknown)`
- [ ] **0.8** `modules/stories/domain/repositories/story.repository.ts:9` — replace `user: unknown;` with proper Prisma payload type
- [ ] **0.9** `modules/stories/usecases/get-stories.usecase.ts:7-8` — replace `user: unknown; stories: unknown[];`
- [ ] **0.10** `modules/users/usecases/user.usecase.ts` (multiple lines) — fix `catch (error: unknown)` syntax
- [ ] **0.11** `modules/users/users.controller.ts` (multiple lines) — fix `catch (error: unknown)` and `error as { code?: string }` casts using `isPrismaError` guard
- [ ] **0.12** `shared/decorators/current-user.decorator.ts:5` — replace `data: unknown`
- [ ] **0.13** `shared/http/exception-filter.ts:16` — type `exception: unknown`
- [ ] **0.14** `shared/http/response.interceptor.ts:17` — type `value as { _tag: string; value: unknown };` using typed Either interface

---

## 🔴 Phase 1: Usecases throwing expected errors / direct Prisma `[CRIT]`

expected failures must return `left(Failure)` and usecases must NOT inject `PrismaService`.

- [ ] **1.1** `cart/data/repositories/cart-database.repository.ts` — remove `throw new Error('PRODUCT_UNAVAILABLE')` at lines 140, 145, 162
- [ ] **1.2** `orders/data/repositories/order-database.repository.ts` — remove `throw new AppError('BAD_REQUEST', ...)` at lines 83, 99
- [ ] **1.3** `chat/repositories/conversation-preference.repository.ts` — remove `throw new Error(...)` at line 48
- [ ] **1.4** `auth/api/auth.service.ts` — replace `throw new AppError(...)` in all catch blocks with `return ResponseEntity.error(...)`
- [ ] **1.5** `disputes/usecases/open-dispute.usecase.ts` — replace direct `PrismaService` injection with `DisputeRepository`
- [ ] **1.6** `disputes/usecases/resolve-dispute.usecase.ts` — replace direct `PrismaService` injection
- [ ] **1.7** `disputes/usecases/withdraw-dispute.usecase.ts` — replace direct `PrismaService` injection

---

## 🔴 Phase 2: Nuke `api/` Folders from Already Refactored Modules `[HIGH]`

Standardize already completed modules by removing the `api/` directory.

- [ ] **2.1** **cart** — Move `cart/api/cart.service.ts` to `cart/cart.service.ts`, merge module setup, and nuke `cart/api/`
- [ ] **2.2** **orders** — Move `orders/api/orders.service.ts` to `orders/orders.service.ts`, merge module setup, and nuke `orders/api/`
- [ ] **2.3** **social** — Move `social/api/social.service.ts` to `social/social.service.ts`, merge module setup, and nuke `social/api/`
- [ ] **2.4** **stories** — Move `stories/api/stories.service.ts` to `stories/stories.service.ts`, merge module setup, and nuke `stories/api/`
- [ ] **2.5** **category** — Move `category/api/category.service.ts` to `category/category.service.ts`, merge module setup, and nuke `category/api/`
- [ ] **2.6** **favorites** — Move `favorites/api/favorites.service.ts` to `favorites/favorites.service.ts`, merge module setup, and nuke `favorites/api/`
- [ ] **2.7** **reports** — Move `reports/api/reports.service.ts` to `reports/reports.service.ts`, merge module setup, and nuke `reports/api/`
- [ ] **2.8** **reviews** — Move `reviews/api/reviews.service.ts` to `reviews/reviews.service.ts` and `reviews/api/reviews.controller.ts` to `reviews/reviews.controller.ts`, merge module setup, and nuke `reviews/api/`

---

## 🟠 Phase 3: Split Usecase God Files `[HIGH]`

Break down monolith files into single-responsibility usecase files.

- [ ] **3.1** **Users Monolith** (`users/usecases/user.usecase.ts`) — split into 10 separate usecases (GetProfile, GetUserStats, UpdateProfile, UpdateFcmToken, FollowUser, UnfollowUser, BlockUser, UnblockUser, SearchUsers, GetSuggestions)
- [ ] **3.2** **Notifications Monolith** (`notifications/usecases/notification.usecase.ts`) — split into 3 separate usecases (GetNotifications, MarkAsRead, RegisterFcmToken)
- [ ] **3.3** **Payments Monolith** (`payments/usecases/payment.usecase.ts`) — split into 2 separate usecases (CreatePixPayment, ProcessWebhook)
- [ ] **3.4** **Wallet Monolith** (`wallet/usecases/wallet.usecase.ts`) — split into 3 separate usecases (GetWallet, Withdraw, RegisterBankAccount)

---

## 🟠 Phase 4: Missing Clean Architecture Repos & Services (No `api/` folders) `[HIGH]`

Create layers for modules that bypass abstract repositories or have no service adapter.

### Chat Module (Complete Refactor)
- [ ] **4.1** Create `chat/domain/repositories/conversation-preference.repository.ts` (abstract)
- [ ] **4.2** Create `chat/domain/repositories/message.repository.ts` (abstract)
- [ ] **4.3** Create `chat/data/repositories/conversation-preference-database.repository.ts`
- [ ] **4.4** Create `chat/data/repositories/message-database.repository.ts`
- [ ] **4.5** Migrate all 10 chat usecases to inject abstract repos instead of `PrismaService`
- [ ] **4.6** Move `chat/api/chat.service.ts` to `chat/chat.service.ts` and nuke `chat/api/`
- [ ] **4.7** Delete old concrete directory `chat/repositories/`

### Disputes Module
- [ ] **4.8** Move `PrismaDisputeRepository` to `disputes/data/repositories/dispute-database.repository.ts` and make it implement abstract `DisputeRepository`
- [ ] **4.9** Create `disputes/disputes.service.ts` directly under `disputes/`
- [ ] **4.10** Refactor `disputes.controller.ts` to inject only `DisputesService`
- [ ] **4.11** Delete old concrete directory `disputes/repositories/`

### Wallet Module
- [ ] **4.12** Create `wallet/domain/repositories/wallet.repository.ts` (abstract)
- [ ] **4.13** Create `wallet/data/repositories/wallet-database.repository.ts`
- [ ] **4.14** Create `wallet/wallet.service.ts` directly under `wallet/`
- [ ] **4.15** Refactor `wallet.controller.ts` to inject only `WalletService` (currently injects concrete repo + PrismaService)
- [ ] **4.16** Delete old concrete directory `wallet/repositories/`

### Payments Module
- [ ] **4.17** Create `payments/domain/repositories/payment.repository.ts` (abstract)
- [ ] **4.18** Create `payments/data/repositories/payment-database.repository.ts`
- [ ] **4.19** Create `payments/payments.service.ts` directly under `payments/`
- [ ] **4.20** Refactor `payments.controller.ts` to inject only `PaymentsService`

### Notifications Module
- [ ] **4.21** Create `notifications/domain/repositories/notification.repository.ts` (abstract)
- [ ] **4.22** Create `notifications/data/repositories/notification-database.repository.ts`
- [ ] **4.23** Create `notifications/notifications.service.ts` directly under `notifications/`
- [ ] **4.24** Refactor `notifications.controller.ts` to inject only `NotificationsService` (currently injects `PrismaService` directly)

### Users Module (Clean Up)
- [ ] **4.25** Create `users/domain/repositories/follow.repository.ts` & `block.repository.ts` (abstract)
- [ ] **4.26** Create `users/data/repositories/follow-database.repository.ts` & `block-database.repository.ts`
- [ ] **4.27** Create `users/users.service.ts` directly under `users/`
- [ ] **4.28** Refactor `users.controller.ts` to inject only `UsersService` (currently injects PrismaService, UserRepository, order repo)
- [ ] **4.29** Fix cross-module dependency: `users.module.ts` should NOT import `PrismaOrderRepository` directly. It should import `OrdersModule`.
- [ ] **4.30** Delete old concrete directories under `users/repositories/`

---

## 🟡 Phase 5: Naming & DTO Hardening `[MED]`

Ensure all DTO properties have the `readonly` modifier.

- [ ] **5.1** `auth/dtos/auth.dto.ts`
- [ ] **5.2** `auth/dtos/password-recovery.dto.ts`
- [ ] **5.3** `cart/dtos/cart.dto.ts`
- [ ] **5.4** `chat/dtos/chat.dto.ts`
- [ ] **5.5** `disputes/dtos/dispute.dto.ts`
- [ ] **5.6** `favorites/dtos/favorite.dto.ts`
- [ ] **5.7** `notifications/dtos/notification.dto.ts`
- [ ] **5.8** `orders/dtos/order.dto.ts`
- [ ] **5.9** `payments/dtos/payment.dto.ts`
- [ ] **5.10** `products/dtos/product.dto.ts`
- [ ] **5.11** `reports/dtos/report.dto.ts`
- [ ] **5.12** `reviews/dtos/review.dto.ts`
- [ ] **5.13** `social/dtos/social.dto.ts`
- [ ] **5.14** `users/dtos/user.dto.ts`
- [ ] **5.15** `wallet/dtos/wallet.dto.ts`
- [ ] **5.16** Add `readonly` to all mapper response class properties in `users/mappers/user.mapper.ts`
