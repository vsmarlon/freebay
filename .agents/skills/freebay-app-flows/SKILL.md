---
name: freebay-app-flows
description: Comprehensive architecture diagrams, sequence flows, state hierarchy, navigation rules, and error recovery for all FreeBay core flows — Auth, Biometry, Google Login, Onboarding, Wallet, Chat, Profile, Explore/Feed, Checkout/Payments, Disputes, and Notifications.
---

# FreeBay End-to-End Application Flows & State Architecture

This skill documents every user journey, UI state machine, API interaction, database transaction, and edge case across the FreeBay C2C marketplace platform.

---

## 1. Authentication & Session Lifecycle Flow

### 1.1 Overview & State Hierarchy
- **Frontend State**: `authControllerProvider` (`AsyncValue<UserEntity?>`), `isInitialAuthLoadingProvider` (`bool`), `hasSeenOnboardingProvider` (`bool`).
- **Storage**: `StorageService` (`FlutterSecureStorage` for JWT tokens & refresh token, `SharedPreferences` for `rememberMe` and `hasSeenOnboarding`).
- **Backend**: `AuthModule` -> `RegisterUseCase`, `LoginUseCase`, `GuestUseCase`, `GoogleAuthUseCase`, `BiometricLoginUseCase`, `ResetPasswordUseCase`.
- **Session Protection**: Redis token blacklist on logout, JWT verification via Passport `JwtStrategy`, global rate-limiting (`ThrottlerGuard`).

### 1.2 Auth Sequence Diagram

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant UI as Flutter App (LoginPage / RegisterPage)
    participant AC as AuthController (Riverpod)
    participant Storage as FlutterSecureStorage / Prefs
    participant Backend as NestJS AuthController
    participant UC as LoginUseCase / RegisterUseCase
    participant DB as PostgreSQL (Prisma)
    participant Redis as Redis Cache

    alt Email/Password Registration
        User->>UI: Input name, email, password, username
        UI->>AC: register(email, password, displayName, username)
        AC->>Backend: POST /auth/register { email, password, displayName, username }
        Backend->>UC: RegisterUseCase.execute()
        UC->>DB: Check unique email & username
        UC->>DB: Hash password (bcrypt 12 rounds) + Insert User + Insert Wallet (balance: 0)
        UC->>Backend: Return { user, accessToken, refreshToken }
        Backend->>AC: 201 Created { user, accessToken, refreshToken }
        AC->>Storage: Save tokens & user profile
        AC->>UI: State updated -> Navigate to /feed
    else Email/Password Login
        User->>UI: Input email, password, rememberMe
        UI->>AC: login(email, password, rememberMe)
        AC->>Backend: POST /auth/login { email, password }
        Backend->>UC: LoginUseCase.execute()
        UC->>DB: findByEmail()
        UC->>UC: bcrypt.compare(password, passwordHash)
        UC->>Backend: Return { user, accessToken, refreshToken }
        Backend->>AC: 200 OK { user, accessToken, refreshToken }
        AC->>Storage: Save tokens + rememberMe flag
        AC->>UI: State updated -> Navigate to /feed
    else Guest Browsing Mode
        User->>UI: Tap "Entrar como Convidado"
        UI->>AC: loginAsGuest()
        AC->>Backend: POST /auth/guest
        Backend->>UC: GuestUseCase.execute()
        UC->>Backend: Return ephemeral guest token + UserEntity(isGuest: true)
        Backend->>AC: 200 OK { user: { isGuest: true }, accessToken }
        AC->>UI: State updated -> Navigate to /feed (Guest permissions active)
    else Logout & Token Invalidation
        User->>UI: Tap "Sair da Conta"
        UI->>AC: logout()
        AC->>Backend: POST /auth/logout (Bearer Token)
        Backend->>Redis: Blacklist accessToken (TTL = remaining token life)
        AC->>Storage: Clear tokens, clear biometric keys
        AC->>AC: Invalidate all feature providers (wallet, cart, chat, notifications)
        AC->>UI: State -> null -> GoRouter redirects to /login
    end
