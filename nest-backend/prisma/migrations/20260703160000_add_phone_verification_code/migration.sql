CREATE TABLE "PhoneVerificationCode" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "phone" TEXT NOT NULL,
  "codeHash" TEXT NOT NULL,
  "attempts" INTEGER NOT NULL DEFAULT 0,
  "maxAttempts" INTEGER NOT NULL DEFAULT 5,
  "requestedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "sentAt" TIMESTAMP(3),
  "expiresAt" TIMESTAMP(3) NOT NULL,
  "usedAt" TIMESTAMP(3),
  "provider" TEXT,
  "providerMessageId" TEXT,

  CONSTRAINT "PhoneVerificationCode_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "PhoneVerificationCode_userId_expiresAt_idx" ON "PhoneVerificationCode"("userId", "expiresAt");
CREATE INDEX "PhoneVerificationCode_userId_usedAt_expiresAt_idx" ON "PhoneVerificationCode"("userId", "usedAt", "expiresAt");
CREATE INDEX "PhoneVerificationCode_codeHash_idx" ON "PhoneVerificationCode"("codeHash");

ALTER TABLE "PhoneVerificationCode"
ADD CONSTRAINT "PhoneVerificationCode_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
