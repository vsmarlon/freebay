# FreeBay NestJS Backend — Architecture Migration Tracker

> **Purpose:** Track every file change needed to migrate from the old MVC-Plus pattern to the Clean Architecture defined in `IMPROVEARCHITECTURE.md`.
> **Status:** `[ ]` = Pending | `[~]` = In Progress | `[✓]` = Done
> **Rule:** Only the user marks items `[✓]`. The agent marks items `[~]` while working.
> **2026-06-25:** Stories extracted from social into own `modules/stories/` module to reduce module size. `wishlistrepositories/` deleted (empty).

---

## Phase 1: Shared Core Infrastructure

| # | Task | Status |
|---|------|--------|
| 1.1 | Create `shared/core/entity.ts` — Entity base class | `[~]` |
| 1.2 | Create `shared/core/response-entity.ts` — ResponseEntity class | `[~]` |
| 1.3 | Update `shared/core/errors.ts` — make `AppError` extend `Error`, add `Failure` type alias | `[~]` |
| 1.4 | Update `shared/core/either.ts` — add `RepositoryResponse<T>`, `UsecaseResponse<T>`, `EntityResponse<T>` | `[~]` |
| 1.5 | Update `shared/http/response.interceptor.ts` — pass original `AppError` instead of creating new one | `[~]` |
| 1.6 | Update `shared/core/index.ts` — export `Entity`, `ResponseEntity`, type aliases | `[~]` |

---

## Phase 2: Domain Layer Per Module

### auth/
| # | File Change | Status |
|---|-------------|--------|
| 2.1 | Create `modules/auth/domain/entities/user.model.ts` | `[~]` |
| 2.2 | Create `modules/auth/domain/repositories/user.repository.ts` (abstract) | `[~]` |
| 2.3 | Create `modules/auth/domain/repositories/password-recovery.repository.ts` (abstract) | `[~]` |
| 2.4 | Create `modules/auth/data/repositories/user-database.repository.ts` (implements abstract) | `[~]` |
| 2.5 | Create `modules/auth/data/repositories/password-recovery-database.repository.ts` (implements abstract) | `[~]` |
| 2.6 | Delete old `modules/auth/repositories/prisma-user.repository.ts` | `[~]` |
| 2.7 | Delete old `modules/auth/repositories/password-recovery.repository.ts` | `[~]` |

### cart/
| # | File Change | Status |
|---|-------------|--------|
| 2.8 | Create `modules/cart/domain/repositories/cart.repository.ts` (abstract) | `[✓]` |
| 2.9 | Create `modules/cart/data/repositories/cart-database.repository.ts` | `[✓]` |

### category/
| # | File Change | Status |
|---|-------------|--------|
| 2.10 | Create `modules/category/domain/repositories/category.repository.ts` (abstract) | `[ ]` |
| 2.11 | Create `modules/category/data/repositories/category-database.repository.ts` | `[ ]` |

### chat/
| # | File Change | Status |
|---|-------------|--------|
| 2.12 | Create `modules/chat/domain/repositories/conversation-preference.repository.ts` (abstract) | `[ ]` |
| 2.13 | Create `modules/chat/data/repositories/conversation-preference-database.repository.ts` | `[ ]` |
| 2.14 | Create `modules/chat/domain/repositories/conversation.repository.ts` (abstract) | `[ ]` |
| 2.15 | Create `modules/chat/data/repositories/conversation-database.repository.ts` | `[ ]` |
| 2.16 | Create `modules/chat/domain/repositories/message.repository.ts` (abstract) | `[ ]` |
| 2.17 | Create `modules/chat/data/repositories/message-database.repository.ts` | `[ ]` |

### disputes/
| # | File Change | Status |
|---|-------------|--------|
| 2.18 | Create `modules/disputes/domain/repositories/dispute.repository.ts` (abstract) | `[ ]` |
| 2.19 | Create `modules/disputes/data/repositories/dispute-database.repository.ts` | `[ ]` |

### favorites/
| # | File Change | Status |
|---|-------------|--------|
| 2.20 | Create `modules/favorites/domain/repositories/favorite.repository.ts` (abstract) | `[ ]` |
| 2.21 | Create `modules/favorites/data/repositories/favorite-database.repository.ts` | `[ ]` |