```

### 1.3 Edge Cases & Error Handling
- **Duplicate Email/Username**: Returns `EmailAlreadyExistsError` / `UsernameAlreadyTakenError` -> Controller renders localized `BrutalistErrorBanner`.
- **Account Locked / Invalid Credentials**: Returns `InvalidCredentialsError` (HTTP 401) with standard error envelope `{ success: false, error: { code: 'INVALID_CREDENTIALS', message: '...' } }`.
- **Expired Token**: HTTP 401 triggers Dio interceptor to attempt refresh token rotation; if refresh fails, triggers `forceLogout()` redirecting to `/login`.

---

## 2. Biometry Flow (Fingerprint / Face ID)

### 2.1 Overview
- **Service**: `BiometryService` wraps `local_auth` package.
- **Security**: Device-bound challenge token stored securely.
- **Workflow**:
  1. App cold boot checks `StorageService.getRememberMe()`.
  2. If rememberMe is true but access token is missing/expired, check `BiometryService.isEnabled()`.
  3. Prompt native biometric dialog with custom copy ("Autentique-se para acessar o FreeBay").
  4. On success, exchange stored biometric signature token with NestJS backend `BiometricLoginUseCase`.
  5. On failure/cancellation, fallback cleanly to `LoginPage` without losing saved email.

### 2.2 Biometry Sequence Diagram

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant App as FreeBay App Startup
    participant Bio as BiometryService (local_auth)
    participant Storage as FlutterSecureStorage
    participant AC as AuthController
    participant Backend as NestJS BiometricLoginUseCase
    participant DB as PostgreSQL

    App->>Storage: getRememberMe() & getBiometricKey()
    alt Biometrics Enabled & Key Present
        App->>Bio: authenticate(localizedReason: "Acesse sua conta FreeBay")
        User->>Bio: Scans Fingerprint / Face
        alt Biometric Success
            Bio->>AC: Biometric Verified
            AC->>Storage: Retrieve encrypted device token
            AC->>Backend: POST /auth/biometric-login { deviceToken, signature }
            Backend->>DB: Validate device registration & user
            Backend->>AC: Return refreshed accessToken & UserEntity
            AC->>App: Set authState -> User -> Navigate to /feed
        else Biometric Cancelled or Failed
            Bio->>AC: BiometryCancelledFailure
            AC->>App: Set authState -> null -> Route to /login (password fallback)
        end
    else Biometrics Disabled / Cold First Launch
        App->>App: Route to /login or /onboarding
    end
```

---

## 3. Login with Google (OAuth2 / ID Token)

### 3.1 Overview
- **Frontend**: `google_sign_in` plugin initializes native Google Auth sheet.
- **Backend**: `GoogleAuthUseCase` validates the received Google ID Token cryptographically using Google OAuth2 client libraries.
- **Account Linking**: If email already exists, link Google ID to the existing account. If new user, create user record and redirect user to `/complete-profile` if handle/username is required.

### 3.2 Google Sign-In Sequence Diagram

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant UI as LoginPage
    participant AC as AuthController
    participant Google as Google OAuth SDK
    participant Backend as NestJS AuthController
    participant UC as GoogleAuthUseCase
    participant DB as PostgreSQL

    User->>UI: Tap "Continuar com Google"
    UI->>AC: googleLogin()
    AC->>Google: authenticate()
    Google->>User: Prompt Google Account Chooser
    User->>Google: Select account & grant scopes
    Google->>AC: Return GoogleSignInAuthentication (idToken)
    AC->>Backend: POST /auth/google { idToken }
    Backend->>UC: GoogleAuthUseCase.execute(idToken)
    UC->>UC: Verify token signature with Google Certs
    UC->>DB: Find user by googleId OR email
    alt User exists and has username
        UC->>Backend: Return { user, accessToken, refreshToken }
        Backend->>AC: 200 OK
        AC->>UI: Navigate to /feed
    else User is new or missing username
        UC->>DB: Create user (email, googleId, avatarUrl, username: null) + Wallet
        UC->>Backend: Return { user: { username: null }, accessToken }
        Backend->>AC: 200 OK
        AC->>UI: GoRouter redirect triggers -> /complete-profile
        User->>UI: Choose unique @username, city, state
        UI->>AC: completeProfile(username, city, state)
        AC->>Backend: POST /auth/complete-profile
        Backend->>DB: Update user username, city, state
        AC->>UI: Navigate to /feed
    end
