# FreeBay - Complete Implementation Plan

## C2C Hybrid Platform (NestJS + Flutter + PostgreSQL)

---

## 1. Current State Analysis

### ✅ Already Implemented

| Component | Status | Details |
|-----------|--------|---------|
| **Backend (NestJS)** | 95% done | All modules implemented with full business logic |
| **Database Schema** | 100% done | Prisma schema complete with all entities, enums, relations, indices |
| **Use Cases Pattern** | Done | `Either<L,R>` pattern, Input/Output DTOs, repository interfaces |
| **Frontend (Flutter)** | 60% done | Auth, profile, products, social feed, chat UI, wallet UI |
| **JWT Auth** | Done | Login, register, guest mode, JWT strategy |
| **Tests** | Partially done | Unit tests for auth, products, wallet, orders, social |
| **Social/Stories** | ✅ Complete | Full story CRUD, view tracking, grouped by user |
| **Wallet/Withdrawals** | ✅ Complete | Withdrawals, bank account registration, transaction history |
| **Orders/Escrow** | ✅ Complete | Full HELD → RELEASED workflow, balance updates |
| **Payments** | ✅ Complete | AbacatePay PIX, PagBank payouts, webhooks |
| **Chat** | ✅ Complete | WebSocket + REST, PENDING/ACTIVE status for non-followers |
| **Notifications** | ✅ Complete | WebSocket + FCM integration |
| **Disputes** | ✅ Complete | Open, evidence, resolution flow |
| **Reports** | ✅ Complete | User/post reporting, admin resolution |

### ❌ Still Needed

| Component | Priority | Details |
|-----------|----------|---------|
| **File Upload** | High | Product images, profile photos (S3/local) |
| **KYC Verification** | High | CPF + selfie verification |
| **Admin Panel** | Medium | Platform moderation |
| **Analytics** | Low | Seller dashboard, metrics |
| **Flutter UI Updates** | High | Payment flow, dispute UI, WebSocket chat |

---

## 2. Backend Implementation Plan (NestJS)

### 2.1 Architecture Overview

```
nest-backend/
├── src/
│   ├── shared/
│   │   ├── core/              # Either, errors, base classes
│   │   ├── decorators/        # Custom decorators
│   │   ├── guards/            # Auth, roles guards
│   │   ├── pipes/            # Validation pipes
│   │   ├── http/             # Response formatting, filters
│   │   ├── infra/
│   │   │   ├── prisma/       # Prisma service
│   │   │   ├── redis/        # Cache, queues
│   │   │   └── storage/      # File upload (S3/local) - TODO
│   │   └── utils/
│   │
│   ├── modules/
│   │   ├── auth/             ✅ Complete
│   │   ├── users/            ✅ Complete
│   │   ├── products/         ✅ Complete  
│   │   ├── category/         ✅ Complete
│   │   ├── social/           ✅ Complete (Stories implemented)
│   │   ├── wallet/           ✅ Complete (Withdrawals implemented)
│   │   ├── orders/           ✅ Complete (Escrow implemented)
│   │   ├── payments/         ✅ Complete (AbacatePay + PagBank)
│   │   ├── chat/             ✅ Complete (WebSocket + pending)
│   │   ├── notifications/    ✅ Complete (WebSocket + FCM)
│   │   ├── disputes/         ✅ Complete
│   │   └── reports/          ✅ Complete
│   │
│   └── gateways/             # WebSocket gateways
│       ├── chat.gateway.ts   ✅ Implemented
│       └── notifications.gateway.ts ✅ Implemented
│
└── prisma/
    └── schema.prisma         ✅ Complete (added status to DirectConversation)
```

---

### 2.2 Module-by-Module Implementation

#### **A. Payments Module** ✅ COMPLETE

**Files created:**
```
src/modules/payments/
├── providers/
│   ├── abortepay.provider.ts   # AbacatePay PIX integration
│   └── pagbank.provider.ts    # PagBank payouts/transfers
├── usecases/
│   ├── payment.usecase.ts     # CreatePixPayment, ProcessWebhook, CreateWithdrawal
└── payments.controller.ts     # Updated
```

