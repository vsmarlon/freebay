-- CreateIndex
CREATE INDEX IF NOT EXISTS "Comment_userId_idx" ON "Comment"("userId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "Like_userId_idx" ON "Like"("userId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "CommentLike_userId_idx" ON "CommentLike"("userId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "Share_userId_idx" ON "Share"("userId");
