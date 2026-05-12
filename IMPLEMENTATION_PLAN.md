# FreeBay Implementation Plan - Testing & Critical Features

**Start Date:** March 27, 2026  
**Target MVP:** Week 5-6  
**Approach:** Mixed (Option C) - Testing infrastructure first, then features with tests  
**Coverage Target:** 80% overall, 90% for use cases

---

## Overview

This plan implements critical marketplace features with comprehensive testing:

1. **Testing Infrastructure** (Week 1)
2. **Reviews System** (Week 1-2)
3. **Payment Security & Splits** (Week 2-3)
4. **Checkout & Orders Flow** (Week 3-4)
5. **Final Features & Polish** (Week 4-5)

---

## Phase 1: Testing Infrastructure (Week 1 - Days 1-3)

### Goal
Set up comprehensive testing infrastructure with real integration tests (no mocking use cases).

### Tasks

#### 1.1 Docker Test Database Setup

**File:** `docker-compose.test.yml`
```yaml
version: '3.8'
services:
  postgres-test:
    image: postgres:15
    environment:
      POSTGRES_DB: freebay_test
      POSTGRES_USER: test
      POSTGRES_PASSWORD: test123
    ports:
      - "5433:5432"
  
  redis-test:
    image: redis:7-alpine
    ports:
      - "6380:6379"
```

**Commands:**
```bash
docker-compose -f docker-compose.test.yml up -d
```

**Acceptance Criteria:**
- [ ] Test database runs on port 5433
- [ ] Test Redis runs on port 6380
- [ ] Can connect from tests

---

#### 1.2 Jest Configuration for Integration Tests

**File:** `nest-backend/jest.config.integration.js`
```javascript
module.exports = {
  moduleFileExtensions: ['js', 'json', 'ts'],
  rootDir: 'src',
  testRegex: '.*\\.integration-spec\\.ts$',
  transform: {
    '^.+\\.(t|j)s$': 'ts-jest',
  },
  collectCoverageFrom: [
    '**/*.ts',
    '!**/*.spec.ts',
    '!**/*.integration-spec.ts',
    '!**/node_modules/**',
  ],
  coverageDirectory: '../coverage-integration',
  testEnvironment: 'node',
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/$1',
  },
  setupFilesAfterEnv: ['<rootDir>/../test/setup-integration.ts'],
};
```

**File:** `nest-backend/test/setup-integration.ts`
```typescript
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.TEST_DATABASE_URL,
    },
  },
});

beforeAll(async () => {
  // Run migrations
  await prisma.$executeRawUnsafe('DROP SCHEMA IF EXISTS public CASCADE');
  await prisma.$executeRawUnsafe('CREATE SCHEMA public');
  // Migrations will be run via npm script
});

afterEach(async () => {
  // Clean up data after each test
  const tables = await prisma.$queryRaw`
    SELECT tablename FROM pg_tables WHERE schemaname='public'
  `;
  
  for (const { tablename } of tables) {
    if (tablename !== '_prisma_migrations') {
      await prisma.$executeRawUnsafe(`TRUNCATE TABLE "${tablename}" CASCADE`);
    }
  }
});

afterAll(async () => {
  await prisma.$disconnect();
});

export { prisma };
```

**Package.json scripts:**
```json
{
  "test:integration": "dotenv -e .env.test -- jest --config jest.config.integration.js",
  "test:integration:watch": "dotenv -e .env.test -- jest --config jest.config.integration.js --watch",
  "test:integration:cov": "dotenv -e .env.test -- jest --config jest.config.integration.js --coverage"
}
```

**File:** `nest-backend/.env.test`
```
DATABASE_URL="postgresql://test:test123@localhost:5433/freebay_test"
REDIS_URL="redis://localhost:6380"
JWT_SECRET="test-secret-key"
JWT_REFRESH_SECRET="test-refresh-secret"
```

**Acceptance Criteria:**
- [ ] Integration tests run against test database
- [ ] Database cleaned after each test
- [ ] Test environment isolated from dev/prod

---

#### 1.3 Test Utilities & Factories

**File:** `nest-backend/test/factories/user.factory.ts`
```typescript
import { PrismaClient, User, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

export class UserFactory {
  constructor(private prisma: PrismaClient) {}

  async create(overrides: Partial<User> = {}): Promise<User> {
    const passwordHash = await bcrypt.hash('password123', 10);
    
    return this.prisma.user.create({
      data: {
        displayName: 'Test User',
        email: `test-${Date.now()}@example.com`,
        passwordHash,
        role: UserRole.USER,
        reputationScore: 0,
        totalReviews: 0,
        ...overrides,
      },
    });
  }

  async createWithWallet(overrides: Partial<User> = {}): Promise<User> {
    const user = await this.create(overrides);
    await this.prisma.wallet.create({
      data: {
        userId: user.id,
        availableBalance: 0,
        pendingBalance: 0,
        totalEarned: 0,
      },
    });
    return user;
  }
}
```

**Similar factories needed:**
- `product.factory.ts`
- `order.factory.ts`
- `transaction.factory.ts`
- `post.factory.ts`

**Acceptance Criteria:**
- [ ] Factories create valid test data
- [ ] Factories support overrides
- [ ] Factories handle relationships

---

#### 1.4 Example Integration Test

**File:** `nest-backend/src/modules/auth/usecases/register.usecase.integration-spec.ts`
```typescript
import { RegisterUseCase } from './register.usecase';
import { PrismaUserRepository } from '../repositories/prisma-user.repository';
import { prisma } from '../../../../test/setup-integration';
import { isLeft, isRight } from '@/shared/core/either';

describe('RegisterUseCase Integration', () => {
  let sut: RegisterUseCase;
  let userRepository: PrismaUserRepository;

  beforeEach(() => {
    userRepository = new PrismaUserRepository(prisma);
    sut = new RegisterUseCase(userRepository);
  });

  it('should register a new user successfully', async () => {
    const input = {
      email: 'newuser@example.com',
      password: 'password123',
      displayName: 'New User',
    };

    const result = await sut.execute(input);

    expect(isRight(result)).toBe(true);
    if (isRight(result)) {
      expect(result.right.user).toBeDefined();
      expect(result.right.user.email).toBe(input.email);
      
      // Verify user exists in database
      const dbUser = await prisma.user.findUnique({
        where: { email: input.email },
      });
      expect(dbUser).toBeDefined();
    }
  });

  it('should return error if email already exists', async () => {
    const input = {
      email: 'duplicate@example.com',
      password: 'password123',
      displayName: 'User One',
    };

    // First registration
    await sut.execute(input);

    // Second registration with same email
    const result = await sut.execute(input);

    expect(isLeft(result)).toBe(true);
    if (isLeft(result)) {
      expect(result.left.code).toBe('EMAIL_ALREADY_EXISTS');
    }
  });
});
```

**Acceptance Criteria:**
- [ ] Test hits real database
- [ ] Test validates business rules
- [ ] Test checks database state
- [ ] No mocking of repositories or use cases

---

### Phase 1 Deliverables

- [ ] Docker test environment running
- [ ] Jest configured for integration tests
- [ ] Test utilities and factories created
- [ ] 5+ example integration tests written for existing modules
- [ ] Documentation on running tests

**Time Estimate:** 2-3 days

---

## Phase 2: Reviews System (Week 1-2 - Days 4-10)

### Goal
Implement complete reviews system with reputation calculation and comprehensive tests.

### Backend Tasks

#### 2.1 Reviews Module Structure

