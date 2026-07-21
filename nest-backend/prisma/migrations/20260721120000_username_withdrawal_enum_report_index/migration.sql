-- CreateEnum
CREATE TYPE "WithdrawalStatus" AS ENUM ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED');

-- AddColumn (nullable first, backfilled below)
ALTER TABLE "User" ADD COLUMN "username" TEXT;

-- Backfill: slugify displayName (lowercase, [a-z0-9_] only, max 15 chars), dedupe with numeric suffix
WITH slugged AS (
  SELECT
    id,
    NULLIF(
      left(
        regexp_replace(
          regexp_replace(lower(trim("displayName")), '[^a-z0-9_]+', '_', 'g'),
          '^_+|_+$', '', 'g'
        ),
        15
      ),
      ''
    ) AS base_slug
  FROM "User"
),
based AS (
  SELECT
    id,
    COALESCE(base_slug, 'user_' || substr(id, 1, 8)) AS base_slug
  FROM slugged
),
numbered AS (
  SELECT
    id,
    base_slug,
    row_number() OVER (PARTITION BY base_slug ORDER BY id) AS rn
  FROM based
)
UPDATE "User" u
SET "username" = CASE WHEN n.rn = 1 THEN n.base_slug ELSE n.base_slug || '_' || n.rn::text END
FROM numbered n
WHERE u.id = n.id;

-- Enforce NOT NULL + UNIQUE
ALTER TABLE "User" ALTER COLUMN "username" SET NOT NULL;
CREATE UNIQUE INDEX "User_username_key" ON "User"("username");

-- Withdrawal.status: String -> WithdrawalStatus enum
ALTER TABLE "Withdrawal" ALTER COLUMN "status" DROP DEFAULT;
ALTER TABLE "Withdrawal" ALTER COLUMN "status" TYPE "WithdrawalStatus" USING ("status"::"WithdrawalStatus");
ALTER TABLE "Withdrawal" ALTER COLUMN "status" SET DEFAULT 'PENDING';

-- Report: index on reportedPostId
CREATE INDEX "Report_reportedPostId_idx" ON "Report"("reportedPostId");
