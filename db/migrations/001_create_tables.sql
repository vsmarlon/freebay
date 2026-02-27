-- ─── Enums ──────────────────────────────────────────────

DO $$ BEGIN
  CREATE TYPE "UserRole" AS ENUM ('USER', 'ADMIN');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE "Condition" AS ENUM ('NEW', 'USED');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE "ProductStatus" AS ENUM ('ACTIVE', 'SOLD', 'PAUSED', 'DELETED');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE "PostType" AS ENUM ('PRODUCT', 'REGULAR');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE "OrderStatus" AS ENUM ('PENDING', 'CONFIRMED', 'DISPUTED', 'COMPLETED', 'CANCELLED');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE "EscrowStatus" AS ENUM ('HELD', 'RELEASED', 'REFUNDED');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE "PaymentMethod" AS ENUM ('PIX', 'CREDIT_CARD');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE "PaymentProvider" AS ENUM ('PAGARME', 'WOOVI');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE "TransactionStatus" AS ENUM ('PENDING', 'PROCESSING', 'PAID', 'HELD', 'RELEASED', 'REFUNDED', 'FAILED');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE "DisputeStatus" AS ENUM ('OPEN', 'AWAITING_SELLER', 'AWAITING_BUYER', 'RESOLVED', 'CANCELLED');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE "ReviewType" AS ENUM ('BUYER_REVIEWING_SELLER', 'SELLER_REVIEWING_BUYER');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ─── Tables ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "User" (
  "id"              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "displayName"     VARCHAR(50) NOT NULL,
  "email"           VARCHAR(255) NOT NULL UNIQUE,
  "emailVerified"   BOOLEAN NOT NULL DEFAULT FALSE,
  "passwordHash"    VARCHAR(255) NOT NULL,
  "cpfHash"         VARCHAR(255) UNIQUE,
  "phone"           VARCHAR(20),
  "phoneVerified"   BOOLEAN NOT NULL DEFAULT FALSE,
  "city"            VARCHAR(100),
  "state"           VARCHAR(2),
  "avatarUrl"       TEXT,
  "bio"             VARCHAR(150),
  "isVerified"      BOOLEAN NOT NULL DEFAULT FALSE,
  "role"            "UserRole" NOT NULL DEFAULT 'USER',
  "reputationScore" DOUBLE PRECISION NOT NULL DEFAULT 0,
  "totalReviews"    INTEGER NOT NULL DEFAULT 0,
  "createdAt"       TIMESTAMP NOT NULL DEFAULT NOW(),
  "updatedAt"       TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS "idx_user_email" ON "User" ("email");
CREATE INDEX IF NOT EXISTS "idx_user_created_at" ON "User" ("createdAt");

-- ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "Post" (
  "id"            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "content"       TEXT,
  "type"          "PostType" NOT NULL,
  "userId"        UUID NOT NULL REFERENCES "User"("id"),
  "likesCount"    INTEGER NOT NULL DEFAULT 0,
  "commentsCount" INTEGER NOT NULL DEFAULT 0,
  "sharesCount"   INTEGER NOT NULL DEFAULT 0,
  "createdAt"     TIMESTAMP NOT NULL DEFAULT NOW(),
  "updatedAt"     TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS "idx_post_user_created" ON "Post" ("userId", "createdAt");

-- ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "Product" (
  "id"          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "title"       VARCHAR(100) NOT NULL,
  "description" TEXT NOT NULL,
  "price"       INTEGER NOT NULL,  -- centavos
  "condition"   "Condition" NOT NULL,
  "status"      "ProductStatus" NOT NULL DEFAULT 'ACTIVE',
  "sellerId"    UUID NOT NULL REFERENCES "User"("id"),
  "postId"      UUID UNIQUE REFERENCES "Post"("id"),
  "createdAt"   TIMESTAMP NOT NULL DEFAULT NOW(),
  "updatedAt"   TIMESTAMP NOT NULL DEFAULT NOW(),
  "deletedAt"   TIMESTAMP
);

CREATE INDEX IF NOT EXISTS "idx_product_seller_created" ON "Product" ("sellerId", "createdAt");
CREATE INDEX IF NOT EXISTS "idx_product_status" ON "Product" ("status");

-- ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "ProductImage" (
  "id"        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "url"       TEXT NOT NULL,
  "order"     INTEGER NOT NULL DEFAULT 0,
  "productId" UUID NOT NULL REFERENCES "Product"("id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "idx_product_image_product" ON "ProductImage" ("productId");

-- ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "Comment" (
  "id"        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "content"   TEXT NOT NULL,
  "userId"    UUID NOT NULL REFERENCES "User"("id"),
  "postId"    UUID NOT NULL REFERENCES "Post"("id") ON DELETE CASCADE,
  "createdAt" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS "idx_comment_post" ON "Comment" ("postId");

-- ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "Like" (
  "id"        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "userId"    UUID NOT NULL REFERENCES "User"("id"),
  "postId"    UUID NOT NULL REFERENCES "Post"("id") ON DELETE CASCADE,
  "createdAt" TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE ("userId", "postId")
);

CREATE INDEX IF NOT EXISTS "idx_like_post" ON "Like" ("postId");

-- ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "Follow" (
  "id"          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "followerId"  UUID NOT NULL REFERENCES "User"("id"),
  "followingId" UUID NOT NULL REFERENCES "User"("id"),
  "createdAt"   TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE ("followerId", "followingId")
);

-- ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "Order" (
  "id"                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "buyerId"             UUID NOT NULL REFERENCES "User"("id"),
  "sellerId"            UUID NOT NULL REFERENCES "User"("id"),
  "productId"           UUID NOT NULL REFERENCES "Product"("id"),
  "amount"              INTEGER NOT NULL,  -- centavos
  "platformFee"         INTEGER NOT NULL,
  "sellerAmount"        INTEGER NOT NULL,
  "status"              "OrderStatus" NOT NULL DEFAULT 'PENDING',
  "escrowStatus"        "EscrowStatus" NOT NULL DEFAULT 'HELD',
  "meetingScheduledAt"  TIMESTAMP,
  "deliveryConfirmedAt" TIMESTAMP,
  "createdAt"           TIMESTAMP NOT NULL DEFAULT NOW(),
  "updatedAt"           TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS "idx_order_buyer" ON "Order" ("buyerId");
CREATE INDEX IF NOT EXISTS "idx_order_seller" ON "Order" ("sellerId");
CREATE INDEX IF NOT EXISTS "idx_order_status" ON "Order" ("status");
CREATE INDEX IF NOT EXISTS "idx_order_product_status" ON "Order" ("productId", "status");

-- ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "Transaction" (
  "id"             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "orderId"        UUID NOT NULL UNIQUE REFERENCES "Order"("id"),
  "externalId"     VARCHAR(255),
  "amount"         INTEGER NOT NULL,
  "platformFee"    INTEGER NOT NULL,
  "sellerAmount"   INTEGER NOT NULL,
  "paymentMethod"  "PaymentMethod" NOT NULL,
  "provider"       "PaymentProvider" NOT NULL,
  "status"         "TransactionStatus" NOT NULL DEFAULT 'PENDING',
  "idempotencyKey" VARCHAR(255) NOT NULL UNIQUE,
  "pixQrCode"      TEXT,
  "pixExpiresAt"   TIMESTAMP,
  "paidAt"         TIMESTAMP,
  "releasedAt"     TIMESTAMP,
  "createdAt"      TIMESTAMP NOT NULL DEFAULT NOW(),
  "updatedAt"      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS "idx_transaction_status" ON "Transaction" ("status");
CREATE INDEX IF NOT EXISTS "idx_transaction_idempotency" ON "Transaction" ("idempotencyKey");

-- ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "Wallet" (
  "id"               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "userId"           UUID NOT NULL UNIQUE REFERENCES "User"("id"),
  "availableBalance" INTEGER NOT NULL DEFAULT 0,  -- centavos
  "pendingBalance"   INTEGER NOT NULL DEFAULT 0,
  "totalEarned"      INTEGER NOT NULL DEFAULT 0,
  "recipientId"      VARCHAR(255)
);

-- ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "Withdrawal" (
  "id"        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "walletId"  UUID NOT NULL REFERENCES "Wallet"("id"),
  "amount"    INTEGER NOT NULL,
  "status"    VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  "createdAt" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS "idx_withdrawal_wallet" ON "Withdrawal" ("walletId");

-- ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "Dispute" (
  "id"             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "orderId"        UUID NOT NULL UNIQUE REFERENCES "Order"("id"),
  "openedById"     UUID NOT NULL REFERENCES "User"("id"),
  "status"         "DisputeStatus" NOT NULL DEFAULT 'OPEN',
  "reason"         TEXT NOT NULL,
  "buyerEvidence"  JSONB,
  "sellerEvidence" JSONB,
  "resolution"     TEXT,
  "resolvedAt"     TIMESTAMP,
  "createdAt"      TIMESTAMP NOT NULL DEFAULT NOW(),
  "expiresAt"      TIMESTAMP NOT NULL
);

-- ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "Review" (
  "id"         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "reviewerId" UUID NOT NULL REFERENCES "User"("id"),
  "reviewedId" UUID NOT NULL REFERENCES "User"("id"),
  "orderId"    UUID NOT NULL REFERENCES "Order"("id"),
  "type"       "ReviewType" NOT NULL,
  "score"      INTEGER NOT NULL CHECK ("score" >= 1 AND "score" <= 5),
  "comment"    TEXT,
  "createdAt"  TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE ("reviewerId", "orderId", "type")
);

CREATE INDEX IF NOT EXISTS "idx_review_reviewed" ON "Review" ("reviewedId");

-- ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "ChatMessage" (
  "id"        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "orderId"   UUID NOT NULL REFERENCES "Order"("id"),
  "senderId"  UUID NOT NULL REFERENCES "User"("id"),
  "content"   TEXT NOT NULL,
  "readAt"    TIMESTAMP,
  "createdAt" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS "idx_chat_order_created" ON "ChatMessage" ("orderId", "createdAt");
