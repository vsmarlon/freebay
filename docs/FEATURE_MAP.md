# FreeBay Feature Map

> Agent navigation infrastructure. Updated: 2026-09-26.
> This document maps every feature to its implementation across backend, frontend, database, and API.

---

## Quick Reference

| Feature | Backend Module | Frontend Feature | Key Models | Primary Routes |
|---------|---------------|-----------------|------------|----------------|
| **Authentication & Session** | [`nest-backend/src/modules/auth`](#auth) | [`frontend/lib/features/auth`](#auth-1), [`onboarding`](#onboarding) | `User`, `PasswordRecoveryCode`, `WebMagicLink`, `PhoneVerificationCode` | `POST /auth/register`, `POST /auth/login`, `POST /auth/google`, `POST /auth/refresh`, `POST /auth/biometric-login` |
| **Catalog & Products** | [`nest-backend/src/modules/products`](#products), [`category`](#category) | [`frontend/lib/features/product`](#product) | `Product`, `ProductImage`, `Category` | `GET /products`, `GET /products/:id`, `POST /products`, `GET /categories` |
| **Cart & Multi-Vendor Checkout** | [`nest-backend/src/modules/cart`](#cart) | [`frontend/lib/features/cart`](#cart-1) | `CartItem`, `PaymentGroup`, `Order` | `GET /cart`, `POST /cart/:productId`, `POST /cart/checkout`, `PATCH /cart/clear` |
| **Orders & Escrow Lifecycle** | [`nest-backend/src/modules/orders`](#orders) | [`frontend/lib/features/orders`](#orders-1) | `Order`, `Transaction`, `WalletEntry` | `POST /orders`, `GET /orders/:id`, `PATCH /orders/:id/ship`, `PATCH /orders/:id/confirm` |
| **Payments & Stripe Connect** | [`nest-backend/src/modules/payments`](#payments) | [`frontend/lib/features/payments`](#payments-1) | `Transaction`, `PaymentGroup`, `ConnectAccount` | `POST /payments/connect/onboarding`, `POST /payments/checkout/:orderId`, `POST /payments/payment-intent/:orderId`, `POST /payments/webhook` |
| **Wallet & Balances** | [`nest-backend/src/modules/wallet`](#wallet) | [`frontend/lib/features/wallet`](#wallet-1) | `Wallet`, `WalletEntry` | `GET /wallet`, `GET /wallet/transactions` |
| **Social Feed, Posts & Engagement** | [`nest-backend/src/modules/social`](#social) | [`frontend/lib/features/social`](#social-1) | `Post`, `PostMention`, `Comment`, `CommentMention`, `Like`, `CommentLike`, `Share`, `SavedPost` | `GET /social/feed`, `POST /social/posts`, `POST /social/posts/:id/like`, `POST /social/posts/:id/comments` |
| **Stories & Highlights** | [`nest-backend/src/modules/stories`](#stories) | [`frontend/lib/features/social`](#social-1) | `Story`, `StoryView`, `StoryHighlight`, `StoryHighlightItem` | `GET /stories`, `POST /stories`, `POST /stories/highlights`, `POST /stories/:id/view` |
| **Chat & Direct Messaging** | [`nest-backend/src/modules/chat`](#chat) | [`frontend/lib/features/chat`](#chat-1) | `DirectConversation`, `DirectMessage`, `ChatMessage`, `ConversationPreference`, `MessageReaction`, `StarredMessage` | `GET /chat/conversations`, `POST /chat/conversations`, WS `/chat` |
| **Reviews & Reputation** | [`nest-backend/src/modules/reviews`](#reviews) | [`frontend/lib/features/reviews`](#reviews-1) | `Review`, `ReviewImage` | `POST /reviews/orders/:orderId`, `GET /reviews/users/:userId`, `GET /reviews/orders/:orderId/can-review` |
| **Favorites** | [`nest-backend/src/modules/favorites`](#favorites) | [`frontend/lib/features/favorites`](#favorites-1) | `Favorite` | `GET /favorites`, `POST /favorites/:productId`, `GET /favorites/check/:productId` |
| **Disputes & Conflict Resolution** | [`nest-backend/src/modules/disputes`](#disputes) | [`frontend/lib/features/dispute`](#dispute) | `Dispute` | `POST /disputes`, `GET /disputes`, `GET /disputes/:id`, `POST /disputes/:id/evidence`, `PATCH /disputes/:id/withdraw`, `PATCH /disputes/:id/resolve` |
| **Notifications** | [`nest-backend/src/modules/notifications`](#notifications) | [`frontend/lib/features/notifications`](#notifications-1) | `Notification` | `GET /notifications`, `POST /notifications/read-all`, `POST /notifications/fcm-token`, WS `/notifications` |
| **User Profiles, Follows & Blocks** | [`nest-backend/src/modules/users`](#users) | [`frontend/lib/features/profile`](#profile-1) | `User`, `Follow`, `Block` | `GET /users/:id`, `GET /users/me`, `PATCH /users/me`, `POST /users/:id/follow`, `POST /users/:id/block` |
| **Reports & Moderation** | [`nest-backend/src/modules/reports`](#reports), [`admin`](#admin) | Modal reporting sheets | `Report`, `ModerationAction` | `POST /reports`, `GET /admin/reports`, `PATCH /admin/reports/:id/resolve`, `POST /admin/users/:id/suspend` |
| **Bug Reports** | [`nest-backend/src/modules/bug-reports`](#bug-reports) | [`frontend/lib/features/bug_report`](#bug_report) | `BugReport` | `POST /bug-reports` |
| **Media Uploads & Storage** | [`nest-backend/src/modules/upload`](#upload), [`media`](#media) | Shared media helpers | Local Disk / S3 Storage | `POST /uploads`, `GET /media/:context/:filename` |
| **System Health** | [`nest-backend/src/modules/health`](#health) | (Infrastructure) | (None) | `GET /health`, `GET /health/ready` |
| **Background Automation** | [`nest-backend/src/modules/tasks`](#tasks) | (Infrastructure) | `Order`, `Transaction`, `Dispute`, `Story`, `WebMagicLink` | Scheduled cron jobs |

---

## Backend Modules

### `admin`
- **Path**: `nest-backend/src/modules/admin/`
- **Controllers**:
  - `AdminController` (`nest-backend/src/modules/admin/admin.controller.ts`) — Prefix: `admin`
    - `GET /admin/reports` `[Admin]` -> `listReports` (List paginated reports for moderation)
    - `PATCH /admin/reports/:id/resolve` `[Admin]` -> `resolveReport` (Resolve report with decision note)
    - `POST /admin/users/:id/suspend` `[Admin]` -> `suspendUser` (Suspend user account and revoke sessions)
    - `PATCH /admin/users/:id/unsuspend` `[Admin]` -> `unsuspendUser` (Lift user account suspension)
    - `DELETE /admin/products/:id` `[Admin]` -> `removeProduct` (Take down a product listing)
    - `DELETE /admin/posts/:id` `[Admin]` -> `removePost` (Take down a post)
    - `DELETE /admin/comments/:id` `[Admin]` -> `removeComment` (Take down a comment)
    - `GET /admin/moderation-actions` `[Admin]` -> `listModerationActions` (List moderation audit trail)
    - `GET /admin/transfer-failures` `[Admin]` -> `listTransferFailures` (List Connect transfer & reversal failures)
- **Use Cases**:
  - `nest-backend/src/modules/admin/usecases/list-reports.usecase.ts`
  - `nest-backend/src/modules/admin/usecases/resolve-report.usecase.ts`
  - `nest-backend/src/modules/admin/usecases/suspend-user.usecase.ts`
  - `nest-backend/src/modules/admin/usecases/remove-content.usecase.ts`
  - `nest-backend/src/modules/admin/usecases/list-moderation-actions.usecase.ts`
  - `nest-backend/src/modules/admin/usecases/list-transfer-failures.usecase.ts`
- **Repositories**:
  - `nest-backend/src/modules/admin/data/repositories/moderation-database.repository.ts`
- **Key DTOs / Types**:
  - `AdminReportQueryDTO`, `ResolveReportDTO`, `SuspendUserDTO`, `ModerationReasonDTO` (`admin.dto.ts`)
  - `AdminReportPageResponse`, `ModerationActionPageResponse` (`dtos/admin-response.class.ts`)

### `auth`
- **Path**: `nest-backend/src/modules/auth/`
- **Controllers**:
  - `AuthController` (`nest-backend/src/modules/auth/auth.controller.ts`) — Prefix: `auth`
    - `POST /auth/register` `[Public]` -> `register` (Register new user with email & password)
    - `GET /auth/username-available` `[Public]` -> `usernameAvailable` (Check availability of username)
    - `POST /auth/login` `[Public]` -> `login` (Authenticate with email & password)
    - `POST /auth/google` `[Public]` -> `googleAuth` (Authenticate via Google ID token)
    - `POST /auth/complete-profile` `[Auth]` -> `completeProfile` (Set initial username & profile details)
    - `POST /auth/refresh` `[Auth]` -> `refresh` (Rotate refresh token and issue new access token)
    - `POST /auth/logout` `[Auth]` -> `logout` (Revoke current session and blacklist tokens in Redis)
    - `POST /auth/forgot-password` `[Public]` -> `forgotPassword` (Request 6-digit recovery code)
    - `POST /auth/verify-reset-code` `[Public]` -> `verifyResetCode` (Verify 6-digit recovery code)
    - `POST /auth/reset-password` `[Public]` -> `resetPassword` (Reset password using verified token)
    - `POST /auth/biometric-login` `[Public]` -> `biometricLogin` (Authenticate with encrypted biometric token)
    - `POST /auth/biometric-token/enroll` `[Auth]` -> `enrollBiometricToken` (Issue new biometric token)
    - `PATCH /auth/biometric-token/revoke` `[Auth]` -> `revokeBiometricToken` (Revoke biometric token)
  - `AuthWebSessionController` (`nest-backend/src/modules/auth/auth-web-session.controller.ts`) — Prefix: `auth`
    - `POST /auth/web/magic-link/request` `[Public]` -> `requestWebMagicLink` (Request passwordless magic link)
    - `POST /auth/web/magic-link/consume` `[Public]` -> `consumeWebMagicLink` (Consume magic link & set HttpOnly cookies)
    - `POST /auth/web/session/refresh` `[Auth]` -> `refreshWebSession` (Refresh web session cookies)
    - `POST /auth/web/session/logout` `[Auth]` -> `logoutWebSession` (Clear web session cookies & revoke session)
- **Use Cases**:
  - `register.usecase.ts`, `login.usecase.ts`, `google-auth.usecase.ts`, `complete-profile.usecase.ts`
  - `refresh-mobile-session.usecase.ts`, `logout-session.usecase.ts`, `check-username-availability.usecase.ts`
  - `request-password-recovery.usecase.ts`, `verify-password-recovery-code.usecase.ts`, `reset-password.usecase.ts`
  - `biometric-login.usecase.ts`, `enroll-biometric.usecase.ts`, `revoke-biometric.usecase.ts`
  - `request-magic-link.usecase.ts`, `consume-magic-link.usecase.ts`, `refresh-web-session.usecase.ts`, `logout-web-session.usecase.ts`
- **Repositories**:
  - `nest-backend/src/modules/auth/data/repositories/user-database.repository.ts`
  - `nest-backend/src/modules/auth/data/repositories/password-recovery-database.repository.ts`
  - `nest-backend/src/modules/auth/data/repositories/magic-link-database.repository.ts`
  - `nest-backend/src/modules/auth/domain/repositories/magic-link.repository.ts`
- **Key DTOs / Types**:
  - `RegisterDTO`, `LoginDTO`, `GoogleAuthDTO`, `CompleteProfileDTO`, `BiometricLoginDTO` (`auth.dto.ts`)
  - `RequestPasswordRecoveryDTO`, `VerifyPasswordRecoveryCodeDTO`, `ResetPasswordDTO` (`password-recovery.dto.ts`)
  - `RequestMagicLinkDTO`, `ConsumeMagicLinkDTO` (`magic-link.dto.ts`)
  - `AuthSessionResponse`, `TokenRefreshResponse`, `BiometricSessionResponse` (`auth-response.class.ts`)

### `bug-reports`
- **Path**: `nest-backend/src/modules/bug-reports/`
- **Controllers**:
  - `BugReportController` (`nest-backend/src/modules/bug-reports/bug-report.controller.ts`) — Prefix: `bug-reports`
    - `POST /bug-reports` `[Auth]` -> `create` (Submit user bug report with device context)
- **Use Cases**:
  - `nest-backend/src/modules/bug-reports/usecases/create-bug-report.usecase.ts`
- **Repositories**:
  - `nest-backend/src/modules/bug-reports/data/repositories/bug-report-database.repository.ts`
- **Key DTOs / Types**:
  - `CreateBugReportDTO`, `BugReportResponseDTO` (`bug-report.dto.ts`)

### `cart`
- **Path**: `nest-backend/src/modules/cart/`
- **Controllers**:
  - `CartController` (`nest-backend/src/modules/cart/cart.controller.ts`) — Prefix: `cart`
    - `GET /cart` `[Auth]` -> `getCart` (Retrieve active cart items and totals)
    - `POST /cart/:productId` `[Auth]` -> `addToCart` (Add item or increment quantity)
    - `PATCH /cart/:productId` `[Auth]` -> `updateCartItem` (Update item quantity)
    - `PATCH /cart/:productId/remove` `[Auth]` -> `removeFromCart` (Remove single item from cart)
    - `PATCH /cart/clear` `[Auth]` -> `clearCart` (Empty entire cart)
    - `POST /cart/checkout` `[Auth]` -> `checkout` (Validate cart, create multi-seller orders & payment group)
- **Use Cases**:
  - `get-cart.usecase.ts`, `add-to-cart.usecase.ts`, `update-cart-item.usecase.ts`
  - `remove-from-cart.usecase.ts`, `clear-cart.usecase.ts`, `checkout-cart.usecase.ts`
- **Repositories**:
  - `nest-backend/src/modules/cart/data/repositories/cart-database.repository.ts`
- **Key DTOs / Types**:
  - `AddToCartDTO`, `UpdateCartItemDTO`, `CheckoutCartDTO`, `CartResponseDTO` (`cart.dto.ts`)

### `category`
- **Path**: `nest-backend/src/modules/category/`
- **Controllers**:
  - `CategoryController` (`nest-backend/src/modules/category/category.controller.ts`) — Prefix: `categories`
    - `GET /categories` `[Public]` -> `findAll` (List category hierarchy)
    - `GET /categories/:id` `[Public]` -> `findOne` (Get category details by UUID)
- **Use Cases**:
  - `list-categories.usecase.ts`, `get-category.usecase.ts`
- **Repositories**:
  - `nest-backend/src/modules/category/data/repositories/category-database.repository.ts`
- **Key DTOs / Types**:
  - `CategoryDTO`, `CategoryTreeResponse`

### `chat`
- **Path**: `nest-backend/src/modules/chat/`
- **Controllers**:
  - `ChatController` (`nest-backend/src/modules/chat/chat.controller.ts`) — Prefix: `chat`
    - `GET /chat/conversations` `[Auth]` -> `getConversations` (Unified conversations: direct & order)
    - `GET /chat/direct` `[Auth]` -> `getDirectConversations` (Direct conversations only)
    - `GET /chat/archived` `[Auth]` -> `getArchivedConversations` (Archived conversations)
    - `POST /chat/conversations` `[Auth]` -> `startConversation` (Start new direct conversation)
    - `POST /chat/conversations/:id/accept` `[Auth]` -> `acceptConversation` (Accept pending conversation)
    - `GET /chat/conversations/:id` `[Auth]` -> `getConversation` (Get conversation details & other participant)
    - `GET /chat/conversations/:id/messages` `[Auth]` -> `getFilteredMessages` (Paginated message history)
    - `POST /chat/conversations/:id/messages` `[Auth]` -> `sendMessage` (Send text, media, or product message)
    - `PATCH /chat/conversations/:id/archive` `[Auth]` -> `archiveConversation` (Archive/unarchive conversation)
    - `PATCH /chat/conversations/:id/delete` `[Auth]` -> `deleteConversation` (Soft-delete conversation for user)
    - `PATCH /chat/conversations/:id/read` `[Auth]` -> `markAsRead` (Mark incoming messages as read)
    - `PATCH /chat/conversations/:id/theme` `[Auth]` -> `setTheme` (Update conversation color theme)
    - `PATCH /chat/conversations/:id/background` `[Auth]` -> `setBackground` (Set conversation custom background)
    - `PATCH /chat/conversations/:convId/messages/:msgId/delete` `[Auth]` -> `deleteMessage` (Delete a specific message)
    - `POST /chat/conversations/:convId/messages/:msgId/react` `[Auth]` -> `reactToMessage` (Toggle emoji reaction)
    - `POST /chat/conversations/:convId/messages/:msgId/star` `[Auth]` -> `toggleStar` (Star/unstar message)
    - `GET /chat/conversations/:id/starred` `[Auth]` -> `getStarredMessages` (List starred messages in conversation)
    - `POST /chat/security/verify-url` `[Auth]` -> `verifyUrl` (Verify link safety before opening)
    - `POST /chat/messages/forward` `[Auth]` -> `forwardMessages` (Forward selected messages to conversation)
- **WebSockets Gateway**:
  - `ChatGateway` (`nest-backend/src/modules/chat/chat.gateway.ts`) — Namespace: `/chat`
    - Subscribed: `join_conversation`, `leave_conversation`, `send_message`, `typing`, `typing_stop`, `delete_message`, `toggle_reaction`
    - Emitted: `user_online`, `user_offline`, `joined`, `left`, `new_message`, `user_typing`, `user_stopped_typing`, `message_deleted`, `reaction_updated`
- **Use Cases**:
  - `start-conversation.usecase.ts`, `accept-conversation.usecase.ts`, `get-conversations.usecase.ts`, `get-unified-conversations.usecase.ts`
  - `get-messages.usecase.ts`, `send-message.usecase.ts`, `delete-message.usecase.ts`, `mark-as-read.usecase.ts`
  - `archive-conversation.usecase.ts`, `delete-conversation.usecase.ts`, `set-conversation-theme.usecase.ts`
  - `set-conversation-background.usecase.ts`, `toggle-reaction.usecase.ts`, `toggle-star.usecase.ts`, `get-starred-messages.usecase.ts`
  - `verify-url-safety.usecase.ts`, `forward-messages.usecase.ts`, `get-conversation-media.usecase.ts`
- **Repositories**:
  - `nest-backend/src/modules/chat/data/repositories/conversation-database.repository.ts`
  - `nest-backend/src/modules/chat/data/repositories/conversation-preference-database.repository.ts`
- **Key DTOs / Types**:
  - `StartConversationDTO`, `SendMessageDTO`, `ForwardMessagesDTO`, `SetThemeDTO`, `SetBackgroundDTO`, `VerifyUrlDTO` (`chat.dto.ts`)

### `disputes`
- **Path**: `nest-backend/src/modules/disputes/`
- **Controllers**:
  - `DisputesController` (`nest-backend/src/modules/disputes/disputes.controller.ts`) — Prefix: `disputes`
    - `POST /disputes` `[Auth]` -> `create` (Open dispute for an order)
    - `GET /disputes` `[Auth]` -> `findAll` (Get all disputes involving the user)
    - `GET /disputes/:id` `[Auth]` -> `findOne` (Get single dispute details & evidence)
    - `POST /disputes/:id/evidence` `[Auth]` -> `submitEvidence` (Attach evidence JSON payload)
    - `PATCH /disputes/:id/withdraw` `[Auth]` -> `withdraw` (Buyer cancels/withdraws dispute)
    - `PATCH /disputes/:id/resolve` `[Admin]` -> `resolve` (Admin resolution: release to seller or refund buyer)
- **Use Cases**:
  - `open-dispute.usecase.ts`, `get-user-disputes.usecase.ts`, `get-dispute.usecase.ts`
  - `submit-evidence.usecase.ts`, `resolve-dispute.usecase.ts`, `withdraw-dispute.usecase.ts`
- **Repositories**:
  - `nest-backend/src/modules/disputes/data/repositories/dispute-database.repository.ts`
- **Key DTOs / Types**:
  - `OpenDisputeDTO`, `ResolveDisputeDTO`, `OpenDisputeOutput` (`dispute.dto.ts`)

### `favorites`
- **Path**: `nest-backend/src/modules/favorites/`
- **Controllers**:
  - `FavoritesController` (`nest-backend/src/modules/favorites/favorites.controller.ts`) — Prefix: `favorites`
    - `GET /favorites` `[Auth]` -> `getFavorites` (Get user favorited products)
    - `GET /favorites/check/:productId` `[Auth]` -> `checkFavorite` (Check if product is favorited)
    - `POST /favorites/:productId` `[Auth]` -> `toggleFavorite` (Toggle favorite status)
- **Use Cases**:
  - `get-favorites.usecase.ts`, `check-favorite.usecase.ts`, `toggle-favorite.usecase.ts`
- **Repositories**:
  - `nest-backend/src/modules/favorites/data/repositories/favorite-database.repository.ts`
- **Key DTOs / Types**:
  - `FavoriteResponseDTO`, `CheckFavoriteDTO` (`favorite.dto.ts`)

### `health`
- **Path**: `nest-backend/src/modules/health/`
- **Controllers**:
  - `HealthController` (`nest-backend/src/modules/health/health.controller.ts`) — Prefix: `health`
    - `GET /health` `[Public]` -> `check` (Liveness probe: uptime, memory, system info)
    - `GET /health/ready` `[Public]` -> `readiness` (Readiness probe: database & Redis ping)

### `media`
- **Path**: `nest-backend/src/modules/media/`
- **Controllers**:
  - `MediaController` (`nest-backend/src/modules/media/media.controller.ts`) — Prefix: `media`
    - `GET /media/:context/:filename` `[Auth]` -> `serve` (Stream uploaded media files with security headers & caching)

### `notifications`
- **Path**: `nest-backend/src/modules/notifications/`
- **Controllers**:
  - `NotificationsController` (`nest-backend/src/modules/notifications/notifications.controller.ts`) — Prefix: `notifications`
    - `GET /notifications` `[Auth]` -> `findAll` (List paginated notifications)
    - `GET /notifications/unread-count` `[Auth]` -> `countUnread` (Get unread notifications count)
    - `POST /notifications/read-all` `[Auth]` -> `markAllAsRead` (Mark all notifications as read)
    - `PATCH /notifications/:id/read` `[Auth]` -> `markAsRead` (Mark single notification as read)
    - `POST /notifications/fcm-token` `[Auth]` -> `registerFcmToken` (Register Firebase Cloud Messaging device token)
- **WebSockets Gateway**:
  - `NotificationsGateway` (`nest-backend/src/modules/notifications/notifications.gateway.ts`) — Namespace: `/notifications`
    - Subscribed: `mark_read`
    - Emitted: `notification`
- **Use Cases**:
  - `get-notifications.usecase.ts`, `mark-as-read.usecase.ts`, `mark-all-as-read.usecase.ts`, `register-fcm-token.usecase.ts`
- **Repositories**:
  - `nest-backend/src/modules/notifications/data/repositories/notification-database.repository.ts`
- **Key DTOs / Types**:
  - `RegisterFcmTokenDTO`, `NotificationResponseDTO` (`notification.dto.ts`)

### `orders`
- **Path**: `nest-backend/src/modules/orders/`
- **Controllers**:
  - `OrdersController` (`nest-backend/src/modules/orders/orders.controller.ts`) — Prefix: `orders`
    - `POST /orders` `[Auth]` -> `create` (Create order, reserve inventory & calculate escrow fee)
    - `GET /orders` `[Auth]` -> `findAll` (List user orders)
    - `GET /orders/my/purchases` `[Auth]` -> `getMyPurchases` (List user buyer orders)
    - `GET /orders/my/sales` `[Auth]` -> `getMySales` (List user seller orders)
    - `GET /orders/:id` `[Auth]` -> `findOne` (Get detailed order info, status & transaction)
    - `PATCH /orders/:id/ship` `[Auth]` -> `markAsShipped` (Seller marks order as shipped)
    - `PATCH /orders/:id/deliver` `[Auth]` -> `markAsDelivered` (Seller marks order as delivered to meeting point)
    - `PATCH /orders/:id/confirm` `[Auth]` -> `confirmDelivery` (Buyer confirms receipt -> triggers escrow release)
    - `PATCH /orders/:id/confirm-delivery` `[Auth]` -> `confirmDeliveryAlias` (Alias for receipt confirmation)
    - `PATCH /orders/:id/cancel` `[Auth]` -> `cancel` (Cancel order before shipment)
- **Use Cases**:
  - `create-order.usecase.ts`, `get-order.usecase.ts`, `list-sales-orders.usecase.ts`
  - `mark-as-shipped.usecase.ts`, `mark-as-delivered.usecase.ts`, `confirm-delivery.usecase.ts`, `cancel-order.usecase.ts`
- **Repositories**:
  - `nest-backend/src/modules/orders/data/repositories/order-database.repository.ts`
  - `nest-backend/src/modules/orders/data/repositories/order-read.repository.ts`
  - `nest-backend/src/modules/orders/data/repositories/order-mutation.repository.ts`
  - `nest-backend/src/modules/orders/data/repositories/order-reservation.repository.ts`
- **Key DTOs / Types**:
  - `CreateOrderDTO`, `CancelOrderDTO`, `OrderResponseDTO` (`order.dto.ts`)

### `payments`
- **Path**: `nest-backend/src/modules/payments/`
- **Controllers**:
  - `PaymentsController` (`nest-backend/src/modules/payments/payments.controller.ts`) — Prefix: `payments`
    - `POST /payments/connect/onboarding` `[Auth]` -> `startConnectOnboarding` (Create Stripe Connect Express onboarding link)
    - `GET /payments/connect/status` `[Auth]` -> `getConnectStatus` (Check payouts/transfers status)
    - `POST /payments/connect/dashboard` `[Auth]` -> `getConnectDashboardLink` (Generate Stripe Express dashboard login link)
    - `POST /payments/checkout/:orderId` `[Auth]` -> `createPaymentSession` (Web: Create Stripe Checkout Session URL)
    - `POST /payments/payment-intent/:orderId` `[Auth]` -> `createPaymentIntent` (Mobile: Create Stripe PaymentIntent clientSecret)
    - `POST /payments/webhook` `[StripeWebhook]` -> `handleWebhook` (Process Stripe webhook events: charges, payments, transfers)
- **Use Cases**:
  - `create-payment-intent.usecase.ts`, `create-payment-session.usecase.ts`, `process-webhook.usecase.ts`, `process-group-webhook.usecase.ts`
  - `process-refund.usecase.ts`, `start-connect-onboarding.usecase.ts`, `get-connect-status.usecase.ts`, `get-connect-dashboard-link.usecase.ts`
  - `sync-connect-account.usecase.ts`, `recover-dispute-transfer.usecase.ts`, `expire-checkout-group.usecase.ts`
- **Repositories**:
  - `nest-backend/src/modules/payments/data/repositories/transaction-database.repository.ts`
  - `nest-backend/src/modules/payments/data/repositories/payment-group-database.repository.ts`
  - `nest-backend/src/modules/payments/data/repositories/connect-account-database.repository.ts`
  - `nest-backend/src/modules/payments/data/repositories/transaction-reconciliation.repository.ts`
  - `nest-backend/src/modules/payments/data/repositories/transaction-guarded-claims.repository.ts`
  - `nest-backend/src/modules/payments/data/repositories/transaction-upsert.repository.ts`
- **Key DTOs / Types**:
  - `CreatePaymentSessionDTO`, `PaymentIntentResponseDTO`, `PaymentSessionResponseDTO` (`payment.dto.ts`)
  - `ConnectOnboardingDTO`, `ConnectStatusResponseDTO` (`connect.dto.ts`)

### `products`
- **Path**: `nest-backend/src/modules/products/`
- **Controllers**:
  - `ProductsController` (`nest-backend/src/modules/products/products.controller.ts`) — Prefix: `products`
    - `GET /products` `[Public]` -> `findAll` (Search/filter active products with pagination)
    - `GET /products/mine/all` `[Auth]` -> `findMyProducts` (List authenticated seller's products)
    - `GET /products/:id` `[Public]` -> `findOne` (Get detailed product with images & seller info)
    - `POST /products` `[Auth]` -> `create` (Multipart: Create product listing with uploaded image)
    - `PATCH /products/:id` `[Auth]` -> `update` (Update product details, condition, price, quantity)
    - `PATCH /products/:id/delete` `[Auth]` -> `delete` (Soft-delete product listing)
- **Use Cases**:
  - `create-product.usecase.ts`, `get-products.usecase.ts`, `get-product-by-id.usecase.ts`
  - `get-my-products.usecase.ts`, `update-product.usecase.ts`, `delete-product.usecase.ts`
- **Repositories**:
  - `nest-backend/src/modules/products/data/repositories/product-database.repository.ts`
- **Key DTOs / Types**:
  - `CreateProductDTO`, `UpdateProductDTO`, `ProductQueryDTO`, `ProductResponseDTO` (`product.dto.ts`)

### `reports`
- **Path**: `nest-backend/src/modules/reports/`
- **Controllers**:
  - `ReportsController` (`nest-backend/src/modules/reports/reports.controller.ts`) — Prefix: `reports`
    - `POST /reports` `[Auth]` -> `create` (Submit abuse report for user, post, message, or conversation)
- **Use Cases**:
  - `create-report.usecase.ts`
- **Repositories**:
  - `nest-backend/src/modules/reports/data/repositories/report-database.repository.ts`
- **Key DTOs / Types**:
  - `CreateReportDTO`, `ReportResponseDTO` (`report.dto.ts`, `report.types.ts`)

### `reviews`
- **Path**: `nest-backend/src/modules/reviews/`
- **Controllers**:
  - `ReviewsController` (`nest-backend/src/modules/reviews/reviews.controller.ts`) — Prefix: `reviews`
    - `POST /reviews/orders/:orderId` `[Auth]` -> `create` (Submit review for completed order)
    - `POST /reviews/orders/:orderId/images` `[Auth]` -> `uploadImage` (Upload proof/photo for review)
    - `GET /reviews/users/:userId` `[Public]` -> `getUserReviews` (Get public reviews received by user)
    - `GET /reviews/orders/:orderId/can-review` `[Auth]` -> `canReviewOrder` (Verify review eligibility)
- **Use Cases**:
  - `create-review.usecase.ts`, `get-user-reviews.usecase.ts`, `can-review-order.usecase.ts`
- **Repositories**:
  - `nest-backend/src/modules/reviews/data/repositories/review-database.repository.ts`
- **Key DTOs / Types**:
  - `CreateReviewInput`, `CreateReviewDTO`, `CanReviewOrderDTO` (`create-review.dto.ts`)

### `social`
- **Path**: `nest-backend/src/modules/social/`
- **Controllers**:
  - `SocialReadController` (`nest-backend/src/modules/social/social-read.controller.ts`) — Prefix: `social`
    - `GET /social/feed` `[Public]` -> `getFeed` (Home social feed with pagination)
    - `GET /social/posts/search` `[Public]` -> `searchPosts` (Search posts by query)
    - `GET /social/posts/liked` `[Auth]` -> `getLikedPosts` (Posts liked by current user)
    - `GET /social/posts/saved` `[Auth]` -> `getSavedPosts` (Posts bookmarked by current user)
    - `GET /social/posts/user/:userId/timeline` `[Public]` -> `getProfileTimeline` (User profile social timeline)
    - `GET /social/posts/user/:userId` `[Public]` -> `getUserPosts` (Posts authored by specific user)
    - `GET /social/posts/user/:userId/reposts` `[Public]` -> `getUserReposts` (Posts shared by specific user)
    - `GET /social/posts/:id` `[Public]` -> `getPost` (Get single post by ID)
    - `GET /social/posts/:id/comments` `[Public]` -> `getComments` (Get comment tree for post)
  - `SocialWriteController` (`nest-backend/src/modules/social/social-write.controller.ts`) — Prefix: `social`
    - `POST /social/posts` `[Auth]` -> `createPost` (Multipart: Create post with optional image upload)
    - `PATCH /social/posts/:id/delete` `[Auth]` -> `deletePost` (Soft-delete post)
    - `POST /social/posts/:id/like` `[Auth]` -> `likePost` (Like post)
    - `PATCH /social/posts/:id/unlike` `[Auth]` -> `unlikePost` (Unlike post)
    - `POST /social/posts/:id/share` `[Auth]` -> `sharePost` (Repost/share post)
    - `PATCH /social/posts/:id/unshare` `[Auth]` -> `unsharePost` (Remove repost)
    - `POST /social/posts/:id/save` `[Auth]` -> `savePost` (Bookmark/save post)
    - `PATCH /social/posts/:id/unsave` `[Auth]` -> `unsavePost` (Remove bookmark)
    - `POST /social/posts/:id/comments` `[Auth]` -> `createComment` (Add comment to post)
    - `PATCH /social/comments/:id/delete` `[Auth]` -> `deleteComment` (Soft-delete comment)
    - `POST /social/comments/:commentId/like` `[Auth]` -> `likeComment` (Like comment)
    - `PATCH /social/comments/:commentId/unlike` `[Auth]` -> `unlikeComment` (Unlike comment)
- **Use Cases**:
  - `get-feed.usecase.ts`, `create-post.usecase.ts`, `delete-post.usecase.ts`, `get-post.usecase.ts`, `search-posts.usecase.ts`
  - `like-post.usecase.ts`, `unlike-post.usecase.ts`, `share-post.usecase.ts`, `unshare-post.usecase.ts`, `save-post.usecase.ts`, `unsave-post.usecase.ts`
  - `comment.usecase.ts`, `get-comments.usecase.ts`, `delete-comment.usecase.ts`, `like-comment.usecase.ts`, `unlike-comment.usecase.ts`
  - `get-profile-timeline.usecase.ts`, `get-user-posts.usecase.ts`, `get-user-reposts.usecase.ts`, `get-liked-posts.usecase.ts`, `get-saved-posts.usecase.ts`
- **Repositories**:
  - `nest-backend/src/modules/social/data/repositories/post-database.repository.ts`
  - `nest-backend/src/modules/social/data/repositories/comment-database.repository.ts`
  - `nest-backend/src/modules/social/data/repositories/like-database.repository.ts`
  - `nest-backend/src/modules/social/data/repositories/share-database.repository.ts`
  - `nest-backend/src/modules/social/data/repositories/saved-post-database.repository.ts`
- **Key DTOs / Types**:
  - `CreatePostDTO`, `CommentDTO`, `FeedQueryDTO`, `PostResponseDTO` (`social.dto.ts`)

### `stories`
- **Path**: `nest-backend/src/modules/stories/`
- **Controllers**:
  - `StoriesController` (`nest-backend/src/modules/stories/stories.controller.ts`) — Prefix: `stories`
    - `GET /stories` `[Auth]` -> `getFeed` (Active 24h stories feed grouped by user)
    - `GET /stories/user/:userId` `[Auth]` -> `getUserStories` (Active stories for specific user)
    - `GET /stories/archive` `[Auth]` -> `getArchive` (Authenticated user's historical archived stories)
    - `POST /stories` `[Auth]` -> `createStory` (Upload photo/video story with overlay text blocks)
    - `PATCH /stories/:id/delete` `[Auth]` -> `deleteStory` (Soft-delete story)
    - `POST /stories/:id/view` `[Auth]` -> `viewStory` (Register story view)
    - `GET /stories/highlights/user/:userId` `[Auth]` -> `getHighlights` (Get user's profile highlights)
    - `GET /stories/highlights/:id` `[Auth]` -> `getHighlight` (Get highlight by ID with story items)
    - `POST /stories/highlights` `[Auth]` -> `createHighlight` (Create permanent highlight collection)
    - `PATCH /stories/highlights/:id` `[Auth]` -> `updateHighlight` (Edit highlight title/cover)
    - `PATCH /stories/highlights/:id/delete` `[Auth]` -> `deleteHighlight` (Delete highlight)
- **Use Cases**:
  - `get-stories.usecase.ts`, `get-user-stories.usecase.ts`, `create-story.usecase.ts`, `delete-story.usecase.ts`, `view-story.usecase.ts`
  - `save-story-highlight.usecase.ts`, `delete-story-highlight.usecase.ts`
- **Repositories**:
  - `nest-backend/src/modules/stories/data/repositories/story-database.repository.ts`
  - `nest-backend/src/modules/stories/data/repositories/story-highlight-database.repository.ts`
- **Key DTOs / Types**:
  - `CreateStoryMultipartDTO`, `CreateHighlightDTO`, `StoryFeedResponseDTO` (`stories.dto.ts`)

### `tasks` (Background Cron Jobs)
- **Path**: `nest-backend/src/modules/tasks/`
- **Scheduled Tasks**:
  - `AccountDeletionTask` (`account-deletion.task.ts`) — Daily: Permanently deletes accounts whose 30-day grace period expired.
  - `CheckoutExpiryTask` (`checkout-expiry.task.ts`) — Every 5 min: Cancels stale checkout sessions & unlocks product quantities.
  - `DisputeCleanupTask` (`dispute-cleanup.task.ts`) — Hourly: Automatically escalates or closes expired disputes.
  - `EscrowReleaseTask` (`escrow-release.task.ts`) — Every 15 min: Auto-releases escrow funds to seller 48h after delivery confirmation.
  - `MagicLinkCleanupTask` (`magic-link-cleanup.task.ts`) — Hourly: Cleans up expired magic links and phone verification codes.
  - `StoryCleanupTask` (`story-cleanup.task.ts`) — Every 15 min: Archives stories older than 24 hours.
  - `TransferReconciliationTask` (`transfer-reconciliation.task.ts`) — Every 10 min: Retries pending/failed Stripe Connect seller payouts and reversals.

### `upload`
- **Path**: `nest-backend/src/modules/upload/`
- **Controllers**:
  - `UploadController` (`nest-backend/src/modules/upload/upload.controller.ts`) — Prefix: `uploads`
    - `POST /uploads` `[Auth]` -> `upload` (Upload image, audio, video; validates context: `chat`, `background`, `post`, `avatar`)

### `users`
- **Path**: `nest-backend/src/modules/users/`
- **Controllers**:
  - `UsersAccountController` (`nest-backend/src/modules/users/users-account.controller.ts`) — Prefix: `users`
    - `GET /users/me` `[Auth]` -> `getMe` (Get profile of authenticated user)
    - `GET /users/me/stats` `[Auth]` -> `getMyStats` (Follower, following, post, and sales counts)
    - `GET /users/me/export` `[Auth]` -> `exportMyData` (Export GDPR/LGPD user data)
    - `DELETE /users/me` `[Auth]` -> `requestAccountDeletion` (Initiate 30-day account deletion grace period)
    - `PATCH /users/me/deletion/cancel` `[Auth]` -> `cancelAccountDeletion` (Cancel pending account deletion)
    - `PATCH /users/me` `[Auth]` -> `updateProfile` (Update displayName, bio, city, state)
    - `POST /users/me/avatar` `[Auth]` -> `uploadAvatar` (Upload profile avatar image)
    - `POST /users/me/banner` `[Auth]` -> `uploadBanner` (Upload profile header banner)
    - `POST /users/me/phone` `[Auth]` -> `registerPhone` (Submit phone number for verification)
    - `POST /users/me/phone/verify` `[Auth]` -> `verifyPhone` (Verify phone number with SMS code)
    - `PATCH /users/me/fcm-token` `[Auth]` -> `updateFcmToken` (Register/update FCM push token)
  - `UsersDiscoveryController` (`nest-backend/src/modules/users/users-discovery.controller.ts`) — Prefix: `users`
    - `GET /users/search` `[Auth]` -> `searchUsers` (Search users by displayName/username)
    - `GET /users/suggestions` `[Auth]` -> `getSuggestions` (Suggested users to follow)
    - `GET /users/blocked` `[Auth]` -> `getBlockedUsers` (List blocked users)
  - `UsersSocialController` (`nest-backend/src/modules/users/users-social.controller.ts`) — Prefix: `users`
    - `GET /users/:id` `[Public]` -> `getUser` (Public profile by ID or username)
    - `POST /users/:id/follow` `[Auth]` -> `followUser` (Follow user)
    - `PATCH /users/:id/unfollow` `[Auth]` -> `unfollowUser` (Unfollow user)
    - `GET /users/me/followers` `[Auth]` -> `getMyFollowers` (Followers of current user)
    - `GET /users/me/following` `[Auth]` -> `getMyFollowing` (Accounts current user follows)
    - `GET /users/:id/followers` `[Public]` -> `getFollowers` (Public follower list of a user)
    - `GET /users/:id/following` `[Public]` -> `getFollowing` (Public following list of a user)
    - `GET /users/:id/is-following` `[Auth]` -> `isFollowing` (Check follow status)
    - `POST /users/:id/block` `[Auth]` -> `blockUser` (Block user)
    - `PATCH /users/:id/unblock` `[Auth]` -> `unblockUser` (Unblock user)
    - `GET /users/:id/is-blocked` `[Auth]` -> `isBlocked` (Check block status)
- **Use Cases**:
  - `get-profile.usecase.ts`, `update-profile.usecase.ts`, `get-user-stats.usecase.ts`, `export-user-data.usecase.ts`
  - `request-account-deletion.usecase.ts`, `cancel-account-deletion.usecase.ts`, `register-phone.usecase.ts`, `verify-phone.usecase.ts`, `update-fcm-token.usecase.ts`
  - `search-users.usecase.ts`, `get-suggestions.usecase.ts`
  - `follow-user.usecase.ts`, `unfollow-user.usecase.ts`, `list-followers.usecase.ts`, `list-following.usecase.ts`, `get-follow-status.usecase.ts`
  - `block-user.usecase.ts`, `unblock-user.usecase.ts`, `get-block-status.usecase.ts`
- **Repositories**:
  - `nest-backend/src/modules/users/data/repositories/account-lifecycle-database.repository.ts`
  - `nest-backend/src/modules/users/data/repositories/block-database.repository.ts`
  - `nest-backend/src/modules/users/data/repositories/follow-database.repository.ts`
  - `nest-backend/src/modules/users/data/repositories/phone-verification-database.repository.ts`
  - `nest-backend/src/modules/users/data/repositories/user-data-export.repository.ts`
  - `nest-backend/src/modules/users/domain/repositories/block.repository.ts`
  - `nest-backend/src/modules/users/domain/repositories/follow.repository.ts`
  - `nest-backend/src/modules/users/domain/repositories/user-lookup.repository.ts`
- **Key DTOs / Types**:
  - `UpdateProfileDTO`, `RegisterPhoneDTO`, `VerifyPhoneDTO`, `UserResponse` (`user.dto.ts`)

### `wallet`
- **Path**: `nest-backend/src/modules/wallet/`
- **Controllers**:
  - `WalletController` (`nest-backend/src/modules/wallet/wallet.controller.ts`) — Prefix: `wallet`
    - `GET /wallet` `[Auth]` -> `getWallet` (Get availableBalance, pendingBalance, totalEarned in cents)
    - `GET /wallet/transactions` `[Auth]` -> `getTransactions` (List ledger wallet entries)
- **Use Cases**:
  - `get-wallet.usecase.ts`
- **Repositories**:
  - `nest-backend/src/modules/wallet/data/repositories/wallet-database.repository.ts`
  - `nest-backend/src/modules/wallet/domain/repositories/wallet.repository.ts`
- **Key DTOs / Types**:
  - `WalletDTO`, `WalletEntryDTO` (`wallet.dto.ts`)

---

## Frontend Features

### `auth`
- **Path**: `frontend/lib/features/auth/`
- **Pages** (`presentation/pages/`):
  - `splash_page.dart` (Initial app entry screen with animated brutalist logo)
  - `login_page.dart` (Email/password and Google login)
  - `register_page.dart` (Account registration with username availability check)
  - `complete_profile_page.dart` (Post-signup profile setup: username, avatar, bio)
  - `password_recovery_page.dart` (Request recovery code via email)
  - `reset_password_page.dart` (Enter 6-digit code and new password)
- **Providers & Controllers** (`presentation/controllers/`):
  - `auth_controller.dart` (`authControllerProvider`)
  - `auth_dependencies.dart`
  - `auth_google_authentication.dart`
  - `auth_session_lifecycle.dart`
- **Entities** (`data/entities/`):
  - `user_entity.dart` (`UserEntity`)
- **Repositories**:
  - `auth_repository.dart` (`AuthRepository` via Dio)

### `bug_report`
- **Path**: `frontend/lib/features/bug_report/`
- **Widgets / Sheets**:
  - `bug_report_sheet.dart` (Modal sheet for capturing issue description and logs)
- **Providers**:
  - `bug_report_provider.dart` (`bugReportProvider`)
- **Use Cases / Repositories**:
  - `create_bug_report_usecase.dart`

### `cart`
- **Path**: `frontend/lib/features/cart/`
- **Pages**:
  - `cart_checkout_page.dart` (Review cart items, address, shipping fee, checkout button)
- **Providers**:
  - `cart_provider.dart` (`cartProvider`, `cartTotalProvider`)
- **Entities**:
  - `cart_entity.dart`, `cart_item_entity.dart`, `cart_checkout_entity.dart`
- **Repositories**:
  - `cart_repository.dart` (`CartRepository`)

### `chat`
- **Path**: `frontend/lib/features/chat/`
- **Pages**:
  - `chat_list_page.dart` (Main chat tab with direct & order conversation threads)
  - `new_chat_page.dart` (Start chat with a seller/user or discuss a product)
  - `chat_conversation_page.dart` (Full-screen messaging view with media attachments)
  - `conversation_details_page.dart` (Participant info, media gallery, theme settings)
  - `archived_chats_page.dart` (List of archived threads)
  - `image_editor_page.dart` (Photo cropping, text overlays, drawing before sending)
  - `location_picker_page.dart` (Pick meeting place location for delivery)
- **Providers**:
  - `chat_provider.dart`, `chat_socket_provider.dart`, `conversation_messages_provider.dart`
- **Entities**:
  - `chat_entity.dart`, `message_entity.dart`, `message_reaction_entity.dart`, `conversation_preference.dart`, `order_info.dart`, `chat_thread_type.dart`, `message_type.dart`
- **Repositories**:
  - `chat_repository.dart` (`ChatRepository`)

### `dispute`
- **Path**: `frontend/lib/features/dispute/`
- **Pages**:
  - `dispute_list_page.dart` (User disputes list with status badges)
  - `create_dispute_page.dart` (Form for opening dispute against an order with evidence upload)
  - `dispute_detail_page.dart` (Evidence timeline, dispute status, withdraw/resolve options)
- **Providers**:
  - `dispute_providers.dart` (`userDisputesProvider`, `disputeDetailProvider`)
- **Entities**:
  - `dispute_entity.dart` (`DisputeEntity`)
- **Repositories**:
  - `dispute_repository.dart` (`DisputeRepository`)

### `favorites`
- **Path**: `frontend/lib/features/favorites/`
- **Providers**:
  - `favorites_provider.dart` (`favoritesProvider`, `isFavoriteProvider`)
- **Repositories**:
  - `favorites_repository.dart` (`FavoritesRepository`)

### `help`
- **Path**: `frontend/lib/features/help/`
- **Pages**:
  - `faq_page.dart` (Frequently asked questions, escrow instructions, platform rules)

### `notifications`
- **Path**: `frontend/lib/features/notifications/`
- **Pages**:
  - `notifications_page.dart` (List of notifications with unread indicators and action links)
- **Providers**:
  - `notifications_provider.dart` (`notificationsProvider`, `unreadCountProvider`)
- **Entities**:
  - `notification_entity.dart` (`NotificationEntity`)
- **Repositories**:
  - `notification_repository.dart` (`NotificationRepository`)

### `onboarding`
- **Path**: `frontend/lib/features/onboarding/`
- **Pages**:
  - `onboarding_page.dart` (Introductory walkthrough slides)
  - `welcome_setup_page.dart` (Welcome step after first registration)
- **Widgets**:
  - `onboarding_slides.dart`

### `orders`
- **Path**: `frontend/lib/features/orders/`
- **Pages**:
  - `orders_page.dart` (Tabs for Purchases and Sales)
  - `order_detail_page.dart` (Status stepper, QR verification, escrow details, chat link)
- **Providers**:
  - `order_providers.dart`, `order_providers_state.dart`
- **Entities**:
  - `order_entity.dart` (`OrderEntity`)
- **Repositories**:
  - `order_repository.dart` (`OrderRepository`)

### `payments`
- **Path**: `frontend/lib/features/payments/`
- **Pages**:
  - `payment_page.dart` (Stripe Connect account status, onboarding button, payout history)
- **Providers**:
  - `payment_providers.dart` (`connectStatusProvider`, `paymentIntentProvider`)
- **Entities**:
  - `payment_entity.dart`, `payment_intent_entity.dart`
- **Repositories**:
  - `payment_repository.dart` (`PaymentRepository`)

### `product`
- **Path**: `frontend/lib/features/product/`
- **Pages**:
  - `explorar_page.dart` (Explore grid with category filters and product cards)
  - `product_list_page.dart` (Paginated list of all products)
  - `product_detail_page.dart` (Image gallery, seller info, Buy Now, Add to Cart, Chat)
  - `create_product_page.dart` (Listing creation with photo upload, title, price, category)
  - `edit_product_page.dart` (Edit existing listing)
  - `my_products_page.dart` (Seller management of own products)
  - `cart_page.dart` (Cart overview)
- **Providers**:
  - `product_controller.dart` (`productsProvider`, `productDetailProvider`, `categoriesProvider`)
- **Entities**:
  - `product_entity.dart`, `product_image_entity.dart`, `category_entity.dart`, `create_product_input.dart`, `product_page_result.dart`
- **Repositories**:
  - `product_repository.dart`, `category_repository.dart`

### `profile`
- **Path**: `frontend/lib/features/profile/`
- **Pages**:
  - `profile_page.dart` (Current user profile tab with bio, stats, and shortcuts)
  - `user_profile_page.dart` (Public profile of other users with Follow button)
  - `edit_profile_page.dart` (Edit avatar, banner, bio, city, state)
  - `followers_page.dart` (List of user followers)
  - `following_page.dart` (List of accounts followed)
  - `favorites_page.dart` (Favorited products)
  - `saved_posts_page.dart` (Bookmarked posts)
  - `purchases_page.dart` (Order purchase history)
  - `blocked_users_page.dart` (List and unblock managed blocked users)
- **Providers**:
  - `profile_controller.dart`, `user_posts_state.dart`, `follow_list_provider.dart`, `follow_status_provider.dart`, `profile_timeline_provider.dart`, `user_reposts_provider.dart`
- **Entities**:
  - `user_stats_entity.dart`, `follower_entity.dart`, `follow_responses.dart`, `block_responses.dart`
- **Repositories**:
  - `profile_repository.dart`

### `reviews`
- **Path**: `frontend/lib/features/reviews/`
- **Pages**:
  - `create_review_page.dart` (Star rating 1-5, comment, photo evidence upload)
  - `user_reviews_page.dart` (Public review list for seller or buyer)
- **Providers**:
  - `review_providers.dart` (`userReviewsProvider`, `canReviewOrderProvider`)
- **Entities**:
  - `review_entity.dart`, `review_list_response.dart`, `review_user_info.dart`
- **Repositories**:
  - `review_repository.dart`

### `social`
- **Path**: `frontend/lib/features/social/`
- **Pages**:
  - `feed_page.dart` (Main brutalist social feed with story carousel)
  - `post_details_page.dart` (Single post with comment tree and reply box)
  - `create_post_page.dart` (Create text or media post, tag products)
  - `post_search_page.dart` (Search posts by text query)
  - `people_search_page.dart` (Search people by username / name)
  - `liked_posts_page.dart` (Posts liked by user)
  - `my_posts_page.dart` (Posts authored by user)
  - `my_stories_page.dart` (User's active and archived stories)
  - `create_story_page.dart` (Camera/gallery picker with sticker & text overlay)
  - `story_viewer_page.dart` / `story_viewer_wrapper.dart` (Timed 24h story carousel)
- **Providers**:
  - `feed_provider.dart`, `post_details_provider.dart`, `post_details_controller.dart`, `likes_provider.dart`, `comment_likes_provider.dart`, `saves_provider.dart`, `reposts_provider.dart`, `post_search_provider.dart`, `user_search_provider.dart`, `story_highlight_provider.dart`, `story_submission_coordinator.dart`
- **Entities**:
  - `post_entity.dart`, `comment_entity.dart`, `story_entity.dart`, `feed_page_result.dart`, `user_search_entity.dart`, `social_filters.dart`
- **Repositories**:
  - `social_repository.dart` (`SocialRepository`)

### `wallet`
- **Path**: `frontend/lib/features/wallet/`
- **Pages**:
  - `wallet_page.dart` (Available balance, pending escrow balance, total earned, transaction ledger)
- **Providers**:
  - `wallet_controller.dart` (`walletControllerProvider`)
- **Entities**:
  - `wallet_entity.dart`, `wallet_transaction_entity.dart`, `connect_status_entity.dart`
- **Repositories**:
  - `wallet_repository.dart` (`WalletRepository`)

---

## Navigation Routes

All routes are defined in [`frontend/lib/core/router/app_routes.dart`](file:///C:/Users/Qiyana/Documents/GitHub/ME/freebay/frontend/lib/core/router/app_routes.dart) and registered in [`frontend/lib/core/router/app_router.dart`](file:///C:/Users/Qiyana/Documents/GitHub/ME/freebay/frontend/lib/core/router/app_router.dart).

### 1. Root & Auth Routes (`routes/auth_routes.dart`)
| Path Constant | Route Path | Mapped Page | Description |
|---------------|------------|-------------|-------------|
| `AppRoutes.splash` | `/splash` | `SplashPage` | App initialization and auth check |
| `AppRoutes.login` | `/login` | `LoginPage` | Email and Google authentication |
| `AppRoutes.register` | `/register` | `RegisterPage` | User account registration |
| `AppRoutes.completeProfile` | `/complete-profile` | `CompleteProfilePage` | Mandatory first-time profile completion |
| `AppRoutes.recoverPassword` | `/recover-password` | `PasswordRecoveryPage` | Request recovery code |
| `AppRoutes.resetPassword` | `/reset-password` | `ResetPasswordPage` | Enter recovery code and reset password |
| `AppRoutes.onboarding` | `/onboarding` | `OnboardingPage` | Onboarding tutorial slides |
| `AppRoutes.welcome` | `/welcome` | `WelcomeSetupPage` | Post-login welcome intro |

### 2. Shell Navigation Branches (Bottom Bar inside `AppShell`)
| Shell Branch | Root Path | Primary Page | Sub-routes |
|--------------|-----------|--------------|------------|
| Branch 0 | `AppRoutes.feed` (`/feed`) | `FeedPage` | Main social feed & story carousel |
| Branch 1 | `AppRoutes.explore` (`/explore`) | `ExplorarPage` | `AppRoutes.products` (`/products`) -> `ProductListPage` |
| Branch 2 | `AppRoutes.wallet` (`/wallet`) | `WalletPage` | Balances, escrow funds, transaction history |
| Branch 3 | `AppRoutes.chat` (`/chat`) | `ChatListPage` | Direct and order messaging threads |
| Branch 4 | `AppRoutes.profile` (`/profile`) | `ProfilePage` | Authenticated user profile and settings |

### 3. Product & Cart Routes (`routes/product_routes.dart`)
| Path Constant | Route Path | Mapped Page | Helper Builder |
|---------------|------------|-------------|----------------|
| `AppRoutes.createProduct` | `/products/create` | `CreateProductPage` | — |
| `AppRoutes.productDetail` | `/products/:id` | `ProductDetailPage` | `AppRoutes.productPath(id)` |
| `AppRoutes.editProduct` | `/products/:id/edit` | `EditProductPage` | `AppRoutes.productEditPath(id)` |
| `AppRoutes.cart` | `/cart` | `CartPage` | — |
| `AppRoutes.checkoutCart` | `/checkout/cart` | `CartCheckoutPage` | — |

### 4. Social & Stories Routes (`routes/social_routes.dart`)
| Path Constant | Route Path | Mapped Page | Helper Builder |
|---------------|------------|-------------|----------------|
| `AppRoutes.createPost` | `/create-post` | `CreatePostPage` | — |
| `AppRoutes.postDetails` | `/post/:id` | `PostDetailsPage` | `AppRoutes.postPath(id)` |
| `AppRoutes.postSearch` | `/posts/search` | `PostSearchPage` | `AppRoutes.postSearchWith(q)` |
| `AppRoutes.peopleSearch` | `/people/search` | `PeopleSearchPage` | `AppRoutes.peopleSearchWith(q)` |
| `AppRoutes.story` | `/story` | `StoryViewerWrapper` | `AppRoutes.storyAt(index)` |
| `AppRoutes.storyHighlight` | `/story/highlights/:id` | `HighlightStoryViewerWrapper` | `AppRoutes.storyHighlightPath(id)` |
| `AppRoutes.createStory` | `/create-story` | `CreateStoryPage` | — |
| `AppRoutes.userProfile` | `/user/:id` | `UserProfilePage` | `AppRoutes.userPath(id)` |

### 5. Chat Routes (`routes/chat_routes.dart`)
| Path Constant | Route Path | Mapped Page | Helper Builder |
|---------------|------------|-------------|----------------|
| `AppRoutes.chatNew` | `/chat/new` | `NewChatPage` | `AppRoutes.chatNewWith(userId, prodId)` |
| `AppRoutes.chatArchived` | `/chat/archived` | `ArchivedChatsPage` | — |
| `AppRoutes.chatConversation` | `/chat/:chatId` | `ChatConversationPage` | `AppRoutes.chatPath(id)` |
| `AppRoutes.chatDetails` | `/chat/:chatId/details` | `ConversationDetailsPage` | `AppRoutes.chatDetailsPath(id)` |
| `AppRoutes.imageEditor` | `/image-editor` | `ImageEditorPage` | — |

### 6. Order & Dispute Routes (`routes/order_routes.dart`)
| Path Constant | Route Path | Mapped Page | Helper Builder |
|---------------|------------|-------------|----------------|
| `AppRoutes.orders` | `/orders` | `OrdersPage` | — |
| `AppRoutes.orderDetail` | `/orders/:orderId` | `OrderDetailPage` | `AppRoutes.orderPath(id)` |
| `AppRoutes.disputes` | `/disputes` | `DisputeListPage` | — |
| `AppRoutes.createDispute` | `/disputes/create/:orderId` | `CreateDisputePage` | `AppRoutes.createDisputePath(orderId)` |
| `AppRoutes.disputeDetail` | `/disputes/:disputeId` | `DisputeDetailPage` | `AppRoutes.disputePath(id)` |

### 7. Profile & Relationship Routes (`routes/profile_routes.dart`)
| Path Constant | Route Path | Mapped Page | Helper Builder |
|---------------|------------|-------------|----------------|
| `AppRoutes.profileBlocked` | `/profile/blocked` | `BlockedUsersPage` | — |
| `AppRoutes.notifications` | `/notifications` | `NotificationsPage` | — |
| `AppRoutes.profilePosts` | `/profile/posts` | `MyPostsPage` | — |
| `AppRoutes.profileStories` | `/profile/stories` | `MyStoriesPage` | — |
| `AppRoutes.profileProducts` | `/profile/products` | `MyProductsPage` | — |
| `AppRoutes.profileLiked` | `/profile/liked` | `LikedPostsPage` | — |
| `AppRoutes.profileFavorites` | `/profile/favorites` | `FavoritesPage` | — |
| `AppRoutes.profileSaved` | `/profile/saved` | `SavedPostsPage` | — |
| `AppRoutes.profilePurchases` | `/profile/purchases` | `PurchasesPage` | — |
| `AppRoutes.profilePayment` | `/profile/payment` | `PaymentPage` | — |
| `AppRoutes.profileEdit` | `/profile/edit` | `EditProfilePage` | — |
| `AppRoutes.profileFollowers` | `/profile/followers` | `FollowersPage` | `AppRoutes.followersWith(userId)` |
| `AppRoutes.profileFollowing` | `/profile/following` | `FollowingPage` | `AppRoutes.followingWith(userId)` |
| `AppRoutes.userReviews` | `/user/:id/reviews` | `UserReviewsPage` | `AppRoutes.userReviewsPath(id)` |
| `AppRoutes.createReview` | `/reviews/create` | `CreateReviewPage` | — |

### 8. Support & Miscellaneous Routes
| Path Constant | Route Path | Mapped Page | Description |
|---------------|------------|-------------|-------------|
| `AppRoutes.faq` | `/faq` | `FaqPage` | Platform FAQ and help center |
| `AppRoutes.wildCard` | `/:path(.*)` | Redirect to `AppRoutes.login` | Catch-all redirect for invalid routes |

---

## Database Models

From [`nest-backend/prisma/schema.prisma`](file:///C:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/prisma/schema.prisma):

| Model Name | Description & Key Fields | Relations |
|------------|-------------------------|-----------|
| **`User`** | Platform user entity.<br>• `id` (UUID pk), `displayName`, `username` (unique), `email` (unique), `role` (`USER`/`ADMIN`), `reputationScore`, `isVerified`, `isGuest`, `deletedAt`, `suspendedAt`, `fcmToken`, `notificationPrefs` | 1:1 `Wallet`, 1:1 `ConnectAccount`, 1:N `Product`, 1:N `Post`, 1:N `Order` (Buyer/Seller), 1:N `Review`, 1:N `Follow`, 1:N `Block`, 1:N `Dispute`, 1:N `DirectConversation`, 1:N `Notification` |
| **`PasswordRecoveryCode`** | Temporary 6-digit recovery code.<br>• `userId`, `codeHash`, `attempts`, `expiresAt`, `usedAt` | N:1 `User` (onDelete: Cascade) |
| **`WebMagicLink`** | Passwordless web login tokens.<br>• `email`, `tokenHash` (unique), `consentGranted`, `expiresAt`, `consumedAt`, `activatedAt` | None |
| **`PhoneVerificationCode`** | SMS verification code.<br>• `userId`, `phone`, `codeHash`, `attempts`, `expiresAt`, `usedAt` | N:1 `User` (onDelete: Cascade) |
| **`Category`** | Hierarchical product taxonomy.<br>• `id`, `name`, `slug` (unique), `parentId` | 1:N `Category` (children), N:1 `Category` (parent), 1:N `Product` |
| **`Product`** | Marketplace item listing.<br>• `id`, `title`, `description`, `price` (**cents as Int**), `condition` (`NEW`/`USED`), `status` (`ACTIVE`/`SOLD`/`PAUSED`/`DELETED`), `quantity`, `sellerId`, `postId` | N:1 `User` (seller), N:1 `Category`, 1:1 `Post`, 1:N `ProductImage`, 1:N `Order`, 1:N `Favorite`, 1:N `CartItem` |
| **`ProductImage`** | Media photo for product.<br>• `id`, `url`, `order`, `productId` | N:1 `Product` (onDelete: Cascade) |
| **`Post`** | Social network feed post.<br>• `id`, `content`, `imageUrl`, `type` (`PRODUCT`/`REGULAR`), `userId`, `likesCount`, `commentsCount`, `sharesCount`, `deletedAt` | N:1 `User`, 1:1 `Product`, 1:N `Comment`, 1:N `Like`, 1:N `Share`, 1:N `SavedPost`, 1:N `PostMention` |
| **`PostMention`** | User mention tag inside post.<br>• `postId`, `mentionedUserId` | N:1 `Post` (onDelete: Cascade), N:1 `User` |
| **`Comment`** | Discussion comment under post.<br>• `id`, `content`, `userId`, `postId`, `parentId`, `likesCount`, `deletedAt` | N:1 `User`, N:1 `Post`, N:1 `Comment` (parent), 1:N `Comment` (replies), 1:N `CommentLike`, 1:N `CommentMention` |
| **`CommentMention`** | User mention tag inside comment.<br>• `commentId`, `mentionedUserId` | N:1 `Comment` (onDelete: Cascade), N:1 `User` |
| **`Like`** | Post like interaction.<br>• `userId`, `postId` (unique pair) | N:1 `User`, N:1 `Post` (onDelete: Cascade) |
| **`CommentLike`** | Comment like interaction.<br>• `userId`, `commentId` (unique pair) | N:1 `User`, N:1 `Comment` (onDelete: Cascade) |
| **`Share`** | Repost / share of a post.<br>• `userId`, `postId` (unique pair) | N:1 `User`, N:1 `Post` (onDelete: Cascade) |
| **`Follow`** | Social follower / following relationship.<br>• `followerId`, `followingId` (unique pair) | N:1 `User` (follower), N:1 `User` (following) |
| **`Order`** | Marketplace transaction lifecycle.<br>• `id`, `buyerId`, `sellerId`, `productId`, `quantity`, `amount` (cents), `platformFee` (cents), `sellerAmount` (cents), `status` (`PENDING`..`COMPLETED`), `escrowStatus` (`HELD`/`RELEASED`/`REFUNDED`), `deliveryConfirmedAt` | N:1 `User` (buyer), N:1 `User` (seller), N:1 `Product`, 1:1 `Transaction`, 1:1 `Dispute`, 1:N `WalletEntry`, 1:N `Review`, 1:N `ChatMessage` |
| **`Transaction`** | Stripe payment record.<br>• `id`, `orderId` (unique), `amount`, `platformFee`, `sellerAmount`, `paymentMethod`, `status` (`PENDING`/`PAID`/`HELD`..), `transferState`, `reversalState`, `idempotencyKey` | 1:1 `Order`, N:1 `PaymentGroup` |
| **`PaymentGroup`** | Multi-item cart checkout container.<br>• `id`, `buyerId`, `amount`, `currency`, `status`, `stripePaymentIntentId`, `stripeSessionId`, `clientSecret`, `idempotencyKey` | 1:N `Transaction` |
| **`ConnectAccount`** | Stripe Connect Express seller account.<br>• `userId` (unique), `stripeAccountId`, `transfersEnabled`, `payoutsEnabled`, `detailsSubmitted` | 1:1 `User` |
| **`Wallet`** | In-app user balance.<br>• `userId` (unique), `availableBalance` (cents), `pendingBalance` (cents), `totalEarned` (cents) | 1:1 `User` |
| **`WalletEntry`** | Immutable wallet ledger audit entry.<br>• `userId`, `kind` (`AVAILABLE`/`PENDING`/`TOTAL_EARNED`), `amount` (cents), `reason` (`SALE_HELD`/`SALE_RELEASED`/`REFUND`..), `orderId` | N:1 `User`, N:1 `Order` |
| **`Dispute`** | Order conflict case.<br>• `orderId` (unique), `openedById`, `status` (`OPEN`/`AWAITING_SELLER`..), `reason`, `buyerEvidence` (JSON), `sellerEvidence` (JSON), `resolution`, `resolvedById`, `expiresAt` | 1:1 `Order`, N:1 `User` (openedBy), N:1 `User` (resolvedBy) |
| **`Review`** | Bilateral reputation review.<br>• `reviewerId`, `reviewedId`, `orderId`, `type` (`BUYER_REVIEWING_SELLER`/`SELLER_REVIEWING_BUYER`), `score` (1-5), `comment` | N:1 `User` (reviewer), N:1 `User` (reviewed), N:1 `Order`, 1:N `ReviewImage` |
| **`ReviewImage`** | Photo evidence for review.<br>• `id`, `url`, `order`, `reviewId` | N:1 `Review` (onDelete: Cascade) |
| **`ChatMessage`** | Message in an Order-specific chat thread.<br>• `id`, `orderId`, `senderId`, `content`, `type` (`TEXT`/`IMAGE`/`PRODUCT_CARD`..), `attachmentUrl`, `deliveredAt`, `readAt`, `replyToId`, `viewOnce` | N:1 `Order`, N:1 `User` (sender), N:1 `ChatMessage` (replyTo), 1:N `MessageReaction`, 1:N `StarredMessage` |
| **`Favorite`** | Saved bookmark of a product.<br>• `userId`, `productId` (unique pair) | N:1 `User`, N:1 `Product` (onDelete: Cascade) |
| **`CartItem`** | Item in user's shopping basket.<br>• `userId`, `productId`, `quantity` | N:1 `User`, N:1 `Product` (onDelete: Cascade) |
| **`Story`** | Ephemeral 24-hour social story.<br>• `id`, `userId`, `imageUrl`, `mediaType` (`IMAGE`/`VIDEO`), `caption`, `textBlocks` (JSON), `expiresAt`, `deletedAt` | N:1 `User`, 1:N `StoryView`, 1:N `StoryHighlightItem` |
| **`StoryView`** | Record of a user viewing a story.<br>• `storyId`, `viewerId` (unique pair), `viewedAt` | N:1 `Story` (onDelete: Cascade) |
| **`Block`** | User block list record.<br>• `blockerId`, `blockedId` (unique pair) | N:1 `User` (blocker), N:1 `User` (blocked) |
| **`StoryHighlight`** | Persistent story collection on profile.<br>• `id`, `userId`, `title`, `coverStoryId` | N:1 `User`, 1:N `StoryHighlightItem` |
| **`StoryHighlightItem`** | Association of story with a highlight.<br>• `highlightId`, `storyId`, `position` | N:1 `StoryHighlight` (onDelete: Cascade), N:1 `Story` |
| **`MessageReaction`** | Emoji reaction on a chat message.<br>• `emoji`, `userId`, `directMessageId`, `chatMessageId` | N:1 `User`, N:1 `DirectMessage`, N:1 `ChatMessage` |
| **`StarredMessage`** | Bookmarked message.<br>• `userId`, `directMessageId`, `chatMessageId` | N:1 `User`, N:1 `DirectMessage`, N:1 `ChatMessage` |
| **`DirectConversation`** | 1-on-1 direct messaging conversation.<br>• `id`, `user1Id`, `user2Id`, `productId`, `scopeKey`, `status` (`PENDING`/`ACTIVE`/`BLOCKED`), `lastMessageAt` | N:1 `User` (user1), N:1 `User` (user2), N:1 `Product`, 1:N `DirectMessage`, 1:N `ConversationPreference` |
| **`DirectMessage`** | Message in direct conversation.<br>• `id`, `conversationId`, `senderId`, `content`, `type`, `attachmentUrl`, `deliveredAt`, `readAt`, `replyToId`, `viewOnce` | N:1 `DirectConversation`, N:1 `User` (sender), N:1 `DirectMessage` (replyTo), 1:N `MessageReaction`, 1:N `StarredMessage` |
| **`ConversationPreference`**| Per-user chat preferences.<br>• `userId`, `orderId`, `directConversationId`, `isArchived`, `isDeleted`, `theme` (`DEFAULT`/`CRIMSON`/`COBALT`/`FOREST`..), `backgroundUrl` | N:1 `User`, N:1 `Order`, N:1 `DirectConversation` |
| **`Report`** | User abuse / content moderation report.<br>• `id`, `reporterId`, `reportedUserId`, `reportedPostId`, `targetType` (`USER`/`POST`/`CONVERSATION`..), `reason` (`SPAM`/`FRAUD`..), `description`, `status` (`PENDING`/`RESOLVED`..), `reviewedById` | N:1 `User` (reporter), N:1 `User` (reportedUser), N:1 `Post`, N:1 `DirectConversation`, N:1 `Order`, 1:N `ModerationAction` |
| **`ModerationAction`** | Immutable admin moderation action log.<br>• `actorId`, `targetType`, `targetId`, `action` (`USER_SUSPENDED`/`PRODUCT_REMOVED`..), `reason`, `reportId` | N:1 `User` (actor), N:1 `Report` |
| **`BugReport`** | User submitted bug report.<br>• `userId`, `description`, `appVersion`, `platform`, `screenContext` | N:1 `User` |
| **`Notification`** | Push & in-app notification.<br>• `id`, `userId`, `type` (`ORDER`/`FOLLOW`/`MESSAGE`/`DISPUTE`/`PAYMENT`/`MENTION`), `title`, `body`, `data` (JSON), `read` | N:1 `User` |
| **`SavedPost`** | Bookmarked social post.<br>• `userId`, `postId` (unique pair) | N:1 `User`, N:1 `Post` (onDelete: Cascade) |

---

## Cross-Cutting Concerns

### 1. Authentication Flow
- **Dual Session Model**:
  - **Mobile App**: Bearer JWT tokens in Authorization header (`access_token` with short TTL, `refresh_token` with longer TTL). Tokens rotated via `POST /auth/refresh`.
  - **Web Client**: HttpOnly secure cookies via `AuthWebSessionController` (`fb_at`, `fb_rt`).
- **Token Blacklisting**: Redis-backed blacklist ensures immediate invalidation upon `POST /auth/logout` or admin suspension.
- **Biometric Authentication**: Client signs encrypted payload using hardware biometrics (Face ID/Fingerprint). Verified against enrolled public credential via `POST /auth/biometric-login`.
- **Google OAuth**: Verifies Google ID tokens server-side, linking to existing accounts or provisioning new users.
- **Passwordless Magic Links**: HMAC-signed short-lived tokens sent via email (`POST /auth/web/magic-link/request`). Consumed once via `POST /auth/web/magic-link/consume`.
- **Phone Verification**: 6-digit SMS verification code with strict rate-limiting (max 5 attempts, exponential backoff).

### 2. Payment & Escrow Lifecycle (Stripe Connect)
- **Zero-Trust Escrow State Machine**:
  1. **Order Creation**: Buyer orders item -> `Order` in `PENDING` status. Inventory reserved.
  2. **Payment Intent / Session**:
     - Mobile: `POST /payments/payment-intent/:orderId` generates Stripe `clientSecret` for native PaymentSheet.
     - Web: `POST /payments/checkout/:orderId` creates Stripe Checkout Session redirect URL.
     - Multi-vendor Cart: `POST /cart/checkout` aggregates orders into a single `PaymentGroup` payment intent.
  3. **Escrow Held**: Stripe webhook (`payment_intent.succeeded` or `checkout.session.completed`) triggers `ProcessWebhookUseCase`. `Transaction` moves to `PAID`, `Order` to `CONFIRMED`, `Order.escrowStatus` to `HELD`. Seller's wallet logs `PENDING` balance entry.
  4. **Fulfillment**: Seller ships / delivers -> Buyer confirms receipt (`PATCH /orders/:id/confirm`).
  5. **Escrow Release**: Confirmation triggers `EscrowReleaseTask` (or instant release) -> Stripe transfer to seller's Connect account -> `Order.escrowStatus` becomes `RELEASED`. Funds move from `PENDING` to `AVAILABLE` in `Wallet`.
  6. **Dispute / Refund**: If disputed or cancelled, `ProcessRefundUseCase` cancels Stripe charge or reverses transfer, returning funds to buyer.
- **Reconciliation & Idempotency**:
  - Webhooks verified using HMAC secret and deduplicated via `WebhookDedupeInterceptor`.
  - Background `TransferReconciliationTask` retries failed Connect transfers with idempotency keys.

### 3. Real-Time Chat & Socket.IO
- **Namespaces**:
  - `/chat`: Real-time chat messages, typing status, presence, and emoji reactions.
  - `/notifications`: Instant in-app notification alerts and badge counts.
- **Thread Types**:
  - `ORDER`: Chat scoped to a specific purchase between buyer and seller.
  - `DIRECT`: 1-on-1 private messaging between two users (optionally initiated from a product inquiry).
- **Security & Safety**:
  - Handshake authenticated via JWT access token.
  - Automatic participant checks and blocking enforcement (messages blocked if either party has blocked the other).
  - Malicious link protection via `POST /chat/security/verify-url`.

### 4. Background Tasks & Cron Automation
Engineered via `@nestjs/schedule` vertical tasks under `nest-backend/src/modules/tasks/`:
- **`EscrowReleaseTask`** (Every 15 min): Auto-releases escrow funds to seller 48 hours after delivery if buyer neither confirms nor opens a dispute.
- **`CheckoutExpiryTask`** (Every 5 min): Expires abandoned checkout sessions and returns reserved quantities back to active inventory.
- **`StoryCleanupTask`** (Every 15 min): Marks stories older than 24 hours as archived.
- **`TransferReconciliationTask`** (Every 10 min): Scans `Transaction` records with `RETRYABLE` transfer states and re-executes Stripe Connect transfers with exponential backoff.
- **`DisputeCleanupTask`** (Hourly): Flags overdue disputes where seller or buyer failed to respond in the required timeframe.
- **`AccountDeletionTask`** (Daily): Permanently purges user data after 30-day grace period.
- **`MagicLinkCleanupTask`** (Hourly): Deletes expired recovery codes and magic link hashes.

### 5. File Uploads & Media Architecture
- **Multer Memory Storage**: Files processed in memory without writing temporary files to arbitrary OS directories.
- **MIME & Extension Whitelisting**: Strict verification of Magic Bytes and MIME types (JPEG, PNG, WebP, GIF, MP3, MP4, MOV).
- **Size Limits**:
  - Profile Avatars & Review Images: 5MB
  - Banner Images: 8MB
  - Story Media (Images & Video clips): 10MB
- **Storage & Serving**:
  - Persisted under structured context directories (`uploads/avatar/`, `uploads/post/`, `uploads/story/`, `uploads/product/`, `uploads/chat/`).
  - Served securely via `MediaController` (`GET /media/:context/:filename`) with appropriate HTTP cache headers and authentication checks.