```
nest-backend/src/modules/reviews/
├── dtos/
│   └── review.dto.ts
├── mappers/
│   └── review.mapper.ts
├── repositories/
│   └── prisma-review.repository.ts
├── usecases/
│   ├── create-review.usecase.ts
│   ├── create-review.usecase.spec.ts
│   ├── create-review.usecase.integration-spec.ts
│   ├── get-user-reviews.usecase.ts
│   ├── get-user-reviews.usecase.spec.ts
│   ├── get-review.usecase.ts
│   └── calculate-reputation.usecase.ts
├── controllers/
│   └── reviews.controller.ts
├── routes.ts
└── reviews.module.ts
```

---

#### 2.2 DTOs with Zod Validation

**File:** `nest-backend/src/modules/reviews/dtos/review.dto.ts`
```typescript
import { z } from 'zod';
import { ReviewType } from '@prisma/client';

export const createReviewSchema = z.object({
  orderId: z.string().uuid(),
  type: z.nativeEnum(ReviewType),
  score: z.number().int().min(1).max(5),
  comment: z.string().min(10).max(500).optional(),
});

export type CreateReviewDto = z.infer<typeof createReviewSchema>;

export const getUserReviewsSchema = z.object({
  userId: z.string().uuid(),
  cursor: z.string().uuid().optional(),
  limit: z.number().int().min(1).max(50).default(20),
});

export type GetUserReviewsDto = z.infer<typeof getUserReviewsSchema>;
```

---

#### 2.3 Create Review Use Case

**File:** `nest-backend/src/modules/reviews/usecases/create-review.usecase.ts`
```typescript
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, ValidationError } from '@/shared/core/errors';
import { PrismaReviewRepository } from '../repositories/prisma-review.repository';
import { PrismaOrderRepository } from '@/modules/orders/repositories/prisma-order.repository';
import { PrismaUserRepository } from '@/modules/auth/repositories/prisma-user.repository';
import { Review, ReviewType, OrderStatus } from '@prisma/client';

interface CreateReviewInput {
  orderId: string;
  reviewerId: string;
  type: ReviewType;
  score: number;
  comment?: string;
}

export class CreateReviewUseCase {
  constructor(
    private reviewRepository: PrismaReviewRepository,
    private orderRepository: PrismaOrderRepository,
    private userRepository: PrismaUserRepository,
  ) {}

  async execute(input: CreateReviewInput): Promise<Either<AppError, { review: Review }>> {
    // 1. Verify order exists and is completed
    const order = await this.orderRepository.findById(input.orderId);
    if (!order) {
      return left(new NotFoundError('Order'));
    }

    if (order.status !== OrderStatus.COMPLETED) {
      return left(new ValidationError('Order must be completed before reviewing'));
    }

    // 2. Verify reviewer is part of the order
    const isReviewerBuyer = order.buyerId === input.reviewerId;
    const isReviewerSeller = order.sellerId === input.reviewerId;

    if (!isReviewerBuyer && !isReviewerSeller) {
      return left(new ValidationError('You are not part of this order'));
    }

    // 3. Verify review type matches reviewer role
    if (isReviewerBuyer && input.type !== ReviewType.BUYER_REVIEWING_SELLER) {
      return left(new ValidationError('Buyers can only review sellers'));
    }

    if (isReviewerSeller && input.type !== ReviewType.SELLER_REVIEWING_BUYER) {
      return left(new ValidationError('Sellers can only review buyers'));
    }

    // 4. Check for duplicate review
    const existingReview = await this.reviewRepository.findByOrderAndType(
      input.orderId,
      input.reviewerId,
      input.type,
    );

    if (existingReview) {
      return left(new ValidationError('You have already reviewed this order'));
    }

    // 5. Determine who is being reviewed
    const reviewedId = input.type === ReviewType.BUYER_REVIEWING_SELLER
      ? order.sellerId
      : order.buyerId;

    // 6. Create review
    const review = await this.reviewRepository.create({
      reviewerId: input.reviewerId,
      reviewedId,
      orderId: input.orderId,
      type: input.type,
      score: input.score,
      comment: input.comment,
    });

    // 7. Update reviewed user's reputation
    await this.updateUserReputation(reviewedId);

    return right({ review });
  }

  private async updateUserReputation(userId: string): Promise<void> {
    // Calculate average score from all reviews
    const reviews = await this.reviewRepository.findByReviewedId(userId);
    
    const totalReviews = reviews.length;
    const averageScore = totalReviews > 0
      ? reviews.reduce((sum, r) => sum + r.score, 0) / totalReviews
      : 0;

    // Update user
    await this.userRepository.updateReputation(userId, {
      reputationScore: averageScore,
      totalReviews,
    });
  }
}
```

**Business Rules:**
- Only completed orders can be reviewed
- Reviewer must be buyer or seller in the order
- Buyers review sellers, sellers review buyers
- No duplicate reviews per order+type
- Reputation auto-calculated as simple average

---

#### 2.4 Review Repository

**File:** `nest-backend/src/modules/reviews/repositories/prisma-review.repository.ts`
```typescript
import { PrismaClient, Review, Prisma } from '@prisma/client';

export class PrismaReviewRepository {
  constructor(private prisma: PrismaClient) {}

  async create(data: Prisma.ReviewCreateInput): Promise<Review> {
    return this.prisma.review.create({ data });
  }

  async findById(id: string): Promise<Review | null> {
    return this.prisma.review.findUnique({ where: { id } });
  }

  async findByOrderAndType(
    orderId: string,
    reviewerId: string,
    type: ReviewType,
  ): Promise<Review | null> {
    return this.prisma.review.findUnique({
      where: {
        reviewerId_orderId_type: {
          reviewerId,
          orderId,
          type,
        },
      },
    });
  }

  async findByReviewedId(reviewedId: string): Promise<Review[]> {
    return this.prisma.review.findMany({
      where: { reviewedId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findByReviewedIdPaginated(
    reviewedId: string,
    cursor?: string,
    limit: number = 20,
  ): Promise<Review[]> {
    return this.prisma.review.findMany({
      where: { reviewedId },
      take: limit,
      ...(cursor && { skip: 1, cursor: { id: cursor } }),
      orderBy: { createdAt: 'desc' },
      include: {
        reviewer: {
          select: {
            id: true,
            displayName: true,
            avatarUrl: true,
            isVerified: true,
          },
        },
      },
    });
  }
}
```

---

#### 2.5 Integration Tests for Reviews