### notifications/
| # | File Change | Status |
|---|-------------|--------|
| 2.22 | Create `modules/notifications/domain/repositories/notification.repository.ts` (abstract) | `[ ]` |
| 2.23 | Create `modules/notifications/data/repositories/notification-database.repository.ts` | `[ ]` |

### orders/
| # | File Change | Status |
|---|-------------|--------|
| 2.24 | Create `modules/orders/domain/repositories/order.repository.ts` (abstract) | `[✓]` |
| 2.25 | Create `modules/orders/data/repositories/order-database.repository.ts` | `[✓]` |

### payments/
| # | File Change | Status |
|---|-------------|--------|
| 2.26 | Create `modules/payments/domain/repositories/payment.repository.ts` (abstract) | `[ ]` |
| 2.27 | Create `modules/payments/data/repositories/payment-database.repository.ts` | `[ ]` |

### products/
| # | File Change | Status |
|---|-------------|--------|
| 2.28 | Create `modules/products/domain/repositories/product.repository.ts` (abstract) | `[✓]` |
| 2.29 | Create `modules/products/data/repositories/product-database.repository.ts` | `[✓]` |

### reports/
| # | File Change | Status |
|---|-------------|--------|
| 2.30 | Create `modules/reports/domain/repositories/report.repository.ts` (abstract) | `[ ]` |
| 2.31 | Create `modules/reports/data/repositories/report-database.repository.ts` | `[ ]` |

### reviews/
| # | File Change | Status |
|---|-------------|--------|
| 2.32 | Create `modules/reviews/domain/repositories/review.repository.ts` (abstract) | `[ ]` |
| 2.33 | Create `modules/reviews/data/repositories/review-database.repository.ts` | `[ ]` |

### social/
| # | File Change | Status |
|---|-------------|--------|
| 2.34 | Create `modules/social/domain/repositories/post.repository.ts` (abstract) | `[✓]` |
| 2.35 | Create `modules/social/domain/repositories/like.repository.ts` (abstract) | `[✓]` |
| 2.36 | Create `modules/social/domain/repositories/comment.repository.ts` (abstract) | `[✓]` |
| 2.37 | ~~Create `modules/social/domain/repositories/story.repository.ts` (abstract)~~ → moved to `modules/stories/` | `[✓]` |
| 2.38 | Create `modules/social/domain/repositories/share.repository.ts` (abstract) | `[✓]` |
| 2.39 | Create `modules/social/domain/repositories/saved-post.repository.ts` (abstract) | `[✓]` |
| 2.40 | Create `modules/social/data/repositories/post-database.repository.ts` | `[✓]` |
| 2.41 | Create `modules/social/data/repositories/like-database.repository.ts` | `[✓]` |
| 2.42 | Create `modules/social/data/repositories/comment-database.repository.ts` | `[✓]` |
| 2.43 | ~~Create `modules/social/data/repositories/story-database.repository.ts`~~ → moved to `modules/stories/` | `[✓]` |
| 2.44 | Create `modules/social/data/repositories/share-database.repository.ts` | `[✓]` |
| 2.45 | Create `modules/social/data/repositories/saved-post-database.repository.ts` | `[✓]` |

### stories/ (extracted from social)
| # | File Change | Status |
|---|-------------|--------|
| 2.46 | Create `modules/stories/domain/repositories/story.repository.ts` (abstract) | `[✓]` |
| 2.47 | Create `modules/stories/data/repositories/story-database.repository.ts` | `[✓]` |
| 2.48 | Create `modules/stories/usecases/` (5 usecases) | `[✓]` |
| 2.49 | Create `modules/stories/api/stories.service.ts` | `[✓]` |
| 2.50 | Create `modules/stories/api/stories-api.module.ts` | `[✓]` |
| 2.51 | Create `modules/stories/stories.controller.ts` | `[✓]` |
| 2.52 | Create `modules/stories/stories.module.ts` | `[✓]` |
| 2.53 | Register `StoriesModule` in `app.module.ts` | `[✓]` |