```

---

## 4. Onboarding & First-Launch Flow

### 4.1 Overview
- First-time users see a high-impact Digital Brutalist onboarding carousel explaining Escrow protection, C2C discovery, and social feeds.
- Once completed or skipped, `StorageService.setHasSeenOnboarding(true)` is saved.
- `hasSeenOnboardingProvider` is hydrated synchronously during cold boot so GoRouter evaluates redirects with zero UI flicker.

### 4.2 Onboarding Navigation State Machine

```mermaid
stateDiagram-v2
    [*] --> ColdBoot
    ColdBoot --> CheckStorage: Read tokens & hasSeenOnboarding
    CheckStorage --> SplashPage: Display Brutalist Logo
    
    SplashPage --> OnboardingCarousel: User == null AND !hasSeenOnboarding
    SplashPage --> LoginPage: User == null AND hasSeenOnboarding
    SplashPage --> FeedPage: User != null (Authenticated)
    
    OnboardingCarousel --> LoginPage: Tap "Começar" / Complete slides
    LoginPage --> RegisterPage: Tap "Criar conta"
    LoginPage --> FeedPage: Login Success / Guest Login
    RegisterPage --> FeedPage: Register Success
```

---

## 5. Wallet, Balance & Financial Escrow Flow

### 5.1 Financial Ledger Architecture
- **Currencies**: All monetary values stored in **Cents (`Int`)** (e.g. `1000` = R$ 10,00).
- **Balances**:
  - `availableBalance` (Int): Available balance shown in the wallet.
  - `pendingBalance` (Int): Held in escrow for active sales until buyer confirms delivery.
- **Ledger**: Statement rows show the financial reason for each balance movement.

### 5.2 Wallet & Escrow Sequence Diagram

```mermaid
sequenceDiagram
    autonumber
    actor Buyer
    actor Seller
    participant App as Flutter WalletPage
    participant Backend as NestJS Wallet / Payments
    participant DB as PostgreSQL
    participant Cron as EscrowReleaseTask (Cron)

    Note over Buyer,Seller: Buyer purchases item -> Payment confirmed
    Backend->>DB: tx: order.status = CONFIRMED, escrow.status = HELD
    Backend->>DB: tx: seller.wallet.pendingBalance += orderAmount
    
    alt Happy Path: Buyer confirms delivery
        Buyer->>Backend: POST /orders/:id/confirm-delivery
        Backend->>DB: tx: order.status = COMPLETED, escrow.status = RELEASED
        Backend->>DB: tx: seller.wallet.pendingBalance -= orderAmount
        Backend->>DB: tx: seller.wallet.availableBalance += orderAmount
        Backend->>App: Push notification -> "Saldo de R$ XX liberado!"
    else Auto-Release Timeout (7 days after SHIPPED)
        Cron->>Backend: Run EscrowReleaseTask
        Backend->>DB: Find orders SHIPPED > 7 days with no open dispute
        Backend->>DB: Auto-transition to COMPLETED & credit availableBalance
    else Dispute Opened
        Buyer->>Backend: POST /disputes/create/:orderId
        Backend->>DB: order.status = DISPUTED, escrow.status = HELD (Frozen)
    end
    
    Note over Seller,App: Seller reviews balances and ledger
    Seller->>App: Open Wallet
    App->>Backend: Load balances and ledger entries
    Backend->>App: Return available/pending balances and statement rows
    Seller->>App: Tap "CONFIGURAR RECEBIMENTOS"
    App->>Stripe: Open hosted onboarding
    Stripe->>App: Return to Wallet after onboarding
    Seller->>App: Tap "ABRIR PAINEL DE PAGAMENTOS"
    App->>Stripe: Open Express dashboard
    Stripe->>Seller: Pays out on its own schedule
```

---

## 6. Real-Time Chat & Messaging Flow

### 6.1 Architecture Overview
- **Gateway**: Socket.IO NestJS WebSocket Gateway at `/chat`.
- **Dual Model**:
  - **Direct Messages**: 1-on-1 user conversations (`DirectConversation`, `DirectMessage`).
  - **Order Chat**: Contextual chat attached to specific `Order` (`ChatMessage`).
- **Features**: Real-time delivery, typing indicators, read receipts, emoji reactions, link preview (OpenGraph metadata scraper), file/image attachments.

### 6.2 Chat Sequence Diagram

```mermaid
sequenceDiagram
    autonumber
    actor UserA as Sender (Alice)
    actor UserB as Receiver (Bob)
    participant UI as ChatConversationPage
    participant WS as Socket.IO Gateway (/chat)
    participant UC as SendMessageUseCase
    participant OG as OGScraperService
    participant DB as PostgreSQL
    participant Push as NotificationService (FCM)

    UserA->>UI: Type message + paste link (e.g. "https://item...")
    UI->>WS: socket.emit('sendMessage', { conversationId, content, mediaUrl })
    WS->>UC: SendMessageUseCase.execute()
    alt Message contains URL
        UC->>OG: scrape(url) -> { title, description, imageUrl }
    end
    UC->>DB: Insert DirectMessage (status: SENT)
    UC->>WS: Broadcast 'messageReceived' to room: conversationId
    
    alt UserB is Connected to Socket
        WS->>UserB: socket.on('messageReceived', payload)
        UserB->>WS: socket.emit('markAsRead', { messageId })
        WS->>DB: Update DirectMessage status = READ
        WS->>UserA: socket.on('messageRead', { messageId })
    else UserB is Offline
        UC->>Push: sendPushNotification(userB.fcmToken, "Nova mensagem de Alice")
    end