**Implementation:**
- `AbacatePayProvider` - Creates PIX charges, verifies webhooks
- `PagBankProvider` - OAuth token management, recipient creation, transfers
- `CreatePixPaymentUseCase` - Creates PIX payment for orders, stores transaction
- `ProcessWebhookUseCase` - Handles `charge.completed`, activates escrow
- `CreateWithdrawalUseCase` - Processes withdrawals via PagBank

---

#### **B. Chat Module** ✅ COMPLETE

**Files created:**
```
src/modules/chat/
├── chat.gateway.ts           # WebSocket gateway (JWT auth, join/send/typing)
├── usecases/
│   ├── chat.usecase.ts       # SendMessage, GetConversations, GetMessages, 
│                             # StartConversation, AcceptConversation
└── chat.controller.ts        # Updated - full REST endpoints
```

**Implementation:**
- `ChatGateway` - WebSocket with JWT authentication, rooms by conversation
- `StartConversationUseCase` - Creates DM, sets PENDING if not following, ACTIVE if following
- `AcceptConversationUseCase` - Accepts PENDING conversation → ACTIVE
- `GetConversationsUseCase` - Returns conversations with PENDING/ACTIVE status

---

#### **C. Notifications Module** ✅ COMPLETE

**Files created:**
```
src/modules/notifications/
├── notifications.gateway.ts  # WebSocket for real-time notifications
├── fcm.service.ts           # Firebase Cloud Messaging
├── usecases/
│   └── notification.usecase.ts # GetNotifications, MarkAsRead, RegisterFcmToken
└── notifications.controller.ts # Updated
```

**Implementation:**
- `NotificationsGateway` - Real-time notification delivery via WebSocket
- `FcmService` - Push notifications (payment, message, follower, order)
- `RegisterFcmTokenUseCase` - Stores FCM token for push notifications

---

#### **D. Disputes Module** ✅ COMPLETE

**Files created:**
```
src/modules/disputes/
├── usecases/
│   └── dispute.usecase.ts   # OpenDispute, GetDispute, SubmitEvidence, ResolveDispute
└── disputes.controller.ts   # Updated
```

**Implementation:**
- `OpenDisputeUseCase` - Opens dispute within 48h of delivery, 72h expiry
- `SubmitEvidenceUseCase` - Buyer/seller submit evidence
- `ResolveDisputeUseCase` - Refund to buyer OR release to seller

---

#### **E. Reports Module** ✅ COMPLETE

**Files created:**
```
src/modules/reports/
├── usecases/
│   └── report.usecase.ts    # CreateReport, GetReports, ResolveReport
└── reports.controller.ts     # Updated
```

**Implementation:**
- `CreateReportUseCase` - Report users or posts (prevents duplicates)
- `GetReportsUseCase` - Admin view all reports
- `ResolveReportUseCase` - Admin resolves, can disable user

---

#### **F. Social Module** ✅ COMPLETE (Stories)

**Updated files:**
```
src/modules/social/
├── usecases/
│   └── social.usecase.ts    # Added: CreateStory, GetStories, ViewStory, DeleteStory
└── social.controller.ts      # Updated - story endpoints
```

**Implementation:**
- `CreateStoryUseCase` - Creates story with 24h expiry
- `GetStoriesUseCase` - Returns stories grouped by user
- `ViewStoryUseCase` - Records story views
- `DeleteStoryUseCase` - Deletes own stories

---

#### **G. Wallet Module** ✅ COMPLETE (Withdrawals)

**Updated files:**
```
src/modules/wallet/
├── usecases/
│   └── wallet.usecase.ts   # Added: Withdraw, RegisterBankAccount
└── wallet.controller.ts     # Updated - withdrawals, bank account
```

**Implementation:**
- `WithdrawUseCase` - Creates withdrawal, deducts from available balance (min R$20)
- `RegisterBankAccountUseCase` - Registers bank account for PagBank payouts

---

#### **H. Orders Module** ✅ COMPLETE (Escrow)

**Updated files:**
```
src/modules/orders/
├── usecases/
│   └── order.usecase.ts    # Added: ConfirmDelivery (release escrow), ActivateEscrow
└── orders.controller.ts     # Updated
```