### users/
| # | File Change | Status |
|---|-------------|--------|
| 2.46 | Create `modules/users/domain/repositories/user.repository.ts` (abstract) | `[~]` — reused `auth/domain/repositories/user.repository.ts` |
| 2.47 | Create `modules/users/domain/repositories/follow.repository.ts` (abstract) | `[ ]` |
| 2.48 | Create `modules/users/domain/repositories/block.repository.ts` (abstract) | `[ ]` |
| 2.49 | Create `modules/users/data/repositories/user-database.repository.ts` | `[~]` — reused `auth/data/repositories/user-database.repository.ts` |
| 2.50 | Create `modules/users/data/repositories/follow-database.repository.ts` | `[ ]` |
| 2.51 | Create `modules/users/data/repositories/block-database.repository.ts` | `[ ]` |

### wallet/
| # | File Change | Status |
|---|-------------|--------|
| 2.52 | Create `modules/wallet/domain/repositories/wallet.repository.ts` (abstract) | `[ ]` |
| 2.53 | Create `modules/wallet/data/repositories/wallet-database.repository.ts` | `[ ]` |

---

## Phase 3: Service Layer Per Module

### auth/
| # | File Change | Status |
|---|-------------|--------|
| 3.1 | Create `modules/auth/api/auth.service.ts` | `[~]` |
| 3.2 | Create `modules/auth/api/auth.module.ts` | `[~]` |
| 3.3 | Create `modules/auth/api/input/` directory | `[ ]` |
| 3.4 | Create `modules/auth/usecases/auth-usecases.module.ts` with `provide/useClass` bindings | `[~]` |

### cart/
| # | File Change | Status |
|---|-------------|--------|
| 3.5 | Create `modules/cart/api/cart.service.ts` | `[✓]` |
| 3.6 | Create `modules/cart/api/cart-api.module.ts` | `[✓]` |

### category/
| # | File Change | Status |
|---|-------------|--------|
| 3.7 | Create `modules/category/api/category.service.ts` | `[ ]` |

### chat/
| # | File Change | Status |
|---|-------------|--------|
| 3.8 | Create `modules/chat/api/chat.service.ts` | `[ ]` |
| 3.9 | Create usecase module files for each usecase | `[ ]` |

### disputes/
| # | File Change | Status |
|---|-------------|--------|
| 3.10 | Create `modules/disputes/api/disputes.service.ts` | `[ ]` |
| 3.11 | Create usecase module files | `[ ]` |

### favorites/
| # | File Change | Status |
|---|-------------|--------|
| 3.12 | Create `modules/favorites/api/favorites.service.ts` | `[ ]` |

### notifications/
| # | File Change | Status |
|---|-------------|--------|
| 3.13 | Create `modules/notifications/api/notifications.service.ts` | `[ ]` |
| 3.14 | Create `modules/notifications/api/notifications.module.ts` | `[ ]` |

### orders/
| # | File Change | Status |
|---|-------------|--------|
| 3.15 | Create `modules/orders/api/orders.service.ts` | `[✓]` |
| 3.16 | Create `modules/orders/api/orders-api.module.ts` | `[✓]` |

### payments/
| # | File Change | Status |
|---|-------------|--------|
| 3.17 | Create `modules/payments/api/payments.service.ts` | `[ ]` |
| 3.18 | Create usecase module files | `[ ]` |

### products/
| # | File Change | Status |
|---|-------------|--------|
| 3.19 | Create `modules/products/api/products.service.ts` | `[✓]` |
| 3.20 | Create usecase module files | `[✓]` |

### reports/
| # | File Change | Status |
|---|-------------|--------|
| 3.21 | Create `modules/reports/api/reports.service.ts` | `[ ]` |
| 3.22 | Create usecase module files | `[ ]` |

### reviews/
| # | File Change | Status |
|---|-------------|--------|
| 3.23 | Create `modules/reviews/api/reviews.service.ts` | `[ ]` |
| 3.24 | Create usecase module files | `[ ]` |

### social/
| # | File Change | Status |
|---|-------------|--------|
| 3.25 | Create `modules/social/api/social.service.ts` | `[✓]` |
| 3.26 | Create `modules/social/api/social-api.module.ts` | `[✓]` |