```

---

## 7. Profile, Social Graph & User Settings Flow

### 7.1 Overview
- **Capabilities**: View own/other profiles, edit bio/display name/city, follow/unfollow, block/unblock users, aggregate seller reviews/ratings.
- **Privacy & Safety**: Blocked users cannot send DMs, see posts in feed, or purchase products.

### 7.2 Profile State Flow

```mermaid
graph TD
    ProfilePage[Profile Screen] --> ViewTabs[Tab Navigation]
    ViewTabs --> Posts[Meus Posts / Anúncios]
    ViewTabs --> Favorites[Favoritos]
    ViewTabs --> Purchases[Minhas Compras]
    ViewTabs --> Sales[Minhas Vendas]
    ViewTabs --> Reviews[Avaliações Recebidas]
    
    ProfilePage --> EditProfile[Editar Perfil]
    EditProfile --> UploadAvatar[ImagePicker + Upload API]
    EditProfile --> SaveProfile[PUT /users/profile]
    
    ProfilePage --> Settings[Configurações]
    Settings --> ThemeToggle[Dark / Light Mode]
    Settings --> BiometryToggle[Habilitar Biometria]
    Settings --> BlockedUsers[Usuários Bloqueados]
    Settings --> LogoutAction[Desconectar]
```

---

## 8. Explore, Discovery & Social Feed Flow

### 8.1 Feed Architecture
- **Feeds**:
  - `FeedPage`: Following feed + curated community posts, stories tray at the top.
  - `ExplorarPage`: Product catalog, category filter chips, search query, location radius.
  - `StoryTray`: Ephemeral 24h stories with auto-cleanup task on NestJS backend.
- **Post Structure**: Media carousel, Markdown text, Product Tagging (`productId` linked directly to a buyable marketplace item), Like button, Comment tree sheet, Share button, Bookmark button.

### 8.2 Feed Interaction Flow

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant UI as FeedPage / PostCard
    participant Controller as SocialController
    participant Backend as NestJS SocialModule
    participant DB as PostgreSQL

    User->>UI: Scroll feed (Infinite Scroll)
    UI->>Controller: loadNextPage()
    Controller->>Backend: GET /social/feed?page=2&limit=10
    Backend->>DB: Query posts (with author, likesCount, commentsCount, taggedProduct)
    Backend->>Controller: Return List<PostResponse>
    Controller->>UI: Render SocialPost widgets
    
    User->>UI: Tap Like ❤️
    UI->>Controller: toggleLike(postId)
    Controller->>Backend: POST /social/posts/:id/like
    Backend->>DB: Upsert Like record
    Controller->>UI: Optimistic UI update (increment like count)
    
    User->>UI: Tap Tagged Product Card in Post
    UI->>UI: GoRouter.push('/products/:id')
```

---

## 9. Order, Checkout & Stripe Payment Flow

### 9.1 Platform Specific Checkout
- **Mobile (Android / iOS)**: Uses Stripe **PaymentSheet** (`POST /payments/payment-intent/:orderId` -> `initPaymentSheet` -> `presentPaymentSheet`).
- **Web / Multi-item Cart**: Uses Stripe **Checkout Session** (`POST /payments/checkout/:orderId` -> Web Checkout URL with PIX / Card).
- **Webhooks**: Stripe webhook listener (`/payments/webhook`) verified with `WebhookGuard` signature check and idempotency deduplication (`WebhookDedupeInterceptor`).

### 9.2 Complete Payment Sequence Diagram

