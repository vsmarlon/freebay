# FreeBay

<p align="center">
  <img src="https://img.shields.io/badge/NestJS-11-E23C56?style=flat&logo=nestjs" alt="NestJS">
  <img src="https://img.shields.io/badge/Flutter-3.6-02569B?style=flat&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Prisma-7.4-2D3748?style=flat&logo=prisma" alt="Prisma">
  <img src="https://img.shields.io/badge/PostgreSQL-4169E1?style=flat&logo=postgresql" alt="PostgreSQL">
  <img src="https://img.shields.io/badge/Redis-DC382D?style=flat&logo=redis" alt="Redis">
</p>

FreeBay é uma plataforma de marketplace híbrida **C2C** (Customer to Customer) que combina a interatividade social do **Instagram** com a robustez e segurança de transações do **Mercado Livre**.

---

## O Projeto

FreeBay permite que usuários vendam e comprem produtos enquanto interagem em uma rede social integrada. O diferenciador principal é o sistema de **escrow** (garantia) que protege ambas as partes durante transações, além de uma experiência social rica para descoberta de produtos.

### Arquitetura

```
┌─────────────────────────────────────────────────────────────────┐
│                          FRONTEND                                │
│                    Flutter (Mobile App)                         │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ │
│  │  Auth   │ │ Social  │ │Products │ │ Orders  │ │ Wallet  │ │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ │
└───────┼───────────┼───────────┼───────────┼─────────────┼──────┘
        │           │           │           │             │
        │           │           │           │             │
        ▼           ▼           ▼           ▼             ▼
┌─────────────────────────────────────────────────────────────────┐
│                          BACKEND                                │
│                    NestJS + Prisma                              │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ │
│  │  Auth   │ │ Social  │ │Products │ │ Orders  │ │ Wallet  │ │
│  │ Module  │ │ Module  │ │ Module  │ │ Module  │ │ Module  │ │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ │
└───────┼───────────┼───────────┼───────────┼─────────────┼──────┘
        │           │           │           │             │
        ▼           ▼           ▼           ▼             ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────┐
│  PostgreSQL  │  │    Redis     │  │  WebSocket   │  │ Firebase │
│   (Database) │  │    (Cache)   │  │   (Chat)     │  │  (FCM)   │
└──────────────┘  └──────────────┘  └──────────────┘  └──────────┘
```

---

## Stack Tecnológica

### Backend

| Tecnologia | Versão | Propósito |
|------------|--------|-----------|
| NestJS | 11.x | Framework Node.js |
| TypeScript | 5.7.x | Linguagem fortemente tipada |
| Prisma | 7.4.x | ORM e migrations |
| PostgreSQL | - | Banco de dados relacional |
| Redis | - | Cache e sessões |
| Socket.io | 4.8.x | WebSocket para chat em tempo real |
| JWT | 11.x | Autenticação |
| Zod | 3.24.x | Validação de DTOs |
| Firebase | - | Cloud Messaging (FCM) |

### Frontend

| Tecnologia | Versão | Propósito |
|------------|--------|-----------|
| Flutter | 3.6.x | Framework UI |
| Riverpod | 2.6.x | State management |
| go_router | 15.x | Navegação |
| Dio | 5.8.x | HTTP client |
| Firebase Core | 4.4.x | Firebase SDK |
| Firebase Messaging | 16.x | Push notifications |

---

## Funcionalidades por Status

### ✅ COMPLETO

Funcionalidades completamente implementadas (backend + frontend + testes).

#### 🔐 Autenticação (`auth`)
- Registro com email/senha
- Login com JWT (15min access, 7 dias refresh)
- Login guest (usuários não autenticados)
- JWT Strategy e Guards
- **Backend:** `nest-backend/src/modules/auth/`
- **Frontend:** `frontend/lib/features/auth/`

#### 👤 Usuários e Perfil (`users`)
- CRUD de perfil (displayName, bio, avatar, city, state)
- Sistema de seguidores (follow/unfollow)
- Sistema de blocking (block/unblock)
- Repositórios separados: `follow.repository.ts`, `block.repository.ts`
- **Backend:** `nest-backend/src/modules/users/`
- **Frontend:** `frontend/lib/features/profile/`

