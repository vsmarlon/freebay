# Code Simplifications and Logic Issues

This report highlights code consolidation issues, stateful patterns that block horizontal scaling, and broken query logic in search and suggestions.

---

## 1. Multiple Use Cases in a Single File

In multiple modules, several unrelated use cases are grouped together in a single file. This violates the Single Responsibility Principle and the single-usecase-per-file architectural rule of the project:

- **Wallet Use Cases:** [wallet.usecase.ts](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/wallet/usecases/wallet.usecase.ts) contains `GetWalletUseCase`, `WithdrawUseCase`, and `RegisterBankAccountUseCase`.
- **Payment Use Cases:** [payment.usecase.ts](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/payments/usecases/payment.usecase.ts) contains `CreatePixPaymentUseCase` and `ProcessWebhookUseCase`.
- **Notification Use Cases:** [notification.usecase.ts](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/notifications/usecases/notification.usecase.ts) contains `GetNotificationsUseCase`, `MarkAsReadUseCase`, and `RegisterFcmTokenUseCase`.

> [!TIP]
> Each Use Case class should reside in its own file (e.g., `withdraw.usecase.ts`, `get-wallet.usecase.ts`) to make files smaller, easier to read, and isolate import dependencies.

---

## 2. In-Memory State in NestJS Singletons

Storing application state in-memory inside singleton classes is a dangerous anti-pattern. If the server scales horizontally (multiple instances running behind a load balancer), the instances will have divergent, incomplete state, causing random and untraceable failures.

### 2.1. Caching Uploaded Review Images in `ReviewsService`
When an image is uploaded for a review, it is cached temporarily in an instance-level Map:

- **Vulnerable Code Location:** [reviews.service.ts:L29-L33](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/reviews/reviews.service.ts#L29-L33) & [L60](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/reviews/reviews.service.ts#L60)
```typescript
private tempImages = new Map<string, string>(); // In-memory cache

async uploadImage(...) {
  ...
  this.tempImages.set(result.value.imageId, result.value.url); // Write
}

async createReview(...) {
  const imageUrls = (body.imageIds ?? [])
    .map((id) => this.tempImages.get(id)) // Read (Fails if routed to a different instance!)
  ...
}
```

### 2.2. Tracking Socket Connections in `ChatGateway`
`ChatGateway` maintains a local Map of active client socket connections:

- **Vulnerable Code Location:** [chat.gateway.ts:L34](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/chat/chat.gateway.ts#L34)
```typescript
private connectedUsers = new Map<string, AuthenticatedUser>();
```

If User A connects to Instance 1, and User B connects to Instance 2, they will not be able to exchange messages because Instance 1 doesn't know about User B's socket connection, and vice-versa.

---

## 3. Ignored Search Query Filters in `searchPosts`

The post search route accepts a filter parameter that can be `"all"`, `"following"`, or `"followers"` to scope the search context. However, the repository implementation discards this parameter entirely and searches all posts globally.

- **Vulnerable Controller Code:** [social.controller.ts:L158-L164](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/social/social.controller.ts#L158-L164)
  Exposes the `filter` parameter to `socialService.searchPosts`.
- **Vulnerable Repository Code:** [post-database.repository.ts:L83-L99](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/social/data/repositories/post-database.repository.ts#L83-L99)
```typescript
async searchPosts(query: SearchPostsQuery): RepositoryResponse<PostPayload[]> {
  try {
    const where: Prisma.PostWhereInput = {
      content: { contains: query.query, mode: 'insensitive' }, // "filter" field is ignored!
    };
    ...
```

---

## 4. Broken User Suggestions Query Logic (Contradiction)

The user suggestions endpoint compiles recommendations of users to follow. However, due to a logical contradiction in the Prisma `where` clause, the query always resolves to an empty list `[]`.

- **Vulnerable Code Location:** [user-database.repository.ts:L67-L92](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/auth/data/repositories/user-database.repository.ts#L67-L92)
```typescript
const following = await this.prisma.follow.findMany({
  where: { followerId: userId },
  select: { followingId: true },
});
const followingIds = following.map((f) => f.followingId); // People the current user follows

const suggestions = await this.prisma.user.findMany({
  where: {
    id: { not: userId },
    following: { some: { followerId: { in: followingIds } } }, // Clause A
    NOT: { followers: { some: { followerId: userId } } },       // Clause B
  },
  ...
```

### Analysis of the Contradiction:

1. In the Prisma schema:
   - `following` relation on `User` represents follow records where the user is the **follower** (`followerId = User.id`).
   - `followers` relation on `User` represents follow records where the user is the **following party** (`followingId = User.id`).
2. Therefore:
   - **Clause A (`following: { some: { followerId: { in: followingIds } } }`):** Since this is evaluated on the `following` relation of the suggestion user, the query filters for follow records where `followerId` is the suggestion user itself. This requires that the suggestion user's ID (`followerId`) is present in `followingIds`.
     - *Meaning:* "The suggestion user must be someone the current user already follows."
   - **Clause B (`NOT: { followers: { some: { followerId: userId } } }`):** This filters out suggestion users who have a follower with `followerId = userId`.
     - *Meaning:* "The suggestion user must NOT be someone the current user already follows."
3. **The Contradiction:** A user cannot be both followed and not followed by the current user at the same time. The query requests:
   $$\text{suggestion.id} \in \text{followingIds} \quad \land \quad \text{suggestion.id} \notin \text{followingIds}$$
   This intersection is always empty ($\emptyset$), so user suggestions never return any results.

---

## Remediation Plan

1. **Decompose Single-File Use Cases:** Move all grouped use cases to separate files under the `usecases/` directories of their respective modules.
2. **Move State out of Singletons:**
   - For `ReviewsService` review images: Upload files to temporary cloud bucket folders directly, or write metadata to a temporary Redis key instead of an in-memory Map.
   - For `ChatGateway` socket connections: Integrate `socket.io-redis` adapter to manage socket rooms and message distribution across multiple node instances.
3. **Implement Search Scopes:** Update `post-database.repository.ts` to process search filters:
   ```typescript
   if (query.filter === 'following') {
     const following = await this.prisma.follow.findMany({ where: { followerId: query.userId } });
     where.userId = { in: following.map(f => f.followingId) };
   }
   ```
4. **Fix Suggestions Query:** The query intended to find "mutual follows" (friends of friends). It should filter for users who are followed by the people the current user follows, excluding the current user and people the current user already follows:
   ```typescript
   where: {
     id: { not: userId, notIn: followingIds }, // Exclude self and already followed
     followers: { some: { followerId: { in: followingIds } } } // Followed by people the user follows
   }
   ```