```mermaid
sequenceDiagram
    autonumber
    actor Buyer
    participant Mobile as FreeBay Flutter (Mobile)
    participant Nest as NestJS PaymentsController
    participant Stripe as Stripe API
    participant Webhook as Stripe Webhook Worker
    participant DB as PostgreSQL
    participant Notif as NotificationService

    Buyer->>Mobile: Tap "Comprar Agora"
    Mobile->>Nest: POST /orders { productId, shippingAddress }
    Nest->>DB: Create Order (status: PENDING)
    Nest->>Mobile: Return OrderEntity (orderId)
    
    alt Mobile App (PaymentSheet Flow)
        Mobile->>Nest: POST /payments/payment-intent/:orderId
        Nest->>Stripe: stripe.paymentIntents.create({ amount, currency: 'brl', metadata: { orderId } })
        Stripe->>Nest: Return { clientSecret, paymentIntentId }
        Nest->>DB: Store Transaction record (PENDING)
        Nest->>Mobile: Return { clientSecret }
        Mobile->>Mobile: Stripe.instance.initPaymentSheet(clientSecret)
        Mobile->>Mobile: Stripe.instance.presentPaymentSheet()
        Buyer->>Mobile: Authorizes via ApplePay / GooglePay / Card
        Mobile->>Mobile: Payment Sheet completes successfully
    end
    
    Note over Stripe,Webhook: Async Webhook Execution
    Stripe->>Webhook: Event: payment_intent.succeeded (Signed Payload)
    Webhook->>Nest: POST /payments/webhook
    Nest->>Nest: WebhookGuard verifies Stripe-Signature
    Nest->>DB: Transaction: status = PAID
    Nest->>DB: Order: status = CONFIRMED
    Nest->>DB: Seller Wallet: pendingBalance += orderAmount (Escrow HELD)
    Nest->>Notif: Send Push to Buyer & Seller ("Pagamento Aprovado!")
```

---

## 10. Dispute Resolution Flow

### 10.1 Dispute Lifecycle
```mermaid
stateDiagram-v2
    [*] --> OPEN: Buyer opens dispute (Order DELIVERED/SHIPPED)
    OPEN --> UNDER_REVIEW: Admin/Moderator assigned
    UNDER_REVIEW --> RESOLVED_BUYER: Refund to Buyer
    UNDER_REVIEW --> RESOLVED_SELLER: Release to Seller
    RESOLVED_BUYER --> REFUNDED: Stripe / Wallet Refund Processed
    RESOLVED_SELLER --> COMPLETED: Escrow released to Seller wallet
    REFUNDED --> [*]
    COMPLETED --> [*]
```

### 10.2 Dispute Rules & Safety
- Either party can submit evidence messages and photos.
- While a dispute is `OPEN` or `UNDER_REVIEW`, escrow funds are **strictly locked**; `EscrowReleaseTask` ignores disputed orders.
- Resolving with `REFUND` cancels the order and reverses the seller's `pendingBalance`.

---

## 11. Notification System Architecture

### 11.1 Notification Channels
1. **Push Notifications**: Firebase Cloud Messaging (FCM) triggered via `NotificationService` for background/killed app events.
2. **In-App Badges & Socket Events**: Instant UI updates for active sessions.
3. **Database Records**: `Notification` model storing notification history, category (`ORDER`, `CHAT`, `SOCIAL`, `PAYMENT`, `SYSTEM`), and read state.

---

## 12. Complete Route & Navigation Matrix

| Path | Screen / Page | Auth Guard | Notes |
|---|---|---|---|
| `/splash` | `SplashPage` | Public | Boot & session check |
| `/onboarding` | `OnboardingPage` | Public | Shown on first launch |
| `/login` | `LoginPage` | Public | Email/pwd, Google, Biometric |
| `/register` | `RegisterPage` | Public | Create new account |
| `/recover-password` | `RecoverPasswordPage` | Public | Send recovery OTP |
| `/reset-password` | `ResetPasswordPage` | Public | Set new password |
| `/complete-profile` | `CompleteProfilePage` | Auth Required | Google Sign-in handle setup |
| `/feed` | `FeedPage` (Tab 0) | Public/Guest OK | Social posts & stories |
| `/explore` | `ExplorarPage` (Tab 1) | Public/Guest OK | Product discovery & search |
| `/wallet` | `WalletPage` (Tab 2) | Auth Required | Balances, ledger & Stripe payouts |
| `/chat` | `ChatListPage` (Tab 3) | Auth Required | DMs & Order chats |
| `/profile` | `ProfilePage` (Tab 4) | Public/Guest OK | User profile & listings |
| `/checkout` | `CheckoutPage` | Non-Guest Only | Order placement & payment |
| `/disputes` | `DisputeListPage` | Non-Guest Only | Dispute management |
| `/products/create` | `CreateProductPage` | Non-Guest Only | Sell item |
| `/create-post` | `CreatePostPage` | Non-Guest Only | Share social post |

---
