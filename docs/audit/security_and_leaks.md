# Security Audit: Leaks, Race Conditions, and Guard Gaps

This report covers critical vulnerabilities identified in the transactional, financial, and security boundaries of the FreeBay backend.

---

## 1. Financial & Wallet Leaks

### 1.1. Dangling Escrow on Order Cancellation
When an order is created and paid, the seller's `pendingBalance` is incremented. However, if the order is subsequently cancelled, the buyer's balance is refunded, but the seller's pending balance is **never decremented**. This leads to inflated, incorrect pending balances.

- **Vulnerable Code Location:** [order-database.repository.ts:L231-L239](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/orders/data/repositories/order-database.repository.ts#L231-L239)
```typescript
if (data.status === 'CONFIRMED') {
  const wallet = await tx.wallet.findUnique({ where: { userId: data.buyerId } });
  if (wallet) {
    await tx.wallet.update({
      where: { userId: data.buyerId },
      data: { availableBalance: { increment: data.amount } }, // Buyer refunded
    });
    // Missing: decrement of seller's pendingBalance by data.sellerAmount!
  }
}
```

### 1.2. Unreclaimed Escrow on Buyer Dispute Wins
A similar balance leak occurs in the dispute resolution execution engine. When a dispute is resolved in favor of the buyer, the buyer receives a refund. However, the seller's wallet `pendingBalance` remains untouched, trapping the escrow amount.

- **Vulnerable Code Location:** [dispute-resolution-execution.service.ts:L7-L20](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/disputes/services/dispute-resolution-execution.service.ts#L7-L20)
```typescript
async resolveInFavorOfBuyer(tx: Prisma.TransactionClient, dispute: DisputeWithOrder): Promise<void> {
  await tx.order.update({
    where: { id: dispute.orderId },
    data: { status: 'CANCELLED', escrowStatus: 'REFUNDED' },
  });

  const buyerWallet = await tx.wallet.findUnique({ where: { userId: dispute.order.buyerId } });
  if (buyerWallet) {
    await tx.wallet.update({
      where: { userId: dispute.order.buyerId },
      data: { availableBalance: { increment: dispute.order.amount } }, // Buyer refunded
    });
    // Missing: decrement of seller's pendingBalance by dispute.order.sellerAmount!
  }
}
```

### 1.3. Double-Withdrawals / Balance Bypass
In `WithdrawUseCase`, the balance check is performed in memory on a previously fetched entity, without a database transaction or lock. If a user triggers multiple withdrawal requests concurrently, they can withdraw more money than their available balance.

- **Vulnerable Code Location:** [wallet.usecase.ts:L36-L65](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/wallet/usecases/wallet.usecase.ts#L36-L65)
```typescript
const wallet = await this.walletRepository.findByUserId(input.userId); // Read 1 (Unlocked)
if (wallet.availableBalance < input.amount) { ... }                     // Validation (Race Condition)

const withdrawal = await this.prisma.withdrawal.create({ ... });       // Unlocked Insert
await this.prisma.wallet.update({                                     // Unlocked Update
  where: { userId: input.userId },
  data: { availableBalance: { decrement: input.amount } },
});
```

> [!CAUTION]
> Under PostgreSQL's default `Read Committed` isolation level, concurrent requests can execute this block simultaneously, passing the balance check in parallel and completing multiple updates. To fix this, use `$transaction` with a `SELECT ... FOR UPDATE` row lock.

---

## 2. Race Conditions & Concurrency

### 2.1. Over-selling/Lost Updates on Product Stock
When multi-quantity products are purchased, the application performs stock reservation inside a Prisma transaction, but reads the data without a pessimistic lock (`SELECT FOR UPDATE`). This allows two concurrent orders to read the same `soldCount` in parallel, resulting in lost updates and overselling.

- **Vulnerable Code Location:** [order-database.repository.ts:L91-L104](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/orders/data/repositories/order-database.repository.ts#L91-L104)
```typescript
const order = await this.prisma.$transaction(async (tx) => {
  if (product.quantity > 1) {
    const current = await tx.product.findUnique({ where: { id: data.productId } }); // Read (Unlocked)
    if (!current || current.quantity <= current.soldCount) {
      throw new AppError('BAD_REQUEST', 'Produto sem estoque');
    }
    const newSoldCount = current.soldCount + 1;
    await tx.product.update({                                                       // Update
      where: { id: data.productId },
      data: { soldCount: newSoldCount },
    });
  }
});
```

### 2.2. Blind State Editing in Background Tasks (Escrow & Disputes)
Cron tasks retrieve items matching query conditions, then loop through them sequentially, updating statuses in separate transactions. If order or dispute states change (e.g., buyer opens a dispute or resolves it) while the loop is running, the task overwrites the state blindly.

- **Escrow Release Task:** [escrow-release.task.ts:L24-L49](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/tasks/escrow-release.task.ts#L24-L49)
  Loads orders with `dispute: null` globally, but does not check if a dispute was opened during loop processing before updating status to `COMPLETED`.
- **Dispute Cleanup Task:** [dispute-cleanup.task.ts:L26-L38](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/tasks/dispute-cleanup.task.ts#L26-L38)
  Updates the dispute status to `RESOLVED` blindly, resolving in favor of the seller, without validating that the dispute remains open and unresolved.

### 2.3. Non-Atomic Multi-Order Checkout
When checking out a cart with multiple orders, the items are processed sequentially in a `for` loop. The use case initiates order creation and payment generation requests separately for each product. If a failure occurs midway through, prior orders remain committed while later ones are aborted, creating an inconsistent checkout state.

- **Vulnerable Code Location:** [checkout-cart.usecase.ts:L33-L83](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/cart/usecases/checkout-cart.usecase.ts#L33-L83)
```typescript
for (const item of cartItems) {
  const orderResult = await this.cartRepository.createOrderFromCheckout(...);
  const pixResult = await this.createPixPaymentUseCase.execute(...); // PIX HTTP integration
  if (isLeft(pixResult)) {
    await this.cartRepository.rollbackOrderReservation(...); // Rollback only current item
    return left(pixResult.value);                            // Exits loop, leaving previous orders active!
  }
}
```

---

## 3. Guard Gaps & Data Leaks

### 3.1. Missing `JwtAuthGuard` on Story View
The story view route lacks verification. A guest session can trigger this route, setting the `viewerId` to `""`. Since `""` is a truthy value, it triggers a database insertion of an empty string into the `StoryView` schema, causing a foreign key violation or validation crash.

- **Vulnerable Code Location:** [stories.controller.ts:L116-L128](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/stories/stories.controller.ts#L116-L128)
```typescript
@Post(':id/view')
// Missing @UseGuards(JwtAuthGuard)!
async viewStory(@Param('id') id: string, @CurrentUser() user: AuthUser) {
  const result = await this.storiesService.viewStory({ storyId: id, viewerId: user?.userId || '' });
  ...
}
```

### 3.2. Missing `NonGuestGuard` (Exposing Admin/Write Endpoints to Guests)
While guest accounts receive a valid JWT, their access should be restricted to read-only endpoints. The following controllers lack the `NonGuestGuard`, allowing guest sessions to create database objects:
- **`DisputesController`:** Guest sessions can create disputes, submit evidence, and fetch order history.
- **`ReportsController`:** Guest sessions can submit reports.
- **`ChatController` & Gateway:** Guest sessions can connect to websockets, join conversations, and send chat messages.
- **FCM Token Route:** [users.controller.ts:L247](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/users/users.controller.ts#L247) allows guest sessions to update FCM tokens, polluting user devices lists.

### 3.3. Broken Optional Auth on explore feeds
The explore/feed route extracts the current user via `@CurrentUser()`. However, because the endpoint has no guards registered, passport is never activated to parse the headers. Thus, `user` is always undefined and falls back to `""`, rendering the explore custom matching useless.

- **Vulnerable Code Location:** [social.controller.ts:L42-L56](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/social/social.controller.ts#L42-L56)
```typescript
@Get('feed')
// Missing Optional Auth Guard!
async getFeed(@CurrentUser() user: AuthUser, @Query() query: GetFeedQueryDTO) {
  const result = await this.socialService.getFeed({
    userId: user?.userId || '', // Always evaluates to ''
    ...
  });
}
```

### 3.4. Public CPF and Role Leak
When requesting a profile by ID, the route uses `UserResponse` mapper which formats and includes the masked CPF (`123.***.***-00`) and the account role in the JSON response. This exposes sensitive information of all registered users to any unauthenticated caller.

- **Vulnerable Code Location:** [users.controller.ts:L382-L413](file:///c:/Users/Qiyana/Documents/GitHub/ME/freebay/nest-backend/src/modules/users/users.controller.ts#L382-L413)
```typescript
@Get(':id') // Unauthenticated profile page
async getUser(@Param('id', ParseUUIDPipe) id: string) {
  const userRecord = userResult.value;
  return toUserResponse(userRecord, ...); // Maps role and masked CPF!
}
```

---

## Remediation Plan

To address these vulnerabilities, implement:
1. **Fix Escrow Leaks:** Modify both `cancelOrder` and `resolveInFavorOfBuyer` to decrement the seller's wallet `pendingBalance` by the matching `sellerAmount`.
2. **Implement Pessimistic Locks:** Use raw SQL queries or Prisma interactive transactions with row-level locks for withdrawals and stock decrements:
   ```typescript
   await tx.$executeRaw`SELECT * FROM "Wallet" WHERE "userId" = ${userId} FOR UPDATE`;
   ```
3. **Task State Verification:** Add target state validation to cron updates:
   ```typescript
   await tx.order.update({
     where: { id: order.id, status: 'DELIVERED', dispute: null },
     data: { status: 'COMPLETED' }
   });
   ```
4. **Apply Required Guards:** Add `@UseGuards(JwtAuthGuard, NonGuestGuard)` to all write routes (chat, disputes, reports, stories). Use an optional auth guard to parse user context for feeds without blocking guest reads.
5. **Differentiate Public Profiles:** Create a separate `PublicUserResponse` mapper that excludes the `cpf` and `role` fields, reserving `UserResponse` only for the `/me` personal endpoint.
