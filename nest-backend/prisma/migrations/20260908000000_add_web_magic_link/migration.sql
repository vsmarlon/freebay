CREATE TABLE "WebMagicLink" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "tokenHash" TEXT NOT NULL,
    "consentGranted" BOOLEAN NOT NULL,
    "consentAt" TIMESTAMP(3),
    "requestedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "consumedAt" TIMESTAMP(3),
    "sentAt" TIMESTAMP(3),
    "deliveredAt" TIMESTAMP(3),
    "requestedIp" TEXT,
    "userAgent" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "WebMagicLink_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "WebMagicLink_tokenHash_key" ON "WebMagicLink"("tokenHash");
CREATE INDEX "WebMagicLink_email_requestedAt_idx" ON "WebMagicLink"("email", "requestedAt");
CREATE INDEX "WebMagicLink_email_consumedAt_expiresAt_idx" ON "WebMagicLink"("email", "consumedAt", "expiresAt");
CREATE INDEX "WebMagicLink_expiresAt_idx" ON "WebMagicLink"("expiresAt");

ALTER TABLE "User" ADD COLUMN "webConsentGrantedAt" TIMESTAMP(3), ADD COLUMN "webConsentIp" TEXT, ADD COLUMN "webConsentUserAgent" TEXT;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM "User" GROUP BY lower(btrim("email")) HAVING COUNT(*) > 1) THEN
    RAISE EXCEPTION 'Cannot normalize User.email: case-insensitive trimmed duplicate email groups exist; resolve them before deploying this migration';
  END IF;
END $$;
UPDATE "User"
SET "email" = lower(btrim("email"))
WHERE "email" IS DISTINCT FROM lower(btrim("email"));
CREATE UNIQUE INDEX "User_email_lower_key" ON "User" (lower("email"));
