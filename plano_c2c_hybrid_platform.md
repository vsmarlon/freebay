# C2C Hybrid Platform — Plano Completo de Produto & Arquitetura

> Marketplace Social · Carteira Digital · Split Payment Justo · Escrow In-House

---

## Índice

1. [Visão do Produto](#1-visão-do-produto)
2. [Identidade Visual](#2-identidade-visual)
3. [Regras de Negócio](#3-regras-de-negócio)
4. [Perfil Social](#4-perfil-social)
5. [Stack de Pagamento](#5-stack-de-pagamento)
6. [Arquitetura Frontend — Flutter](#6-arquitetura-frontend--flutter)
7. [Arquitetura Backend — TypeScript + Fastify + Prisma](#7-arquitetura-backend--typescript--fastify--prisma)
8. [Modelo de Dados](#8-modelo-de-dados)
9. [Gateway de Pagamento — Integração](#9-gateway-de-pagamento--integração)
10. [Roadmap do MVP](#10-roadmap-do-mvp)
11. [Decisões Técnicas Anti-Bottleneck](#11-decisões-técnicas-anti-bottleneck)
12. [Posicionamento Competitivo](#12-posicionamento-competitivo)

## 0. Status Atual do Desenvolvimento (Checklist)

### ✅ Concluído
- Estruturação do repositório híbrido monorepo (Backend Fastify/Prisma, Frontend Flutter)
- Separação de Entidades de Domínio em arquivos limpos e individuais
- Implementação de Design Pattern Funcional para tratativa de Erros (`Either<L,R>`)
- Refatoração dos casos de uso (Auth, Product, Social, Wallet, Order) usando `Either`
- Isolamento dos `Inputs` / `Outputs` dos Use Cases para arquivos `$module/input/input.ts`
- Implementação e Mock dos Prisma Repositories
- Criação dos Controllers com Validação de DTOs via Zod (`auth`, `product`, `social`, etc)
- Configuração de todas as Rotas HTTP no backend mapeadas aos controllers
- Entidades de Resposta do Cliente Flutter (`Either.dart`, `ApiResponse.dart`, Models)
- Testes do Backend (Jest) corrigidos e estabilizados

### ⏳ A Fazer (Próximos Passos)
- Implementar integração real Pagar.me e Woovi (Gateway e Webhooks)
- Finalizar implementação de mensageria WebSockets (Chat in-house)
- Desenhamento UI e telas no Flutter conectadas à nossa API unificada
- Gerenciar estados complexos da Carteira e Escrow (Flutter + Backend)
- Criar a camada da interface pública dos Perfis Sociais / Anúncios

---

## 1. Visão do Produto

Uma plataforma **C2C híbrida** onde qualquer pessoa — sem CNPJ, sem nota fiscal, sem burocracia — pode vender e comprar produtos com a segurança de um escrow inteligente gerenciado in-house, a experiência de uma rede social e taxas que não massacram quem vende.

> **Missão:** Ser o marketplace mais justo do Brasil — proteger comprador e vendedor ao mesmo tempo, sem que a plataforma saia no prejuízo de nenhuma disputa.

> **Diferencial:** Perfil social com posts, likes, comentários e compartilhamentos. Reputação construída publicamente. Dados sensíveis protegidos. Taxas menores que todos os concorrentes para vendedor pessoa física. Escrow totalmente controlado pelo nosso backend.

### Por que existe essa oportunidade?

- Mercado Livre expulsou **80–90 mil vendedores PF** que não abriram CNPJ
- OLX gerou **R$ 3,5 bilhões em prejuízos** por fraudes em 2024 — sem escrow
- Enjoei consome **30–40%** do valor da venda em taxas e tarifas
- Shopee eleva comissões para o patamar do Mercado Livre em 2026
- Mercado de segunda mão: **R$ 58 bilhões**, crescendo 22,8% ao ano
- Pix já é o meio de pagamento mais usado no Brasil (**76,4% de adoção**)
- Geração Z trata brechó como estilo de vida — **80%+** quer comprar/vender usado

---

## 2. Identidade Visual

### Paleta de Cores

| Cor | Hex | Psicologia | Uso Principal |
|-----|-----|-----------|---------------|
| **Roxo Principal** | `#7C3AED` | Inovação, confiança, premium, criatividade | Brand, CTAs primários, headers |
| **Verde-Esmeralda** | `#10B981` | Dinheiro, crescimento, sucesso, aprovação | Saldo, confirmações, status positivo |
| **Cinza Escuro/Claro** | `#1F2937` / `#F9FAFB` | Neutralidade, leitura, minimalismo | Textos, fundos, backgrounds |

### Diretrizes de Design

- **Minimalista:** menos elementos, mais respiro — sem poluição visual
- **Bordas arredondadas:** `radius 12px` para cards, `8px` para inputs, `100px` para chips/badges
- **SVGs exclusivos** para ícones e ilustrações — sem PNG pixelado
- **Tipografia:** Inter — limpa, moderna, legível em qualquer tamanho
- **Sombras suaves:** box-shadow leve para elevar cards, sem efeito dramático
- **Imagens:** placeholders SVG com degradê roxo/verde onde irão fotos reais

---

## 3. Regras de Negócio

### 3.1 Modelo de Monetização — Taxa Justa

O modelo de taxa cobre os custos do **Pagar.me (~1.19–4.39% por transação)** mais margem operacional, com transparência total para o vendedor.

> **Custo base real:** Pagar.me cobra ~1.19% no Pix e ~4.39% + R$0.99 no crédito. Nossa taxa precisa cobrir isso mais a margem. Meta de taxa líquida para a plataforma: **4–6%**.

| Perfil do Vendedor | Volume Mensal | Taxa da Plataforma | Observação |
|---|---|---|---|
| Vendedor Casual | Até 10 vendas/mês | **8%** sobre o valor | Sem taxa fixa, sem mensalidade |
| Vendedor Ativo | 11 a 50 vendas/mês | **7%** sobre o valor | Acesso a analytics básico |
| Vendedor Profissional | 51+ vendas/mês | **6%** sobre o valor | Destaque nos resultados |
| Vendedor Premium | Ilimitado | **5% + R$29,90/mês** | Badge verificado + prioridade |

> **Transparência total:** A taxa é exibida ao vendedor **antes** de confirmar o anúncio. *"Você receberá R$ X após a taxa de Y%."* Nenhum custo oculto.

### 3.2 Fluxo de Pagamento com Escrow In-House

O escrow vive inteiramente no nosso backend. O Pagar.me entrega os fundos para a **conta da plataforma** — nós controlamos quando e quanto liberamos para o vendedor.

```
Comprador paga
      ↓
Pagar.me processa → fundos chegam na conta da plataforma
      ↓
Transaction criada: status = HELD
Wallet do vendedor: pendingBalance += valor bruto
      ↓
[Encontro presencial combinado via chat interno]
      ↓
Comprador confirma entrega no app
      ↓
Split calculado no backend:
  ├── vendedor: availableBalance += (valor - taxa da plataforma)
  └── plataforma: retém a taxa
Transaction → status = RELEASED
      ↓
Vendedor pode sacar via Recipients API do Pagar.me
```

| Etapa | Ação | Responsável | Prazo |
|---|---|---|---|
| 1. Comprador paga | Pix ou cartão via Pagar.me | Comprador | No ato |
| 2. Escrow ativado | `Transaction.status = HELD`, pendingBalance atualizado | Sistema | Imediato |
| 3. Encontro presencial | Combinado via chat interno criptografado | Ambos | Acordado |
| 4. Confirmação de entrega | Comprador confirma no app | Comprador | No momento |
| 5. Split & liberação | Backend calcula split, `status = RELEASED`, disponível para saque | Sistema | Até 1h |
| 6. Avaliação mútua | Bidirecional obrigatória para liberar próxima venda | Ambos | Até 48h |

### 3.3 Política de Disputas — Plataforma Neutra

A plataforma **nunca absorve o prejuízo**. O escrow só é liberado após a disputa ser resolvida.

**Regras:**
- Abertura: qualquer parte pode abrir disputa em até **48h** após a entrega confirmada
- **Evidência bilateral obrigatória:** ambos enviam fotos/vídeo. Sem evidência = sem direito de reclamar
- Prazo de resposta: **72h** para a outra parte responder
- Em caso de empate: valor devolvido ao comprador, produto devolvido ao vendedor
- Usuário com **3 disputas perdidas em 90 dias** é suspenso preventivamente
- O escrow **permanece retido** até resolução completa

### 3.4 Sistema de Reputação Bidirecional

Diferente do Mercado Livre, avaliamos **comprador E vendedor**:

- Score de **1 a 5 estrelas** para ambas as partes — público no perfil social
- Métricas adicionais: taxa de resposta, tempo médio, taxa de disputas, volume
- **Badge Verificado:** CPF + selfie + celular validados — dados não expostos, apenas confirmados
- **Badge Top Seller:** 4.5+ estrelas e 20+ vendas nos últimos 90 dias
- Reputação não pode ser deletada — apenas construída ao longo do tempo

---

## 4. Perfil Social

O perfil não é apenas uma loja — é uma identidade. Inspirado em **Instagram + Depop**, com privacidade como princípio.

### 4.1 Estrutura do Perfil

| Elemento | Visível ao Público | Descrição |
|---|---|---|
| Avatar / Foto de perfil | ✅ | Foto ou avatar SVG gerado automaticamente |
| Nome de exibição | ✅ | Apelido escolhido — nome real **nunca** exposto |
| Bio | ✅ | Texto livre de até 150 caracteres |
| Score de reputação | ✅ | Estrelas + badges conquistados |
| Cidade (geral) | ✅ | Apenas cidade/estado — endereço exato **nunca** exposto |
| Posts e anúncios | ✅ | Feed público de publicações |
| Seguidores / Seguindo | ✅ | Rede social padrão |
| Telefone / CPF / E-mail | ❌ | Apenas verificado internamente |
| Histórico de transações | ❌ | Privado — apenas contagens agregadas |

### 4.2 Tipos de Post

- **Anúncio de Produto:** post principal com fotos (até 8), vídeo (até 30s), preço e botão "Comprar". Tags de categoria, condição (novo/usado) e localização geral
- **Post Regular:** conteúdo sem produto vinculado — para engajamento e construção de audiência
- **Story (futuro):** conteúdo efêmero 24h para promoções relâmpago

### 4.3 Interações Sociais

- **Like** — coração no post, contador público
- **Comentário** — texto público, vendedor pode responder, denunciar ou deletar
- **Compartilhar** — gera link público do produto, rastreado para analytics
- **Salvar** — bookmarks privados do comprador
- **Seguir** — feed personalizado com posts de quem você segue
- **Mencionar (@usuario)** — notificação push instantânea

> **Privacidade no encontro:** O chat interno é criptografado. Localização exata é trocada apenas no momento do encontro e não fica armazenada.

---

## 5. Stack de Pagamento

### Decisão Final

Após pesquisa comparativa de processadores disponíveis no Brasil para nosso C2C (sem CNPJ obrigatório):

| Provider | Função | Por quê |
|---|---|---|
| **AbacatePay** | Recebimentos (Pix, Cartão) | Sem necessidade de CNPJ, taxas menores, API simples focada em Pix |
| **PagBank** | Custódia e Pagamentos (Payout) | Usado para transferirar os valores via Pix aos vendedores assim que o escrow for liberado |

### Por que não os outros?

| Provider | Motivo da Eliminação |
|---|---|
| PagBank/PagSeguro | Exige conta PagBank para cada vendedor (alta fricção no C2C), Pix a 1.89% |
| Mercado Pago | Split só entre contas MP — inviável para C2C com saques bancários |
| Stripe Connect | Pix via EBANX (complexidade extra), taxas similares ao Pagar.me |
| Zoop | Enterprise — sem preço público, overkill para MVP |
| Adyen | Mínimo de volume que desqualifica early-stage |
| Juno | Descontinuado — migrado para iugu/EBANX |

### Escrow In-House — Por que não precisamos do escrow do processador

O AbacatePay recebe o pagamento e repassa os fundos para a **conta da plataforma**. Nós controlamos o repasse aos vendedores:

```
AbacatePay → conta da plataforma → [nossa lógica] → chave Pix do vendedor
                                        ↑
                            Aqui mora o escrow:
                            Transaction.status = HELD | RELEASED
                            Wallet.pendingBalance vs availableBalance
```

O repasse para o vendedor acontece via **API do PagBank (ou transferência programática)**, pagando diretamente na chave Pix do vendedor no momento em que a entrega for confirmada. O custo de repasse via Pix costuma ser zero ou muito baixo.

### Comparativo de Taxas Estimado

| Método | AbacatePay | Saque (PagBank) | Nossa taxa ao vendedor | Margem líquida |
|---|---|---|---|---|
| Pix | ~1.00% | R$ 0,00 | 6–8% | ~5–7% |
| Crédito 1x | ~4.00% | R$ 0,00 | 7–8% | ~3.00% |
| Crédito parcelado | +~2.99%/parcela | N/A | Não oferecer parcelado no MVP | — |

> **Decisão MVP:** Oferecer apenas **Pix e crédito à vista** no início. Parcelado encarece demais e complica o escrow.

---

## 6. Arquitetura Frontend — Flutter

### 6.1 Clean Architecture — Estrutura de Pastas

```
lib/
├── core/
│   ├── theme/              # tokens: cores, tipografia, bordas, spacing
│   ├── components/         # Design System completo
│   └── router/             # go_router — rotas nomeadas + guards
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── entities/           # AuthToken, UserEntity
│   │   │   └── datasources/        # AuthRemoteDataSource (http)
│   │   ├── domain/
│   │   │   ├── repositories/       # IAuthRepository (interface)
│   │   │   └── usecases/           # LoginUseCase, RegisterUseCase
│   │   └── presentation/
│   │       ├── pages/              # LoginPage, RegisterPage
│   │       ├── controllers/        # AuthController (estado + lógica)
│   │       └── forms/              # LoginForm, RegisterForm
│   │
│   ├── social/             # Feed, posts, likes, comentários
│   ├── product/            # Anúncios, busca, detalhe
│   ├── checkout/           # Pagamento, confirmação, escrow status
│   ├── wallet/             # Saldo, extrato, saque
│   ├── chat/               # Chat criptografado entre comprador/vendedor
│   ├── dispute/            # Abertura e acompanhamento de disputas
│   └── profile/            # Perfil social, reputação, badges
│
└── shared/
    ├── services/           # HttpClient, StorageService, TokenService
    └── errors/             # Failures, Exceptions padronizados
```

### 6.2 Design System — Componentes

| Componente | Descrição | Variantes |
|---|---|---|
| `AppButton` | Botão com loading state, radius 12 | Primary, Secondary, Ghost, Danger |
| `AppTextField` | Input com validação inline, ícones | Default, Error, Success, Disabled |
| `AppCard` | Card de produto com imagem, preço, score | Compact, Full, Skeleton |
| `BannerCarousel` | Carrossel SVG placeholders + dots | AutoPlay, Manual |
| `SocialPost` | Post do feed — foto, like, comentário, share | Anúncio, Regular, Loading |
| `UserAvatar` | Avatar circular + badge verificação | Small (32), Medium (48), Large (80) |
| `ReputationStars` | Score 1–5 com contagem de avaliações | Compact, Full, Editable |
| `EscrowStatus` | Timeline visual do status do pagamento | Pending, Held, Released, Dispute |
| `AppBottomSheet` | Modal deslizante para ações rápidas | Actions, Confirmation, Form |
| `WalletCard` | Saldo disponível + a liberar com animação | Default, Minimized |

---

## 7. Arquitetura Backend — TypeScript + Fastify + Prisma

### 7.1 Clean Architecture — Estrutura de Pastas

```
src/
├── domain/
│   ├── entities/           # User, Product, Order, Wallet, Post, Dispute — classes puras
│   ├── repositories/       # Interfaces: IUserRepository, IOrderRepository, etc.
│   └── usecases/           # Interfaces dos casos de uso
│
├── application/
│   └── usecases/
│       ├── auth/           # LoginUseCase, RegisterUseCase, RefreshTokenUseCase
│       ├── social/         # CreatePostUseCase, LikePostUseCase
│       ├── products/       # CreateProductUseCase, SearchProductsUseCase
│       ├── orders/         # CreateOrderUseCase, ConfirmDeliveryUseCase
│       ├── payments/       # ProcessPaymentUseCase, ReleaseEscrowUseCase
│       └── wallet/         # GetWalletUseCase, WithdrawUseCase
│
├── infra/
│   ├── database/
│   │   ├── prisma/         # schema.prisma, migrations, PrismaClient
│   │   └── repositories/   # PrismaUserRepository, PrismaOrderRepository, etc.
│   ├── http/
│   │   ├── fastify/        # instância, plugins (@fastify/jwt, cors, helmet)
│   │   └── routes/         # registro de rotas por módulo
│   ├── payment/
│   │   ├── pagarme/        # PagarmeClient, RecipientService, WebhookParser
│   │   └── woovi/          # WooviClient (Pix de alto volume)
│   ├── queue/              # Bull + Redis — webhooks async, jobs de liberação
│   └── cache/              # Redis adapter — feed cache, rate limiting
│
└── presentation/
    ├── controllers/        # recebem request → chamam usecase → retornam response
    ├── middlewares/        # AuthGuard, RateLimiter, ErrorHandler
    └── dtos/               # validação de entrada com Zod
```

### 7.2 Módulos e Endpoints

| Módulo | Endpoints Principais | Regras Chave |
|---|---|---|
| `auth` | POST /register, /login, /refresh, /logout | JWT + refresh tokens, bcrypt+salt (12 rounds), blacklist Redis |
| `users` | GET /profile/:id, PATCH /profile, POST /verify | Perfil público sem dados sensíveis, KYC via CPF+selfie |
| `social` | POST /posts, GET /feed, POST /likes, /comments, /shares | Feed paginado por cursor, contadores em cache Redis |
| `products` | POST /products, GET /products, GET /products/:id, DELETE | Anúncio vinculado a post, soft delete, status: active/sold/paused |
| `orders` | POST /orders, GET /orders/:id, PATCH /orders/:id/confirm | Cria escrow ao criar pedido, libera após confirmação |
| `payments` | POST /payments/pix, POST /payments/card, POST /payments/webhook | Pagar.me + Woovi, webhook async via Bull, idempotency key |
| `wallet` | GET /wallet, GET /wallet/transactions, POST /wallet/withdraw | pendingBalance vs availableBalance, saque via Recipients API |
| `recipients` | POST /recipients, GET /recipients/:id | Cadastro de conta bancária do vendedor no Pagar.me |
| `disputes` | POST /disputes, PATCH /disputes/:id/evidence, PATCH /disputes/:id/resolve | Evidência bilateral obrigatória, timer 72h |
| `chat` | WebSocket /chat/:orderId | Criptografado, apenas para o par comprador+vendedor do pedido |
| `notifications` | GET /notifications, WebSocket /notifications | FCM push + badge counter em tempo real |

---

## 8. Modelo de Dados

### Entidades Core

```prisma
model User {
  id              String   @id @default(uuid())
  displayName     String
  email           String   @unique  // privado — nunca exposto na API pública
  emailVerified   Boolean  @default(false)
  passwordHash    String
  cpfHash         String?  @unique  // hash do CPF — verificado mas não exposto
  phone           String?           // privado
  phoneVerified   Boolean  @default(false)
  city            String?
  state           String?
  avatarUrl       String?
  bio             String?  @db.VarChar(150)
  isVerified      Boolean  @default(false)  // badge verificado
  role            UserRole @default(USER)
  reputationScore Float    @default(0)
  totalReviews    Int      @default(0)
  createdAt       DateTime @default(now())

  wallet          Wallet?
  products        Product[]
  posts           Post[]
  ordersAsBuyer   Order[]  @relation("BuyerOrders")
  ordersAsSeller  Order[]  @relation("SellerOrders")
  reviewsGiven    Review[] @relation("ReviewsGiven")
  reviewsReceived Review[] @relation("ReviewsReceived")
  followers       Follow[] @relation("Following")
  following       Follow[] @relation("Followers")
}

model Product {
  id          String        @id @default(uuid())
  title       String
  description String
  price       Int           // em centavos — nunca float
  condition   Condition     // NEW | USED
  status      ProductStatus // ACTIVE | SOLD | PAUSED | DELETED
  sellerId    String
  postId      String?       @unique
  createdAt   DateTime      @default(now())
  deletedAt   DateTime?     // soft delete

  seller      User          @relation(fields: [sellerId], references: [id])
  post        Post?         @relation(fields: [postId], references: [id])
  images      ProductImage[]
  orders      Order[]
}

model Post {
  id            String    @id @default(uuid())
  content       String?
  type          PostType  // PRODUCT | REGULAR
  userId        String
  likesCount    Int       @default(0)
  commentsCount Int       @default(0)
  sharesCount   Int       @default(0)
  createdAt     DateTime  @default(now())

  user          User      @relation(fields: [userId], references: [id])
  product       Product?
  comments      Comment[]
  likes         Like[]
}

model Order {
  id                  String        @id @default(uuid())
  buyerId             String
  sellerId            String
  productId           String
  amount              Int           // em centavos
  platformFee         Int           // taxa da plataforma em centavos
  sellerAmount        Int           // amount - platformFee
  status              OrderStatus   // PENDING | CONFIRMED | DISPUTED | COMPLETED | CANCELLED
  escrowStatus        EscrowStatus  // HELD | RELEASED | REFUNDED
  meetingScheduledAt  DateTime?
  deliveryConfirmedAt DateTime?
  createdAt           DateTime      @default(now())

  buyer               User          @relation("BuyerOrders", fields: [buyerId], references: [id])
  seller              User          @relation("SellerOrders", fields: [sellerId], references: [id])
  product             Product       @relation(fields: [productId], references: [id])
  transaction         Transaction?
  dispute             Dispute?
  reviews             Review[]
  chatMessages        ChatMessage[]
}

model Transaction {
  id               String            @id @default(uuid())
  orderId          String            @unique
  externalId       String?           // ID do Pagar.me
  amount           Int
  platformFee      Int
  sellerAmount     Int
  paymentMethod    PaymentMethod     // PIX | CREDIT_CARD
  provider         PaymentProvider   // PAGARME | WOOVI
  status           TransactionStatus // PENDING | PROCESSING | PAID | HELD | RELEASED | REFUNDED | FAILED
  idempotencyKey   String            @unique
  pixQrCode        String?
  pixExpiresAt     DateTime?
  paidAt           DateTime?
  releasedAt       DateTime?
  createdAt        DateTime          @default(now())

  order            Order             @relation(fields: [orderId], references: [id])
}

model Wallet {
  id               String    @id @default(uuid())
  userId           String    @unique
  availableBalance Int       @default(0)  // em centavos — pronto para saque
  pendingBalance   Int       @default(0)  // em centavos — retido no escrow
  totalEarned      Int       @default(0)
  recipientId      String?               // ID do recipient no Pagar.me

  user             User      @relation(fields: [userId], references: [id])
  withdrawals      Withdrawal[]
}

model Dispute {
  id              String        @id @default(uuid())
  orderId         String        @unique
  openedById      String
  status          DisputeStatus // OPEN | AWAITING_SELLER | AWAITING_BUYER | RESOLVED | CANCELLED
  reason          String
  buyerEvidence   Json?         // array de URLs de fotos/vídeos
  sellerEvidence  Json?
  resolution      String?
  resolvedAt      DateTime?
  createdAt       DateTime      @default(now())
  expiresAt       DateTime      // createdAt + 72h

  order           Order         @relation(fields: [orderId], references: [id])
  openedBy        User          @relation(fields: [openedById], references: [id])
}

model Review {
  id          String     @id @default(uuid())
  reviewerId  String
  reviewedId  String
  orderId     String
  type        ReviewType // BUYER_REVIEWING_SELLER | SELLER_REVIEWING_BUYER
  score       Int        // 1–5
  comment     String?
  createdAt   DateTime   @default(now())
}
```

---

## 9. Gateway de Pagamento — Integração

### 9.1 Pagar.me — Fluxo Completo

#### Autenticação
```typescript
// Todas as requests usam Basic Auth com a API Key
const headers = {
  'Authorization': `Basic ${Buffer.from(API_KEY + ':').toString('base64')}`,
  'Content-Type': 'application/json'
}
```

#### Criar Pedido com Pix (escrow manual)
```typescript
// POST https://api.pagar.me/core/v5/orders
{
  "customer": {
    "name": "Nome do Comprador",
    "email": "comprador@email.com",
    "document": "CPF_DO_COMPRADOR",
    "type": "individual"
  },
  "items": [{
    "amount": 5000,         // em centavos
    "description": "Produto X",
    "quantity": 1,
    "code": "product_id"
  }],
  "payments": [{
    "payment_method": "pix",
    "pix": {
      "expires_in": 3600    // 1 hora para pagar
    }
  }]
}
// Resposta: retorna pix.qr_code e pix.qr_code_url para o comprador escanear
```

#### Cadastrar Recipient (vendedor para saque)
```typescript
// POST https://api.pagar.me/core/v5/recipients
{
  "name": "Nome do Vendedor",
  "email": "vendedor@email.com",
  "document": "CPF_DO_VENDEDOR",
  "type": "individual",
  "default_bank_account": {
    "holder_name": "Nome do Vendedor",
    "holder_type": "individual",
    "holder_document": "CPF",
    "bank": "341",          // código do banco
    "branch_number": "1234",
    "branch_check_digit": "5",
    "account_number": "12345",
    "account_check_digit": "6",
    "type": "checking"
  }
}
// Salvar recipient.id na Wallet do usuário
```

#### Transferir para Vendedor (release do escrow)
```typescript
// POST https://api.pagar.me/core/v5/transfers
{
  "amount": sellerAmount,   // em centavos, já descontada a taxa
  "recipient_id": wallet.recipientId,
  "metadata": {
    "order_id": order.id
  }
}
```

#### Webhook Handler (async via Bull)
```typescript
// Eventos relevantes:
// order.paid          → escrow ativado, Transaction.status = HELD
// order.payment_failed → Transaction.status = FAILED, notificar comprador
// charge.refunded     → Transaction.status = REFUNDED, Order cancelado

// IMPORTANTE: validar assinatura do webhook
const signature = req.headers['x-hub-signature']
const isValid = verifySignature(req.body, signature, WEBHOOK_SECRET)
```

### 9.2 Woovi — Pix de Alto Volume

```typescript
// POST https://api.openpix.com.br/api/v1/charge
// Header: Authorization: APP_ID
{
  "correlationID": order.id,     // idempotency
  "value": amount,               // em centavos
  "comment": "Compra via [Nome da Plataforma]",
  "expiresIn": 3600,
  "customer": {
    "name": "Nome do Comprador",
    "taxID": "CPF_DO_COMPRADOR",
    "email": "comprador@email.com"
  }
}
// Woovi também tem webhook: charge.completed → mesmo fluxo do Pagar.me
```

### 9.3 API Gateway Layer (Fastify)

Camada simples de roteamento e segurança que fica na frente dos serviços:

```typescript
// src/infra/http/fastify/index.ts
import Fastify from 'fastify'
import fastifyJwt from '@fastify/jwt'
import fastifyCors from '@fastify/cors'
import fastifyHelmet from '@fastify/helmet'
import fastifyRateLimit from '@fastify/rate-limit'

const app = Fastify({ logger: true })

// Segurança
app.register(fastifyHelmet)
app.register(fastifyCors, { origin: ALLOWED_ORIGINS })
app.register(fastifyJwt, { secret: JWT_SECRET })

// Rate limiting — proteção contra abuso
app.register(fastifyRateLimit, {
  max: 100,             // 100 requests
  timeWindow: '1 minute',
  redis: redisClient    // compartilhado — funciona em múltiplas instâncias
})

// Auth guard como decorator
app.decorate('authenticate', async (req, reply) => {
  try {
    await req.jwtVerify()
  } catch (err) {
    reply.code(401).send({ error: 'Unauthorized' })
  }
})

// Rotas
app.register(authRoutes,    { prefix: '/auth' })
app.register(userRoutes,    { prefix: '/users' })
app.register(socialRoutes,  { prefix: '/social' })
app.register(productRoutes, { prefix: '/products' })
app.register(orderRoutes,   { prefix: '/orders' })
app.register(paymentRoutes, { prefix: '/payments' })
app.register(walletRoutes,  { prefix: '/wallet' })
app.register(disputeRoutes, { prefix: '/disputes' })
```

### 9.4 Fluxo Completo de Pagamento — Diagrama

```
[Flutter App]
     |
     | POST /orders → cria Order (status: PENDING)
     |
[Fastify Backend]
     |
     | POST /payments/pix → chama Pagar.me ou Woovi
     |
[Pagar.me / Woovi]
     |
     | retorna QR Code Pix
     |
[Flutter App]
     | exibe QR Code ao comprador
     |
[Comprador paga no banco]
     |
[Pagar.me Webhook] → POST /payments/webhook
     |
[Bull Queue] → processa async
     |
     | Transaction.status = HELD
     | Order.status = CONFIRMED
     | Wallet.pendingBalance += sellerAmount
     | Push notification → vendedor + comprador
     |
[Encontro presencial]
     |
[Flutter App] → Comprador: POST /orders/:id/confirm
     |
[Backend]
     |
     | Transaction.status = RELEASED
     | Wallet.pendingBalance -= sellerAmount
     | Wallet.availableBalance += sellerAmount
     | Order.status = COMPLETED
     | POST /recipients → transferência para conta do vendedor
     | Push notification → "Valor liberado!"
     |
[Pagar.me Recipients API] → transfere para conta bancária
```

---

## 10. Roadmap do MVP

### Fase 1 — Base (Semanas 1–4)
- Setup: repositórios, CI/CD básico, Docker Compose (Postgres + Redis)
- Auth completo: registro, login, JWT + refresh tokens, bcrypt+salt
- Perfil social: criação de conta, avatar, bio, cidade
- Design System Flutter: AppButton, AppTextField, AppCard, UserAvatar, tema
- CRUD de produtos: criar anúncio, listar, detalhe

### Fase 2 — Social (Semanas 5–8)
- Feed social: posts, likes, comentários, compartilhamentos
- Sistema de seguir: follow/unfollow, feed personalizado por cursor
- Busca e filtros de produtos
- Notificações push via FCM
- Badges de verificação leve (celular + e-mail)

### Fase 3 — Transacional (Semanas 9–14)
- Integração Pagar.me: criação de pedidos Pix + crédito
- Escrow in-house: fluxo completo HELD → RELEASED
- Recipients API: cadastro de conta bancária do vendedor
- Chat interno criptografado para combinar entrega
- Wallet: saldo, extrato, saque
- Webhooks via Bull/Redis (async)
- Integração Woovi como alternativa Pix

### Fase 4 — Confiança (Semanas 15–20)
- Sistema de disputas com evidência bilateral obrigatória
- Avaliações bidirecionais (comprador + vendedor)
- Score de reputação público, badges Top Seller
- Verificação KYC completa (CPF + selfie)
- Analytics básico para vendedor (visualizações, conversão)

---

## 11. Decisões Técnicas Anti-Bottleneck

### Backend
- **Fastify** ao invés de Express: 2x mais rápido, type-safe nativamente
- **Prisma + PostgreSQL:** schema versionado, migrations rastreadas, queries type-safe
- **Stateless (JWT):** zero sessão no servidor — escala horizontal sem estado compartilhado
- **Redis:** cache de feed/listagens + rate limiting + blacklist de refresh tokens
- **Bull (Redis queue):** webhooks de pagamento processados async — sem timeout em requests HTTP
- **Soft delete** em todas as entidades financeiras — dado de transação nunca é apagado
- **Idempotency key** em todos os pagamentos — previne cobrança dupla em falhas de rede
- **Preços sempre em centavos (Int)** — nunca Float para dinheiro
- **Event-driven** nos módulos de payment/wallet — facilita auditoria e migração futura para microservices
- **Índices compostos** no banco desde o schema inicial: `(userId, createdAt)`, `(productId, status)`, `(orderId, status)`

### Frontend
- **Riverpod** ou **GetX**: gerenciamento de estado reativo com injeção de dependência
- **go_router:** navegação declarativa com deep linking e guards de auth
- **Hive / SharedPreferences:** cache local de tokens e dados do usuário
- **Infinite scroll com cursor pagination** — nunca OFFSET (não escala)
- **cached_network_image** com placeholder SVG — zero flash branco
- **WebSocket** para notificações em tempo real — sem polling

### Segurança de Pagamento
- Webhook signature validation em todos os eventos do Pagar.me e Woovi
- Idempotency key = `${orderId}-${paymentMethod}-${timestamp}` — determinístico
- Toda lógica de split calculada no backend — nunca aceitar valores do cliente
- Transações financeiras com database transactions (Prisma `$transaction`) — atomicidade garantida

---

## 12. Posicionamento Competitivo

| Critério | Mercado Livre | OLX | Enjoei | **Nossa Plataforma** |
|---|---|---|---|---|
| Taxa ao vendedor PF | 10–19% + taxa fixa | Grátis (sem proteção) | 30–40% total | **6–8% (com escrow)** |
| Exige CNPJ | Sim (em escala) | Não | Não | **Nunca** |
| Escrow | Sim | Não | Sim | **Sim (in-house)** |
| Reputação do comprador | Não | Não | Parcial | **Sim (bidirecional)** |
| Rede social no perfil | Não | Não | Parcial | **Sim (feed completo)** |
| Chat interno seguro | Sim | Não | Sim | **Sim (criptografado)** |
| Disputa com evidência bilateral | Não | Não | Não | **Sim (obrigatório)** |
| Plataforma absorve prejuízo | Não (favorece comprador) | N/A | Parcial | **Nunca (escrow garante)** |
| Taxa Pix ao processador | N/A (MP próprio) | N/A | N/A | **1.19% (Pagar.me) ou 0.80% (Woovi)** |

---

*Documento gerado em 25/02/2026 — versão 2.0*
*Stack: Flutter · Fastify · Prisma · PostgreSQL · Redis · Bull · Pagar.me · Woovi*
