-- CreateEnum
CREATE TYPE "ModerationTargetType" AS ENUM ('USER', 'PRODUCT', 'POST', 'COMMENT', 'REPORT');

-- CreateEnum
CREATE TYPE "ModerationActionType" AS ENUM ('REPORT_REVIEWED', 'REPORT_RESOLVED', 'REPORT_REJECTED', 'USER_SUSPENDED', 'USER_UNSUSPENDED', 'PRODUCT_REMOVED', 'POST_REMOVED', 'COMMENT_REMOVED');

-- CreateEnum
CREATE TYPE "PaymentGroupStatus" AS ENUM ('PENDING', 'PAID', 'FAILED', 'EXPIRED');

-- AlterTable
ALTER TABLE "User" ADD COLUMN "deletionRequestedAt" TIMESTAMP(3);
ALTER TABLE "User" ADD COLUMN "suspendedAt" TIMESTAMP(3);
ALTER TABLE "User" ADD COLUMN "suspensionReason" TEXT;

-- CreateIndex
CREATE INDEX "User_deletionRequestedAt_idx" ON "User"("deletionRequestedAt");

-- AlterTable
ALTER TABLE "Report" ADD COLUMN "reviewedById" TEXT;

-- CreateIndex
CREATE INDEX "Report_status_createdAt_idx" ON "Report"("status", "createdAt");

-- AddForeignKey
ALTER TABLE "Report" ADD CONSTRAINT "Report_reviewedById_fkey" FOREIGN KEY ("reviewedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- CreateTable
CREATE TABLE "ModerationAction" (
    "id" TEXT NOT NULL,
    "actorId" TEXT NOT NULL,
    "targetType" "ModerationTargetType" NOT NULL,
    "targetId" TEXT NOT NULL,
    "action" "ModerationActionType" NOT NULL,
    "reason" TEXT,
    "reportId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ModerationAction_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ModerationAction_createdAt_idx" ON "ModerationAction"("createdAt");

-- CreateIndex
CREATE INDEX "ModerationAction_actorId_createdAt_idx" ON "ModerationAction"("actorId", "createdAt");

-- CreateIndex
CREATE INDEX "ModerationAction_targetType_targetId_idx" ON "ModerationAction"("targetType", "targetId");

-- AddForeignKey
ALTER TABLE "ModerationAction" ADD CONSTRAINT "ModerationAction_actorId_fkey" FOREIGN KEY ("actorId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ModerationAction" ADD CONSTRAINT "ModerationAction_reportId_fkey" FOREIGN KEY ("reportId") REFERENCES "Report"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- CreateTable
CREATE TABLE "PaymentGroup" (
    "id" TEXT NOT NULL,
    "buyerId" TEXT NOT NULL,
    "amount" INTEGER NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'brl',
    "status" "PaymentGroupStatus" NOT NULL DEFAULT 'PENDING',
    "provider" "PaymentProvider" NOT NULL,
    "idempotencyKey" TEXT NOT NULL,
    "stripePaymentIntentId" TEXT,
    "stripeSessionId" TEXT,
    "clientSecret" TEXT,
    "checkoutUrl" TEXT,
    "chargeId" TEXT,
    "expiresAt" TIMESTAMP(3),
    "paidAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PaymentGroup_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "PaymentGroup_idempotencyKey_key" ON "PaymentGroup"("idempotencyKey");

-- CreateIndex
CREATE UNIQUE INDEX "PaymentGroup_stripePaymentIntentId_key" ON "PaymentGroup"("stripePaymentIntentId");

-- CreateIndex
CREATE UNIQUE INDEX "PaymentGroup_stripeSessionId_key" ON "PaymentGroup"("stripeSessionId");

-- CreateIndex
CREATE INDEX "PaymentGroup_buyerId_createdAt_idx" ON "PaymentGroup"("buyerId", "createdAt");

-- CreateIndex
CREATE INDEX "PaymentGroup_status_expiresAt_idx" ON "PaymentGroup"("status", "expiresAt");

-- AlterTable
ALTER TABLE "Transaction" ADD COLUMN "paymentGroupId" TEXT;

-- CreateIndex
CREATE INDEX "Transaction_paymentGroupId_idx" ON "Transaction"("paymentGroupId");

-- CreateIndex
CREATE INDEX "Transaction_status_checkoutExpiresAt_idx" ON "Transaction"("status", "checkoutExpiresAt");

-- AddForeignKey
ALTER TABLE "Transaction" ADD CONSTRAINT "Transaction_paymentGroupId_fkey" FOREIGN KEY ("paymentGroupId") REFERENCES "PaymentGroup"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AlterTable
ALTER TABLE "Dispute" ADD COLUMN "resolvedById" TEXT;

-- AddForeignKey
ALTER TABLE "Dispute" ADD CONSTRAINT "Dispute_resolvedById_fkey" FOREIGN KEY ("resolvedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
