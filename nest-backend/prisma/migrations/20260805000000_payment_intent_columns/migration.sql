-- Add the Transaction columns schema.prisma declares but no migration ever created.
-- Deployment path is `prisma db push` (see payments ADR); guards keep this replay-safe.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Transaction' AND column_name = 'idempotencyKey') THEN
    ALTER TABLE "Transaction" ADD COLUMN "idempotencyKey" VARCHAR(255);
    UPDATE "Transaction" SET "idempotencyKey" = 'tx-' || "id";
    ALTER TABLE "Transaction" ALTER COLUMN "idempotencyKey" SET NOT NULL;
    ALTER TABLE "Transaction" ADD CONSTRAINT "Transaction_idempotencyKey_key" UNIQUE ("idempotencyKey");
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Transaction' AND column_name = 'checkoutUrl') THEN
    ALTER TABLE "Transaction" ADD COLUMN "checkoutUrl" TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Transaction' AND column_name = 'checkoutExpiresAt') THEN
    ALTER TABLE "Transaction" ADD COLUMN "checkoutExpiresAt" TIMESTAMP(3);
  END IF;
END $$;