**Implementation:**
- `ConfirmDeliveryUseCase` - Releases escrow: pending → available, updates transaction
- `ActivateEscrowUseCase` - Activates escrow on payment confirmation
- Full Prisma transaction for atomic balance updates

---

### 2.3 Database Changes

**Added to `DirectConversation`:**
```prisma
model DirectConversation {
  id            String    @id @default(uuid())
  user1Id       String
  user2Id       String
  status        String    @default("PENDING")  // PENDING | ACTIVE | BLOCKED
  lastMessageAt DateTime  @default(now())
  ...
}
```

---

### 2.4 Environment Variables

```env
# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/freebay

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT
JWT_SECRET=your-jwt-secret
JWT_EXPIRES_IN=15m
REFRESH_TOKEN_EXPIRES_IN=7d

# AbacatePay (PIX payments)
ABACATEPAY_API_KEY=sk_test_xxx
ABACATEPAY_WEBHOOK_SECRET=whsec_xxx

# PagBank (Payouts)
PAGBANK_CLIENT_ID=xxx
PAGBANK_CLIENT_SECRET=xxx
PAGBANK_WEBHOOK_SECRET=whsec_xxx

# Firebase (Push notifications)
FIREBASE_PROJECT_ID=freebay-xxx
FIREBASE_PRIVATE_KEY=xxx
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@...

# App
FRONTEND_URL=http://localhost:3000
API_URL=http://localhost:3001
```

---

## 3. Frontend Implementation Plan (Flutter)

### 3.1 Current State

**✅ Implemented:**
- Auth pages (login, register, splash)
- Profile pages (profile, edit, followers, following)
- Product pages (list, detail, create, my products)
- Social pages (feed, post details, comments, create post)
- Chat UI (conversation list, chat page)
- Wallet UI (wallet page)
- Core components (buttons, cards, text fields, avatars)
- Theme (colors, typography)

**❌ Missing:**
- Payment flow (Pix QR code display, card payment)
- Escrow status visualization
- Real WebSocket chat
- Push notifications
- Story viewer full implementation
- Dispute flow UI
- KYC verification UI
- Settings page
- Search (advanced)

### 3.2 Features to Implement

#### **A. Payment & Escrow UI**
```
lib/features/checkout/           # NEW
├── data/
│   ├── models/
│   │   ├── payment_model.dart
│   │   └── escrow_status_model.dart
│   └── repositories/
│       └── payment_repository.dart
├── domain/
│   └── usecases/
│       └── create_payment_usecase.dart
└── presentation/
    ├── pages/
    │   ├── payment_page.dart       # Select Pix/Card
    │   ├── pix_qr_page.dart        # Show QR code
    │   ├── payment_waiting_page.dart
    │   └── escrow_status_page.dart # Track HELD → RELEASED
    └── widgets/
        ├── escrow_timeline.dart
        └── payment_method_selector.dart
```

#### **B. Real-time Chat**
```
lib/features/chat/
├── data/
│   └── datasources/
│       └── chat_websocket_datasource.dart  # WebSocket client
└── presentation/
    └── providers/
        └── chat_provider.dart      # Update to use WebSocket
```

#### **C. Dispute Flow**
```
lib/features/dispute/              # NEW
├── data/
│   ├── models/
│   │   └── dispute_model.dart
│   └── repositories/
│       └── dispute_repository.dart
└── presentation/
    ├── pages/
    │   ├── open_dispute_page.dart
    │   ├── dispute_detail_page.dart
    │   └── submit_evidence_page.dart
    └── widgets/
        └── dispute_timeline.dart
```

#### **D. KYC Verification**
```
lib/features/kyc/                  # NEW
├── data/
│   └── repositories/
│       └── kyc_repository.dart
└── presentation/
    ├── pages/
    │   ├── kyc_start_page.dart
    │   ├── cpf_validation_page.dart
    │   └── selfie_verification_page.dart
    └── widgets/
        └── document_camera_widget.dart
```

---

## 4. Integration Points

### 4.1 AbacatePay API

