-- CreateEnum
CREATE TYPE "WalletBalanceKind" AS ENUM ('AVAILABLE', 'PENDING', 'TOTAL_EARNED');

-- CreateEnum
CREATE TYPE "WalletEntryReason" AS ENUM ('SALE_HELD', 'SALE_RELEASED', 'HOLD_RELEASED', 'REFUND', 'DISPUTE_REFUND', 'DISPUTE_RELEASE', 'PAYOUT', 'WITHDRAWAL', 'ADJUSTMENT');

-- CreateTable
CREATE TABLE "WalletEntry" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "kind" "WalletBalanceKind" NOT NULL,
    "amount" INTEGER NOT NULL,
    "reason" "WalletEntryReason" NOT NULL,
    "orderId" TEXT,
    "transferId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "WalletEntry_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "WalletEntry_userId_createdAt_idx" ON "WalletEntry"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "WalletEntry_orderId_idx" ON "WalletEntry"("orderId");

-- AddForeignKey
ALTER TABLE "WalletEntry" ADD CONSTRAINT "WalletEntry_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WalletEntry" ADD CONSTRAINT "WalletEntry_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Backfill
INSERT INTO "WalletEntry" ("id", "userId", "kind", "amount", "reason", "createdAt")
SELECT gen_random_uuid(), w."userId", 'AVAILABLE'::"WalletBalanceKind", w."availableBalance", 'ADJUSTMENT'::"WalletEntryReason", CURRENT_TIMESTAMP
FROM "Wallet" w WHERE w."availableBalance" <> 0;

INSERT INTO "WalletEntry" ("id", "userId", "kind", "amount", "reason", "createdAt")
SELECT gen_random_uuid(), w."userId", 'PENDING'::"WalletBalanceKind", w."pendingBalance", 'ADJUSTMENT'::"WalletEntryReason", CURRENT_TIMESTAMP
FROM "Wallet" w WHERE w."pendingBalance" <> 0;

INSERT INTO "WalletEntry" ("id", "userId", "kind", "amount", "reason", "createdAt")
SELECT gen_random_uuid(), w."userId", 'TOTAL_EARNED'::"WalletBalanceKind", w."totalEarned", 'ADJUSTMENT'::"WalletEntryReason", CURRENT_TIMESTAMP
FROM "Wallet" w WHERE w."totalEarned" <> 0;