### users/
| # | File Change | Status |
|---|-------------|--------|
| 3.27 | Create `modules/users/api/users.service.ts` | `[ ]` |
| 3.28 | Create usecase module files | `[ ]` |

### wallet/
| # | File Change | Status |
|---|-------------|--------|
| 3.29 | Create `modules/wallet/api/wallet.service.ts` | `[ ]` |
| 3.30 | Create usecase module files | `[ ]` |

---

## Phase 4: Controller Refactoring

| # | Controller | Change | Status |
|---|-----------|--------|--------|
| 4.1 | `auth.controller.ts` | Replace usecase injections → service injection; remove redundant `left()` wrapping | `[~]` |
| 4.2 | `cart.controller.ts` | Replace usecase+repo injections → service; move validation to DTO; extract business logic | `[✓]` |
| 4.3 | `category.controller.ts` | Add service layer; replace repo injection with service | `[ ]` |
| 4.4 | `chat.controller.ts` | Replace usecase injections → service injection | `[ ]` |
| 4.5 | `disputes.controller.ts` | Replace usecase injections → service injection | `[ ]` |
| 4.6 | `favorites.controller.ts` | Add usecase+service; remove repo injection; extract business logic | `[ ]` |
| 4.7 | `notifications.controller.ts` | Remove PrismaService; add notification service layer | `[ ]` |
| 4.8 | `orders.controller.ts` | Remove repo injections; replace with service | `[✓]` |
| 4.9 | `payments.controller.ts` | Replace usecase injections → service injection | `[ ]` |
| 4.10 | `products.controller.ts` | Remove repo injection; replace with service | `[✓]` |
| 4.11 | `reports.controller.ts` | Replace usecase injections → service injection | `[ ]` |
| 4.12 | `reviews.controller.ts` | Replace usecase injections → service injection | `[ ]` |
| 4.13 | `social.controller.ts` | **Worst offender** — extract ALL logic to usecases; remove repo + Prisma injections | `[✓]` |
| 4.14 | `users.controller.ts` | Remove Prisma + repo injections; extract ALL logic to usecases | `[~]` — replaced `PrismaUserRepository` → `UserRepository`, added Either handling |
| 4.15 | `wallet.controller.ts` | Remove Prisma + repo injections; replace with service | `[ ]` |

---

## Phase 5: Usecase Refactoring

