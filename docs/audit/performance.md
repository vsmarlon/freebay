# Performance Audit: N+1 Queries, Indexes, and Caching

This report identifies bottlenecks in data retrieval, indexing gaps, and caching omissions that will degrade API responsiveness as the platform scales.

---

## 1. N+1 Query Loops in Background Tasks

Both the escrow release and dispute resolution cron jobs use a pattern where they query a list of entities and then loop over them to execute updates and database transactions sequentially:

- **Escrow Release Task:** [escrow-release.task.ts:L24-L49](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/tasks/escrow-release.task.ts#L24-L49)
  Queries orders, then for each order, starts a transaction, updates the order, finds the seller's wallet, updates the wallet, and updates the transaction record.
- **Dispute Cleanup Task:** [dispute-cleanup.task.ts:L26-L38](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/tasks/dispute-cleanup.task.ts#L26-L38)
  Queries expired disputes, then for each dispute, runs a transaction to update the dispute and resolve the escrow.

> [!WARNING]
> Processing thousands of orders or disputes sequentially results in N+1 database transactions. If one transaction is slow or stalls, it blocks the entire queue. These should be batched (e.g. using `updateMany` or parallelizing operations in chunked batches).

---

## 2. In-Memory Tree Building and Slicing (Comments)

The comment retrieval endpoint fetches all comments for a post from the database without any pagination parameters. It then builds a nested tree hierarchy and slices the tree array in-memory to paginate the result.

- **Vulnerable Code Location:** [get-comments.usecase.ts:L11-L35](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/social/usecases/get-comments.usecase.ts#L11-L35)
```typescript
async execute(input: { postId: string; limit?: number; offset?: number }) {
  const result = await this.commentRepository.findAllByPostId(input.postId); // Loads ALL comments
  
  const nodes = new Map<string, CommentTree>();
  for (const comment of result.value) {
    nodes.set(comment.id, { ...comment, replies: [] }); // Allocates Map in memory
  }
  
  // Building tree roots...
  
  return right(roots.slice(offset, offset + limit)); // Slices result in memory
}
```

If a popular post accumulates thousands of comments, this endpoint will cause significant CPU and memory spikes, and transfer large volumes of unnecessary data from PostgreSQL on every request.

---

## 3. Database Queries on Unindexed Fields

The database queries utilize filters and sorting operations on fields that lack index definitions in [schema.prisma](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/prisma/schema.prisma):

- **`Post.createdAt`:** Queried globally for explore feeds and search queries. The index is only a composite index `@@index([userId, createdAt])` which cannot be utilized for global sorting.
- **`Story.expiresAt`:** Cleaned up by cron jobs and fetched globally for active stories. The composite index `@@index([userId, expiresAt])` does not cover queries checking `expiresAt` globally without a `userId` filter.
- **`Follow.followingId`:** Lookups of followers for a user perform a scan because the only constraint is `@@unique([followerId, followingId])` (left-prefix indexing rule makes it unusable when filtering by `followingId`).
- **`Product.createdAt`:** Sorting products globally by date triggers filesorts due to missing indexes.
- **`Order.buyerId` and `Order.sellerId` with `createdAt`:** Listing user orders sorted by date triggers full table scans because the indexes `@@index([buyerId])` and `@@index([sellerId])` lack `createdAt` columns.

### Prisma Index Solutions

To resolve these database bottlenecks, add the following index definitions to `schema.prisma`:

```prisma
model Post {
  // ...
  @@index([createdAt]) // For global post feeds
}

model Story {
  // ...
  @@index([expiresAt]) // For global story expiration queries
}

model Follow {
  // ...
  @@index([followingId]) // For followers count and listing followers
}

model Product {
  // ...
  @@index([createdAt]) // For global search sorting
}

model Order {
  // ...
  @@index([buyerId, createdAt(sort: Desc)])  // Optimized list of buyer purchases
  @@index([sellerId, createdAt(sort: Desc)]) // Optimized list of seller sales
}
```

---

## 4. Lack of Pagination on Global Stories Feed

The global stories feed fetching logic loads all active stories in the database in a single query, maps them, groups them in memory, and returns them as a single response payload without offset or cursor-based pagination.

- **Vulnerable Code Location:** [get-stories.usecase.ts:L12-L34](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/stories/usecases/get-stories.usecase.ts#L12-L34)
```typescript
const result = await this.storyRepository.findActiveWithViews(); // Loads ALL active stories
const stories = result.value;
const groupedByUser = stories.reduce<Record<string, GroupedStory>>((acc, story) => { ... }, {}); // Group in memory
return right({ stories: Object.values(groupedByUser), userHasStory });
```

This will rapidly degrade in performance as the active user base grows.

---

## 5. Missing Redis Caching Layers

Frequently read, slow-moving configuration and resource endpoints fetch data from the relational database on every request instead of utilizing a fast memory store (Redis):

- **Product Categories:** Categories list rarely changes but is fetched on every browse request.
- **User Public Profiles:** Requested frequently but queried directly from PostgreSQL.
- **Social Feeds:** Building the ranked explore feed is resource intensive and should be cached with short TTLs.

---

## Remediation Plan

1. **Optimize Comment Loading:** Paginate comments at the database level by loading only root comments for a page, and fetch replies dynamically (lazy loading) when requested.
2. **Apply Indexing:** Update the schema definitions as shown above and run `prisma migrate dev` to create the database indexes.
3. **Paginate Stories:** Limit the global stories query to the top 20 active users with active stories, utilizing cursor-based pagination.
4. **Implement Caching:** Integrate Redis caching decorators or service interfaces for category queries and public profiles with cache invalidation on edits.