```typescript
// Base URL: https://api.abacatepay.com.br/v1
// Auth: x-api-key header

// Create PIX charge
POST /charge
{
  "correlationID": "order-uuid",
  "value": 5000,  // cents
  "comment": "Purchase on FreeBay",
  "expiresIn": 3600,
  "customer": {
    "name": "John Doe",
    "taxID": "12345678900",  // CPF
    "email": "john@example.com"
  }
}

// Response
{
  "id": "ch_xxx",
  "status": "PENDING",
  "pix": {
    "key": "12345678-1234-1234-1234-123456789012",
    "image": "data:image/png;base64,...",
    "qrCode": "000201..."
  }
}
```

### 4.2 PagBank API

```typescript
// Base URL: https://api.pagbank.com.br
// Auth: Bearer token

// Create recipient (seller bank account)
POST /accounts/recipients
{
  "name": "Seller Name",
  "email": "seller@email.com",
  "document": "12345678900",
  "type": "individual",
  "default_bank_account": {
    "holder_name": "Seller Name",
    "holder_type": "individual",
    "holder_document": "12345678900",
    "bank": "001",  // Banco do Brasil
    "branch_number": "12345",
    "branch_check_digit": "1",
    "account_number": "12345678",
    "account_check_digit": "9",
    "type": "checking"
  }
}

// Transfer to recipient
POST /transfers
{
  "amount": 4700,  // after 6% fee
  "recipient_id": "rec_xxx"
}
```

### 4.3 Firebase Cloud Messaging

```typescript
// Server-side: firebase-admin
// Client-side: firebase_messaging package

// Request permissions
await FirebaseMessaging.instance.requestPermission();

// Get token
final fcmToken = await FirebaseMessaging.instance.getToken();

// Send to backend
await http.post(
  '/users/fcm-token',
  headers: authHeaders,
  body: { fcmToken },
);
```

---

## 5. Implementation Phases

### **Phase 1: Backend Modules** ✅ COMPLETED

| Task | Status |
|------|--------|
| Social Stories implementation | ✅ |
| Wallet Withdrawals | ✅ |
| Orders Escrow flow | ✅ |
| Payments (AbacatePay + PagBank) | ✅ |
| Chat WebSocket + Pending | ✅ |
| Notifications WebSocket + FCM | ✅ |
| Disputes flow | ✅ |
| Reports system | ✅ |

### **Phase 2: Frontend Integration** (Next)

| Task | Priority |
|------|----------|
| Payment flow UI (PIX QR) | High |
| Real-time Chat WebSocket | High |
| Push Notifications | High |
| Dispute UI | Medium |
| Story viewer | Medium |
| KYC verification UI | Medium |

### **Phase 3: Infrastructure** (Later)

| Task | Priority |
|------|----------|
| File Upload (S3) | High |
| Admin Panel | Medium |
| Analytics Dashboard | Low |
| Performance optimization | Low |

---

## 6. Environment Variables

```env
# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/freebay

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT
JWT_SECRET=your-jwt-secret
JWT_EXPIRES_IN=15m
REFRESH_TOKEN_EXPIRES_IN=7d

# AbacatePay
ABACATEPAY_API_KEY=sk_test_xxx
ABACATEPAY_WEBHOOK_SECRET=whsec_xxx

# PagBank
PAGBANK_CLIENT_ID=xxx
PAGBANK_CLIENT_SECRET=xxx
PAGBANK_WEBHOOK_SECRET=whsec_xxx

# Firebase
FIREBASE_PROJECT_ID=freebay-xxx
FIREBASE_PRIVATE_KEY=xxx
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@...

# Storage
STORAGE_TYPE=local  # or 's3'
AWS_S3_BUCKET=freebay-uploads
AWS_ACCESS_KEY_ID=xxx
AWS_SECRET_ACCESS_KEY=xxx

# App
FRONTEND_URL=http://localhost:3000
API_URL=http://localhost:3001
```

---

## 7. API Endpoints Summary

### Authentication
- `POST /auth/register` ✅
- `POST /auth/login` ✅
- `POST /auth/refresh` ✅
- `POST /auth/guest` ✅