**File:** `nest-backend/src/modules/reviews/usecases/create-review.usecase.integration-spec.ts`
```typescript
import { CreateReviewUseCase } from './create-review.usecase';
import { PrismaReviewRepository } from '../repositories/prisma-review.repository';
import { PrismaOrderRepository } from '@/modules/orders/repositories/prisma-order.repository';
import { PrismaUserRepository } from '@/modules/auth/repositories/prisma-user.repository';
import { prisma } from '../../../../test/setup-integration';
import { UserFactory } from '../../../../test/factories/user.factory';
import { OrderFactory } from '../../../../test/factories/order.factory';
import { ReviewType, OrderStatus } from '@prisma/client';
import { isLeft, isRight } from '@/shared/core/either';

describe('CreateReviewUseCase Integration', () => {
  let sut: CreateReviewUseCase;
  let reviewRepository: PrismaReviewRepository;
  let orderRepository: PrismaOrderRepository;
  let userRepository: PrismaUserRepository;
  let userFactory: UserFactory;
  let orderFactory: OrderFactory;

  beforeEach(() => {
    reviewRepository = new PrismaReviewRepository(prisma);
    orderRepository = new PrismaOrderRepository(prisma);
    userRepository = new PrismaUserRepository(prisma);
    userFactory = new UserFactory(prisma);
    orderFactory = new OrderFactory(prisma);
    
    sut = new CreateReviewUseCase(reviewRepository, orderRepository, userRepository);
  });

  describe('Business Rules', () => {
    it('should create review for completed order', async () => {
      // Arrange
      const buyer = await userFactory.create();
      const seller = await userFactory.create();
      const order = await orderFactory.createCompleted(buyer.id, seller.id);

      // Act
      const result = await sut.execute({
        orderId: order.id,
        reviewerId: buyer.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 5,
        comment: 'Great seller!',
      });

      // Assert
      expect(isRight(result)).toBe(true);
      if (isRight(result)) {
        expect(result.right.review.score).toBe(5);
        expect(result.right.review.reviewedId).toBe(seller.id);
      }
    });

    it('should reject review for non-completed order', async () => {
      // Arrange
      const buyer = await userFactory.create();
      const seller = await userFactory.create();
      const order = await orderFactory.create(buyer.id, seller.id, {
        status: OrderStatus.PENDING,
      });

      // Act
      const result = await sut.execute({
        orderId: order.id,
        reviewerId: buyer.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 5,
      });

      // Assert
      expect(isLeft(result)).toBe(true);
      if (isLeft(result)) {
        expect(result.left.message).toContain('completed');
      }
    });

    it('should reject duplicate review', async () => {
      // Arrange
      const buyer = await userFactory.create();
      const seller = await userFactory.create();
      const order = await orderFactory.createCompleted(buyer.id, seller.id);

      // First review
      await sut.execute({
        orderId: order.id,
        reviewerId: buyer.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 5,
      });

      // Act - Second review (duplicate)
      const result = await sut.execute({
        orderId: order.id,
        reviewerId: buyer.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 4,
      });

      // Assert
      expect(isLeft(result)).toBe(true);
      if (isLeft(result)) {
        expect(result.left.message).toContain('already reviewed');
      }
    });

    it('should calculate reputation as simple average', async () => {
      // Arrange
      const seller = await userFactory.create();
      const buyer1 = await userFactory.create();
      const buyer2 = await userFactory.create();
      const buyer3 = await userFactory.create();

      const order1 = await orderFactory.createCompleted(buyer1.id, seller.id);
      const order2 = await orderFactory.createCompleted(buyer2.id, seller.id);
      const order3 = await orderFactory.createCompleted(buyer3.id, seller.id);

      // Act - Create 3 reviews: 5, 4, 3
      await sut.execute({
        orderId: order1.id,
        reviewerId: buyer1.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 5,
      });

      await sut.execute({
        orderId: order2.id,
        reviewerId: buyer2.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 4,
      });

      await sut.execute({
        orderId: order3.id,
        reviewerId: buyer3.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 3,
      });

      // Assert
      const updatedSeller = await prisma.user.findUnique({
        where: { id: seller.id },
      });

      expect(updatedSeller.reputationScore).toBe(4); // (5+4+3)/3 = 4
      expect(updatedSeller.totalReviews).toBe(3);
    });
  });
});
```

**Required Tests:**
- [ ] Create review for completed order
- [ ] Reject review for non-completed order
- [ ] Reject duplicate review
- [ ] Buyer can only review seller
- [ ] Seller can only review buyer
- [ ] Reputation calculation (average)
- [ ] Reputation updates on each new review
- [ ] Reviewer must be part of order

**Coverage Target:** 90%+ for CreateReviewUseCase

---

#### 2.6 Review Endpoints

**File:** `nest-backend/src/modules/reviews/controllers/reviews.controller.ts`
```typescript
import { Controller, Post, Get, Param, Body, Query, UseGuards, Req } from '@nestjs/common';
import { CreateReviewUseCase } from '../usecases/create-review.usecase';
import { GetUserReviewsUseCase } from '../usecases/get-user-reviews.usecase';
import { createReviewSchema, getUserReviewsSchema } from '../dtos/review.dto';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { isLeft } from '@/shared/core/either';

@Controller('reviews')
export class ReviewsController {
  constructor(
    private createReviewUseCase: CreateReviewUseCase,
    private getUserReviewsUseCase: GetUserReviewsUseCase,
  ) {}

  @Post('orders/:orderId')
  @UseGuards(JwtAuthGuard)
  async createReview(
    @Param('orderId') orderId: string,
    @Body() body: unknown,
    @Req() req: any,
  ) {
    const dto = createReviewSchema.parse({ ...body, orderId });
    
    const result = await this.createReviewUseCase.execute({
      orderId: dto.orderId,
      reviewerId: req.user.id,
      type: dto.type,
      score: dto.score,
      comment: dto.comment,
    });

    if (isLeft(result)) {
      throw result.left;
    }

    return { success: true, data: result.right };
  }

  @Get('users/:userId')
  async getUserReviews(
    @Param('userId') userId: string,
    @Query() query: unknown,
  ) {
    const dto = getUserReviewsSchema.parse({ ...query, userId });
    
    const result = await this.getUserReviewsUseCase.execute(dto);

    if (isLeft(result)) {
      throw result.left;
    }

    return { success: true, data: result.right };
  }
}
```

**Endpoints:**
```
POST   /reviews/orders/:orderId    - Create review (auth required)
GET    /reviews/users/:userId      - Get user reviews (public, paginated)
```

---

### Frontend Tasks

#### 2.7 Review Form UI

**File:** `frontend/lib/features/reviews/pages/create_review_page.dart`
```dart
class CreateReviewPage extends HookConsumerWidget {
  final String orderId;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rating = useState<int>(0);
    final comment = useState<String>('');
    
    return Scaffold(
      appBar: AppBar(title: Text('Avaliar Pedido')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Como foi sua experiência?', style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            
            // Star Rating
            ReputationStars(
              rating: rating.value,
              size: 40,
              onRatingChanged: (newRating) => rating.value = newRating,
              interactive: true,
            ),
            
            SizedBox(height: 24),
            
            // Comment
            AppTextField(
              label: 'Comentário (opcional)',
              maxLines: 5,
              maxLength: 500,
              onChanged: (value) => comment.value = value,
            ),
            
            Spacer(),
            
            // Submit
            AppButton.primary(
              label: 'Enviar Avaliação',
              enabled: rating.value > 0,
              onPressed: () => _submitReview(context, ref, orderId, rating.value, comment.value),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Required UI:**
- [ ] Star rating selector (1-5)
- [ ] Comment text field (optional, max 500 chars)
- [ ] Submit button (disabled until rating selected)
- [ ] Loading state during submission
- [ ] Success/error feedback

---

#### 2.8 Display Reviews on Profile

**File:** `frontend/lib/features/profile/widgets/user_reviews_list.dart`
```dart
class UserReviewsList extends ConsumerWidget {
  final String userId;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsState = ref.watch(userReviewsProvider(userId));
    
    return reviewsState.when(
      data: (reviews) => ListView.builder(
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          final review = reviews[index];
          return ReviewCard(review: review);
        },
      ),
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, stack) => ErrorWidget(err),
    );
  }
}