| # | Usecase File | Fix | Status |
|---|-------------|-----|--------|
| 5.1 | `auth/guest.usecase.ts` | Return `Promise<Either<AppError, GuestResponse>>` instead of `Promise<GuestResponse>` | `[~]` |
| 5.2 | `auth/forgot-password.usecase.ts` | Replace RedisService + EmailService → abstract repository methods | `[~]` |
| 5.3 | `auth/reset-password.usecase.ts` | Replace RedisService → abstract repository methods | `[~]` |
| 5.4 | `auth/request-password-recovery.usecase.ts` | Replace ResendService → abstract repository methods | `[~]` |
| 5.5 | `cart/checkout-cart.usecase.ts` | Remove `throw` inside transaction; replace PrismaService with repository; remove usecase→usecase call | `[ ]` |
| 5.6 | `chat/start-conversation.usecase.ts` | Replace PrismaService with repository | `[ ]` |
| 5.7 | `chat/send-message.usecase.ts` | Replace PrismaService with repository | `[ ]` |
| 5.8 | `chat/get-conversations.usecase.ts` | Replace PrismaService with repository | `[ ]` |
| 5.9 | `chat/get-messages.usecase.ts` | Replace PrismaService with repository | `[ ]` |
| 5.10 | `chat/get-unified-conversations.usecase.ts` | Replace PrismaService with repository | `[ ]` |
| 5.11 | `chat/accept-conversation.usecase.ts` | Replace PrismaService with repository | `[ ]` |
| 5.12 | `chat/archive-conversation.usecase.ts` | Replace ChatThreadAccessService call with repository | `[ ]` |
| 5.13 | `chat/delete-conversation.usecase.ts` | Replace ChatThreadAccessService call with repository | `[ ]` |
| 5.14 | `chat/set-conversation-theme.usecase.ts` | Replace ChatThreadAccessService call with repository | `[ ]` |
| 5.15 | `chat/set-conversation-background.usecase.ts` | Replace ChatThreadAccessService call with repository | `[ ]` |
| 5.16 | `disputes/open-dispute.usecase.ts` | Replace PrismaService + NotificationService with repository | `[ ]` |
| 5.17 | `disputes/resolve-dispute.usecase.ts` | Replace PrismaService + services with repository | `[ ]` |
| 5.18 | `disputes/submit-evidence.usecase.ts` | Replace DisputeTransitionPolicy call with repository | `[ ]` |
| 5.19 | `disputes/withdraw-dispute.usecase.ts` | Replace PrismaService + services with repository | `[ ]` |
| 5.20 | `notifications/notification.usecase.ts` | **Split into 3 files**; replace PrismaService with repository | `[ ]` |
| 5.21 | `orders/order.usecase.ts` | **Split into 6 files**; replace PrismaService + NotificationService with repository | `[ ]` |
| 5.22 | `orders/create-order.usecase.ts` | Fix `throw new InvalidOrderStateError()` → `return left(...)` | `[ ]` |
| 5.23 | `payments/payment.usecase.ts` | **Split into 2 files**; replace PrismaService + AbacatePayProvider with repository | `[ ]` |
| 5.24 | `products/product.usecase.ts` | **Split into 6 files** (create, update, delete, get-products, get-by-id, get-my) | `[✓]` |
| 5.25 | `reports/create-report.usecase.ts` | Add repository; replace PrismaService | `[ ]` |
| 5.26 | `reports/get-reports.usecase.ts` | Add repository; replace PrismaService | `[ ]` |
| 5.27 | `reports/resolve-report.usecase.ts` | Add repository; replace PrismaService | `[ ]` |
| 5.28 | `reviews/create-review.usecase.ts` | Replace PrismaService with repository | `[ ]` |
| 5.29 | `reviews/can-review-order.usecase.ts` | Add repository; replace PrismaService | `[ ]` |
| 5.30 | `reviews/get-user-reviews.usecase.ts` | Replace PrismaService with repository | `[ ]` |
| 5.31 | `social/get-stories.usecase.ts` | Return `Either<AppError, Output>` | `[✓]` |
| 5.32 | `social/get-user-stories.usecase.ts` | Return `Either<AppError, Output>` | `[✓]` |
| 5.33 | `users/user.usecase.ts` | **Split into 10 files** | `[ ]` — migrated to abstract `UserRepository` + Either pattern |
| 5.34 | `users/GetUserStatsUseCase` | Return `Either<AppError, UserStatsResponse>` | `[ ]` |
| 5.35 | `users/SearchUsersUseCase` | Return `Either<AppError, SearchUserResponse[]>` | `[~]` |
| 5.36 | `users/GetSuggestionsUseCase` | Return `Either<AppError, SuggestionResponse[]>` | `[~]` |
| 5.37 | `users/FollowUserUseCase` | Fix `throw error` → `return left(Failures.default(error))` | `[~]` — migrated to abstract `UserRepository` + Either |
| 5.38 | `users/UnfollowUserUseCase` | Fix `throw error` → `return left(Failures.default(error))` | `[~]` — migrated to abstract `UserRepository` + Either |
| 5.39 | `users/BlockUserUseCase` | Fix `throw error` → `return left(Failures.default(error))` | `[~]` — migrated to abstract `UserRepository` + Either |
| 5.40 | `users/UnblockUserUseCase` | Fix `throw error` → `return left(Failures.default(error))` | `[~]` — migrated to abstract `UserRepository` + Either |
| 5.41 | `wallet/wallet.usecase.ts` | **Split into 3 files** | `[ ]` |
| 5.42 | `wallet/GetWalletUseCase` | Return `Either<AppError, GetWalletOutput>` | `[ ]` |
| 5.43 | `wallet/WithdrawUseCase` | Replace PrismaService with repository | `[ ]` |
| 5.44 | `wallet/RegisterBankAccountUseCase` | Replace PrismaService with repository | `[ ]` |

---

## Phase 6: DTO Refactoring (readonly + naming)

