CREATE TABLE "PasswordRecoveryCode" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "codeHash" TEXT NOT NULL,
  "attempts" INTEGER NOT NULL DEFAULT 0,
  "maxAttempts" INTEGER NOT NULL DEFAULT 5,
  "requestedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "sentAt" TIMESTAMP(3),
  "expiresAt" TIMESTAMP(3) NOT NULL,
  "usedAt" TIMESTAMP(3),
  "requestedIp" TEXT,
  "userAgent" TEXT,
  "resendMessageId" TEXT,

  CONSTRAINT "PasswordRecoveryCode_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "PasswordRecoveryCode_userId_expiresAt_idx" ON "PasswordRecoveryCode"("userId", "expiresAt");
CREATE INDEX "PasswordRecoveryCode_userId_usedAt_expiresAt_idx" ON "PasswordRecoveryCode"("userId", "usedAt", "expiresAt");
CREATE INDEX "PasswordRecoveryCode_codeHash_idx" ON "PasswordRecoveryCode"("codeHash");

ALTER TABLE "PasswordRecoveryCode"
ADD CONSTRAINT "PasswordRecoveryCode_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
