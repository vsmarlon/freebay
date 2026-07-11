# Backend Cleanup — Phases 5–10 ✅ COMPLETE

Phase 4 (repo abstractions) is complete. Phases 5–10 are all done.

---

## Phase 5 — ProcessWebhookUseCase Decomposition

Add `tx?: Prisma.TransactionClient` to repository methods, refactor `process-webhook.usecase.ts` to inject repos instead of raw PrismaService.

### New repo methods needed

**ProductRepository** (`domain/repositories/product.repository.ts`):
```
abstract updateInventoryOnSale(productId: string, tx?: Prisma.TransactionClient): RepositoryResponse<void>
abstract restoreInventoryOnExpiry(productId: string, tx?: Prisma.TransactionClient): RepositoryResponse<void>
```

**OrderRepository** — add to existing abstract class:
```
abstract confirm(orderId: string, tx?: Prisma.TransactionClient): RepositoryResponse<void>
abstract cancel(orderId: string, tx?: Prisma.TransactionClient): RepositoryResponse<void>
```

**WalletRepository** — add to existing abstract class:
```
abstract creditPending(userId: string, amount: number, tx?: Prisma.TransactionClient): RepositoryResponse<void>
```

Create new **TransactionRepository**:
```
domain/repositories/transaction.repository.ts (abstract)
data/repositories/transaction-database.repository.ts (Prisma impl)

abstract markAsPaid(id: string, tx?: Prisma.TransactionClient): RepositoryResponse<void>
abstract markAsFailed(id: string, tx?: Prisma.TransactionClient): RepositoryResponse<void>
abstract findByIdempotencyKey(key: string): RepositoryResponse<TransactionWithOrder | null>
```

### Refactored process-webhook.usecase.ts

```typescript
constructor(
  private productRepo: ProductRepository,
  private transactionRepo: TransactionRepository,
  private orderRepo: OrderRepository,
  private walletRepo: WalletRepository,
  private notificationService: NotificationService,
  private prisma: PrismaService,
) {}

// charge.completed handler:
try {
  await this.prisma.$transaction(async (tx) => {
    await this.productRepo.updateInventoryOnSale(transaction.order.productId, tx);
    await this.transactionRepo.markAsPaid(transaction.id, tx);
    await this.orderRepo.confirm(transaction.orderId, tx);
    await this.walletRepo.creditPending(transaction.order.sellerId, transaction.sellerAmount, tx);
  });
} catch {
  return left(new DatabaseError('Failed to process payment webhook'));
}
```

---

## Phase 6 — N+1 Fix in CreatePixPaymentUseCase

Add to **UserRepository** abstract class:
```typescript
abstract findPaymentInfo(userId: string): RepositoryResponse<{ displayName: string; email: string; cpf: string | null } | null>
```

Implement in `PrismaUserRepository` (single `findUnique` selecting `displayName`, `email`, `cpf`).

In `create-pix-payment.usecase.ts`:
- Remove `PrismaService` injection
- Inject `UserRepository` instead
- Replace 3 separate `findUnique` calls with single `findPaymentInfo(input.userId)` call

---

## Phase 7 — Weak Boolean Returns → void

Change ~30 usecases from `Either<AppError, { verb: boolean }>` to `Either<AppError, void>`.
Replace `return right({ verb: true })` with `return right(undefined)`.

Files (all in nest-backend/src/modules/):
- orders: mark-as-shipped, mark-as-delivered, cancel-order, activate-escrow
- orders/confirm-delivery: change to `Either<AppError, { sellerAmount: number }>` (keep sellerAmount)
- cart: remove-from-cart, clear-cart
- social: like-post, unlike-post, like-comment, unlike-comment, share-post, unshare-post, save-post, unsave-post
- stories: view-story, delete-story
- auth: reset-password, verify-password-recovery-code, request-password-recovery
- users: update-fcm-token, register-phone (if exists)
- products: delete-product
- notifications: mark-as-read, register-fcm-token (after Phase 3 split)
- reports: resolve-report
- disputes: resolve-dispute, submit-evidence, withdraw-dispute
- favorites: toggle-favorite (keep check-favorite as `{ isFavorited: boolean }`)

Update controller callers — remove `.verb` field access; just check `isLeft(result)`.

---

## Phase 8 — RegisterBankAccountUseCase Stub

In `register-bank-account.usecase.ts`:
```typescript
async execute(_input: RegisterBankAccountInput): Promise<Either<AppError, void>> {
  return left(new NotImplementedError('PagBank recipient registration'));
}
```

Create GitHub issue: "feat: implement real PagBank recipient registration in RegisterBankAccountUseCase"

Skip any tests that call this usecase with `it.skip`.

---

## Phase 9 — Move P2002 Infrastructure Leaks to Repositories

### follow-user.usecase.ts
Currently catches raw Prisma `P2002` code in usecase. Move to `FollowRepository.create()`:
```typescript
} catch (error: any) {
  if (error?.code === 'P2002') return left(new AlreadyExistsError('Follow'));
  return left(new DatabaseError());
}
```
Usecase just does `isLeft` check.

### withdraw.usecase.ts
Move the P2002 retry block (lines 95–103) to `WalletRepository`. Replace bare `new AppError('INTERNAL_ERROR', ...)` in catch with `new DatabaseError(error instanceof Error ? error.message : 'Erro interno ao realizar saque')`.

---

## Phase 10 — Documentation Pass

Update all project-level .md files to reflect post-refactor state:
- `CLAUDE.md` — add DatabaseError/NotImplementedError, tx? pattern, void return convention
- `AGENTS.md` — update module file layout
- `nest-backend/CONTEXT.md` + `CONTEXT-MAP.md` — reflect new domain/data repo structure
- `REVIEWEDARCHITECTURETODO.md`, `TODO.md`, `.planning/checklist.md` — mark done, add PagBank issue
- `IMPROVEDARCH.md` — reconcile
- `docs/audit/*.md` (5 files) — update resolved findings
- `nest-backend/src/modules/disputes/CONTEXT.md`
- `db/README.md`, `frontend/README.md` — update if stale

---

## Verification (run after all phases)
```bash
cd nest-backend && npx tsc --noEmit   # zero errors
cd nest-backend && npm test            # all tests pass
cd nest-backend && npm run lint        # zero lint errors
```