| # | DTO File | Fix | Status |
|---|----------|-----|--------|
| 6.1 | `auth/dtos/auth.dto.ts` | Add `readonly` to all properties | `[ ]` |
| 6.2 | `auth/dtos/password-recovery.dto.ts` | Add `readonly` | `[ ]` |
| 6.3 | `cart/dtos/cart.dto.ts` | Add `readonly`; move manual `@Min`/`@Max` validation to DTOs | `[ ]` |
| 6.4 | `chat/dtos/chat.dto.ts` | Add `readonly` | `[ ]` |
| 6.5 | `disputes/dtos/dispute.dto.ts` | Add `readonly` | `[ ]` |
| 6.6 | `favorites/dtos/favorite.dto.ts` | Add `readonly` | `[ ]` |
| 6.7 | `notifications/dtos/notification.dto.ts` | Add `readonly` | `[ ]` |
| 6.8 | `orders/dtos/order.dto.ts` | Add `readonly` | `[ ]` |
| 6.9 | `payments/dtos/payment.dto.ts` | Add `readonly` | `[ ]` |
| 6.10 | `products/dtos/product.dto.ts` | Add `readonly` | `[ ]` |
| 6.11 | `reports/dtos/report.dto.ts` | Add `readonly` | `[ ]` |
| 6.12 | `reviews/dtos/review.dto.ts` | Add `readonly` | `[ ]` |
| 6.13 | `social/dtos/social.dto.ts` | Add `readonly` | `[ ]` |
| 6.14 | `users/dtos/user.dto.ts` | Add `readonly` | `[ ]` |
| 6.15 | `wallet/dtos/wallet.dto.ts` | Add `readonly` | `[ ]` |

---

## Phase 7: Module Wiring Refactoring

| # | Module | Change | Status |
|---|--------|--------|--------|
| 7.1 | `auth/auth.module.ts` | Replace concrete repo providers → import usecase modules; add service | `[~]` |
| 7.2 | `cart/cart.module.ts` | Import CartApiModule | `[✓]` |
| 7.3 | `category/category.module.ts` | Add usecase + service; add domain/data repos | `[ ]` |
| 7.4 | `chat/chat.module.ts` | Add usecase module imports | `[ ]` |
| 7.5 | `disputes/disputes.module.ts` | Add usecase module imports | `[ ]` |
| 7.6 | `favorites/favorites.module.ts` | Add usecase + service; add domain/data repos | `[ ]` |
| 7.7 | `notifications/notifications.module.ts` | Split 3-in-1 usecase file; add service | `[ ]` |
| 7.8 | `orders/orders.module.ts` | Split 6-in-1 usecase file; add usecase modules | `[✓]` |
| 7.9 | `payments/payments.module.ts` | Split 2-in-1 usecase file; add usecase modules | `[ ]` |
| 7.10 | `products/products.module.ts` | Split 3-in-1 usecase file; add usecase modules | `[✓]` |
| 7.11 | `reports/reports.module.ts` | Add usecase module imports | `[ ]` |
| 7.12 | `reviews/reviews.module.ts` | Add usecase module imports | `[ ]` |
| 7.13 | `social/social.module.ts` | Add service; import SocialApiModule | `[✓]` |
| 7.14 | `users/users.module.ts` | Split 10-in-1 usecase file; add usecase modules | `[ ]` |
| 7.15 | `wallet/wallet.module.ts` | Split 3-in-1 usecase file; add usecase modules | `[ ]` |
| 7.16 | `app.module.ts` | Remove redundant provider from app.module | `[ ]` |

---

## Phase 8: Agent Skill Update

| # | Skill | Change | Status |
|---|-------|--------|--------|
| 8.1 | `freebay-backend-module/SKILL.md` | Rewrite to teach Clean Architecture (abstract repos, service layer, domain entities, ResponseEntity, Failure hierarchy, naming conventions, readonly DTOs) | `[ ]` |

---

## Legend

| Symbol | Meaning |
|--------|---------|
| `[ ]` | Pending — not started |
| `[~]` | In progress — agent is actively working |
| `[✓]` | Done — completed and verified |
| `[✗]` | Blocked — cannot proceed due to dependency |