#### 📦 Produtos (`products`)
- Criar, editar, listar, deletar produtos
- Categorias hierárquicas (parent/child)
- Busca por título/descrição
- Imagens múltiplas por produto
- Condição: NEW, USED
- Status: ACTIVE, SOLD, PAUSED, DELETED
- **Backend:** `nest-backend/src/modules/products/`, `nest-backend/src/modules/category/`
- **Frontend:** `frontend/lib/features/product/`

#### 📱 Social / Feed (`social`)
- Posts (type: PRODUCT, REGULAR)
- Likes em posts
- Comentários (threaded com parentId)
- Contadores: likesCount, commentsCount, sharesCount
- Feed social com paginação
- **Backend:** `nest-backend/src/modules/social/`
- **Frontend:** `frontend/lib/features/social/` (verificar existência)

#### 🛒 Pedidos (`orders`)
- Ciclo de vida completo do pedido
- Estados: PENDING → CONFIRMED → SHIPPED → DELIVERED → DISPUTED → COMPLETED/CANCELLED
- Relação buyer/seller
- Cálculo automático de platformFee e sellerAmount
- **Backend:** `nest-backend/src/modules/orders/`
- **Frontend:** `frontend/lib/features/orders/`

#### 🛒 Carrinho (`cart`)
- Adicionar/remover itens
- Checkout com criação de order
- **Backend:** `nest-backend/src/modules/cart/`
- **Frontend:** `frontend/lib/features/cart/`

#### 💰 Carteira (`wallet`)
- Saldo disponível e pendente
- Total earned (acumulado)
- Saques (withdrawals) com status
- **Backend:** `nest-backend/src/modules/wallet/`
- **Frontend:** `frontend/lib/features/wallet/`

---

### 🔄 INCOMPLETO / PARCIAL

Funcionalidades com implementação parcial (algumas partes faltando).

#### ⭐ Avaliações (`reviews`)
| Componente | Status |
|------------|--------|
| Controller | ✅ Completo |
| Use Cases | ✅ Completo |
| Repository | ✅ Completo |
| Module | ❌ Falta `reviews.module.ts` |
| Tests | ✅ Unit + Integration |

- Reviews bidirecionais: buyer_reviewing_seller, seller_reviewing_buyer
- Score 1-5 com comentário opcional
- Restrição: só pode revisar após order entregue
- **Backend:** `nest-backend/src/modules/reviews/`
- **Frontend:** `frontend/lib/features/reviews/`

#### 💳 Pagamentos (`payments`)
| Componente | Status |
|------------|--------|
| Controller | ✅ Completo |
| Use Cases | ✅ Completo |
| Provider (AbacatePay) | ✅ Completo |
| Repository | ❌ Não existe (lógica no use case) |
| Tests | ✅ Unit test |

- Métodos: PIX, CREDIT_CARD
- Providers reais: **AbacatePay** (PIX), **PagBank** (payouts). O enum `PaymentProvider` ainda usa labels legados `PAGARME`/`WOOVI` por razões históricas — os adapters por trás apontam para AbacatePay/PagBank.
- Idempotency keys para evitar duplicatas
- PIX QR Code com expiração
- **Backend:** `nest-backend/src/modules/payments/`
- **Frontend:** `frontend/lib/features/payments/`

#### 💬 Chat (`chat`)
| Componente | Status |
|------------|--------|
| Controller | ✅ Completo |
| Use Cases | ✅ Completo |
| WebSocket Gateway | ✅ Completo |
| Repository | ❌ Não existe |
| Tests | ❌ Não existe |

- Mensagens associadas a orders
- WebSocket para tempo real
- Tipos: TEXT, IMAGE, VIDEO, GIF, PRODUCT_CARD, LOCATION
- **Backend:** `nest-backend/src/modules/chat/`
- **Frontend:** `frontend/lib/features/chat/`

#### 🔔 Notificações (`notifications`)
| Componente | Status |
|------------|--------|
| Controller | ✅ Completo |
| Use Cases | ✅ Completo |
| WebSocket Gateway | ✅ Completo |
| FCM Service | ✅ Completo |
| Repository | ❌ Não existe |
| Tests | ✅ Unit test |