class ReviewCard extends StatelessWidget {
  final Review review;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(url: review.reviewer.avatarUrl, size: 32),
                SizedBox(width: 8),
                Text(review.reviewer.displayName, style: TextStyle(fontWeight: FontWeight.bold)),
                Spacer(),
                ReputationStars(rating: review.score, size: 16),
              ],
            ),
            if (review.comment != null) ...[
              SizedBox(height: 8),
              Text(review.comment!),
            ],
            SizedBox(height: 4),
            Text(
              _formatDate(review.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Integration Points:**
- [ ] Add "Avaliações" tab to profile page
- [ ] Show average rating in profile header
- [ ] Show total reviews count
- [ ] Paginate reviews (load more on scroll)

---

### Phase 2 Deliverables

**Backend:**
- [ ] Reviews module created
- [ ] CreateReviewUseCase with 90%+ coverage
- [ ] GetUserReviewsUseCase with tests
- [ ] Reputation calculation logic tested
- [ ] Endpoints: POST /reviews/orders/:id, GET /reviews/users/:id
- [ ] Integration tests for all business rules

**Frontend:**
- [ ] Review form page
- [ ] Review display on profiles
- [ ] Reputation stars integration throughout app
- [ ] Prompt users to review after order completion

**Time Estimate:** 4-6 days

---

## Phase 3: Payment Security & Split Logic (Week 2-3 - Days 11-17)

### Goal
Secure payment processing with Abacate Pay, implement split logic (10% platform), and comprehensive testing.

### Tasks

#### 3.1 Abacate Pay Integration Research

**Action Items:**
- [ ] Review Abacate Pay API documentation
- [ ] Identify webhook signature algorithm
- [ ] Identify idempotency key header
- [ ] Test sandbox environment

**Documentation Needed:**
```
nest-backend/docs/ABACATE_PAY_INTEGRATION.md
- API endpoints
- Webhook signature verification algorithm
- Idempotency key implementation
- Error codes and handling
```

---

#### 3.2 Payment Security Infrastructure

**File:** `nest-backend/src/modules/payments/services/webhook-verifier.service.ts`
```typescript
import * as crypto from 'crypto';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class WebhookVerifierService {
  private readonly webhookSecret: string;

  constructor(private config: ConfigService) {
    this.webhookSecret = config.get<string>('ABACATE_WEBHOOK_SECRET');
  }

  verifySignature(payload: string, signature: string): boolean {
    const expectedSignature = crypto
      .createHmac('sha256', this.webhookSecret)
      .update(payload)
      .digest('hex');

    return crypto.timingSafeEqual(
      Buffer.from(signature),
      Buffer.from(expectedSignature),
    );
  }

  verifyTimestamp(timestamp: number, maxAgeSeconds: number = 300): boolean {
    const now = Math.floor(Date.now() / 1000);
    return (now - timestamp) <= maxAgeSeconds;
  }
}
```

**Tests:**
```typescript
describe('WebhookVerifierService', () => {
  it('should verify valid signature', () => {
    // Test with known payload + signature
  });

  it('should reject invalid signature', () => {
    // Test with tampered payload
  });

  it('should reject old timestamps', () => {
    // Test with timestamp > 5 minutes old
  });
});
```

---

#### 3.3 Idempotency Enforcement

**File:** `nest-backend/src/modules/payments/services/idempotency.service.ts`
```typescript
import { Injectable } from '@nestjs/common';
import { Redis } from 'ioredis';
import { InjectRedis } from '@/shared/infra/redis/redis.module';

@Injectable()
export class IdempotencyService {
  constructor(@InjectRedis() private redis: Redis) {}

  async get(key: string): Promise<any | null> {
    const cached = await this.redis.get(`idempotency:${key}`);
    return cached ? JSON.parse(cached) : null;
  }

  async set(key: string, result: any, ttlSeconds: number = 86400): Promise<void> {
    await this.redis.setex(
      `idempotency:${key}`,
      ttlSeconds,
      JSON.stringify(result),
    );
  }

  async execute<T>(
    key: string,
    operation: () => Promise<T>,
  ): Promise<T> {
    // Check if already executed
    const cached = await this.get(key);
    if (cached) {
      return cached;
    }

    // Execute operation
    const result = await operation();

    // Cache result
    await this.set(key, result);

    return result;
  }
}
```

**Integration in CreatePixPaymentUseCase:**
```typescript
async execute(input: CreatePixPaymentInput): Promise<Either<AppError, { transaction: Transaction }>> {
  // Generate idempotency key from orderId + timestamp
  const idempotencyKey = `pix-${input.orderId}-${Date.now()}`;

  const result = await this.idempotencyService.execute(
    idempotencyKey,
    async () => {
      // Existing payment logic here
      return { transaction };
    },
  );

  return right(result);
}
```

**Tests:**
```typescript
describe('IdempotencyService Integration', () => {
  it('should return cached result for duplicate request', async () => {
    const key = 'test-key';
    let executionCount = 0;

    const operation = async () => {
      executionCount++;
      return { data: 'result' };
    };

    // First call
    const result1 = await service.execute(key, operation);
    expect(executionCount).toBe(1);

    // Second call (should return cached)
    const result2 = await service.execute(key, operation);
    expect(executionCount).toBe(1); // Not executed again
    expect(result2).toEqual(result1);
  });
});
```

---

#### 3.4 Split Payment Logic

**File:** `nest-backend/src/modules/orders/usecases/create-order.usecase.ts` (Updated)
```typescript
export class CreateOrderUseCase {
  private readonly PLATFORM_FEE_PERCENTAGE = 0.10; // 10%

  async execute(input: CreateOrderInput): Promise<Either<AppError, { order: Order }>> {
    // 1. Verify product exists
    const product = await this.productRepository.findById(input.productId);
    if (!product) {
      return left(new NotFoundError('Product'));
    }

    // 2. NEVER TRUST FRONTEND - Recalculate all amounts server-side
    const amount = product.price; // Product price in cents
    const platformFee = Math.floor(amount * this.PLATFORM_FEE_PERCENTAGE);
    const sellerAmount = amount - platformFee;

    // 3. Verify buyer is not seller
    if (input.buyerId === product.sellerId) {
      return left(new ValidationError('Cannot buy your own product'));
    }

    // 4. Create order with calculated splits
    const order = await this.orderRepository.create({
      buyerId: input.buyerId,
      sellerId: product.sellerId,
      productId: input.productId,
      amount,
      platformFee,
      sellerAmount,
      status: OrderStatus.PENDING,
      escrowStatus: EscrowStatus.HELD,
    });

    // 5. Auto-start chat (next phase)
    // await this.chatService.createOrderConversation(order.id, order.buyerId, order.sellerId);

    return right({ order });
  }
}
```

**Business Rules:**
- Platform fee: 10% of product price
- Seller amount: 90% of product price
- Calculations always server-side
- Never trust frontend amounts
- Store splits in Order model

**Tests:**
```typescript
describe('CreateOrderUseCase - Split Calculations', () => {
  it('should calculate 10% platform fee correctly', async () => {
    // Product price: R$100.00 (10000 cents)
    const product = await productFactory.create({ price: 10000 });

    const result = await sut.execute({
      buyerId: buyer.id,
      productId: product.id,
    });

    expect(isRight(result)).toBe(true);
    if (isRight(result)) {
      const order = result.right.order;
      expect(order.amount).toBe(10000);
      expect(order.platformFee).toBe(1000); // 10%
      expect(order.sellerAmount).toBe(9000); // 90%
    }
  });

  it('should handle fractional cents correctly', async () => {
    // Product price: R$10.55 (1055 cents)
    const product = await productFactory.create({ price: 1055 });

    const result = await sut.execute({
      buyerId: buyer.id,
      productId: product.id,
    });

    if (isRight(result)) {
      const order = result.right.order;
      expect(order.platformFee).toBe(105); // floor(1055 * 0.10) = 105
      expect(order.sellerAmount).toBe(950); // 1055 - 105 = 950
      // Verify total equals original
      expect(order.platformFee + order.sellerAmount).toBe(order.amount);
    }
  });
});
```

---

#### 3.5 Automatic Fund Release on Completion

**File:** `nest-backend/src/modules/orders/usecases/confirm-delivery.usecase.ts` (Updated)
```typescript
export class ConfirmDeliveryUseCase {
  constructor(
    private orderRepository: PrismaOrderRepository,
    private walletService: WalletService,
    private platformWalletService: PlatformWalletService,
  ) {}

  async execute(input: ConfirmDeliveryInput): Promise<Either<AppError, { order: Order }>> {
    // 1. Verify order and authorization
    const order = await this.orderRepository.findById(input.orderId);
    if (!order) {
      return left(new NotFoundError('Order'));
    }

    if (order.buyerId !== input.userId) {
      return left(new UnauthorizedError('Only buyer can confirm delivery'));
    }

    if (order.status !== OrderStatus.DELIVERED) {
      return left(new ValidationError('Order must be delivered before confirmation'));
    }

    // 2. Update order status
    const updatedOrder = await this.orderRepository.update(order.id, {
      status: OrderStatus.COMPLETED,
      escrowStatus: EscrowStatus.RELEASED,
      deliveryConfirmedAt: new Date(),
    });

    // 3. AUTOMATIC SPLIT - Release funds
    await this.releaseFunds(updatedOrder);

    // 4. Notify seller
    // await this.notificationService.notifyFundsReleased(order.sellerId, order.id);

    return right({ order: updatedOrder });
  }

  private async releaseFunds(order: Order): Promise<void> {
    // Atomic transaction: Update both wallets
    await this.prisma.$transaction(async (tx) => {
      // Add seller amount to seller's available balance
      await tx.wallet.update({
        where: { userId: order.sellerId },
        data: {
          availableBalance: { increment: order.sellerAmount },
          totalEarned: { increment: order.sellerAmount },
        },
      });

      // Add platform fee to platform wallet
      await this.platformWalletService.addRevenue(order.platformFee, tx);
    });
  }
}
```

**Tests:**
```typescript
describe('ConfirmDeliveryUseCase - Fund Release', () => {
  it('should release funds to seller and platform on confirmation', async () => {
    // Arrange
    const seller = await userFactory.createWithWallet({ 
      wallet: { availableBalance: 0, pendingBalance: 0 } 
    });
    const buyer = await userFactory.create();
    const order = await orderFactory.create(buyer.id, seller.id, {
      status: OrderStatus.DELIVERED,
      amount: 10000,
      platformFee: 1000,
      sellerAmount: 9000,
    });

    // Act
    const result = await sut.execute({
      orderId: order.id,
      userId: buyer.id,
    });

    // Assert
    expect(isRight(result)).toBe(true);

    // Verify seller wallet updated
    const sellerWallet = await prisma.wallet.findUnique({
      where: { userId: seller.id },
    });
    expect(sellerWallet.availableBalance).toBe(9000);
    expect(sellerWallet.totalEarned).toBe(9000);

    // Verify platform revenue recorded
    const platformRevenue = await prisma.platformRevenue.findFirst({
      where: { orderId: order.id },
    });
    expect(platformRevenue.amount).toBe(1000);
  });

  it('should use atomic transaction for fund release', async () => {
    // Test that if platform wallet update fails, seller wallet is not updated
    // This ensures data integrity
  });
});
```

---

#### 3.6 Rate Limiting

**File:** `nest-backend/src/modules/payments/guards/rate-limit.guard.ts`
```typescript
import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { Redis } from 'ioredis';
import { InjectRedis } from '@/shared/infra/redis/redis.module';
import { TooManyRequestsError } from '@/shared/core/errors';

@Injectable()
export class RateLimitGuard implements CanActivate {
  constructor(@InjectRedis() private redis: Redis) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const userId = request.user?.id || request.ip;
    const key = `rate-limit:payment:${userId}`;

    const requests = await this.redis.incr(key);
    
    if (requests === 1) {
      // Set expiry on first request
      await this.redis.expire(key, 60); // 1 minute window
    }

    if (requests > 10) { // Max 10 payment requests per minute
      throw new TooManyRequestsError('Too many payment requests');
    }

    return true;
  }
}
```

**Apply to payment endpoints:**
```typescript
@Post('pix/:orderId')
@UseGuards(JwtAuthGuard, RateLimitGuard)
async createPixPayment(...) {
  // Payment logic
}
```

---

### Phase 3 Deliverables

**Backend:**
- [ ] Abacate Pay integration documented
- [ ] Webhook signature verification implemented and tested
- [ ] Idempotency enforcement with Redis
- [ ] Split payment logic (10%/90%) tested
- [ ] Automatic fund release on order completion
- [ ] Rate limiting on payment endpoints
- [ ] 90%+ test coverage for payment flows

**Frontend:**
- [ ] No changes required (backend-only phase)

**Time Estimate:** 5-7 days

---

## Phase 4: Checkout & Orders Flow (Week 3-4 - Days 18-25)

### Goal
Complete frontend transaction flows: cart, checkout, payment, and order tracking.

### Backend Tasks

#### 4.1 Order Status Management

**File:** `nest-backend/src/modules/orders/usecases/update-order-status.usecase.ts`
```typescript
export class UpdateOrderStatusUseCase {
  private readonly VALID_TRANSITIONS = {
    [OrderStatus.PENDING]: [OrderStatus.CONFIRMED, OrderStatus.CANCELLED],
    [OrderStatus.CONFIRMED]: [OrderStatus.SHIPPED, OrderStatus.CANCELLED],
    [OrderStatus.SHIPPED]: [OrderStatus.DELIVERED, OrderStatus.DISPUTED],
    [OrderStatus.DELIVERED]: [OrderStatus.COMPLETED, OrderStatus.DISPUTED],
    [OrderStatus.DISPUTED]: [OrderStatus.COMPLETED, OrderStatus.CANCELLED],
  };

  async execute(input: UpdateOrderStatusInput): Promise<Either<AppError, { order: Order }>> {
    const order = await this.orderRepository.findById(input.orderId);
    if (!order) {
      return left(new NotFoundError('Order'));
    }

    // Verify user authorization
    if (order.sellerId !== input.userId && order.buyerId !== input.userId) {
      return left(new UnauthorizedError('Not authorized'));
    }

    // Validate transition
    const validTransitions = this.VALID_TRANSITIONS[order.status] || [];
    if (!validTransitions.includes(input.newStatus)) {
      return left(new ValidationError(
        `Cannot transition from ${order.status} to ${input.newStatus}`
      ));
    }

    // Update status
    const updatedOrder = await this.orderRepository.update(order.id, {
      status: input.newStatus,
    });

    return right({ order: updatedOrder });
  }
}
```

**Endpoint:**
```typescript
@Patch(':id/status')
@UseGuards(JwtAuthGuard)
async updateStatus(
  @Param('id') orderId: string,
  @Body() body: { status: OrderStatus },
  @Req() req: any,
) {
  // Implementation
}
```

---

#### 4.2 Auto-Create Chat After Order

**File:** `nest-backend/src/modules/orders/usecases/create-order.usecase.ts` (Add auto-chat)
```typescript
async execute(input: CreateOrderInput): Promise<Either<AppError, { order: Order; conversation: DirectConversation }>> {
  // ... existing order creation logic ...

  // Auto-create conversation between buyer and seller
  const conversation = await this.chatService.createOrderConversation({
    buyerId: order.buyerId,
    sellerId: order.sellerId,
    orderId: order.id,
  });

  return right({ order, conversation });
}
```

**Chat Service Method:**
```typescript
async createOrderConversation(data: {
  buyerId: string;
  sellerId: string;
  orderId: string;
}): Promise<DirectConversation> {
  // Check if conversation already exists
  let conversation = await this.conversationRepository.findByUsers(
    data.buyerId,
    data.sellerId,
  );

  if (!conversation) {
    conversation = await this.conversationRepository.create({
      user1Id: data.buyerId,
      user2Id: data.sellerId,
      status: 'ACTIVE',
    });
  }

  // Send automatic first message
  await this.messageRepository.create({
    conversationId: conversation.id,
    senderId: data.buyerId,
    content: `Olá! Criei um pedido para o seu produto. Podemos conversar sobre os detalhes?`,
    type: MessageType.TEXT,
    metadata: { orderId: data.orderId },
  });

  return conversation;
}
```

---

### Frontend Tasks

#### 4.3 Cart Implementation

**File:** `frontend/lib/features/product/pages/cart_page.dart` (Remove stub, implement)
```dart
class CartPage extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final total = cartItems.fold<int>(0, (sum, item) => sum + item.product.price);

    return Scaffold(
      appBar: AppBar(title: Text('Carrinho')),
      body: cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      return CartItemCard(item: cartItems[index]);
                    },
                  ),
                ),
                _buildCheckoutSection(context, ref, total),
              ],
            ),
    );
  }

  Widget _buildCheckoutSection(BuildContext context, WidgetRef ref, int total) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                'R\$ ${(total / 100).toStringAsFixed(2)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 16),
          AppButton.primary(
            label: 'Finalizar Compra',
            onPressed: () => context.push('/checkout'),
          ),
        ],
      ),
    );
  }
}
```

**Cart Provider:**
```dart
@riverpod
class Cart extends _$Cart {
  @override
  List<CartItem> build() {
    // Load from local storage
    return [];
  }

  void addItem(Product product) {
    state = [...state, CartItem(product: product)];
    _saveToStorage();
  }

  void removeItem(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
    _saveToStorage();
  }

  void clear() {
    state = [];
    _saveToStorage();
  }
}
```

---

#### 4.4 Checkout Flow

**File:** `frontend/lib/features/checkout/pages/checkout_page.dart`
```dart
class CheckoutPage extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final selectedPaymentMethod = useState<PaymentMethod>(PaymentMethod.PIX);

    return Scaffold(
      appBar: AppBar(title: Text('Finalizar Compra')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderSummary(cartItems),
                  Divider(),
                  _buildPaymentMethodSelection(selectedPaymentMethod),
                  Divider(),
                  _buildTotalSection(cartItems),
                ],
              ),
            ),
          ),
          _buildConfirmButton(context, ref, cartItems, selectedPaymentMethod.value),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(
    BuildContext context,
    WidgetRef ref,
    List<CartItem> items,
    PaymentMethod method,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      child: AppButton.primary(
        label: 'Confirmar Pedido',
        onPressed: () async {
          // Create order for each item (or batch)
          for (final item in items) {
            await _createOrder(context, ref, item.product.id);
          }
          
          // Clear cart
          ref.read(cartProvider.notifier).clear();
          
          // Navigate to payment
          context.push('/payment/${orderId}');
        },
      ),
    );
  }
}
```

---

#### 4.5 PIX Payment Display

**File:** `frontend/lib/features/checkout/pages/payment_pix_page.dart`
```dart
class PaymentPixPage extends HookConsumerWidget {
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentState = ref.watch(pixPaymentProvider(orderId));

    return paymentState.when(
      data: (payment) => Scaffold(
        appBar: AppBar(title: Text('Pagamento PIX')),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Escaneie o QR Code para pagar', style: TextStyle(fontSize: 18)),
              SizedBox(height: 24),
              
              // QR Code
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: payment.pixQrCode,
                  size: 250,
                ),
              ),
              
              SizedBox(height: 24),
              
              // Expiration Timer
              _buildExpirationTimer(payment.pixExpiresAt),
              
              SizedBox(height: 16),
              
              // Copy PIX Code
              AppButton.secondary(
                label: 'Copiar Código PIX',
                icon: Icons.copy,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: payment.pixQrCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Código copiado!')),
                  );
                },
              ),
              
              Spacer(),
              
              Text(
                'Aguardando pagamento...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, stack) => ErrorWidget(err),
    );
  }

  Widget _buildExpirationTimer(DateTime expiresAt) {
    // Countdown timer showing time remaining
    return TimerWidget(expiresAt: expiresAt);
  }
}
```

**WebSocket Payment Status Listener:**
```dart
@riverpod
Stream<PaymentStatus> paymentStatus(PaymentStatusRef ref, String orderId) {
  final channel = IOWebSocketChannel.connect(
    'ws://192.168.1.2:3000/payments/status?orderId=$orderId',
  );

  return channel.stream.map((message) {
    final data = jsonDecode(message);
    return PaymentStatus.fromJson(data);
  });
}
```

---

#### 4.6 Orders Tracking UI

**File:** `frontend/lib/features/orders/pages/orders_list_page.dart`
```dart
class OrdersListPage extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = useState<OrderTab>(OrderTab.PURCHASES);
    final ordersState = ref.watch(ordersProvider(tab.value));

    return Scaffold(
      appBar: AppBar(
        title: Text('Meus Pedidos'),
        bottom: TabBar(
          onTap: (index) => tab.value = OrderTab.values[index],
          tabs: [
            Tab(text: 'Compras'),
            Tab(text: 'Vendas'),
          ],
        ),
      ),
      body: ordersState.when(
        data: (orders) => ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return OrderCard(
              order: orders[index],
              onTap: () => context.push('/orders/${orders[index].id}'),
            );
          },
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, stack) => ErrorWidget(err),
      ),
    );
  }
}
```

**Order Detail with Timeline:**
```dart
class OrderDetailPage extends HookConsumerWidget {
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderDetailProvider(orderId));

    return orderState.when(
      data: (order) => Scaffold(
        appBar: AppBar(title: Text('Pedido #${order.id.substring(0, 8)}')),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildProductInfo(order.product),
              Divider(),
              _buildStatusTimeline(order),
              Divider(),
              _buildEscrowStatus(order.escrowStatus),
              Divider(),
              _buildActions(context, ref, order),
            ],
          ),
        ),
      ),
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, stack) => ErrorWidget(err),
    );
  }

  Widget _buildStatusTimeline(Order order) {
    return OrderStatusTimeline(
      currentStatus: order.status,
      statuses: [
        OrderStatus.PENDING,
        OrderStatus.CONFIRMED,
        OrderStatus.SHIPPED,
        OrderStatus.DELIVERED,
        OrderStatus.COMPLETED,
      ],
    );
  }

  Widget _buildEscrowStatus(EscrowStatus status) {
    return EscrowStatusWidget(
      status: status,
      message: _getEscrowMessage(status),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, Order order) {
    if (order.status == OrderStatus.DELIVERED && order.buyerId == currentUserId) {
      return AppButton.primary(
        label: 'Confirmar Recebimento',
        onPressed: () => _confirmDelivery(context, ref, order.id),
      );
    }
    
    if (order.status == OrderStatus.COMPLETED && !order.hasReview) {
      return AppButton.secondary(
        label: 'Avaliar',
        onPressed: () => context.push('/reviews/create?orderId=${order.id}'),
      );
    }

    return SizedBox.shrink();
  }
}
```

---

#### 4.7 Quick Response Chat Feature

**File:** `frontend/lib/features/chat/pages/chat_conversation_page.dart` (Add quick responses)
```dart
class ChatConversationPage extends HookConsumerWidget {
  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showQuickResponses = useState(false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        actions: [
          IconButton(
            icon: Icon(Icons.question_answer),
            onPressed: () => showQuickResponses.value = !showQuickResponses.value,
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Responses Drawer
          if (showQuickResponses.value) _buildQuickResponsesDrawer(ref),
          
          // Messages
          Expanded(child: MessagesList(conversationId: conversationId)),
          
          // Input
          MessageInput(conversationId: conversationId),
        ],
      ),
    );
  }

  Widget _buildQuickResponsesDrawer(WidgetRef ref) {
    final quickResponses = ref.watch(userQuickResponsesProvider);

    return Container(
      height: 120,
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        color: Colors.grey.shade50,
      ),
      child: quickResponses.isEmpty
          ? _buildEmptyQuickResponses()
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8),
              itemCount: quickResponses.length,
              itemBuilder: (context, index) {
                final response = quickResponses[index];
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: QuickResponseChip(
                    text: response,
                    onTap: () => _sendQuickResponse(ref, response),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyQuickResponses() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Nenhuma resposta rápida configurada'),
          TextButton(
            onPressed: () => context.push('/settings/quick-responses'),
            child: Text('Configurar'),
          ),
        ],
      ),
    );
  }
}

class QuickResponseChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
```

**Quick Responses Settings:**
```dart
class QuickResponsesSettingsPage extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickResponses = ref.watch(userQuickResponsesProvider);
    final controller = useTextEditingController();

    return Scaffold(
      appBar: AppBar(title: Text('Respostas Rápidas')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: controller,
                    label: 'Nova resposta rápida',
                    maxLength: 100,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => _addQuickResponse(ref, controller.text),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              itemCount: quickResponses.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(quickResponses[index]),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _removeQuickResponse(ref, index),
                  ),
                );
              },
            ),
          ),
          
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Máximo de 10 respostas rápidas',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Backend Endpoint for Quick Responses:**
```typescript
// Store in User model
model User {
  // ... existing fields
  quickResponses Json? @default("[]")
}

@Patch('me/quick-responses')
@UseGuards(JwtAuthGuard)
async updateQuickResponses(
  @Body() body: { responses: string[] },
  @Req() req: any,
) {
  // Validate: max 10, each max 100 chars
  if (body.responses.length > 10) {
    throw new ValidationError('Maximum 10 quick responses');
  }

  for (const response of body.responses) {
    if (response.length > 100) {
      throw new ValidationError('Quick response too long (max 100 chars)');
    }
  }

  await this.userRepository.update(req.user.id, {
    quickResponses: body.responses,
  });

  return { success: true };
}
```

---

### Phase 4 Deliverables

**Backend:**
- [ ] Order status management with state machine
- [ ] Auto-create chat after order placement
- [ ] Quick responses storage endpoint
- [ ] Order cancellation endpoint
- [ ] Integration tests for all order flows

**Frontend:**
- [ ] Cart implementation (remove stub)
- [ ] Checkout flow (cart → checkout → payment)
- [ ] PIX payment display with QR code
- [ ] Order list page (buyer/seller views)
- [ ] Order detail with status timeline
- [ ] EscrowStatus widget
- [ ] Confirm delivery button
- [ ] Quick responses drawer in chat
- [ ] Quick responses settings page
- [ ] Navigation flow: Product → Cart → Checkout → Payment → Order Tracking

**Time Estimate:** 7-8 days

---

## Phase 5: Final Polish & Testing (Week 5 - Days 26-30)

### Goal
Complete remaining features, achieve 80% test coverage, and prepare for production.

### Tasks

#### 5.1 Dispute UI

**File:** `frontend/lib/features/disputes/pages/create_dispute_page.dart`
```dart
class CreateDisputePage extends HookConsumerWidget {
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reason = useState<String>('');
    final description = useState<String>('');
    final evidence = useState<List<File>>([]);

    return Scaffold(
      appBar: AppBar(title: Text('Abrir Disputa')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Motivo da disputa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            _buildReasonSelector(reason),
            
            SizedBox(height: 24),
            
            Text('Descrição', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            AppTextField(
              label: 'Descreva o problema',
              maxLines: 5,
              maxLength: 1000,
              onChanged: (value) => description.value = value,
            ),
            
            SizedBox(height: 24),
            
            Text('Evidências (opcional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            _buildEvidenceUpload(evidence),
            
            SizedBox(height: 32),
            
            AppButton.primary(
              label: 'Abrir Disputa',
              enabled: reason.value.isNotEmpty && description.value.length >= 20,
              onPressed: () => _submitDispute(context, ref, orderId, reason.value, description.value, evidence.value),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Other Dispute Pages:**
- `dispute_detail_page.dart` - View dispute, submit additional evidence
- `disputes_list_page.dart` - List user's disputes

---

#### 5.2 Wallet UI Completion

**File:** `frontend/lib/features/wallet/pages/withdraw_page.dart`
```dart
class WithdrawPage extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amount = useState<int>(0);
    final wallet = ref.watch(walletProvider);

    return wallet.when(
      data: (walletData) => Scaffold(
        appBar: AppBar(title: Text('Sacar')),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Saldo disponível:', style: TextStyle(fontSize: 14)),
              Text(
                'R\$ ${(walletData.availableBalance / 100).toStringAsFixed(2)}',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              
              SizedBox(height: 32),
              
              AppTextField(
                label: 'Valor a sacar (R\$)',
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final cents = (double.tryParse(value) ?? 0) * 100;
                  amount.value = cents.toInt();
                },
              ),
              
              SizedBox(height: 16),
              
              if (amount.value > walletData.availableBalance)
                Text(
                  'Saldo insuficiente',
                  style: TextStyle(color: Colors.red),
                ),
              
              Spacer(),
              
              AppButton.primary(
                label: 'Confirmar Saque',
                enabled: amount.value > 0 && amount.value <= walletData.availableBalance,
                onPressed: () => _requestWithdrawal(context, ref, amount.value),
              ),
            ],
          ),
        ),
      ),
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, stack) => ErrorWidget(err),
    );
  }
}
```

**Transaction History:**
```dart
class TransactionHistoryPage extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(transactionHistoryProvider);

    return transactionsState.when(
      data: (transactions) => ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          return TransactionTile(transaction: transactions[index]);
        },
      ),
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, stack) => ErrorWidget(err),
    );
  }
}
```

---

#### 5.3 Product Update Page

**File:** `frontend/lib/features/product/pages/edit_product_page.dart`
```dart
class EditProductPage extends HookConsumerWidget {
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productState = ref.watch(productDetailProvider(productId));

    return productState.when(
      data: (product) => Scaffold(
        appBar: AppBar(title: Text('Editar Produto')),
        body: ProductForm(
          initialData: product,
          onSubmit: (data) => _updateProduct(context, ref, productId, data),
        ),
      ),
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, stack) => ErrorWidget(err),
    );
  }
}
```

**Backend Update Endpoint:**
```typescript
@Patch(':id')
@UseGuards(JwtAuthGuard)
async updateProduct(
  @Param('id') id: string,
  @Body() body: UpdateProductDto,
  @Req() req: any,
) {
  const result = await this.updateProductUseCase.execute({
    productId: id,
    userId: req.user.id,
    ...body,
  });

  if (isLeft(result)) {
    throw result.left;
  }

  return { success: true, data: result.right };
}
```

---

#### 5.4 Backfill Tests for Existing Modules

**Priority Test Targets:**
1. Auth module (register, login, refresh)
2. Orders module (create, confirm)
3. Wallet module (balance, withdrawals)
4. Social module (posts, comments, likes)
5. Chat module (conversations, messages)

**Target Coverage:**
- Use cases: 90%
- Repositories: 80%
- Controllers: 70%

**Run Coverage Report:**
```bash
npm run test:integration:cov
```

---

#### 5.5 E2E Tests for Critical Flows

**File:** `nest-backend/test/e2e/order-flow.e2e-spec.ts`
```typescript
describe('Order Flow E2E', () => {
  it('should complete full order lifecycle', async () => {
    // 1. Register buyer and seller
    const buyer = await registerUser('buyer@test.com');
    const seller = await registerUser('seller@test.com');

    // 2. Seller creates product
    const product = await createProduct(seller.token, {
      title: 'Test Product',
      price: 10000,
    });

    // 3. Buyer creates order
    const order = await createOrder(buyer.token, product.id);
    expect(order.amount).toBe(10000);
    expect(order.platformFee).toBe(1000);
    expect(order.sellerAmount).toBe(9000);

    // 4. Buyer pays via PIX
    const payment = await createPixPayment(buyer.token, order.id);
    expect(payment.status).toBe('PENDING');

    // 5. Simulate webhook (payment confirmed)
    await simulateWebhook({
      orderId: order.id,
      status: 'PAID',
    });

    // 6. Verify order status updated
    const updatedOrder = await getOrder(buyer.token, order.id);
    expect(updatedOrder.status).toBe('CONFIRMED');

    // 7. Seller ships product
    await updateOrderStatus(seller.token, order.id, 'SHIPPED');

    // 8. Seller marks as delivered
    await updateOrderStatus(seller.token, order.id, 'DELIVERED');

    // 9. Buyer confirms delivery
    await confirmDelivery(buyer.token, order.id);

    // 10. Verify funds released
    const sellerWallet = await getWallet(seller.token);
    expect(sellerWallet.availableBalance).toBe(9000);

    // 11. Buyer reviews seller
    await createReview(buyer.token, order.id, {
      type: 'BUYER_REVIEWING_SELLER',
      score: 5,
    });

    // 12. Verify seller reputation updated
    const sellerProfile = await getProfile(seller.token);
    expect(sellerProfile.reputationScore).toBe(5);
    expect(sellerProfile.totalReviews).toBe(1);
  });
});
```

---

#### 5.6 Security Audit Checklist

- [ ] All payment endpoints have rate limiting
- [ ] Webhook signatures verified
- [ ] Idempotency keys enforced
- [ ] JWT tokens validated
- [ ] Authorization checks on all protected routes
- [ ] SQL injection prevention (Prisma)
- [ ] XSS prevention (input sanitization)
- [ ] CORS configured correctly
- [ ] Sensitive data not logged
- [ ] Environment variables secure

---

#### 5.7 Performance Optimization

- [ ] Database indexes verified
- [ ] N+1 query issues resolved
- [ ] Redis caching for hot data
- [ ] Image optimization on frontend
- [ ] Bundle size optimized
- [ ] API response times < 200ms (p95)

---

#### 5.8 Documentation

**Create/Update:**
- [ ] API documentation (OpenAPI/Swagger)
- [ ] README.md (setup instructions)
- [ ] DEPLOYMENT.md (production deployment guide)
- [ ] TESTING.md (how to run tests)
- [ ] CONTRIBUTING.md (development workflow)

---

### Phase 5 Deliverables

**Backend:**
- [ ] 80% overall test coverage
- [ ] 90% use case coverage
- [ ] E2E tests for critical flows
- [ ] Security audit passed
- [ ] Performance benchmarks met

**Frontend:**
- [ ] Dispute UI complete
- [ ] Wallet UI complete
- [ ] Product update page
- [ ] All navigation flows working
- [ ] Widget tests for key components

**Documentation:**
- [ ] API docs complete
- [ ] Setup guides written
- [ ] Deployment guide ready

**Time Estimate:** 5-6 days

---

## Summary Timeline

| Phase | Duration | Completion |
|-------|----------|------------|
| Phase 1: Testing Infrastructure | 2-3 days | Day 3 |
| Phase 2: Reviews System | 4-6 days | Day 9 |
| Phase 3: Payment Security | 5-7 days | Day 16 |
| Phase 4: Checkout & Orders | 7-8 days | Day 24 |
| Phase 5: Final Polish | 5-6 days | Day 30 |

**Total: 5-6 weeks to production-ready MVP**

---

## Success Metrics

### Code Quality
- [ ] 80% overall test coverage
- [ ] 90% use case coverage
- [ ] Zero critical security vulnerabilities
- [ ] All TypeScript strict mode compliance

### Features
- [ ] Reviews system functional
- [ ] Payment security complete
- [ ] Checkout flow working
- [ ] Order tracking working
- [ ] Quick responses in chat

### Performance
- [ ] API response times < 200ms (p95)
- [ ] Frontend bundle < 2MB
- [ ] Database queries optimized

### Documentation
- [ ] API fully documented
- [ ] Setup guide complete
- [ ] Deployment guide ready

---

## Next Steps

1. **Start Phase 1:** Set up testing infrastructure (Docker, Jest, factories)
2. **Daily Standups:** Review progress, adjust timeline
3. **Weekly Reviews:** Assess quality, coverage, blockers
4. **Final Review:** Before production deployment

---

**Plan Created:** March 27, 2026
**Target MVP Launch:** Week of May 5, 2026
**Maintained By:** Development Team

---

## Known Gaps (as of 2026-04-20)

Transparent list of items mentioned elsewhere in the docs that are **not yet fully shipped**. These are acknowledged debt, not hidden work.

| Area | Status | Notes |
|---|---|---|
| **Wishlist** | ❌ Dropped | Superseded by Favorites. Backend module + Prisma model + frontend page removed. Checklist Phase 3/7/11 no longer apply. |
| **KYC verification (CPF + selfie)** | ⚠️ Stub | Flagged HIGH in original plan. No UI or backend flow. Sellers currently listed as "pending verification". |
| **Cloud image upload** | ⚠️ Partial | Images go through `FileStorageService` (base64 → local disk). No S3/CDN wiring. |
| **Admin panel** | ❌ Not started | Listed MEDIUM in original plan. Admin actions (resolve report, disable user) exist as API only. |
| **Search & category UI polish** | ⚠️ Partial | Backend endpoints exist; frontend search delegate and category filters are minimal. |
| **PaymentProvider enum labels** | ⚠️ Legacy | Prisma enum still says `PAGARME`/`WOOVI` but adapters target AbacatePay + PagBank. Rename is a future migration. |

See `CLAUDE.md` and this file's phase sections for everything that **is** shipped.
