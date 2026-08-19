-- AlterEnum: Rename PaymentProvider values to STRIPE only
ALTER TYPE "PaymentProvider" RENAME TO "_old_PaymentProvider";
CREATE TYPE "PaymentProvider" AS ENUM ('STRIPE');
ALTER TABLE "Transaction" ALTER COLUMN "provider" TYPE "PaymentProvider" USING "provider"::text::"PaymentProvider";
DROP TYPE "_old_PaymentProvider";

-- AlterTable: Rename pixQrCode to checkoutUrl, pixExpiresAt to checkoutExpiresAt
ALTER TABLE "Transaction" RENAME COLUMN "pixQrCode" TO "checkoutUrl";
ALTER TABLE "Transaction" RENAME COLUMN "pixExpiresAt" TO "checkoutExpiresAt";