- Tipos: ORDER, FOLLOW, MESSAGE, DISPUTE, PAYMENT
- Push via Firebase Cloud Messaging
- Notificações in-app persistidas
- **Backend:** `nest-backend/src/modules/notifications/`
- **Frontend:** `frontend/lib/features/notifications/`

---

### 📋 NÃO INICIADO / A FAZER

Funcionalidades projetadas mas não implementadas.

#### 📂 Categoria (`category`)
```
Status: Controller existe, use cases/repositório não existem
```
- Modelo: Category com parent/child hierarchy
- Endpoint: category.controller.ts (vazio)
- **Precisa:** Implementar use cases CRUD, repository

#### ❤️ Lista de Desejos (`wishlist`)
```
Status: Controller + Repository existem, use cases não existem
```
- Modelo: Wishlist (userId, productId)
- Repository: `wishlist.repository.ts`
- **Precisa:** Implementar use cases, testes

#### ⭐ Favoritos (`favorites`)
```
Status: Controller + Repository existem, use cases não existem
```
- Modelo: Favorite (userId, productId)
- Repository: `favorite.repository.ts`
- **Precisa:** Implementar use cases, testes

#### ⚖️ Disputas (`disputes`)
```
Status: Mínimo implementado, sem repository dedicado
```
- Modelo: Dispute com evidence (buyerEvidence, sellerEvidence)
- Estados: OPEN → AWAITING_SELLER → AWAITING_BUYER → RESOLVED/CANCELLED
- Prazo de expiração (expiresAt)
- **Precisa:** Repository dedicado, completar use cases, frontend

#### 🚩 Reports (`reports`)
```
Status: Mínimo implementado, sem repository/testes
```
- Modelo: Report (reporterId, reportedUserId/postId)
- Razões: FALSE_ADVERTISING, SPAM, FRAUD, NUDITY, FAKE_ACCOUNT, etc.
- Estados: PENDING, REVIEWED, RESOLVED, REJECTED
- **Precisa:** Repository, testes, frontend completo

#### 📖 Stories (social)
```
Status: Modelos existem no Prisma, backend não implementado
```
- Modelos: Story, StoryView
- Stories expiram (expiresAt)
- Views únicas por usuário
- **Precisa:** Implementar completo

---

## Database Schema

Local: `nest-backend/prisma/schema.prisma`

### Entidades (28 modelos)

| Entidade | Descrição | Relacionamentos |
|----------|-----------|------------------|
| **User** | Usuário da plataforma | wallet, products, posts, orders, reviews, follow/following, blocks, disputes, chat, etc. |
| **Category** | Categorias hierárquicas de produtos | parent/children, products |
| **Product** | Produto à venda | seller, category, post, images, orders, favorites, wishlist, cart |
| **ProductImage** | Imagens do produto | product (Cascade delete) |
| **Post** | Post no feed social | user, product, comments, likes, shares, savedBy |
| **Comment** | Comentário em post | user, post, parent (threaded), commentLikes |
| **CommentLike** | Like em comentário | user, comment |
| **Like** | Like em post | user, post (unique) |
| **Share** | Compartilhamento de post | user, post (unique) |
| **Follow** | Seguimento de usuário | follower, following (unique) |
| **Story** | Story efêmera do usuário | user, views |
| **StoryView** | Visualização de story | story, viewer (unique) |
| **Block** | Bloqueio de usuário | blocker, blocked (unique) |
| **Order** | Pedido de compra | buyer, seller, product, transaction, dispute, reviews, chatMessages |
| **Transaction** | Transação de pagamento | order (unique) |
| **Wallet** | Carteira do usuário | user (unique), withdrawals |
| **Withdrawal** | Solicitação de saque | wallet |
| **Dispute** | Disputa de pedido | order (unique), openedBy |
| **Review** | Avaliação após pedido | reviewer, reviewed, order (unique por type) |
| **ChatMessage** | Mensagem no contexto de pedido | order, sender |
| **DirectConversation** | Conversa direta entre usuários | user1, user2 (unique), messages |
| **DirectMessage** | Mensagem direta | conversation, sender |
| **Favorite** | Produto favoritado | user, product (unique) |
| **Wishlist** | Produto na lista de desejos | user, product (unique) |
| **CartItem** | Item no carrinho | user, product (unique) |
| **Report** | Denúncia de conteúdo/usuário | reporter, reportedUser/post |
| **Notification** | Notificação in-app | user |