### Users
- `GET /users/profile/:id` ✅
- `PATCH /users/profile` ✅
- `POST /users/fcm-token` ✅

### Products
- `POST /products` ✅
- `GET /products` ✅
- `GET /products/:id` ✅
- `DELETE /products/:id` ✅
- `POST /products/:id/images` (TODO - need file upload)

### Social
- `POST /social/posts` ✅
- `GET /social/feed` ✅
- `POST /social/posts/:id/like` ✅
- `POST /social/posts/:id/comment` ✅
- `GET /social/stories` ✅
- `GET /social/stories/user/:userId` ✅
- `POST /social/stories` ✅
- `DELETE /social/stories/:id` ✅
- `POST /social/stories/:id/view` ✅

### Orders
- `POST /orders` ✅
- `GET /orders/:id` ✅
- `PATCH /orders/:id/confirm` ✅ (releases escrow)

### Payments
- `POST /payments/pix/:orderId` ✅
- `POST /payments/webhook` ✅
- `POST /payments/withdrawals/:id/process` ✅

### Wallet
- `GET /wallet` ✅
- `GET /wallet/transactions` ✅
- `POST /wallet/withdraw` ✅
- `POST /wallet/bank-account` ✅
- `GET /wallet/withdrawals` ✅

### Chat
- WebSocket `/chat` ✅
- `GET /chat/conversations` ✅
- `POST /chat/conversations` ✅ (start new)
- `POST /chat/conversations/:id/accept` ✅ (accept pending)
- `GET /chat/conversations/:id` ✅
- `POST /chat/conversations/:id/messages` ✅

### Disputes
- `POST /disputes` ✅
- `GET /disputes` ✅
- `GET /disputes/:id` ✅
- `POST /disputes/:id/evidence` ✅
- `POST /disputes/:id/resolve` ✅

### Notifications
- WebSocket `/notifications` ✅
- `GET /notifications` ✅
- `POST /notifications/:id/read` ✅
- `POST /notifications/fcm-token` ✅
- `POST /notifications/read-all` ✅

### Reports
- `POST /reports` ✅
- `GET /reports` ✅ (admin)
- `POST /reports/:id/resolve` ✅ (admin)

---

## 8. Technology Stack Summary

| Layer | Technology | Version |
|-------|------------|---------|
| Backend | NestJS | ^11.0.0 |
| Database | PostgreSQL | 15+ |
| ORM | Prisma | ^7.4.2 |
| Cache/Queue | Redis | 7+ |
| Auth | JWT | - |
| Payments | AbacatePay + PagBank | API v1 |
| Push | Firebase Cloud Messaging | - |
| File Storage | AWS S3 / Local | - |
| Frontend | Flutter | 3.x |
| State Management | Riverpod / GetX | - |

---

## 9. Summary

### ✅ Completed Backend Implementation

All 8 modules have been fully implemented:
1. **Social** - Stories CRUD, view tracking
2. **Wallet** - Withdrawals, bank account registration
3. **Orders** - Full escrow flow (HELD → RELEASED)
4. **Payments** - AbacatePay (PIX) + PagBank (payouts)
5. **Chat** - WebSocket + PENDING/ACTIVE for non-followers
6. **Notifications** - WebSocket + FCM push
7. **Disputes** - Open, evidence, resolution
8. **Reports** - User/post reporting, admin resolution

### 📋 Next Steps

1. **Frontend Integration** - Connect Flutter to new endpoints
2. **File Upload** - Implement S3/local storage for images
3. **KYC** - Add CPF + selfie verification
4. **Admin Panel** - Platform moderation
5. **Tests** - Write E2E tests

---

## 10. Technology Stack Summary

| Layer | Technology | Version |
|-------|------------|---------|
| Backend | NestJS | ^11.0.0 |
| Database | PostgreSQL | 15+ |
| ORM | Prisma | ^7.4.2 |
| Cache/Queue | Redis | 7+ |
| Auth | JWT | - |
| Payments | AbacatePay + PagBank | API v1 |
| Push | Firebase Cloud Messaging | - |
| File Storage | AWS S3 / Local | - |
| Frontend | Flutter | 3.x |
| State Management | Riverpod / GetX | - |