### Enums (15 tipos)

```sql
-- Usuário
UserRole           : USER, ADMIN

-- Produto
Condition          : NEW, USED
ProductStatus      : ACTIVE, SOLD, PAUSED, DELETED

-- Social
PostType           : PRODUCT, REGULAR

-- Pedido
OrderStatus        : PENDING, CONFIRMED, SHIPPED, DELIVERED, DISPUTED, COMPLETED, CANCELLED
EscrowStatus       : HELD, RELEASED, REFUNDED

-- Pagamento
PaymentMethod      : PIX, CREDIT_CARD
PaymentProvider    : PAGARME, WOOVI
TransactionStatus  : PENDING, PROCESSING, PAID, HELD, RELEASED, REFUNDED, FAILED

-- Disputa
DisputeStatus      : OPEN, AWAITING_SELLER, AWAITING_BUYER, RESOLVED, CANCELLED

-- Review
ReviewType         : BUYER_REVIEWING_SELLER, SELLER_REVIEWING_BUYER

-- Mensagem direta
MessageType        : TEXT, IMAGE, VIDEO, GIF, PRODUCT_CARD, LOCATION

-- Report
ReportReason       : FALSE_ADVERTISING, SPAM, FRAUD, NUDITY, OTHER, FAKE_ACCOUNT, IMPERSONATING, BLACKMAIL
ReportStatus       : PENDING, REVIEWED, RESOLVED, REJECTED

-- Notificação
NotificationType   : ORDER, FOLLOW, MESSAGE, DISPUTE, PAYMENT
```

---

## Padrões de Arquitetura

### Clean Architecture (Backend)

```
src/
├── modules/                    # Vertical slices
│   ├── {module}/
│   │   ├── dtos/              # Zod validation schemas
│   │   ├── mappers/           # Prisma → API response
│   │   ├── repositories/      # Concrete repositories
│   │   ├── usecases/          # Business logic
│   │   ├── {module}.controller.ts
│   │   └── {module}.module.ts
│   └── ...
│
└── shared/                    # Reusable
    ├── core/                  # Either, AppError classes
    ├── infra/prisma/          # Prisma client
    └── http/                  # Route adapter
```

### Padrões Utilizados

| Padrão | Descrição |
|--------|-----------|
| **Either Type** | Retorno fortemente tipado (success/error) em use cases |
| **Zod DTOs** | Validação de input com schemas |
| **Route Adapter** | Elimina boilerplate de controllers |
| **Concrete Repos** | Sem interfaces, injeção direta |
| **Vertical Modules** | Cada feature é autocontida |

### Flutter Architecture (Frontend)

```
lib/
├── core/
│   ├── components/           # Design System components
│   ├── theme/                # Colors, typography, spacing
│   ├── router/               # go_router config
│   └── providers/            # Global providers
│
├── features/                 # Vertical features
│   ├── auth/
│   │   ├── data/            # Repositories, services
│   │   ├── domain/          # Use cases, entities
│   │   └── presentation/    # Pages, controllers, widgets
│   ├── product/
│   └── ...
│
└── shared/                   # Shared utilities
```

---

## Getting Started

### Pré-requisitos

- **Node.js** 18.x ou superior
- **Flutter** 3.6.x
- **PostgreSQL** (local ou Docker)
- **Redis** (local ou Docker)
- **Docker** (opcional, para DB)

### Backend

```bash
# 1. Instalar dependências
cd nest-backend
npm install

# 2. Configurar .env (baseado em .env.example)
# DATABASE_URL=postgresql://...
# JWT_SECRET=...
# REDIS_HOST=localhost

# 3. Gerar Prisma client e rodar migrations
npm run prisma:generate
npm run prisma:migrate

# 4. Iniciar em modo desenvolvimento
npm run start:dev
# ou
npm run start:dev     # equivalent to: nest start --watch
```

### Frontend

```bash
# 1. Instalar dependências
cd frontend
flutter pub get

# 2. Executar (emulador ou device)
flutter run

# 3. Buildar APK
flutter build apk --debug
# ou release
flutter build apk --release
```

### Testes

```bash
# Backend - Unit tests
cd nest-backend
npm run test

# Backend - Unit tests (watch mode)
npm run test:watch

# Backend - Integration tests
npm run test:integration

# Backend - Todos os testes
npm run test:all

# Frontend
cd frontend
flutter test
```

---

## Variáveis de Ambiente

### Backend (.env)

```env
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/freebay

# JWT
JWT_SECRET=your-super-secret-key
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# Firebase (FCM)
FCM_PROJECT_ID=your-project-id
FCM_PRIVATE_KEY=...
FCM_CLIENT_EMAIL=...

# Payment Provider
PAGARME_API_KEY=...
ABACATEPAY_API_KEY=...

# App
NODE_ENV=development
PORT=3000
```

---

## Estrutura do Projeto

```
freebay/
├── nest-backend/                    # Backend NestJS
│   ├── src/
│   │   ├── modules/
│   │   │   ├── auth/               # Login, register, JWT
│   │   │   ├── users/              # Profile, follow, block
│   │   │   ├── products/           # CRUD products
│   │   │   ├── category/           # Categories (incompleto)
│   │   │   ├── social/             # Posts, likes, comments
│   │   │   ├── orders/             # Order lifecycle
│   │   │   ├── payments/           # PIX, credit card
│   │   │   ├── wallet/             # Balance, withdrawals
│   │   │   ├── cart/               # Cart management
│   │   │   ├── wishlist/           # Wishlist (incompleto)
│   │   │   ├── favorites/          # Favorites (incompleto)
│   │   │   ├── disputes/           # Dispute system (incompleto)
│   │   │   ├── reviews/            # Ratings/reviews
│   │   │   ├── chat/               # Order chat (WebSocket)
│   │   │   ├── notifications/       # Push + in-app
│   │   │   └── reports/            # Content reports (incompleto)
│   │   │
│   │   └── shared/                 # Core, errors, http
│   │
│   ├── prisma/
│   │   └── schema.prisma          # 28 models, 15 enums
│   │
│   ├── test/                      # Integration tests setup
│   │
│   ├── package.json
│   ├── tsconfig.json
│   ├── nest-cli.json
│   └── jest.config.js
│
├── frontend/                       # Frontend Flutter
│   ├── lib/
│   │   ├── core/
│   │   │   ├── components/        # AppButton, AppTextField, etc.
│   │   │   ├── theme/             # AppColors, AppTypography
│   │   │   ├── router/            # GoRouter config
│   │   │   └── providers/         # Theme provider, etc.
│   │   │
│   │   ├── features/
│   │   │   ├── auth/              # Login, register, splash
│   │   │   ├── profile/           # Profile, followers, edit
│   │   │   ├── product/           # List, detail, create, edit
│   │   │   ├── cart/              # Cart, checkout
│   │   │   ├── orders/            # Order detail, status timeline
│   │   │   ├── payments/          # PIX payment
│   │   │   ├── wallet/            # Balance, transactions
│   │   │   ├── chat/              # Conversations
│   │   │   ├── notifications/    # Notification list
│   │   │   ├── reviews/           # Create review, user reviews
│   │   │   ├── favorites/         # Favorited products
│   │   │   └── wishlist/          # Wishlist items
│   │   │
│   │   └── shared/               # Services, utils
│   │
│   ├── assets/
│   │   ├── fonts/                # SpaceGrotesk, Inter
│   │   └── images/
│   │
│   ├── pubspec.yaml
│   └── test/
│
├── db/                            # Database
│   └── migrations/
│       └── 001_create_tables.sql # SQL migration
│
├── package.json                   # Root package (scripts)
├── README.md
└── AGENTS.md                      # Agent guidelines
```

---

## License

MIT License - Feel free to use this project for learning or as a starting point for your own marketplace application.

---

<p align="center">
  Made with ❤️ by the FreeBay Team
</p>